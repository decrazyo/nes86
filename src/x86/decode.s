
; This module is responsible for copying values needed by x86 instructions
; into temporary registers.
; This module must only read the x86 address space though the
; MMU's general-purpose memory interface and dedicated stack interface.
; This module must not write to the x86 address space at all.
; This module may only move data and must not transform it in any other way.
; If an instruction's opcode indicates that it simply moves a value to or from a fixed
; location, i.e. a specific register or the stack, then reading that
; value may be deferred until the "write" stage.
; e.g. decoding "CALL 0x1234:0x5678" may defer reading "CS" to the "write" stage
; since the opcode of the instruction (0x9A) always requires "CS" to be
; pushed onto the stack and "CS" is not needed by the "execute" stage.
; If an instruction will write to the x86 address space during the "write" stage
; then this module must configure the MMU appropriately for that write.
;
; uses:
;   Mmu::set_address
;   Mmu::get_byte
;   Mmu::peek_next_byte
;   Mmu::pop_word
; changes:
;   Reg::zbS0
;   Reg::zbS1
;   Reg::zbD0

.include "x86/decode.inc"
.include "x86/reg.inc"
.include "x86/mmu.inc"
.include "x86.inc"

.include "tmp.inc"
.include "const.inc"

.export zbWord

.export decode

.segment "ZEROPAGE"

; indicates if the current instruction is performing a 16-bit.
; 0 = 8-bit
; 1 = 16-bit
zbWord: .res 1

.segment "RODATA"

; instruction encodings
.enum
    D00 ; no operands. nothing to do.
    D01 ; 16-bit register embedded in opcode -> S0
    D02 ; AL -> S0 ; imm8 -> S1
    D03 ; AX -> S0 ; imm16 -> S1
    D04 ; imm8 -> S1
    D05 ; imm16 -> S1
    D06 ; IP -> S0 ; imm8 -> S1
    D07 ; rm8 -> S0 ; reg8 -> S1
    D08 ; rm16 -> S0 ; reg16 -> S1
    D09 ; reg8 -> S0 ; rm8 -> S1
    D10 ; reg16 -> S0 ; rm16 -> S1
    D11 ; rm16 -> S0 ; seg16 -> S1
    D12 ; seg16 -> S0 ; rm16 -> S1
    D13 ; ptr8 -> mmu ; AL -> S1
    D14 ; ptr16 -> mmu ; AX -> S1
    D15 ; ptr8 -> mmu -> S1
    D16 ; ptr16 -> mmu -> S1
    D17 ; AX -> S1
    D18 ; BX -> S1
    D19 ; CX -> S1
    D20 ; DX -> S1
    D21 ; SP -> S1
    D22 ; BP -> S1
    D23 ; SI -> S1
    D24 ; DI -> S1
    D25 ; CS -> S1
    D26 ; DS -> S1
    D27 ; ES -> S1
    D28 ; SS -> S1
    D29 ; stack -> S1
    D30 ; AX -> S0 ; BX -> S1
    D31 ; AX -> S0 ; CX -> S1
    D32 ; AX -> S0 ; DX -> S1
    D33 ; AX -> S0 ; SP -> S1
    D34 ; AX -> S0 ; BP -> S1
    D35 ; AX -> S0 ; SI -> S1
    D36 ; AX -> S0 ; DI -> S1
    D37 ; ip -> s0 ; imm16 -> s1
    D38 ; imm16 -> s0 ; imm16 -> s1
    D39 ; imm16 -> s0
    D40 ; AL -> S0
    D41 ; flags -> S0
    D42 ; AH -> S0
    D43 ; flags lo -> S0

    BAD ; used for unimplemented or non-existent instructions
    FUNC_COUNT ; used to check function table size at compile-time
.endenum

