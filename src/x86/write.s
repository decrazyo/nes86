
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
    W32 ; S0 -> IP ; S1 -> CS
    W33 ; IP ->stack ; D0 -> IP
    W34 ; CS -> stack ; IP -> stack ; S0 -> IP ; S1 -> CS
    W35 ; S1 -> CS ; D0 -> IP
    W36 ; S0 -> ModR/M rm8 ; S1 -> ModR/M reg8
    W37 ; S0 -> ModR/M rm16 ; S1 -> ModR/M reg16
    W38 ; S0 -> AX
    W39 ; S1 -> flags
    W40 ; S0 -> flags lo
    W41 ; D0 -> AH

    BAD ; used for unimplemented or non-existent instructions
    FUNC_COUNT ; used to check function table size at compile-time
.endenum

; map instruction encodings to their write functions.
rbaWriteFuncLo:
.byte <(write_nop-1)
.byte <(write_embed_reg8_d0-1)
.byte <(write_embed_reg16_d0-1)
.byte <(write_al_d0-1)
.byte <(write_ax_d0-1)
.byte <(write_ip_d0-1)
.byte <(write_modrm_rm8_d0-1)
.byte <(write_modrm_rm16_d0-1)
.byte <(write_modrm_reg8_d0-1)
.byte <(write_modrm_reg16_d0-1)
.byte <(write_modrm_seg16_d0-1)
.byte <(write_mmu8_d0-1)
.byte <(write_mmu16_d0-1)
.byte <(write_stack_d0-1)
.byte <(write_bx_d0-1)
.byte <(write_cx_s0-1)
.byte <(write_dx_s0-1)
.byte <(write_sp_s0-1)
.byte <(write_bp_s0-1)
.byte <(write_si_s0-1)
.byte <(write_di_s0-1)
.byte <(write_cs_s0-1)
.byte <(write_ds_s0-1)
.byte <(write_es_s0-1)
.byte <(write_ss_s0-1)
.byte <(write_bx_s0_ax_s1-1)
.byte <(write_cx_s0_ax_s1-1)
.byte <(write_dx_s0_ax_s1-1)
.byte <(write_sp_s0_ax_s1-1)
.byte <(write_bp_s0_ax_s1-1)
.byte <(write_si_s0_ax_s1-1)
.byte <(write_di_s0_ax_s1-1)
.byte <(write_ip_s0_cs_s1-1)
.byte <(write_stack_ip_ip_d0-1)
.byte <(write_stack_cs_stack_ip_ip_s0_cs_s1-1)
.byte <(write_cs_s1_ip_d0-1)
.byte <(write_modrm_rm8_s0_modrm_reg8_s1-1)
.byte <(write_modrm_rm16_s0_modrm_reg16_s1-1)
.byte <(write_ax_s0-1)
.byte <(write_flags_s1-1)
.byte <(write_flags_lo_s0-1)
.byte <(write_ah_d0-1)
.byte <(write_bad-1)
rbaWriteFuncHi:
.byte >(write_nop-1)
.byte >(write_embed_reg8_d0-1)
.byte >(write_embed_reg16_d0-1)
.byte >(write_al_d0-1)
.byte >(write_ax_d0-1)
.byte >(write_ip_d0-1)
.byte >(write_modrm_rm8_d0-1)
.byte >(write_modrm_rm16_d0-1)
.byte >(write_modrm_reg8_d0-1)
.byte >(write_modrm_reg16_d0-1)
.byte >(write_modrm_seg16_d0-1)
.byte >(write_mmu8_d0-1)
.byte >(write_mmu16_d0-1)
.byte >(write_stack_d0-1)
.byte >(write_bx_d0-1)
.byte >(write_cx_s0-1)
.byte >(write_dx_s0-1)
.byte >(write_sp_s0-1)
.byte >(write_bp_s0-1)
.byte >(write_si_s0-1)
.byte >(write_di_s0-1)
.byte >(write_cs_s0-1)
.byte >(write_ds_s0-1)
.byte >(write_es_s0-1)
.byte >(write_ss_s0-1)
.byte >(write_bx_s0_ax_s1-1)
.byte >(write_cx_s0_ax_s1-1)
.byte >(write_dx_s0_ax_s1-1)
.byte >(write_sp_s0_ax_s1-1)
.byte >(write_bp_s0_ax_s1-1)
.byte >(write_si_s0_ax_s1-1)
.byte >(write_di_s0_ax_s1-1)
.byte >(write_ip_s0_cs_s1-1)
.byte >(write_stack_ip_ip_d0-1)
.byte >(write_stack_cs_stack_ip_ip_s0_cs_s1-1)
.byte >(write_cs_s1_ip_d0-1)
.byte >(write_modrm_rm8_s0_modrm_reg8_s1-1)
.byte >(write_modrm_rm16_s0_modrm_reg16_s1-1)
.byte >(write_ax_s0-1)
.byte >(write_flags_s1-1)
.byte >(write_flags_lo_s0-1)
.byte >(write_ah_d0-1)
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
.byte W06,W07,W08,W09,W03,W04,BAD,W04,W00,W00,W00,W00,W00,W00,BAD,W04 ; 3_
.byte W02,W02,W02,W02,W02,W02,W02,W02,W02,W02,W02,W02,W02,W02,W02,W02 ; 4_
.byte W13,W13,W13,W13,W13,W13,W13,W13,W04,W15,W16,W14,W17,W18,W19,W20 ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte W05,W05,W05,W05,W05,W05,W05,W05,W05,W05,W05,W05,W05,W05,W05,W05 ; 7_
.byte BAD,BAD,BAD,BAD,W00,W00,W36,W37,W06,W07,W08,W09,W07,BAD,W10,BAD ; 8_
.byte W00,W26,W27,W25,W28,W29,W30,W31,W38,W27,W34,BAD,W13,W39,W40,W41 ; 9_
.byte W03,W04,W11,W12,BAD,BAD,BAD,BAD,W00,W00,BAD,BAD,BAD,BAD,BAD,BAD ; A_
.byte W01,W01,W01,W01,W01,W01,W01,W01,W02,W02,W02,W02,W02,W02,W02,W02 ; B_
.byte BAD,BAD,W05,W05,BAD,BAD,BAD,BAD,BAD,BAD,W35,W35,BAD,BAD,BAD,BAD ; C_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; D_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,W33,W05,W32,W05,BAD,BAD,BAD,BAD ; E_
.byte BAD,BAD,BAD,BAD,BAD,W00,BAD,BAD,W00,W00,W00,W00,W00,W00,BAD,BAD ; F_

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

