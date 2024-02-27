
.ifndef _X86_REG_
.define _X86_REG_

.scope Reg
    ; main registers:
    .importzp zdEAX
    .importzp zdEBX
    .importzp zdECX
    .importzp zdEDX

    ; index registers:
    .importzp zdESI
    .importzp zdEDI
    .importzp zdEBP
    .importzp zdESP

    ; instruction pointer register
    .importzp zdEIP

    ; segment registers:
    .importzp zwCS
    .importzp zwDS
    .importzp zwES
    .importzp zwFS
    .importzp zwGS
    .importzp zwSS

    ; status register
    .importzp zbFlagsLo
    .importzp zbFlagsHi
    .importzp zbEFlagsLo
    .importzp zbEFlagsHi

    ; pseudo-registers:
    .importzp zdS0
    .importzp zdS1
    .importzp zdD0

    ; instruction encoding
    .importzp zbInstrEnc

    ; instruction length
    .importzp zbInstrLen

    ; instruction prefix
    .importzp zbInstrPrefix

    ; instruction buffer
    .importzp zbInstrOpcode
    .importzp zbInstrOperands

    .import reg

    ;          FEDCBA9876543210
    FLAG_SF = %0000000010000000 ; sign flag
    FLAG_ZF = %0000000001000000 ; zero flag
    ;         %0000000000100000 ; RESERVED
    FLAG_AF = %0000000000010000 ; auxiliary carry flag
    ;         %0000000000001000 ; RESERVED
    FLAG_PF = %0000000000000100 ; parity flag
    ;         %0000000000000010 ; RESERVED
    FLAG_CF = %0000000000000001 ; carry flag
    .import set_flag_lo
    .import clear_flag_lo

    ;          FEDCBA9876543210
    ;         %1000000000000000 ; RESERVED
    ;         %0100000000000000 ; RESERVED
    ;         %0010000000000000 ; RESERVED
    ;         %0001000000000000 ; RESERVED
    FLAG_OF = %0000100000000000 ; overflow flag
    FLAG_DF = %0000010000000000 ; direction flag
    FLAG_IF = %0000001000000000 ; interrupt flag
    FLAG_TF = %0000000100000000 ; trap flag
    .import set_flag_hi
    .import clear_flag_hi

    .import reg8_to_src0
    .import reg16_to_src0
    .import reg8_to_src1
    .import reg16_to_src1
    .import dst0_to_reg8
    .import dst0_to_reg16

    .ifdef DEBUG
    .import debug_reg
    .endif
.endscope

.endif