; map instruction encodings to their decoding functions.
rbaDecodeFuncLo:
.byte <(decode_nop-1)
.byte <(decode_s0_embed_reg16-1)
.byte <(decode_s0_al_s1_imm8-1)
.byte <(decode_s0_ax_s1_imm16-1)
.byte <(decode_s1_imm8-1)
.byte <(decode_s1_imm16-1)
.byte <(decode_s0_ip_s1_imm8-1)
.byte <(decode_s0_modrm_rm8_s1_modrm_reg8-1)
.byte <(decode_s0_modrm_rm16_s1_modrm_reg16-1)
.byte <(decode_s0_modrm_reg8_s1_modrm_rm8-1)
.byte <(decode_s0_modrm_reg16_s1_modrm_rm16-1)
.byte <(decode_s0_modrm_rm16_s1_modrm_seg16-1)
.byte <(decode_s0_modrm_seg16_s1_modrm_rm16-1)
.byte <(decode_mmu_ptr8_s1_al-1)
.byte <(decode_mmu_ptr16_s1_ax-1)
.byte <(decode_s1_ptr8-1)
.byte <(decode_s1_ptr16-1)
.byte <(decode_s1_ax-1)
.byte <(decode_s1_bx-1)
.byte <(decode_s1_cx-1)
.byte <(decode_s1_dx-1)
.byte <(decode_s1_sp-1)
.byte <(decode_s1_bp-1)
.byte <(decode_s1_si-1)
.byte <(decode_s1_di-1)
.byte <(decode_s1_cs-1)
.byte <(decode_s1_ds-1)
.byte <(decode_s1_es-1)
.byte <(decode_s1_ss-1)
.byte <(decode_s1_stack-1)
.byte <(decode_s0_ax_s1_bx-1)
.byte <(decode_s0_ax_s1_cx-1)
.byte <(decode_s0_ax_s1_dx-1)
.byte <(decode_s0_ax_s1_sp-1)
.byte <(decode_s0_ax_s1_bp-1)
.byte <(decode_s0_ax_s1_si-1)
.byte <(decode_s0_ax_s1_di-1)
.byte <(decode_s0_ip_s1_imm16-1)
.byte <(decode_s0_imm16_s1_imm16-1)
.byte <(decode_s0_imm16-1)
.byte <(decode_s0_al-1)
.byte <(decode_d0_flags-1)
.byte <(decode_s0_ah-1)
.byte <(decode_d0_flags_lo-1)
.byte <(decode_bad-1)
rbaDecodeFuncHi:
.byte >(decode_nop-1)
.byte >(decode_s0_embed_reg16-1)
.byte >(decode_s0_al_s1_imm8-1)
.byte >(decode_s0_ax_s1_imm16-1)
.byte >(decode_s1_imm8-1)
.byte >(decode_s1_imm16-1)
.byte >(decode_s0_ip_s1_imm8-1)
.byte >(decode_s0_modrm_rm8_s1_modrm_reg8-1)
.byte >(decode_s0_modrm_rm16_s1_modrm_reg16-1)
.byte >(decode_s0_modrm_reg8_s1_modrm_rm8-1)
.byte >(decode_s0_modrm_reg16_s1_modrm_rm16-1)
.byte >(decode_s0_modrm_rm16_s1_modrm_seg16-1)
.byte >(decode_s0_modrm_seg16_s1_modrm_rm16-1)
.byte >(decode_mmu_ptr8_s1_al-1)
.byte >(decode_mmu_ptr16_s1_ax-1)
.byte >(decode_s1_ptr8-1)
.byte >(decode_s1_ptr16-1)
.byte >(decode_s1_ax-1)
.byte >(decode_s1_bx-1)
.byte >(decode_s1_cx-1)
.byte >(decode_s1_dx-1)
.byte >(decode_s1_sp-1)
.byte >(decode_s1_bp-1)
.byte >(decode_s1_si-1)
.byte >(decode_s1_di-1)
.byte >(decode_s1_cs-1)
.byte >(decode_s1_ds-1)
.byte >(decode_s1_es-1)
.byte >(decode_s1_ss-1)
.byte >(decode_s1_stack-1)
.byte >(decode_s0_ax_s1_bx-1)
.byte >(decode_s0_ax_s1_cx-1)
.byte >(decode_s0_ax_s1_dx-1)
.byte >(decode_s0_ax_s1_sp-1)
.byte >(decode_s0_ax_s1_bp-1)
.byte >(decode_s0_ax_s1_si-1)
.byte >(decode_s0_ax_s1_di-1)
.byte >(decode_s0_ip_s1_imm16-1)
.byte >(decode_s0_imm16_s1_imm16-1)
.byte >(decode_s0_imm16-1)
.byte >(decode_s0_al-1)
.byte >(decode_d0_flags-1)
.byte >(decode_s0_ah-1)
.byte >(decode_d0_flags_lo-1)
.byte >(decode_bad-1)
rbaDecodeFuncEnd:

