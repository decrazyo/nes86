
.ifndef _TMP_
_TMP_ = 1

.scope Tmp
    ; data stored in these temp locations cannot be guaranteed to exist
    ; after leaving the scope that the data was created in.
    ; i.e. any non-interrupt function can use these locations at any time.
    ; they may also be used for passing arguments to/from functions.
    ; generally, lower numbered temp variables are used for argument passing.
    ; many variables refer to the same memory locations.
    ; the different names are intended to clarify usage elsewhere in code.
    .importzp zd0 ; 32-bit variable (uses zb0 - zb3)
    .importzp zw0 ; 16-bit variable (uses zb0 - zb1)
    .importzp zb0 ; 8-bit variable
    .importzp zb1 ; 8-bit variable
    .importzp zw1 ; 16-bit variable (uses zb2 - zb3)
    .importzp zb2 ; 8-bit variable
    .importzp zb3 ; 8-bit variable

    .import set_zp_ptr0
    .import set_zp_ptr1
    .import set_ptr0
    .import set_ptr1

    .import memcpy
.endscope

.endif
