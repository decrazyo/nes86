
; This module is responsible for writing values to registers and the x86 address space.
; If an instruction's opcode indicates that it simply moves a value to or from a fixed
; location, i.e. a specific register or the stack, then this module may read that value.
; This module may decode instructions to determine where to write data.
; If this module must write to the x86 address space then it expects the MMU
; to have already been configured for that write by the "decode" stage.
; If this module writes to "CS" or "IP" then it must flag the MMU's code address as dirty.
; If this module writes to "SS" or "SP" then it must flag the MMU's stack address as dirty.
;
; uses:
;   Mmu::set_byte
;   Mmu::inc_address
;   Mmu::push_word
;   Mmu::pop_word
; changes:
;   Mmu::zbStackDirty
;   Mmu::zbCodeDirty
;   Reg::zwAX
;   Reg::zwBX
;   Reg::zwCX
;   Reg::zwDX
;   Reg::zwSI
;   Reg::zwDI
;   Reg::zwBP
;   Reg::zwSP
;   Reg::zwIP
;   Reg::zwES
;   Reg::zwCS
;   Reg::zwSS
;   Reg::zwDS

.include "x86/write.inc"
.include "x86/fetch.inc"
.include "x86/decode.inc"
.include "x86/interrupt.inc"
.include "x86/reg.inc"
.include "x86/mem.inc"
.include "x86.inc"

.include "tmp.inc"
.include "const.inc"

.export write

.segment "RODATA"

; map instruction encodings to their write functions.
rbaWriteFuncLo:
.byte <(write_nothing-1)
.byte <(write_d0l_rm8-1)
.byte <(write_d0x_rm16-1)
.byte <(write_d0l_reg8-1)
.byte <(write_d0x_reg16-1)
.byte <(write_d0l_al-1)
.byte <(write_d0x_ax-1)
.byte <(write_d0l_mem8-1)
.byte <(write_d0x_mem16-1)
.byte <(write_d0x_seg16-1)
.byte <(write_d0l_reg8_d1l_rm8-1)
.byte <(write_d0x_reg16_d1x_rm16-1)
.byte <(write_d0x_reg16_d1x_ax-1)
.byte <(write_d0x_ds_d1x_reg16-1)
.byte <(write_d0x_es_d1x_reg16-1)
.byte <(write_d0l_ah-1)
.byte <(write_d0l_flags_lo-1)
.byte <(write_d0x_flags-1)
.byte <(write_d0l_al_d1l_ah-1)
.byte <(write_d0x_ax_d1x_dx-1)
.byte <(write_d0l_mem8_di-1)
.byte <(write_d0x_mem16_di-1)
.byte <(write_group1a-1)
.byte <(write_group1b-1)
.byte <(write_group3a-1)
.byte <(write_group3b-1)
.byte <(write_group4b-1)
.byte <(write_bad-1)
rbaWriteFuncHi:
.byte >(write_nothing-1)
.byte >(write_d0l_rm8-1)
.byte >(write_d0x_rm16-1)
.byte >(write_d0l_reg8-1)
.byte >(write_d0x_reg16-1)
.byte >(write_d0l_al-1)
.byte >(write_d0x_ax-1)
.byte >(write_d0l_mem8-1)
.byte >(write_d0x_mem16-1)
.byte >(write_d0x_seg16-1)
.byte >(write_d0l_reg8_d1l_rm8-1)
.byte >(write_d0x_reg16_d1x_rm16-1)
.byte >(write_d0x_reg16_d1x_ax-1)
.byte >(write_d0x_ds_d1x_reg16-1)
.byte >(write_d0x_es_d1x_reg16-1)
.byte >(write_d0l_ah-1)
.byte >(write_d0l_flags_lo-1)
.byte >(write_d0x_flags-1)
.byte >(write_d0l_al_d1l_ah-1)
.byte >(write_d0x_ax_d1x_dx-1)
.byte >(write_d0l_mem8_di-1)
.byte >(write_d0x_mem16_di-1)
.byte >(write_group1a-1)
.byte >(write_group1b-1)
.byte >(write_group3a-1)
.byte >(write_group3b-1)
.byte >(write_group4b-1)
.byte >(write_bad-1)
rbaWriteFuncEnd:

.assert (rbaWriteFuncHi - rbaWriteFuncLo) = (rbaWriteFuncEnd - rbaWriteFuncHi), error, "incomplete write function"

; instruction encodings
.enum
    W00 ; write_nothing
    W01 ; write_d0l_rm8
    W02 ; write_d0x_rm16
    W03 ; write_d0l_reg8
    W04 ; write_d0x_reg16
    W05 ; write_d0l_al
    W06 ; write_d0x_ax
    W07 ; write_d0l_mem8
    W08 ; write_d0x_mem16
    W09 ; write_d0x_seg16
    W10 ; write_d0l_reg8_d1l_rm8
    W11 ; write_d0x_reg16_d1x_rm16
    W12 ; write_d0x_reg16_d1x_ax
    W13 ; write_d0x_ds_d1x_reg16
    W14 ; write_d0x_es_d1x_reg16
    W15 ; write_d0l_ah
    W16 ; write_d0l_flags_lo
    W17 ; write_d0x_flags
    W18 ; write_d0l_al_d1l_ah
    W19 ; write_d0x_ax_d1x_dx
    W20 ; write_d0l_mem8_di
    W21 ; write_d0x_mem16_di
    W22 ; write_group1a
    W23 ; write_group1b
    W24 ; write_group3a
    W25 ; write_group3b
    W26 ; write_group4b

    BAD ; used for unimplemented or non-existent instructions
    FUNC_COUNT ; used to check function table size at compile-time
.endenum

.assert (rbaWriteFuncHi - rbaWriteFuncLo) = FUNC_COUNT, error, "write function count"

; map opcodes to instruction encodings
rbaInstrWrite:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte W01,W02,W03,W04,W05,W06,W00,W09,W01,W02,W03,W04,W05,W06,W00,BAD ; 0_
.byte W01,W02,W03,W04,W05,W06,W00,W09,W01,W02,W03,W04,W05,W06,W00,W09 ; 1_
.byte W01,W02,W03,W04,W05,W06,BAD,W05,W01,W02,W03,W04,W05,W06,BAD,W05 ; 2_
.byte W01,W02,W03,W04,W05,W06,BAD,W06,W00,W00,W00,W00,W00,W00,BAD,W06 ; 3_
.byte W04,W04,W04,W04,W04,W04,W04,W04,W04,W04,W04,W04,W04,W04,W04,W04 ; 4_
.byte W00,W00,W00,W00,W00,W00,W00,W00,W04,W04,W04,W04,W04,W04,W04,W04 ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte W00,W00,W00,W00,W00,W00,W00,W00,W00,W00,W00,W00,W00,W00,W00,W00 ; 7_
.byte W22,W23,BAD,W23,W00,W00,W10,W11,W01,W02,W03,W04,W02,W04,W09,W02 ; 8_
.byte W00,W12,W12,W12,W12,W12,W12,W12,W06,W19,W00,W00,W00,W17,W16,W15 ; 9_
.byte W05,W06,W07,W08,W20,W21,W00,W00,W00,W00,W20,W21,W05,W06,W00,W00 ; A_
.byte W03,W03,W03,W03,W03,W03,W03,W03,W04,W04,W04,W04,W04,W04,W04,W04 ; B_
.byte BAD,BAD,W00,W00,W14,W13,W01,W02,BAD,BAD,W00,W00,W00,W00,W00,W00 ; C_
.byte W01,W02,W01,W02,W18,W06,BAD,W05,W00,W00,W00,W00,W00,W00,W00,W00 ; D_
.byte W00,W00,W00,W00,W05,W06,W00,W00,W00,W00,W00,W00,W05,W06,W00,W00 ; E_
.byte BAD,BAD,BAD,BAD,W00,W00,W24,W25,W00,W00,W00,W00,W00,W00,W01,W26 ; F_