.proc write_nop
    rts
.endproc


.proc write_embed_reg8_d0
    lda Fetch::zbInstrOpcode
    and #Decode::OPCODE_REG_MASK

skip_embed:
    tay
    ldx Reg::rzbaReg8Map, y

    lda Reg::zwD0X
    sta Const::ZERO_PAGE, x
    rts
.endproc


.proc write_embed_reg16_d0
    lda Fetch::zbInstrOpcode
    and #Decode::OPCODE_REG_MASK

skip_embed:
    tay
    ldx Reg::rzbaReg16Map, y

    lda Reg::zwD0X
    sta Const::ZERO_PAGE, x
    inx
    lda Reg::zwD0X+1
    sta Const::ZERO_PAGE, x

    ; if we changed SP then we need to tell the MMU.
    cpy #Reg::Reg16::SP
    bne done ; branch if we didn't change the stack pointer
    sty Mmu::zbStackDirty
done:
    rts
.endproc


.proc write_ax_d0
    lda Reg::zwD0X+1
    sta Reg::zwAX+1
    ; [fall_through]
.endproc

.proc write_al_d0
    lda Reg::zwD0X
    sta Reg::zbAL
    rts
.endproc


.proc write_ip_d0
    lda Reg::zwD0X
    sta Reg::zwIP
    lda Reg::zwD0X+1
    sta Reg::zwIP+1
    lda #1
    sta Mmu::zbCodeDirty
    rts
.endproc


