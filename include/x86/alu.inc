
.ifndef _X86_ALU_
_X86_ALU_ = 1

.scope Alu
    ; increment
    .import inc_16
    .import inc_8

    ; decrement
    .import dec_16
    .import dec_8

    ; addition
    .import add_16_16
    .import add_8_8

    ; addition with carry
    .import adc_16_16
    .import adc_8_8

    ; subtract
    .import sub_16_16
    .import sub_8_8

    ; subtract with borrow
    .import sbb_16_16
    .import sbb_8_8

    ; unsigned multiplication
    .import mul_16_16
    .import mul_8_8

    ; unsigned division
    .import div_32_16
    .import div_16_8

    .import aam_8_8

    ; signed multiplication
    .import imul_16_16
    .import imul_8_8

    ; signed division
    .import idiv_32_16
    .import idiv_16_8

    ; two's complement negation
    .import neg_16
    .import neg_8

    ; one's complement negation
    .import not_16
    .import not_8

    ; bitwise and
    .import and_16_16
    .import and_8_8

    ; bitwise inclusive or
    .import or_16_16
    .import or_8_8

    ; bitwise exclusive or
    .import xor_16_16
    .import xor_8_8

    ; shift left
    .import shl_16_8
    .import shl_8_8

    ; shift right
    .import shr_16_8
    .import shr_8_8

    ; shift right and preserve sign
    .import sar_16_8
    .import sar_8_8

    ; rotate left
    .import rol_16_8
    .import rol_8_8

    ; rotate right
    .import ror_16_8
    .import ror_8_8

    ; rotate left through carry
    .import rcl_16_8
    .import rcl_8_8

    ; rotate right through carry
    .import rcr_16_8
    .import rcr_8_8

.endscope

.endif
