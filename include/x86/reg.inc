
.ifndef _X86_REG_
    _X86_REG_ = 1

    .scope Reg

        .importzp zwAX
        .importzp zbAL
        .importzp zbAH

        .importzp zwBX
        .importzp zbBL
        .importzp zbBH

        .importzp zwCX
        .importzp zbCL
        .importzp zbCH

        .importzp zwDX
        .importzp zbDL
        .importzp zbDH

        .importzp zwSI
        .importzp zwDI
        .importzp zwBP
        .importzp zwSP

        .importzp zwIP

        .importzp zwES
        .importzp zwCS
        .importzp zwSS
        .importzp zwDS

        .importzp zwFlags
        .importzp zbFlagsLo
        .importzp zbFlagsHi

        .importzp zwS0X
        .importzp zbS0L
        .importzp zbS0H
        .importzp zwS1X
        .importzp zbS1L
        .importzp zbS1H
        .importzp zwS2X
        .importzp zbS2L
        .importzp zbS2H

        .importzp zwD0X
        .importzp zbD0L
        .importzp zbD0H
        .importzp zwD1X
        .importzp zbD1L
        .importzp zbD1H
        .importzp zwD2X
        .importzp zbD2L
        .importzp zbD2H

        .importzp rzbaRegMapsBegin
        .importzp rzbaSegRegMap
        .importzp rzbaReg8Map
        .importzp rzbaReg16Map
        .importzp rzbaMem0Map
        .importzp rzbaMem1Map
        .importzp rzbaRegMapsEnd

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

        FLAGS_MASK_LO = FLAG_SF | FLAG_ZF | FLAG_AF | FLAG_PF | FLAG_CF
        FLAGS_MASK_HI = FLAG_OF | FLAG_DF | FLAG_IF | FLAG_TF

        FLAGS_MASK = FLAGS_MASK_LO | FLAGS_MASK_HI

        .enum eSeg
            ES
            CS
            SS
            DS
        .endenum

        .enum eReg8
            AL
            CL
            DL
            BL
            AH
            CH
            DH
            BH
        .endenum

        .enum eReg16
            AX
            CX
            DX
            BX
            SP
            BP
            SI
            DI
        .endenum

    .endscope

.endif
