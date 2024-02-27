
# NES86
An x86 emulation layer for the NES.  
The ultimate goal of this project is to emulate an Intel 80386 processor (and supporting hardware)
well enough to run an unmodified (or lightly modified) Linux kernel, Bourne shell, and GNU utilities.  
The development strategy is to...
 1. Emulate the entirety of an 8086 processor and MMU.
 2. Enhancing the 8086 emulator to support 80186 functionality.
 3. Enhancing the 80186 emulator to support 80286 functionality.
 4. Probably re-write the whole fucking emulator to support 80386 functionality.
 5. Patch in support for any necessary PC peripherals.
 6. ???
 7. Profit.

## Variable Naming Convention
Variable names should generally be nouns.
`PascalCase` should be used for variable names.
Variables should be prefixed according to the following table.

| prefix | meaning     | description |
|--------|-------------|-------------|
| r      | read-only   | variable should be treated as read-only or is located in ROM |
| z      | zero-page   | variable exists in zero page |
| b      | byte        | variable is 1 byte in size or a pointer to such |
| w      | word        | variable is 2 bytes in size or a pointer to such |
| d      | double word | variable is 4 bytes in size or a pointer to such |
| q      | quad word   | variable is 8 bytes in size or a pointer to such |
| a      | array       | variable is an array or a pointer to such (mutually exclusive with "s") |
| s      | string      | variable is a C string or a pointer to such (mutually exclusive with "a") |
| p      | pointer     | variable is a data pointer |

Prefixes should appear in the same order as the the above table.  
e.g. A 1 byte variable that is stored in zero page should be named like this.  

    zbMyByte
Arrays that store a base type (byte, word, double word, quad word) should indicate that with a prefix.  
e.g. A word array should be named like this.  

    waMyWords
If an array stores a more complex type then only the array prefix is needed.  
e.g. An array of structs should be named like this.  

    aMyStructs
Pointers that point to a variety of types may omit the type specifier.  
e.g. A pointer that may point to a byte or a word should be named like this.  

    pMyPointer

## Function Naming Convention
Function names should generally be a verb or verb-noun pair.
`snake_case` should be used for function names.

## Modules
Modules that export functions/variables must provide a header that imports said exports.
Imports must be wrapped in a scope with a name that matches the module's name with the first letter capitalized.
Public constants must be contained within the module's scope.
Macros my be defined outside of the modules scope since they don't obey scopes anyway.
All of the above also applied to header-only modules.

## Definition of Terms
TODO: define the terms i'm using so that comments are consistent and understandable  

| term  | description |
|-------|-------------|
|  |  |

## Definition of Abbreviations
TODO: define the abbreviations i'm using so that comments are consistent and understandable  

| abbreviations | description |
|---------------|-------------|
| reg8          | 8-bit register |
| reg16         | 16-bit register |
| imm8          | 8-bit immediate value |
| imm16         | 16-bit immediate value |