.assert (rbaDecodeFuncHi - rbaDecodeFuncLo) = (rbaDecodeFuncEnd - rbaDecodeFuncHi), error, "incomplete decode function"
.assert (rbaDecodeFuncHi - rbaDecodeFuncLo) = FUNC_COUNT, error, "decode function count"

; map opcodes to instruction encodings
rbaInstrDecode:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte D07,D08,D09,D10,D02,D03,D27,D29,D07,D08,D09,D10,D02,D03,D25,BAD ; 0_
.byte D07,D08,D09,D10,D02,D03,D28,D29,D07,D08,D09,D10,D02,D03,D26,D29 ; 1_
.byte D07,D08,D09,D10,D02,D03,BAD,BAD,D07,D08,D09,D10,D02,D03,BAD,BAD ; 2_
.byte D07,D08,D09,D10,D02,D03,BAD,D40,D07,D08,D09,D10,D02,D03,BAD,D40 ; 3_
.byte D01,D01,D01,D01,D01,D01,D01,D01,D01,D01,D01,D01,D01,D01,D01,D01 ; 4_
.byte D17,D19,D20,D18,D21,D22,D23,D24,D29,D29,D29,D29,D29,D29,D29,D29 ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte D06,D06,D06,D06,D06,D06,D06,D06,D06,D06,D06,D06,D06,D06,D06,D06 ; 7_
.byte BAD,BAD,BAD,BAD,D09,D10,D09,D10,D07,D08,D09,D10,D11,BAD,D12,BAD ; 8_
.byte D00,D31,D32,D30,D33,D34,D35,D36,D40,D17,D38,BAD,D41,D29,D42,D43 ; 9_
.byte D15,D16,D13,D14,BAD,BAD,BAD,BAD,D02,D03,BAD,BAD,BAD,BAD,BAD,BAD ; A_
.byte D04,D04,D04,D04,D04,D04,D04,D04,D05,D05,D05,D05,D05,D05,D05,D05 ; B_
.byte BAD,BAD,D39,D00,BAD,BAD,BAD,BAD,BAD,BAD,D39,D00,BAD,BAD,BAD,BAD ; C_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; D_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,D37,D37,D38,D06,BAD,BAD,BAD,BAD ; E_
.byte BAD,BAD,BAD,BAD,BAD,D00,BAD,BAD,D00,D00,D00,D00,D00,D00,BAD,BAD ; F_



.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; determine which registers/memory needs to be accessed.
; move data into pseudo-registers.
.proc decode
    lda #0
    sta zbWord

    ldx Reg::zbInstrOpcode
    ldy rbaInstrDecode, x
    lda rbaDecodeFuncHi, y
    pha
    lda rbaDecodeFuncLo, y
    pha
    rts
.endproc

; ==============================================================================
; decode handlers.
; ==============================================================================

; do nothing and return.
; used to handle instructions that don't need any decoding.
.proc decode_nop
    rts
.endproc


; handle an opcode that contains an index to a 16-bit register
.proc decode_s0_embed_reg16
    inc zbWord

    ; lookup the address of the register
    lda Reg::zbInstrOpcode
    and #Const::OPCODE_REG_MASK
    tay
    ldx Reg::rzbaReg16Map, y

    ; copy the register to S0
    lda Const::ZERO_PAGE, x
    sta Reg::zwS0
    inx
    lda Const::ZERO_PAGE, x
    sta Reg::zwS0+1

    rts
.endproc


; opcode implies that AX is used and a 16-bit operand follows it
.proc decode_s0_ax_s1_imm16
    inc zbWord

    lda Reg::zwAX+1
    sta Reg::zwS0+1

    lda Reg::zaInstrOperands+1
    sta Reg::zwS1+1

    ; fall through to copy the low bytes
.endproc

; opcode implies that AL is used and an 8-bit operand follows it
.proc decode_s0_al_s1_imm8
    lda Reg::zbAL
    sta Reg::zwS0

    lda Reg::zaInstrOperands
    sta Reg::zwS1
    rts
