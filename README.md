
# NES86

A x86 emulation layer for the NES.

## Variable Naming Convention
variable names should generally be nouns.
camel case should be used for variable names.
variables should be prefixed according to the following table.

| prefix | meaning     | description |
|--------|-------------|-------------|
| g      | global      | variable is exported from a module |
| r      | read-only   | variable or ROM data is read-only |
| z      | zero-page   | variable exists in zero page |
| p      | pointer     | variable is a data pointer (mutually exclusive with "f") |
| f      | function    | variable is a function pointer (mutually exclusive with "p") |
| b      | byte        | variable is 1 byte in size |
| w      | word        | variable is 2 bytes in size |
| d      | double word | variable is 4 bytes in size |
| q      | quad word   | variable is 8 bytes in size |
| a      | array       | variable is an array (mutually exclusive with "s") |
| s      | string      | variable is a C string (mutually exclusive with "a") |

prefixes should appear in the same order as the the above table.
e.g. a 1 byte variable that is stored in zero page and is exported should be named like this.
    gzbMyByte
arrays that store a base type (byte, word, double word, quad word) should indicate that with a prefix.
e.g. a word array should be named like this.
    waMyWords
if an array stores a more complex type then only the array prefix is needed.
e.g. an array of structs should be named like this.
    aMyStructs

## Function Naming Convention
function names should generally be a verb or verb-noun pair
exported functions should be prefixed with the name of the module that they are being exported from.
snake case should be used for function names.

## Definition of Terms

TODO: define the terms i'm using so that comments are consistent and understandable

| term  | description |
|-------|-------------|
|  |  |

## Common Abbreviations

| abbreviations | description |
|---------------|-------------|
| reg8          | 8-bit register |
| reg16         | 16-bit register |
| imm8          | 8-bit immediate value |
| imm16         | 16-bit immediate value |