.proc write_modrm_rm8_d0
    ; check if we're writing to a register or RAM
    lda Fetch::zaInstrOperands
    and #Decode::MODRM_MOD_MASK
    cmp #Decode::MODRM_MOD_MASK

    bne write_ram ; branch if we need to write back to RAM.

    ; write the value back to a register
    lda Fetch::zaInstrOperands
    and #Decode::MODRM_RM_MASK
    jmp write_embed_reg8_d0::skip_embed
    ; [tail_jump]

write_ram:
    lda Reg::zwD0X
    jmp Mmu::set_byte
    ; [tail_jump]
.endproc


.proc write_modrm_rm16_d0
    ; check if we're writing to a register or RAM
    lda Fetch::zaInstrOperands
    and #Decode::MODRM_MOD_MASK
    cmp #Decode::MODRM_MOD_MASK

    bne write_ram ; branch if we need to write back to RAM.

    ; write the value back to a register
    lda Fetch::zaInstrOperands
    and #Decode::MODRM_RM_MASK
    jmp write_embed_reg16_d0::skip_embed
    ; [tail_jump]

write_ram:
    lda Reg::zwD0X
    jsr Mmu::set_byte
    jsr Mmu::inc_address
    lda Reg::zwD0X+1
    jmp Mmu::set_byte
    ; [tail_jump]
.endproc


.proc write_modrm_reg8_d0
    lda Fetch::zaInstrOperands
    and #Decode::MODRM_REG_MASK
    lsr
    lsr
    lsr
    jmp write_embed_reg8_d0::skip_embed
    ; [tail_jump]
.endproc


.proc write_modrm_reg16_d0
    lda Fetch::zaInstrOperands
    and #Decode::MODRM_REG_MASK
    lsr
    lsr
    lsr
    jmp write_embed_reg16_d0::skip_embed
    ; [tail_jump]
.endproc


.proc write_modrm_seg16_d0
    ; lookup the address of the segment register
    lda Fetch::zaInstrOperands
    and #Decode::MODRM_SEG_MASK
    lsr
    lsr
    lsr
    tay
    ldx Reg::rzbaSegRegMap, y

    lda Reg::zwD0X
    sta Const::ZERO_PAGE, x
    inx
    lda Reg::zwD0X+1
    sta Const::ZERO_PAGE, x

    ; if we changed CS or SS then we need to tell the MMU.
    cpy #Reg::Seg::CS
    bne check_stack ; branch if we didn't change the code segment
    sty Mmu::zbCodeDirty
    bne done ; branch always
check_stack:
    cpy #Reg::Seg::SS
    bne done ; branch if we didn't change the stack segment
    sty Mmu::zbStackDirty
done:
    rts
.endproc


.proc write_mmu8_d0
    lda Reg::zwD0X
    jmp Mmu::set_byte
    ; [tail_jump]
.endproc


.proc write_mmu16_d0
    jsr write_mmu8_d0
    jsr Mmu::inc_address
    lda Reg::zwD0X+1
    jmp Mmu::set_byte
    ; [tail_jump]
.endproc


.proc write_stack_d0
    lda Reg::zwD0X
    sta Tmp::zw0
    lda Reg::zwD0X+1
    sta Tmp::zw0+1
    jmp Mmu::push_word
    ; [tail_jump]
.endproc


.proc write_bx_d0
    lda Reg::zwD0X
    sta Reg::zwBX
    lda Reg::zwD0X+1
    sta Reg::zwBX+1
    rts
.endproc


.proc write_cx_s0
    lda Reg::zwD0X
    sta Reg::zwCX
    lda Reg::zwD0X+1
    sta Reg::zwCX+1
    rts
.endproc


.proc write_dx_s0
    lda Reg::zwD0X
    sta Reg::zwDX
    lda Reg::zwD0X+1
    sta Reg::zwDX+1
    rts
.endproc


.proc write_sp_s0
    lda Reg::zwD0X
    sta Reg::zwSP
    lda Reg::zwD0X+1
    sta Reg::zwSP+1
    lda #1
    sta Mmu::zbStackDirty
    rts
.endproc