.endproc


; opcode is followed by a 16-bit operand
.proc decode_s1_imm16
    inc zbWord

    lda Reg::zaInstrOperands+1
    sta Reg::zwS1+1

    ; fall through to copy the low bytes
.endproc

; opcode is followed by an 8-bit operand
.proc decode_s1_imm8
    lda Reg::zaInstrOperands
    sta Reg::zwS1
    rts
.endproc


; opcode implies that IP is used and an 8-bit operand follows it.
; used for conditional jumps.
.proc decode_s0_ip_s1_imm8
    lda Reg::zwIP
    sta Reg::zwS0
    lda Reg::zwIP+1
    sta Reg::zwS0+1

    lda Reg::zaInstrOperands
    sta Reg::zwS1
    rts
.endproc


.proc decode_s0_modrm_rm8_s1_modrm_reg8
    jsr handle_modrm_rm
    lda Tmp::zb0
    sta Reg::zwS0

    jsr handle_modrm_reg
    lda Tmp::zb0
    sta Reg::zwS1

    rts
.endproc


.proc decode_s0_modrm_rm16_s1_modrm_reg16
    inc zbWord

    jsr handle_modrm_rm
    lda Tmp::zw0
    sta Reg::zwS0
    lda Tmp::zw0+1
    sta Reg::zwS0+1

    jsr handle_modrm_reg
    lda Tmp::zw0
    sta Reg::zwS1
    lda Tmp::zw0+1
    sta Reg::zwS1+1

    rts
.endproc


.proc decode_s0_modrm_reg8_s1_modrm_rm8
    jsr handle_modrm_reg
    lda Tmp::zb0
    sta Reg::zwS0

    jsr handle_modrm_rm
    lda Tmp::zb0
    sta Reg::zwS1

    rts
.endproc


.proc decode_s0_modrm_reg16_s1_modrm_rm16
    inc zbWord

    jsr handle_modrm_reg
    lda Tmp::zw0
    sta Reg::zwS0
    lda Tmp::zw0+1
    sta Reg::zwS0+1

    jsr handle_modrm_rm
    lda Tmp::zw0
    sta Reg::zwS1
    lda Tmp::zw0+1
    sta Reg::zwS1+1

    rts
.endproc


.proc decode_s0_modrm_rm16_s1_modrm_seg16
    inc zbWord

    jsr handle_modrm_rm
    lda Tmp::zw0
    sta Reg::zwS0
    lda Tmp::zw0+1
    sta Reg::zwS0+1

    jsr handle_modrm_seg
    lda Tmp::zw0
    sta Reg::zwS1
    lda Tmp::zw0+1
    sta Reg::zwS1+1

    rts
.endproc


.proc decode_s0_modrm_seg16_s1_modrm_rm16
    inc zbWord

    jsr handle_modrm_seg
    lda Tmp::zw0
    sta Reg::zwS0
    lda Tmp::zw0+1
    sta Reg::zwS0+1

    jsr handle_modrm_rm
    lda Tmp::zw0
    sta Reg::zwS1
    lda Tmp::zw0+1
    sta Reg::zwS1+1

    rts
.endproc


; opcode implies AX is needed
.proc decode_mmu_ptr16_s1_ax
    inc zbWord

    lda Reg::zwAX+1
    sta Reg::zwS1+1
    ; fall through to copy the low bytes
.endproc

; opcode implies AL is needed
.proc decode_mmu_ptr8_s1_al
    lda Reg::zbAL
    sta Reg::zwS1

    jsr prefix_seg_index
    bcc segment_prefix
    ldy #Reg::Seg::DS
segment_prefix:
    lda Reg::zaInstrOperands
    sta Tmp::zw0
    lda Reg::zaInstrOperands+1
    sta Tmp::zw0+1
    jsr Mmu::set_address
    rts
.endproc


.proc decode_s1_ptr8
    jsr prefix_seg_index
    bcc segment_prefix
    ldy #Reg::Seg::DS
segment_prefix:
    lda Reg::zaInstrOperands
    sta Tmp::zw0
    lda Reg::zaInstrOperands+1
    sta Tmp::zw0+1
    jsr Mmu::set_address

    jsr Mmu::get_byte
    sta Reg::zwS1
    rts
