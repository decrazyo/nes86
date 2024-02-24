
.ifndef _TMP_
.define _TMP_

; data stored in these temp locations cannot be guaranteed to exist
; after leaving the scope that the data was created in.
; i.e. any non-interrupt function can use these locations at any time.
; they may also be used for passing arguments to functions.
; generally, lower numbered temp variables are used for argument pasing.
; many variables refer to the same memory locations.
; the different names are intended to clarify usage elsewhere in code.

.globalzp gzdTmp0 ; 32-bit variable (uses gzbTmp0 - gzbTmp3)
.globalzp gzwTmp0 ; 16-bit variable (uses gzbTmp0 - gzbTmp1)
.globalzp gzbTmp0 ; 8-bit variable
.globalzp gzbTmp1 ; 8-bit variable
.globalzp gzwTmp1 ; 16-bit variable (uses gzbTmp2 - gzbTmp3)
.globalzp gzbTmp2 ; 8-bit variable
.globalzp gzbTmp3 ; 8-bit variable

.endif
