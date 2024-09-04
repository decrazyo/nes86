
; this module provides temporary memory for any code that needs it.
; care must be taken when using these variables since any code can change them.

; use of these variables inside of interrupt handlers is allowed.
; interrupt handlers must save the content of a temp variable before using it
; and restore the content before returning from the interrupt handler.
; for that reason, the use of this temporary memory in interrupt handler is discouraged.

; the following general rules are followed to prevent conflicts in this memory space.
; when using these variables to pass arguments between functions,
; lower numbered variables should be used first.
; when using these variables to temporarily store data within a function,
; higher numbered variables should be used first.

.include "tmp.inc"

; many variables refer to the same memory locations.
; the different names are intended to clarify usage elsewhere in code.
.exportzp zd0 ; 32-bit variable (uses zb0 - zb3)
.exportzp zw0 ; 16-bit variable (uses zb0 - zb1)
.exportzp zb0 ; 8-bit variable
.exportzp zb1 ; 8-bit variable
.exportzp zw1 ; 16-bit variable (uses zb2 - zb3)
.exportzp zb2 ; 8-bit variable
.exportzp zb3 ; 8-bit variable

.segment "TEMP":zp

zd0:
zw0:
zb0: .res 1
zb1: .res 1
zw1:
zb2: .res 1
zb3: .res 1

; some functions may depend on this fact.
.assert zb0 = 0, error, "temporary memory does not start at address 0"
