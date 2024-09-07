
# Coding Guidelines
This project uses the following coding guidelines in an effort to make the project
consistent, understandable, and maintainable.
Most of the guidelines are enforced by the project's linter `tools/lint65.py`.
If the linter is emitting warnings then you're probably doing something wrong.

## Modules
Modules that export functions, variables, or data must provide a header that imports said exports.
Module headers must wrap their content in a C-like include guard.
Imports and constants must be wrapped in a `.scope` with a name matching the module's name.
Macros my be defined outside of the modules scope since they don't obey scopes anyway.
All of the above also applied to header-only modules.  

Example:  
```
; module.inc

.ifndef _MODULE_
    _MODULE_ = 1

    .scope Module

        .importzp zbMyExportedVar

        .import some_function
        .import another_function

    .endscope

.endif

```

## Functions
Functions must be defined with a `.proc` command.
Function names must be written in `snake_case`.
Each function must be preceded by a comment that documents the function.
Functions may be given an alias be defining a label before the function's documentation command.

Example:  
```
; alias
bitwise_not:
; perform a bitwise NOT on the content of A.
; < A = value to be negated
; > A = negated value
; changes: A
.proc not
    eor #$ff
    rts
.endproc
```

### Mnemonics
Assembly mnemonics are only allowed inside of functions and must be written in `lower case`.


### Linter Tags
Functions may need to be annotated with linter tags depending on how the function ends.
Functions may end in one of four ways.

 1. Returning with an `rts` or `rti` instruction.
    This is the "normal" way to end a function and no tag is required.
    ```
    .proc normal_function_example
        clc
        adc #$69
        rts
    .endproc
    ```

 2. Jumping to another function with a `jmp` instruction. 
    This is frequently done to optimize a `jsr` followed by an `rts`
    but it can easily cause bugs when carelessly editing a function.
    These function are required to end with a `; [tail_jump]` tag
    to make the tail jump more obvious.
    ```
    .proc tail_jump_example
        jsr do_something
        jsr do_other_stuff
        jmp do_the_last_thing
        ; [tail_jump]
    .endproc
    ```

 3. Branching to another function with a conditional branch instruction.
    This requires the function to end with a `; [tail_branch]` tag
    to encourage programmers to assess under what condition(s) the branch is taken
    and if the following function may be executed if the branch isn't taken.
    ```
    .proc tail_branch_example
        lsr
        bcc do_even_things ; branch if A was even.
        ; [tail_branch]
    .endproc

    .proc do_odd_things
        rol
        adc #1
        rts
    .endproc
    ```

 4. Falling through to another function.
    This is frequently done as an optimization,
    particularly for functions that have an 8-bit and a 16-bit version.
    These functions require a `; [fall_through]` tag
    since they depend on the function that follows it.
    ```
    .proc do_two_things
        jsr do_something_else
        ; [fall_through]
    .endproc

    .proc do_one_thing
        jsr do_something
        rts
    .endproc
    ```

## Constants
Use of constants is highly encouraged in order to avoid "magic numbers".
i.e. Some number that is essential for the program to function but not immediately understandable.
Constants must be written in `UPPER_CASE`.  
Bad example:  
```
and #$4a
sta $1234
```

Good example:  
```
; a hypothetical I/O port
SOME_MEM_MAPPED_IO_PORT = $1234

; hypothetical I/O port bit masks
IO_PORT_IMPOTANT_BIT_A = %00000100 ; controls some hardware feature
IO_PORT_IMPOTANT_BIT_B = %00001000 ; controls another hardware feature
IO_PORT_MASK = IO_PORT_IMPOTANT_BIT_A | IO_PORT_IMPOTANT_BIT_B

and #IO_PORT_MASK
sta SOME_MEM_MAPPED_IO_PORT
```

## Macros
Use of macros is generally discouraged since they tend to over-complicate code and make debugging harder.
Macros are allowed if they provide a substantial benefit to readability or maintainability.
For example, macros are commonly used to generate jump tables, lookup tables, and table offsets.
Macros must be thoroughly documented in the same was as functions.
### `.macro`-style Macros
Macro names, parameters, and variables must be written in `snake_case`.  