.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; write data back to memory or registers after execution.
.proc write
    ldx Fetch::zbInstrOpcode
    ldy rbaInstrWrite, x
    lda rbaWriteFuncHi, y
    pha
    lda rbaWriteFuncLo, y
    pha
    rts
.endproc

; ==============================================================================
; write back handlers
; ==============================================================================

.proc write_d0x_rm16
    lda Decode::zbMod
    cmp #Decode::MODRM_MOD_REGISTER
    bne write_d0x_mem16

    ldy Decode::zbRM
    ldx Reg::rzbaReg16Map, y

    lda Reg::zwD0X
    sta Const::ZERO_PAGE, x
    lda Reg::zwD0X+1
    sta Const::ZERO_PAGE+1, x
    rts
.endproc

.proc write_d0l_rm8
    lda Decode::zbMod
    cmp #Decode::MODRM_MOD_REGISTER
    bne write_d0l_mem8

    ldy Decode::zbRM
    ldx Reg::rzbaReg8Map, y

    lda Reg::zbD0L
    sta Const::ZERO_PAGE, x

    rts
.endproc

.proc write_d0x_reg16
    ldy Decode::zbReg
    ldx Reg::rzbaReg16Map, y

    lda Reg::zwD0X
    sta Const::ZERO_PAGE, x
    lda Reg::zwD0X+1
    sta Const::ZERO_PAGE+1, x

    rts
.endproc

.proc write_d0l_reg8
    ldy Decode::zbReg
    ldx Reg::rzbaReg8Map, y

    lda Reg::zbD0L
    sta Const::ZERO_PAGE, x

    rts
.endproc

.proc write_d0x_ax
    lda Reg::zwD0X+1
    sta Reg::zwAX+1
    ; [fall_through]
.endproc

.proc write_d0l_al
    lda Reg::zbD0L
    sta Reg::zbAL
    rts
.endproc

.proc write_d0x_mem16
    lda Reg::zwD0X
    ldx Reg::zwD0X+1
    jmp Mem::set_word
    ; [tail_jump]
.endproc

.proc write_d0l_mem8
    lda Reg::zbD0L
    jmp Mem::set_byte
    ; [tail_jump]
.endproc

.proc write_d0x_seg16
    ldy Decode::zbSeg
    ldx Reg::rzbaSegRegMap, y

    lda Reg::zwD0X
    sta Const::ZERO_PAGE, x
    lda Reg::zwD0X+1
    sta Const::ZERO_PAGE+1, x

    jmp Interrupt::skip
    ; [tail_jump]
.endproc


.proc write_d0x_reg16_d1x_rm16
    jsr write_d1x_rm16
    jmp write_d0x_reg16
    ; [tail_jump]
.endproc


.proc write_d0l_reg8_d1l_rm8
    jsr write_d1l_rm8
    jmp write_d0l_reg8
    ; [tail_jump]
.endproc

.proc write_d0x_reg16_d1x_ax
    lda Reg::zwD1X
    sta Reg::zwAX
    lda Reg::zwD1X+1
    sta Reg::zwAX+1

    jmp write_d0x_reg16
    ; [tail_jump]
.endproc


.proc write_d0x_ds_d1x_reg16
    jsr write_d0x_reg16

    lda Reg::zwD1X
    sta Reg::zwDS
    lda Reg::zwD1X+1
    sta Reg::zwDS+1

    rts
.endproc


.proc write_d0x_es_d1x_reg16
    jsr write_d0x_reg16

    lda Reg::zwD1X
    sta Reg::zwES
    lda Reg::zwD1X+1
    sta Reg::zwES+1

    rts
.endproc


.proc write_d0l_ah
    lda Reg::zbD0L
    sta Reg::zbAH
    rts
.endproc



.proc write_d0x_flags
    lda Reg::zwD0X+1
    and >Reg::FLAGS_MASK ; only set valid flags
    sta Reg::zwFlags+1
    ; [fall_through]
