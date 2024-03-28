
.ifndef _IDENT_
_IDENT_ = 1

.scope Ident

    .import rbaIdentityTable

.endscope

.macro tyx
    ldx Ident::rbaIdentityTable, y
.endmacro

.macro txy
    ldy Ident::rbaIdentityTable, x
.endmacro

.macro and_x
    and Ident::rbaIdentityTable, x
.endmacro

.macro and_y
    and Ident::rbaIdentityTable, y
.endmacro

.macro ora_x
    ora Ident::rbaIdentityTable, x
.endmacro

.macro ora_y
    ora Ident::rbaIdentityTable, y
.endmacro

.macro eor_x
    eor Ident::rbaIdentityTable, x
.endmacro

.macro eor_y
    eor Ident::rbaIdentityTable, y
.endmacro

.macro adc_x
    adc Ident::rbaIdentityTable, x
.endmacro

.macro adc_y
    adc Ident::rbaIdentityTable, y
.endmacro

.macro sbc_x
    sbc Ident::rbaIdentityTable, x
.endmacro

.macro sbc_y
    sbc Ident::rbaIdentityTable, y
.endmacro

.macro cmp_x
    cmp Ident::rbaIdentityTable, x
.endmacro

.macro cmp_y
    cmp Ident::rbaIdentityTable, y
.endmacro

.macro bit_i arg
    bit Ident::rbaIdentityTable + arg
.endmacro

.endif