Example:  
```
counter .set 0

; add 1 to the specified counter.
; < count = initial counter value.
; > count = incremented counter.
.macro increment_counter count
    .local count
    count .set count + 1
    .out .sprintf("count: %i", count)
.endmacro

increment_counter counter
```
### `.define`-style Macros
Macro names must be written in `UPPER_CASE`.
Macro parameters must be written in `snake_case`.  

Example:  
```
; calculate an offset into the "raStartOfTable" table.
; < label = a label inside of the "raStartOfTable" table.
.define CALCULATE_OFFSET(label) label - raStartOfTable
```

## Labels
This project uses 2 different styles of labels, code labels and data labels.

### Code Labels
Code labels are used to label executable code and must be written in `snake_case`.
The linter will assume that any label in a `"CODE"` segment or inside a function is a code label.
Code labels defined in other locations must followed by a `; [code_label]` tag.  

Example:  
```
.segment "CODE"

my_fucntion_alias:
; function that does nothing
.proc my_fucntion
    nop
done:
    rts
.endproc
```

### Data Labels
Data labels are used to label data in RAM or ROM and must be written in `PascalCase`.
The linter will assume that any label outside of a function and `"CODE"` segment is a data label.
Data labels defined in other locations must followed by a `; [data_label]` tag.
Data labels must be prefixed according to the following table.  

| prefix | meaning     | exclusive     | description |
|--------|-------------|---------------|-------------|
| r      | read-only   |               | data is read-only or treated as such in some context |
| z      | zero-page   |               | data exists in zero page |
| b      | byte        | w, d, q, s    | data is 1 byte in size |
| w      | word        | b, d, q, s    | data is 2 bytes in size |
| d      | double word | b, w, q, s    | data is 4 bytes in size |
| q      | quad word   | b, w, d, s    | data is 8 bytes in size |
| a      | array       | s             | data is an array |
| s      | string      | b, w, d, q, a | data is a NULL-terminated C string |
| p      | pointer     |               | data is a pointer |

Example:  
```
.segment "ZEROPAGE"

; zero-page byte variable
zbMyByteVar: .res 1

; zero-page word variable
zwMyWordVar: .res 2

; zero-page byte treated as read-only in some context
zrbMyByteVar: .res 1

; zero-page byte array
ARRAY_SIZE = 8
zbaMyByteArray: .res ARRAY_SIZE

; zero-page pointer to something
zpMyPointer: .res 2

; zero-page pointer to a byte
zbpMyBytePointer: .res 2

.segment "BSS"

; byte variable
bMyByteVar: .res 1

; pointer to something
pMyPointer: .res 2

.segment "RODATA"

; read-only byte array
rbaMyByteArray:
.byte $11, $22, $33, $44, $55, $66, $77, $88

; read-only string
rsMyString:
.asciiz "read-only string"

.segment "CODE"

; read-only byte array in code
rbaMyByteArrayInCode: ; [data_label]
.byte $11, $22, $33, $44, $55, $66, $77, $88

```

## Structs and Unions
Use of `.struct` and `.union` is limited to arrays of structured data.
Struct and union may be unnamed or have names written in `PascalCase`.
Named structs must be prefixed with `s` and named unions must be prefixed with `u`
Member names must be written in `PascalCase` with a prefix which indicates their type.
Member names must not use the `z` and `r` prefixes.  

Example:  
```
.struct sPoint
    bPosX .byte
    bPosY .byte
.endstruct

NUMBER_OF_POINTS = 8
aPointArray: .res NUMBER_OF_POINTS * .sizeof(sPoint)
```

## Enums
Use of `.enum` encouraged.
Enums may be unnamed or have names written in `PascalCase`.
Named enums must be prefixed with `e`.
Member names must be written in `UPPER_CASE`.  

Example:  
```
.enum eMyEnum
    FOO
    BAR
    BAZ
    QUX
.endenum
```
