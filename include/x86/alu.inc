
.ifndef _X86_ALU_
_X86_ALU_ = 1

.scope Alu
    .import alu

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

    ; TODO: add signed multiplication and division

    ; signed multiplication
    ;.import imul16
    ;.import imul8

    ; signed division
    ;.import idiv16
    ;.import idiv8

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

    ; extended shift/rotate functions.

    ; shift left multiple times
    .import shl16_ex
    .import shl8_ex

    ; shift right multiple times
    .import shr16_ex
    .import shr8_ex

    ; shift right and preserve sign multiple times
    .import sar16_ex
    .import sar8_ex

    ; rotate left multiple times
    .import rol16_ex
    .import rol8_ex

    ; rotate right multiple times
    .import ror16_ex
    .import ror8_ex

    ; rotate left through carry multiple times
    .import rcl16_ex
    .import rcl8_ex

    ; rotate right through carry multiple times
    .import rcr16_ex
    .import rcr8_ex

.endscope

.endif
