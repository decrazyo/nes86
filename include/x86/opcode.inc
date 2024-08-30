
.ifndef _X86_OPCODE_
    _X86_OPCODE_ = 1

    .scope Opcode

        ; NOTE: some enum values do not follow the normal upper case naming convention.
        ;       instead, they borrow from the naming convention used here...
        ;       http://www.mlsite.net/8086/
        ;       http://www.mlsite.net/8086/8086_table.txt
        ;       the linter will complain about this
        ;       but *.inc files aren't linted at compile time so i'm ignoring it.

        .enum
            ; $00
            ADD_Eb_Gb
            ADD_Ev_Gv
            ADD_Gb_Eb
            ADD_Gv_Ev
            ADD_AL_Ib
            ADD_AX_Iv
            PUSH_ES
            POP_ES
            OR_Eb_Gb
            OR_Ev_Gv
            OR_Gb_Eb
            OR_Gv_Ev
            OR_AL_Ib
            OR_AX_Iv
            PUSH_CS
            NONE_0Fh ; invalid opcode
            ; $10
            ADC_Eb_Gb
            ADC_Ev_Gv
            ADC_Gb_Eb
            ADC_Gv_Ev
            ADC_AL_Ib
            ADC_AX_Iv
            PUSH_SS
            POP_SS
            SBB_Eb_Gb
            SBB_Ev_Gv
            SBB_Gb_Eb
            SBB_Gv_Ev
            SBB_AL_Ib
            SBB_AX_Iv
            PUSH_DS
            POP_DS
            ; $20
            AND_Eb_Gb
            AND_Ev_Gv
            AND_Gb_Eb
            AND_Gv_Ev
            AND_AL_Ib
            AND_AX_Iv
            ES ; segment prefix
            DAA
            SUB_Eb_Gb
            SUB_Ev_Gv
            SUB_Gb_Eb
            SUB_Gv_Ev
            SUB_AL_Ib
            SUB_AX_Iv
            CS ; segment prefix
            DAS
            ; $30
            XOR_Eb_Gb
            XOR_Ev_Gv
            XOR_Gb_Eb
            XOR_Gv_Ev
            XOR_AL_Ib
            XOR_AX_Iv
            SS ; segment prefix
            AAA
            CMP_Eb_Gb
            CMP_Ev_Gv
            CMP_Gb_Eb
            CMP_Gv_Ev
            CMP_AL_Ib
            CMP_AX_Iv
            DS ; segment prefix
            AAS
            ; $40
            INC_AX
            INC_CX
            INC_DX
            INC_BX
            INC_SP
            INC_BP
            INC_SI
            INC_DI
            DEC_AX
            DEC_CX
            DEC_DX
            DEC_BX
            DEC_SP
            DEC_BP
            DEC_SI
            DEC_DI
            ; $50
            PUSH_AX
            PUSH_CX
            PUSH_DX
            PUSH_BX
            PUSH_SP
            PUSH_BP
            PUSH_SI
            PUSH_DI
            POP_AX
            POP_CX
            POP_DX
            POP_BX
            POP_SP
            POP_BP
            POP_SI
            POP_DI
            ; $60
            NONE_60h ; invalid opcode
            NONE_61h ; invalid opcode
            NONE_62h ; invalid opcode
            NONE_63h ; invalid opcode
            NONE_64h ; invalid opcode
            NONE_65h ; invalid opcode
            NONE_66h ; invalid opcode
            NONE_67h ; invalid opcode
            NONE_68h ; invalid opcode
            NONE_69h ; invalid opcode
            NONE_6Ah ; invalid opcode
            NONE_6Bh ; invalid opcode
            NONE_6Ch ; invalid opcode
            NONE_6Dh ; invalid opcode
            NONE_6Eh ; invalid opcode
            NONE_6Fh ; invalid opcode
            ; $70
            JO_Jb
            JNO_Jb
            JB_Jb
            JAE_Jb
            JZ_Jb
            JNZ_Jb
            JNA_Jb
            JA_Jb
            JS_Jb
            JNS_Jb
            JPE_Jb
            JPO_Jb
            JL_Jb
            JNL_Jb
            JNG_Jb
            JG_Jb
            ; $80
            GRP1_Eb_Ib
            GRP1_Ev_Iv
            ; this appears to be a more limited version of "GRP1_Eb_Ib".
            ; we'll implement to be identical to "GRP1_Eb_Ib" for simplicity.
            ; naming this "GRP1_82h" because "GRP1_Eb_Ib" is already in use.
            GRP1_82h
            GRP1_Ev_Ib
            TEST_Gb_Eb
            TEST_Gv_Ev
            XCHG_Gb_Eb
            XCHG_Gv_Ev
            MOV_Eb_Gb
            MOV_Ev_Gv
            MOV_Gb_Eb
            MOV_Gv_Ev
            MOV_Ew_Sw
            LEA_Gv_M
            MOV_Sw_Ew
            POP_Ev
            ; $90
            NOP
            XCHG_CX_AX
            XCHG_DX_AX
            XCHG_BX_AX
            XCHG_SP_AX
            XCHG_BP_AX
            XCHG_SI_AX
            XCHG_DI_AX
            CBW
            CWD
            CALL_Ap
            WAIT
            PUSHF
            POPF
            SAHF
            LAHF
            ; $A0
            MOV_AL_Ob
            MOV_AX_Ov
            MOV_Ob_AL
            MOV_Ov_AX
            MOVSB
            MOVSW
            CMPSB
            CMPSW
            TEST_AL_Ib
            TEST_AX_Iv
            STOSB
            STOSW
            LODSB
            LODSW
            SCASB
            SCASW
            ; $B0
            MOV_AL_Ib
            MOV_CL_Ib
            MOV_DL_Ib
            MOV_BL_Ib
            MOV_AH_Ib
            MOV_CH_Ib
            MOV_DH_Ib
            MOV_BH_Ib
            MOV_AX_Iv
            MOV_CX_Iv
            MOV_DX_Iv
            MOV_BX_Iv
            MOV_SP_Iv
            MOV_BP_Iv
            MOV_SI_Iv
            MOV_DI_Iv
            ; $C0
            NONE_C0h ; invalid opcode
            NONE_C1h ; invalid opcode
            RET_Iw
            RET
            LES_Gv_Mp
            LDS_Gv_Mp
            MOV_Eb_Ib
            MOV_Ev_Iv
            NONE_C8h ; invalid opcode
            NONE_C9h ; invalid opcode
            RETF_Iw
            RETF
            INT3
            INT_Ib
            INTO
            IRET
            ; $D0
            GRP2_Eb_1
            GRP2_Ev_1
            GRP2_Eb_CL
            GRP2_Ev_CL
            AAM_I0
            AAD_I0
            NONE_D6h ; invalid opcode
            XLAT
            NONE_D8h ; invalid opcode
            NONE_D9h ; invalid opcode
            NONE_DAh ; invalid opcode
            NONE_DBh ; invalid opcode
            NONE_DCh ; invalid opcode
            NONE_DDh ; invalid opcode
            NONE_DEh ; invalid opcode
            NONE_DFh ; invalid opcode
            ; $E0
            LOOPNZ_Jb
            LOOPZ_Jb
            LOOP_Jb
            JCXZ_Jb
            IN_AL_Ib
            IN_AX_Ib
            OUT_Ib_AL
            OUT_Ib_AX
            CALL_Jv
            JMP_Jv
            JMP_Ap
            JMP_Jb
            IN_AL_DX
            IN_AX_DX
            OUT_DX_AL
            OUT_DX_AX
            ; $F0
            LOCK ; lock prefix
            NONE_F1h ; invalid opcode
            REPNZ ; repeat prefix
            REPZ ; repeat prefix
            HLT
            CMC
            GRP3_Eb
            GRP3_Ev
            CLC
            STC
            CLI
            STI
            CLD
            STD
            GRP4_Eb
            GRP4_Ev
        .endenum

        .enum eGroup1
            ADD
            OR
            ADC
            SBB
            AND
            SUB
            XOR
            CMP
        .endenum

        .enum eGroup2
            ROL
            ROR
            RCL
            RCR
            SHL
            SHR
            NONE_06h ; invalid extended opcode
            SAR
        .endenum

        .enum eGroup3
            TEST
            NONE_01h ; invalid extended opcode
            NOT
            NEG
            MUL
            IMUL
            DIV
            IDIV
        .endenum

        .enum eGroup4
            INC
            DEC
            CALL
            CALL_Mp
            JMP
            JMP_Mp
            PUSH
            NONE_07h ; invalid extended opcode
        .endenum

    .endscope

.endif
