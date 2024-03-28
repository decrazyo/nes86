
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

    ; shift/rotate 1 bit:

    ; shift left
    .import shl16_1
    .import shl8_1

    ; shift right
    .import shr16_1
    .import shr8_1

    ; shift right and preserve sign
    .import sar16_1
    .import sar8_1

    ; rotate left
    .import rol16_1
    .import rol8_1

    ; rotate right
    .import ror16_1
    .import ror8_1

    ; rotate left through carry
    .import rcl16_1
    .import rcl8_1

    ; rotate right through carry
    .import rcr16_1
    .import rcr8_1

    ; shift/rotate N bits:

    ; shift left multiple times
    .import shl16_n
    .import shl8_n

    ; shift right multiple times
    .import shr16_n
    .import shr8_n

    ; shift right and preserve sign multiple times
    .import sar16_n
    .import sar8_n

    ; rotate left multiple times
    .import rol16_n
    .import rol8_n

    ; rotate right multiple times
    .import ror16_n
    .import ror8_n

    ; rotate left through carry multiple times
    .import rcl16_n
    .import rcl8_n

    ; rotate right through carry multiple times
    .import rcr16_n
    .import rcr8_n

    ; extended ALU functions.

    .import add16_ex
    .import adc16_ex

    .import add8_ex
    .import adc8_ex

    ; special-purpose ALU functions.



.endscope

.endif
