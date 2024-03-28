
.ifndef _X86_ALU_
_X86_ALU_ = 1

.scope Alu
    .import alu

    ; convert byte to word
    .import cbw

    ; convert word to double
    .import cwd

    ; increment
    .import inc16
    .import inc8

    ; decrement
    .import dec16
    .import dec8

    ; addition
    .import add8
    .import add16

    ; addition with carry
    .import adc16
    .import adc8

    ; subtract
    .import sub16
    .import sub8

    ; subtract with borrow
    .import sbb16
    .import sbb8

    ; unsigned multiplication
    .import mul16
    .import mul8

    ; unsigned division
    .import div16
    .import div8

    ; signed multiplication
    .import imul16
    .import imul8

    ; signed division
    .import idiv16
    .import idiv8

    ; two's complement negation
    .import neg16
    .import neg8

    ; one's complement negation
    .import not16
    .import not8

    ; bitwise and
    .import and16
    .import and8

    ; bitwise inclusive or
    .import or16
    .import or8

    ; bitwise exclusive or
    .import xor16
    .import xor8

    ; shift left
    .import shl16
    .import shl8

    ; shift right
    .import shr16
    .import shr8

    ; shift right and preserve sign
    .import sar16
    .import sar8

    ; rotate left
    .import rol16
    .import rol8

    ; rotate right
    .import ror16
    .import ror8

    ; rotate left through carry
    .import rcl16
    .import rcl8

    ; rotate right through carry
    .import rcr16
    .import rcr8

    ; extended ALU functions.

    .import add16_ex
    .import adc16_ex

    .import add8_ex
    .import adc8_ex

    ; special-purpose ALU functions.



.endscope

.endif
