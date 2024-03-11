
.include "x86/write.inc"
.include "x86/reg.inc"
.include "x86/mmu.inc"
.include "x86.inc"

.include "tmp.inc"
.include "const.inc"

.export write

.segment "RODATA"

; instruction encodings
.enum
    W00 ; nothing to write
    W01 ; D0 -> 8-bit register embedded in opcode
    W02 ; D0 -> 16-bit register embedded in opcode
    W03 ; D0 -> AL
    W04 ; D0 -> AX
    W05 ; D0 -> IP
    W06 ; D0 -> ModR/M rm8
    W07 ; D0 -> ModR/M rm16
    W08 ; D0 -> ModR/M reg8
    W09 ; D0 -> ModR/M reg16
    W10 ; D0 -> ModR/M seg16
    W11 ; D0 -> mmu8
    W12 ; D0 -> mmu16
    W13 ; D0 -> stack
    W14 ; D0 -> BX
    W15 ; D0 -> CX
    W16 ; D0 -> DX
    W17 ; D0 -> SP
    W18 ; D0 -> BP
    W19 ; D0 -> SI
    W20 ; D0 -> DI
    W21 ; D0 -> CS
    W22 ; D0 -> DS
    W23 ; D0 -> ES
    W24 ; D0 -> SS
    W25 ; S0 -> BX ; S1 -> AX
    W26 ; S0 -> CX ; S1 -> AX
    W27 ; S0 -> DX ; S1 -> AX
    W28 ; S0 -> SP ; S1 -> AX
    W29 ; S0 -> BP ; S1 -> AX
    W30 ; S0 -> SI ; S1 -> AX
    W31 ; S0 -> DI ; S1 -> AX

    BAD ; used for unimplemented or non-existent instructions
    FUNC_COUNT ; used to check function table size at compile-time
.endenum

; map instruction encodings to their write functions.
rbaWriteFuncLo:
.byte <(write_nop-1)
.byte <(write_embed_reg8-1)
.byte <(write_embed_reg16-1)
.byte <(write_al-1)
.byte <(write_ax-1)
.byte <(write_ip-1)
.byte <(write_modrm_rm8-1)
.byte <(write_modrm_rm16-1)
.byte <(write_modrm_reg8-1)
.byte <(write_modrm_reg16-1)
.byte <(write_modrm_seg16-1)
.byte <(write_mmu8-1)
.byte <(write_mmu16-1)
.byte <(write_stack-1)
.byte <(write_bx-1)
.byte <(write_cx-1)
.byte <(write_dx-1)
.byte <(write_sp-1)
.byte <(write_bp-1)
.byte <(write_si-1)
.byte <(write_di-1)
.byte <(write_cs-1)
.byte <(write_ds-1)
.byte <(write_es-1)
.byte <(write_ss-1)
.byte <(write_bx_ax-1)
.byte <(write_cx_ax-1)
.byte <(write_dx_ax-1)
.byte <(write_sp_ax-1)
.byte <(write_bp_ax-1)
.byte <(write_si_ax-1)
.byte <(write_di_ax-1)
.byte <(write_bad-1)
rbaWriteFuncHi:
.byte >(write_nop-1)
.byte >(write_embed_reg8-1)
.byte >(write_embed_reg16-1)
.byte >(write_al-1)
.byte >(write_ax-1)
.byte >(write_ip-1)
.byte >(write_modrm_rm8-1)
.byte >(write_modrm_rm16-1)
.byte >(write_modrm_reg8-1)
.byte >(write_modrm_reg16-1)
.byte >(write_modrm_seg16-1)
.byte >(write_mmu8-1)
.byte >(write_mmu16-1)
.byte >(write_stack-1)
.byte >(write_bx-1)
.byte >(write_cx-1)
.byte >(write_dx-1)
.byte >(write_sp-1)
.byte >(write_bp-1)
.byte >(write_si-1)
.byte >(write_di-1)
.byte >(write_cs-1)
.byte >(write_ds-1)
.byte >(write_es-1)
.byte >(write_ss-1)
.byte >(write_bx_ax-1)
.byte >(write_cx_ax-1)
.byte >(write_dx_ax-1)
.byte >(write_sp_ax-1)
.byte >(write_bp_ax-1)
.byte >(write_si_ax-1)
.byte >(write_di_ax-1)
.byte >(write_bad-1)
rbaWriteFuncEnd:

.assert (rbaWriteFuncHi - rbaWriteFuncLo) = (rbaWriteFuncEnd - rbaWriteFuncHi), error, "incomplete write function"
.assert (rbaWriteFuncHi - rbaWriteFuncLo) = FUNC_COUNT, error, "write function count"