.endproc

.proc decode_s1_ptr16
    inc zbWord

    jsr prefix_seg_index
    bcc segment_prefix
    ldy #Reg::Seg::DS
segment_prefix:
    lda Reg::zaInstrOperands
    sta Tmp::zw0
    lda Reg::zaInstrOperands+1
    sta Tmp::zw0+1
    jsr Mmu::set_address

    jsr Mmu::get_byte
    sta Reg::zwS1
    jsr Mmu::peek_next_byte
    sta Reg::zwS1+1
    rts
.endproc


.proc decode_s1_ax
    lda Reg::zwAX
    sta Reg::zwS1
    lda Reg::zwAX+1
    sta Reg::zwS1+1
    rts
.endproc


.proc decode_s1_bx
    lda Reg::zwBX
    sta Reg::zwS1
    lda Reg::zwBX+1
    sta Reg::zwS1+1
    rts
.endproc


.proc decode_s1_cx
    lda Reg::zwCX
    sta Reg::zwS1
    lda Reg::zwCX+1
    sta Reg::zwS1+1
    rts
.endproc


.proc decode_s1_dx
    lda Reg::zwDX
    sta Reg::zwS1
    lda Reg::zwDX+1
    sta Reg::zwS1+1
    rts
.endproc


.proc decode_s1_sp
    lda Reg::zwSP
    sta Reg::zwS1
    lda Reg::zwSP+1
    sta Reg::zwS1+1
    rts
.endproc


.proc decode_s1_bp
    lda Reg::zwBP
    sta Reg::zwS1
    lda Reg::zwBP+1
    sta Reg::zwS1+1
    rts
.endproc


.proc decode_s1_si
    lda Reg::zwSI
    sta Reg::zwS1
    lda Reg::zwSI+1
    sta Reg::zwS1+1
    rts
.endproc


.proc decode_s1_di
    lda Reg::zwDI
    sta Reg::zwS1
    lda Reg::zwDI+1
    sta Reg::zwS1+1
    rts
.endproc


.proc decode_s1_cs
    lda Reg::zwCS
    sta Reg::zwS1
    lda Reg::zwCS+1
    sta Reg::zwS1+1
    rts
.endproc


.proc decode_s1_ds
    lda Reg::zwDS
    sta Reg::zwS1
    lda Reg::zwDS+1
    sta Reg::zwS1+1
    rts
.endproc


.proc decode_s1_es
    lda Reg::zwES
    sta Reg::zwS1
    lda Reg::zwES+1
    sta Reg::zwS1+1
    rts
.endproc


.proc decode_s1_ss
    lda Reg::zwSS
    sta Reg::zwS1
    lda Reg::zwSS+1
    sta Reg::zwS1+1
    rts
.endproc


.proc decode_s1_stack
    jsr Mmu::pop_word
    lda Tmp::zw0
    sta Reg::zwS1
    lda Tmp::zw0+1
    sta Reg::zwS1+1
    rts
.endproc


.proc decode_s0_ax_s1_bx
    jsr decode_s0_ax
    jmp decode_s1_bx ; jsr rts -> jmp
.endproc


.proc decode_s0_ax_s1_cx
    jsr decode_s0_ax
    jmp decode_s1_cx ; jsr rts -> jmp
.endproc


.proc decode_s0_ax_s1_dx
    jsr decode_s0_ax
    jmp decode_s1_dx ; jsr rts -> jmp
.endproc


.proc decode_s0_ax_s1_sp
    jsr decode_s0_ax
    jmp decode_s1_sp ; jsr rts -> jmp
.endproc


.proc decode_s0_ax_s1_bp
    jsr decode_s0_ax
    jmp decode_s1_bp ; jsr rts -> jmp
.endproc


.proc decode_s0_ax_s1_si
    jsr decode_s0_ax
    jmp decode_s1_si ; jsr rts -> jmp
.endproc


.proc decode_s0_ax_s1_di
    jsr decode_s0_ax
    jmp decode_s1_di ; jsr rts -> jmp
.endproc


.proc decode_s0_ip_s1_imm16
    lda Reg::zwIP
    sta Reg::zwS0
    lda Reg::zwIP+1
    sta Reg::zwS0+1

    lda Reg::zaInstrOperands
    sta Reg::zwS1
    lda Reg::zaInstrOperands+1
    sta Reg::zwS1+1
    rts