.endproc

.proc write_d0l_flags_lo
    lda Reg::zbD0L
    and <Reg::FLAGS_MASK ; only set valid flags
    sta Reg::zbFlagsLo
    rts
.endproc

.proc write_d0l_al_d1l_ah
    lda Reg::zbD0L
    sta Reg::zbAL
    lda Reg::zbD1L
    sta Reg::zbAH
    rts
.endproc


.proc write_d0x_ax_d1x_dx
    lda Reg::zwD0X
    sta Reg::zwAX
    lda Reg::zwD0X+1
    sta Reg::zwAX+1

    lda Reg::zwD1X
    sta Reg::zwDX
    lda Reg::zwD1X+1
    sta Reg::zwDX+1

    rts
.endproc


.proc write_d0x_mem16_di
    lda Reg::zwD0X
    ldx Reg::zwD0X+1
    jmp Mem::set_di_word
    ; [tail_jump]
.endproc


.proc write_d0l_mem8_di
    lda Reg::zbD0L
    jmp Mem::set_di_byte
    ; [tail_jump]
.endproc


.proc write_nothing
    rts
.endproc

.proc write_bad
    lda #X86::Err::WRITE_FUNC
    jmp X86::panic
    ; [tail_jump]
.endproc

; ==============================================================================
; extended instruction write functions
; ==============================================================================

.proc write_group1a
    lda Decode::zbExt
    cmp #7 ; CMP
    beq done
    jsr write_d0l_rm8
done:
    rts
.endproc

.proc write_group1b
    lda Decode::zbExt
    cmp #7 ; CMP
    beq done
    jsr write_d0x_rm16
done:
    rts
.endproc

.proc write_group3a
    lda Decode::zbExt
    lsr
    beq done ; branch if instruction is TEST or illegal.
    lsr
    bne done ; branch if instruction is MUL, IMUL, DIV, or IDIV.

    ; instruction is NOT or NEG
    jmp write_d0l_rm8

done:
    rts
.endproc

.proc write_group3b
    lda Decode::zbExt
    lsr
    beq done ; branch if instruction is TEST or illegal.
    lsr
    bne done ; branch if instruction is MUL, IMUL, DIV, or IDIV.

    ; instruction is NOT or NEG
    jmp write_d0x_rm16

done:
    rts
.endproc


.proc write_group4b
    lda Decode::zbExt
    lsr
    bne done ; branch if instruction is CALL, JMP, or PUSH
    ; instruction is INC or DEC
    jmp write_d0x_rm16
done:
    rts
.endproc

; ==============================================================================
; utility functions
; ==============================================================================

.proc write_d1x_rm16
    lda Decode::zbMod
    cmp #Decode::MODRM_MOD_REGISTER
    bne write_d1x_mem16

    ldy Decode::zbRM
    ldx Reg::rzbaReg16Map, y

    lda Reg::zwD1X
    sta Const::ZERO_PAGE, x
    lda Reg::zwD1X+1
    sta Const::ZERO_PAGE+1, x

    rts
.endproc

.proc write_d1l_rm8
    lda Decode::zbMod
    cmp #Decode::MODRM_MOD_REGISTER
    bne write_d1l_mem8

    ldy Decode::zbRM
    ldx Reg::rzbaReg8Map, y

    lda Reg::zbD1L
    sta Const::ZERO_PAGE, x

    rts
.endproc

.proc write_d1x_mem16
    lda Reg::zwD1X
    ldx Reg::zwD1X+1
    jmp Mem::set_word
    ; [tail_jump]
.endproc

.proc write_d1l_mem8
    lda Reg::zbD1L
    jmp Mem::set_byte
    ; [tail_jump]
.endproc

.proc write_d1x_reg16
    ldy Decode::zbReg
    ldx Reg::rzbaReg16Map, y

    lda Reg::zwD1X
    sta Const::ZERO_PAGE, x
    lda Reg::zwD1X+1
    sta Const::ZERO_PAGE+1, x

    rts
.endproc