; map opcodes to instruction encodings
rbaInstrWrite:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte W06,W07,W08,W09,W03,W04,W13,W23,W06,W07,W08,W09,W03,W04,W13,BAD ; 0_
.byte W06,W07,W08,W09,W03,W04,W13,W24,W06,W07,W08,W09,W03,W04,W13,W22 ; 1_
.byte W06,W07,W08,W09,W03,W04,BAD,BAD,W06,W07,W08,W09,W03,W04,BAD,BAD ; 2_
.byte W06,W07,W08,W09,W03,W04,BAD,BAD,W06,W07,W08,W09,W00,W00,BAD,BAD ; 3_
.byte W02,W02,W02,W02,W02,W02,W02,W02,W02,W02,W02,W02,W02,W02,W02,W02 ; 4_
.byte W13,W13,W13,W13,W13,W13,W13,W13,W04,W15,W16,W14,W17,W18,W19,W20 ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte W05,W05,W05,W05,W05,W05,W05,W05,W05,W05,W05,W05,W05,W05,W05,W05 ; 7_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,W06,W07,W08,W09,W07,BAD,W10,BAD ; 8_
.byte W00,W26,W27,W25,W28,W29,W30,W31,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 9_
.byte W03,W04,W11,W12,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; A_
.byte W01,W01,W01,W01,W01,W01,W01,W01,W02,W02,W02,W02,W02,W02,W02,W02 ; B_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; C_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; D_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; E_
.byte BAD,BAD,BAD,BAD,BAD,W00,BAD,BAD,W00,W00,W00,W00,W00,W00,BAD,BAD ; F_

.segment "CODE"

; write data back to memory or registers after execution.
.proc write
    ldx Reg::zbInstrOpcode
    ldy rbaInstrWrite, x

    ; check for an unsupported encoding.
    cpy #(rbaWriteFuncHi - rbaWriteFuncLo)
    bcc func_ok
    lda #X86::Err::WRITE_FUNC
    jsr X86::panic
func_ok:

    lda rbaWriteFuncHi, y
    pha
    lda rbaWriteFuncLo, y
    pha
    rts
.endproc

; ==============================================================================
; write back handlers
; ==============================================================================

.proc write_nop
    rts
.endproc


.proc write_embed_reg8
    lda Reg::zbInstrOpcode
    and #Reg::OPCODE_REG_MASK

skip_embed:
    tay
    ldx Reg::rzbaReg8Map, y

    lda Reg::zaD0
    sta Const::ZERO_PAGE, x
    rts
.endproc


.proc write_embed_reg16
    lda Reg::zbInstrOpcode
    and #Reg::OPCODE_REG_MASK

skip_embed:
    tay
    ldx Reg::rzbaReg16Map, y

    lda Reg::zaD0
    sta Const::ZERO_PAGE, x
    inx
    lda Reg::zaD0+1
    sta Const::ZERO_PAGE, x

    rts
.endproc


.proc write_ax
    lda Reg::zaD0+1
    sta Reg::zwAX+1
    ; fall through to copy the low byte
.endproc

.proc write_al
    lda Reg::zaD0
    sta Reg::zbAL
    rts
.endproc


.proc write_ip
    lda Reg::zaD0
    sta Reg::zwIP
    lda Reg::zaD0+1
    sta Reg::zwIP+1
    rts
.endproc


.proc write_modrm_rm8
    ; check if we're writing to a register or RAM
    lda Reg::zaInstrOperands
    and #Reg::MODRM_MOD_MASK
    cmp #Reg::MODRM_MOD_MASK

    bne write_ram ; branch if we need to write back to RAM.

    ; write the value back to a register
    lda Reg::zaInstrOperands
    and #Reg::MODRM_RM_MASK
    jmp write_embed_reg8::skip_embed ; jsr rts -> jmp

write_ram:
    lda Reg::zaD0
    jmp Mmu::set_byte ; jsr rts -> jmp
.endproc


.proc write_modrm_rm16
    ; check if we're writing to a register or RAM
    lda Reg::zaInstrOperands
    and #Reg::MODRM_MOD_MASK
    cmp #Reg::MODRM_MOD_MASK

    bne write_ram ; branch if we need to write back to RAM.

    ; write the value back to a register
    lda Reg::zaInstrOperands
    and #Reg::MODRM_RM_MASK
    jmp write_embed_reg16::skip_embed ; jsr rts -> jmp

write_ram:
    lda Reg::zaD0
    jsr Mmu::set_byte
    jsr Mmu::inc_address
    lda Reg::zaD0+1
    jsr Mmu::set_byte ; jsr rts -> jmp
.endproc


.proc write_modrm_reg8
    lda Reg::zaInstrOperands
    and #Reg::MODRM_REG_MASK
    lsr
    lsr
    lsr
    jmp write_embed_reg8::skip_embed ; jsr rts -> jmp
.endproc


.proc write_modrm_reg16
    lda Reg::zaInstrOperands
    and #Reg::MODRM_REG_MASK
    lsr
    lsr
    lsr
    jmp write_embed_reg16::skip_embed ; jsr rts -> jmp
.endproc