.endproc


.proc decode_s0_imm16_s1_imm16
    lda Reg::zaInstrOperands
    sta Reg::zwS0
    lda Reg::zaInstrOperands+1
    sta Reg::zwS0+1

    lda Reg::zaInstrOperands+2
    sta Reg::zwS1
    lda Reg::zaInstrOperands+3
    sta Reg::zwS1+1
    rts
.endproc


.proc decode_s0_imm16
    lda Reg::zaInstrOperands
    sta Reg::zwS0
    lda Reg::zaInstrOperands+1
    sta Reg::zwS0+1
    rts
.endproc


.proc decode_s0_al
    lda Reg::zbAL
    sta Reg::zwS0
    rts
.endproc


.proc decode_d0_flags
    lda Reg::zwFlags
    sta Reg::zwD0
    lda Reg::zwFlags+1
    sta Reg::zwD0+1
    rts
.endproc


.proc decode_s0_ah
    lda Reg::zbAH
    sta Reg::zwS0
    rts
.endproc


.proc decode_d0_flags_lo
    lda Reg::zbFlagsLo
    sta Reg::zwD0
    rts
.endproc


; called when an unsupported instruction byte is decoded.
; < A = instruction byte
.proc decode_bad
    lda #X86::Err::DECODE_FUNC
    jmp X86::panic
.endproc

; ==============================================================================

.segment "RODATA"

rbaModRMFuncLo:
.byte <(modrm_rm_mode0-1)
.byte <(modrm_rm_mode1-1)
.byte <(modrm_rm_mode2-1)
.byte <(modrm_rm_mode3-1)
rbaModRMFuncHi:
.byte >(modrm_rm_mode0-1)
.byte >(modrm_rm_mode1-1)
.byte >(modrm_rm_mode2-1)
.byte >(modrm_rm_mode3-1)
rbaModRMFuncEnd:

.segment "CODE"

; handle the R/M portion of a ModR/M byte based on the mode.
; for 8-bit operations
; > Tmp::zb0 8-bit data
; for 16-bit operations
; > Tmp::zw0 16-bit data
.proc handle_modrm_rm
    ; use the Mod portion of a ModR/M byte as an index to a function pointer.
    lda Reg::zaInstrOperands
    and #Const::MODRM_MOD_MASK
    asl ; discard C as it's in an unknown state
    rol
    rol
    tax
    lda rbaModRMFuncHi, x
    pha
    lda rbaModRMFuncLo, x
    pha
    lda Reg::zaInstrOperands
    and #Const::MODRM_RM_MASK
    rts
.endproc


; handle the reg portion of a ModR/M byte.
; for 8-bit operations
; > Tmp::zb0 8-bit data
; for 16-bit operations
; > Tmp::zw0 16-bit data
.proc handle_modrm_reg
    lda Reg::zaInstrOperands
    and #Const::MODRM_REG_MASK
    lsr
    lsr
    lsr
    jmp modrm_rm_mode3 ; jsr rts -> jmp
.endproc


; handle the segreg portion of a ModR/M byte.
; > Tmp::zw0 16-bit data
.proc handle_modrm_seg
    ; lookup the address of the segment register
    lda Reg::zaInstrOperands
    and #Const::MODRM_SEG_MASK
    lsr
    lsr
    lsr
    tay
    ldx Reg::rzbaSegRegMap, y

    lda Const::ZERO_PAGE, x
    sta Tmp::zw0
    inx
    lda Const::ZERO_PAGE, x
    sta Tmp::zw0+1

    rts
.endproc


; handle pointer in registers or a direct address
; < A = R/M bits of a ModR/M byte
; > Tmp::zw0 = byte(s) read from memory
.proc modrm_rm_mode0
    ; handle pointer in registers
    cmp #%00000110
    beq direct_address ; branch if we have a direct address as an operand

    jsr modrm_get_address
    jmp get_bytes

direct_address:
    lda Reg::zaInstrOperands+1
    sta Tmp::zw0
    lda Reg::zaInstrOperands+2
    sta Tmp::zw0+1