.proc write_bp_s0
    lda Reg::zwD0X
    sta Reg::zwBP
    lda Reg::zwD0X+1
    sta Reg::zwBP+1
    rts
.endproc


.proc write_si_s0
    lda Reg::zwD0X
    sta Reg::zwSI
    lda Reg::zwD0X+1
    sta Reg::zwSI+1
    rts
.endproc


.proc write_di_s0
    lda Reg::zwD0X
    sta Reg::zwDI
    lda Reg::zwD0X+1
    sta Reg::zwDI+1
    rts
.endproc


.proc write_cs_s0
    lda Reg::zwD0X
    sta Reg::zwCS
    lda Reg::zwD0X+1
    sta Reg::zwCS+1
    lda #1
    sta Mmu::zbCodeDirty
    rts
.endproc


.proc write_ds_s0
    lda Reg::zwD0X
    sta Reg::zwDS
    lda Reg::zwD0X+1
    sta Reg::zwDS+1
    rts
.endproc


.proc write_es_s0
    lda Reg::zwD0X
    sta Reg::zwES
    lda Reg::zwD0X+1
    sta Reg::zwES+1
    rts
.endproc


.proc write_ss_s0
    lda Reg::zwD0X
    sta Reg::zwSS
    lda Reg::zwD0X+1
    sta Reg::zwSS+1
    lda #1
    sta Mmu::zbStackDirty
    rts
.endproc


.proc write_bx_s0_ax_s1
    lda Reg::zwS0X
    sta Reg::zwBX
    lda Reg::zwS0X+1
    sta Reg::zwBX+1
    jmp write_ax_s1
    ; [tail_jump]
.endproc


.proc write_cx_s0_ax_s1
    lda Reg::zwS0X
    sta Reg::zwCX
    lda Reg::zwS0X+1
    sta Reg::zwCX+1
    jmp write_ax_s1
    ; [tail_jump]
.endproc


.proc write_dx_s0_ax_s1
    lda Reg::zwS0X
    sta Reg::zwDX
    lda Reg::zwS0X+1
    sta Reg::zwDX+1
    jmp write_ax_s1
    ; [tail_jump]
.endproc


.proc write_sp_s0_ax_s1
    lda Reg::zwS0X
    sta Reg::zwSP
    lda Reg::zwS0X+1
    sta Reg::zwSP+1
    lda #1
    sta Mmu::zbStackDirty
    jmp write_ax_s1
    ; [tail_jump]
.endproc


.proc write_bp_s0_ax_s1
    lda Reg::zwS0X
    sta Reg::zwBP
    lda Reg::zwS0X+1
    sta Reg::zwBP+1
    jmp write_ax_s1
    ; [tail_jump]
.endproc


.proc write_si_s0_ax_s1
    lda Reg::zwS0X
    sta Reg::zwSI
    lda Reg::zwS0X+1
    sta Reg::zwSI+1
    jmp write_ax_s1
    ; [tail_jump]
.endproc


.proc write_di_s0_ax_s1
    lda Reg::zwS0X
    sta Reg::zwDI
    lda Reg::zwS0X+1
    sta Reg::zwDI+1
    jmp write_ax_s1
    ; [tail_jump]
.endproc


.proc write_ip_s0_cs_s1
    lda Reg::zwS0X
    sta Reg::zwIP
    lda Reg::zwS0X+1
    sta Reg::zwIP+1

    lda Reg::zwS1X
    sta Reg::zwCS
    lda Reg::zwS1X+1
    sta Reg::zwCS+1

    lda #1
    sta Mmu::zbCodeDirty
    rts
.endproc


.proc write_stack_ip_ip_d0
    lda Reg::zwIP
    sta Tmp::zw0
    lda Reg::zwIP+1
    sta Tmp::zw0+1
    jsr Mmu::push_word

    lda Reg::zwD0X
    sta Reg::zwIP
    lda Reg::zwD0X+1
    sta Reg::zwIP+1

    lda #1
    sta Mmu::zbCodeDirty
    rts
.endproc