.proc write_modrm_seg16
    ; lookup the address of the segment register
    lda Reg::zaInstrOperands
    and #Reg::MODRM_SEG_MASK
    lsr
    lsr
    lsr
    tay
    ldx Reg::rzbaSegRegMap, y

    lda Reg::zaD0
    sta Const::ZERO_PAGE, x
    inx
    lda Reg::zaD0+1
    sta Const::ZERO_PAGE, x
    inx
    lda Reg::zaD0+2
    sta Const::ZERO_PAGE, x

    rts
.endproc


.proc write_mmu8
    lda Reg::zaD0
    jmp Mmu::set_byte ; jsr rts -> jmp
.endproc


.proc write_mmu16
    jsr write_mmu8
    jsr Mmu::inc_address
    lda Reg::zaD0+1
    jmp Mmu::set_byte ; jsr rts -> jmp
.endproc


.proc write_stack
    lda Reg::zaD0
    sta Tmp::zw0
    lda Reg::zaD0+1
    sta Tmp::zw0+1
    jmp Mmu::push_word
.endproc


.proc write_bx
    lda Reg::zaD0
    sta Reg::zwBX
    lda Reg::zaD0+1
    sta Reg::zwBX+1
    rts
.endproc


.proc write_cx
    lda Reg::zaD0
    sta Reg::zwCX
    lda Reg::zaD0+1
    sta Reg::zwCX+1
    rts
.endproc


.proc write_dx
    lda Reg::zaD0
    sta Reg::zwDX
    lda Reg::zaD0+1
    sta Reg::zwDX+1
    rts
.endproc


.proc write_sp
    lda Reg::zaD0
    sta Reg::zwSP
    lda Reg::zaD0+1
    sta Reg::zwSP+1
    rts
.endproc


.proc write_bp
    lda Reg::zaD0
    sta Reg::zwBP
    lda Reg::zaD0+1
    sta Reg::zwBP+1
    rts
.endproc


.proc write_si
    lda Reg::zaD0
    sta Reg::zwSI
    lda Reg::zaD0+1
    sta Reg::zwSI+1
    rts
.endproc


.proc write_di
    lda Reg::zaD0
    sta Reg::zwDI
    lda Reg::zaD0+1
    sta Reg::zwDI+1
    rts
.endproc


.proc write_cs
    lda Reg::zaD0
    sta Reg::zaCS
    lda Reg::zaD0+1
    sta Reg::zaCS+1
    lda Reg::zaD0+2
    sta Reg::zaCS+2
    rts
.endproc


.proc write_ds
    lda Reg::zaD0
    sta Reg::zaDS
    lda Reg::zaD0+1
    sta Reg::zaDS+1
    lda Reg::zaD0+2
    sta Reg::zaDS+2
    rts
.endproc


.proc write_es
    lda Reg::zaD0
    sta Reg::zaES
    lda Reg::zaD0+1
    sta Reg::zaES+1
    lda Reg::zaD0+2
    sta Reg::zaES+2
    rts
.endproc


.proc write_ss
    lda Reg::zaD0
    sta Reg::zaSS
    lda Reg::zaD0+1
    sta Reg::zaSS+1
    lda Reg::zaD0+2
    sta Reg::zaSS+2
    rts
.endproc


.proc write_bx_ax
    lda Reg::zaS0
    sta Reg::zwBX
    lda Reg::zaS0+1
    sta Reg::zwBX+1
    jmp write_s0_ax ; jsr rts -> jmp
.endproc


.proc write_cx_ax
    lda Reg::zaS0
    sta Reg::zwCX
    lda Reg::zaS0+1
    sta Reg::zwCX+1
    jmp write_s0_ax ; jsr rts -> jmp
.endproc


.proc write_dx_ax
    lda Reg::zaS0
    sta Reg::zwDX
    lda Reg::zaS0+1
    sta Reg::zwDX+1
    jmp write_s0_ax ; jsr rts -> jmp
.endproc


.proc write_sp_ax
    lda Reg::zaS0
    sta Reg::zwSP
    lda Reg::zaS0+1
    sta Reg::zwSP+1
    jmp write_s0_ax ; jsr rts -> jmp
.endproc


.proc write_bp_ax
    lda Reg::zaS0
    sta Reg::zwBP
    lda Reg::zaS0+1
    sta Reg::zwBP+1
    jmp write_s0_ax ; jsr rts -> jmp
.endproc


.proc write_si_ax
    lda Reg::zaS0
    sta Reg::zwSI
    lda Reg::zaS0+1
    sta Reg::zwSI+1
    jmp write_s0_ax ; jsr rts -> jmp
.endproc


.proc write_di_ax
    lda Reg::zaS0
    sta Reg::zwDI
    lda Reg::zaS0+1
    sta Reg::zwDI+1
    jmp write_s0_ax ; jsr rts -> jmp
.endproc


.proc write_bad
    lda #X86::Err::WRITE_FUNC
    jmp X86::panic
.endproc

; ==============================================================================

.proc write_s0_ax
    lda Reg::zaS1
    sta Reg::zwAX
    lda Reg::zaS1+1
    sta Reg::zwAX+1
    rts
.endproc