get_bytes:
    jmp modrm_get_bytes ; jsr rts -> jmp
.endproc

; handle pointer in registers + 8-bit signed offset
; < A = R/M bits of a ModR/M byte
; > Tmp::zw0 = byte(s) read from memory
.proc modrm_rm_mode1
    jsr modrm_get_address

    ; add 8-bit signed offset
    ; TODO: handle negative values
    clc
    lda Reg::zaInstrOperands+1
    adc Tmp::zw0
    sta Tmp::zw0
    lda #0
    adc Tmp::zw0+1
    sta Tmp::zw0+1

    jmp modrm_get_bytes ; jsr rts -> jmp
.endproc


; handle pointer in registers + 16-bit unsigned offset
; < A = R/M bits of a ModR/M byte
; > Tmp::zw0 = byte(s) read from memory
.proc modrm_rm_mode2
    jsr modrm_get_address

    ; add 16-bit unsigned offset
    clc
    lda Reg::zaInstrOperands+1
    adc Tmp::zw0
    sta Tmp::zw0
    lda Reg::zaInstrOperands+2
    adc Tmp::zw0+1
    sta Tmp::zw0+1

    jmp modrm_get_bytes ; jsr rts -> jmp
.endproc


; handle register
; < A = R/M bits of a ModR/M byte
; > Tmp::zw0 = byte(s) read from register
.proc modrm_rm_mode3
    tay

    ; check if the opcode is dealing with 16-bit data
    lda zbWord
    lsr
    bcc reg8 ; branch if 8-bit data is needed

    ldx Reg::rzbaReg16Map, y
    SKIP_WORD
reg8:
    ldx Reg::rzbaReg8Map, y

    ldy Const::ZERO_PAGE, x
    sty Tmp::zw0

    bcc done ; branch if 8-bit data is needed

    inx
    ldy Const::ZERO_PAGE, x
    sty Tmp::zw0+1

done:
    rts
.endproc


; calculate a memory address from the register(s) indicated by ModR/M.
; < A = R/M bits of a ModR/M byte
; > Tmp::zw0 = memory address
; changes: A, X, Y
.proc modrm_get_address
    ; grab the contents of a register specified by table 0
    tay
    ldx Reg::rzbaMem0Map, y
    ldy Const::ZERO_PAGE, x
    sty Tmp::zw0
    inx
    ldy Const::ZERO_PAGE, x
    sty Tmp::zw0

    cmp #4
    bcc done ; branch if we don't need data from a second register

    ; add the contents of another register specified by table 1
    clc
    tay
    ldx Reg::rzbaMem1Map, y
    lda Const::ZERO_PAGE, x
    adc Tmp::zw0
    sta Tmp::zw0
    inx
    lda Const::ZERO_PAGE, x
    adc Tmp::zw0
    sta Tmp::zw0

done:
    rts
.endproc


.proc modrm_get_bytes
    jsr prefix_seg_index
    bcc segment_prefix
    ldy #Reg::Seg::DS
segment_prefix:
    jsr Mmu::set_address
    jsr Mmu::get_byte
    sta Tmp::zw0

    ; check if the opcode is dealing with 16-bit data
    lda zbWord
    beq done ; branch if the opcode is operating on 8-bit data

    ; get the next byte
    jsr Mmu::peek_next_byte
    sta Tmp::zw0+1

done:
    rts
.endproc


.proc decode_s0_ax
    lda Reg::zwAX
    sta Reg::zwS0
    lda Reg::zwAX+1
    sta Reg::zwS0+1
    rts
.endproc


; extract a segment register index from an instruction prefix
; > Y = segment register index
; > C = 0 success. Y contains a segment register index
;   C = 1 failure.
; changes: A, Y
.proc prefix_seg_index
    lda Reg::zbInstrPrefix
    beq error ; branch if there is no prefix

    ; this kind of checks if we have a segment prefix.
    ; hopefully the fetch stage will ensure that only valid prefix values are set.
    ; otherwise we could have some unintended behavior.
    cmp #$3f
    bcs done ; branch if the prefix isn't a segment prefix

    and #Const::PREFIX_SEG_MASK
    lsr
    lsr
    lsr
    tay

    SKIP_BYTE
error:
    sec
done:
    rts
.endproc
