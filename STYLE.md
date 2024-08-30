
# Coding Guidelines
This project uses the following coding guidelines in an effort to make the project
consistent, understandable, and maintainable.

## Modules and Scopes
Modules that export functions/variables must provide a header that imports said exports.
Imports must be wrapped in a scope with a name that matches the module's name with the first letter capitalized.
Public constants must be contained within the module's scope.
Macros my be defined outside of the modules scope since they don't obey scopes anyway.
All of the above also applied to header-only modules.

## Functions and Procedures
Function names should generally be a verb or verb-noun pair.
`snake_case` should be used for function names.

## Variables
Variable names should generally be nouns.
`PascalCase` should be used for variable names.
Variables should be prefixed according to the following table in the order they appear.

| prefix | meaning     | exclusive     | description |
|--------|-------------|---------------|-------------|
| r      | read-only   |               | data is read-only or treated as such in some context |
| z      | zero-page   |               | data exists in zero page |
| b      | byte        | w, d, q, s    | data is 1 byte in size |
| w      | word        | b, d, q, s    | data is 2 bytes in size |
| d      | double word | b, w, q, s    | data is 4 bytes in size |
| q      | quad word   | b, w, d, s    | data is 8 bytes in size |
| a      | array       | s             | data is an array |
| s      | string      | b, w, d, q, a | data is a C string |
| p      | pointer     |               | data is a pointer |

Prefixes should appear in the same order as the the above table.  
e.g. A 1 byte variable that is stored in zero page should be named like this.  

    zbMyByte
Arrays that store a basic type (byte, word, double word, quad word) should indicate that with a prefix.  
e.g. A word array should be named like this.  

    waMyWords
If an array stores a more complex type then only the array prefix is needed.  
e.g. An array of structs should be named like this.  

    aMyStructs
Pointers that point to a variety of types may omit the type specifier.  
e.g. A pointer that may point to a byte or a word should be named like this.  

    pMyPointer


## Constants and Enums

## Structs and Unions

## Custom Macros

## Documentation





## Linter
This project includes a custom linter in `tools/linter.py`.
The linter will enforce the following rules during compilation.
If the linter emits warnings then you're probably doing something wrong.

### Procedure Documentation
All procedures are required to have some amount of documentation directly preceding them.
```
.proc linter_error
    ; this function will make the linter complain.
    rts
.endproc
```

```
; the linter will not complain about this function.
.proc all_good
    rts
.endproc
```

### Tail Calls
The linter will warn about any procedures that end with a `jsr` instruction
followed directly by an `rts` instruction.
These should be optimized by changing the `jsr` to a `jmp` and removing the `rts`.

```
; do 3 things.
.proc unoptimized
    jsr do_something
    jsr do_other_stuff
    jsr do_the_last_thing
    rts
.endproc
```

```
; do 3 things, but better.
.proc optimized
    jsr do_something
    jsr do_other_stuff
    jmp do_the_last_thing
.endproc
```


### Linter Tags
The linter uses special tag comments to annotate the ends of a functions.
Functions may end in one of four ways.
 1. Returning with an `rts` or `rti` instruction.
    This is the "normal" way to end a function and no tag comment is required.
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
    These function are required to end with a `; [tail_jump]` tag comment
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
    This requires the function to end with a `; [tail_branch]` tag comment
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
    These functions require a `; [fall_through]` tag comment
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