.proc write_stack_cs_stack_ip_ip_s0_cs_s1
    lda Reg::zwCS
    sta Tmp::zw0
    lda Reg::zwCS+1
    sta Tmp::zw0+1
    jsr Mmu::push_word

    lda Reg::zwIP
    sta Tmp::zw0
    lda Reg::zwIP+1
    sta Tmp::zw0+1
    jsr Mmu::push_word

    ; this should mark the code segment as dirty
    jmp write_ip_s0_cs_s1
    ; [tail_jump]
.endproc


.proc write_cs_s1_ip_d0
    lda Reg::zwS1X
    sta Reg::zwCS
    lda Reg::zwS1X+1
    sta Reg::zwCS+1

    lda Reg::zwD0X
    sta Reg::zwIP
    lda Reg::zwD0X+1
    sta Reg::zwIP+1

    lda #1
    sta Mmu::zbCodeDirty
    rts
.endproc


.proc write_modrm_rm8_s0_modrm_reg8_s1
    ; check if we're writing to a register or RAM
    lda Fetch::zaInstrOperands
    and #Decode::MODRM_MOD_MASK
    cmp #Decode::MODRM_MOD_MASK

    bne write_ram ; branch if we need to write back to RAM.

    ; write the value back to a register
    lda Fetch::zaInstrOperands
    and #Decode::MODRM_RM_MASK

    tay
    ldx Reg::rzbaReg8Map, y

    lda Reg::zwS0X
    sta Const::ZERO_PAGE, x
    jmp handle_reg

write_ram:
    lda Reg::zwS0X
    jsr Mmu::set_byte

handle_reg:
    lda Fetch::zaInstrOperands
    and #Decode::MODRM_REG_MASK
    lsr
    lsr
    lsr

    tay
    ldx Reg::rzbaReg8Map, y

    lda Reg::zwS1X
    sta Const::ZERO_PAGE, x
    rts
.endproc


.proc write_modrm_rm16_s0_modrm_reg16_s1
    ; check if we're writing to a register or RAM
    lda Fetch::zaInstrOperands
    and #Decode::MODRM_MOD_MASK
    cmp #Decode::MODRM_MOD_MASK

    bne write_ram ; branch if we need to write back to RAM.

    ; write the value back to a register
    lda Fetch::zaInstrOperands
    and #Decode::MODRM_RM_MASK

    tay
    ldx Reg::rzbaReg8Map, y

    lda Reg::zwS0X
    sta Const::ZERO_PAGE, x
    lda Reg::zwS0X+1
    sta Const::ZERO_PAGE+1, x
    jmp handle_reg

write_ram:
    lda Reg::zwS0X
    jsr Mmu::set_byte
    jsr Mmu::inc_address
    lda Reg::zwS0X+1
    jsr Mmu::set_byte

handle_reg:
    lda Fetch::zaInstrOperands
    and #Decode::MODRM_REG_MASK
    lsr
    lsr
    lsr

    tay
    ldx Reg::rzbaReg8Map, y

    lda Reg::zwS1X
    sta Const::ZERO_PAGE, x
    lda Reg::zwS1X+1
    sta Const::ZERO_PAGE+1, x
    rts
.endproc


.proc write_ax_s0
    lda Reg::zwS0X
    sta Reg::zwAX
    lda Reg::zwS0X+1
    sta Reg::zwAX+1
    rts
.endproc


.proc write_flags_s1
    lda Reg::zwS1X
    sta Reg::zwFlags
    lda Reg::zwS1X+1
    sta Reg::zwFlags+1
    rts
.endproc


.proc write_flags_lo_s0
    lda Reg::zwS0X
    sta Reg::zbFlagsLo
    rts
.endproc


.proc write_ah_d0
    lda Reg::zwD0X
    sta Reg::zbAH
    rts
.endproc


.proc write_bad
    lda #X86::Err::WRITE_FUNC
    jmp X86::panic
    ; [tail_jump]
.endproc

; ==============================================================================

.proc write_ax_s1
    lda Reg::zwS1X
    sta Reg::zwAX
    lda Reg::zwS1X+1
    sta Reg::zwAX+1
    rts
.endproc
