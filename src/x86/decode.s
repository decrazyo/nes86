
; This module is responsible for copying values needed by x86 instructions
; into temporary registers.
; This module must only read the x86 address space though the
; Mem's general-purpose memory interface and dedicated stack interface.
; This module must not write to the x86 address space at all.
; This module may only move data and must not transform it in any other way.
; If an instruction's opcode indicates that it simply moves a value to or from a fixed
; location, i.e. a specific register or the stack, then reading that
; value may be deferred until the "write" stage.
; e.g. decoding "CALL 0x1234:0x5678" may defer reading "CS" to the "write" stage
; since the opcode of the instruction (0x9A) always requires "CS" to be
; pushed onto the stack and "CS" is not needed by the "execute" stage.
; If an instruction will write to the x86 address space during the "write" stage
; then this module must configure the Mem appropriately for that write.
;
; uses:
;   Mem::set_address
;   Mem::get_byte
;   Mem::peek_next_byte
;   Mem::pop_word
; changes:
;   Reg::zbS0
;   Reg::zbS1
;   Reg::zbD0

.include "x86/decode.inc"
.include "x86/fetch.inc"
.include "x86/reg.inc"
.include "x86/mem.inc"
.include "x86/util.inc"
.include "x86.inc"

.include "tmp.inc"
.include "const.inc"

.exportzp zbMod

.exportzp zbExt
.exportzp zbSeg
.exportzp zbReg

.exportzp zbRM

.export decode

.segment "ZEROPAGE"

; ModR/M Mod field
; populated by the fetch stage
zbMod: .res 1

; ModR/M reg field and aliases
zbExt: ; opcode extension index
zbSeg: ; segment register index
zbReg: .res 1 ; register index

; ModR/M R/M field
zbRM: .res 1

.segment "RODATA"

; map instruction encodings to their decoding functions.
rbaDecodeFuncLo:
.byte <(decode_nothing-1)
.byte <(decode_s0l_modrm_reg8_d0l_modrm_rm8-1)
.byte <(decode_s0x_modrm_reg16_d0x_modrm_rm16-1)
.byte <(decode_s0l_modrm_rm8_d0l_modrm_reg8-1)
.byte <(decode_s0x_modrm_rm16_d0x_modrm_reg16-1)
.byte <(decode_s0l_imm8_d0l_modrm_rm8-1)
.byte <(decode_s0x_imm16_d0x_modrm_rm16-1)
.byte <(decode_s0l_imm8_d0l_embed_reg8-1)
.byte <(decode_s0x_imm16_d0x_embed_reg16-1)
.byte <(decode_s0l_mem8_imm16-1)
.byte <(decode_s0x_mem16_imm16-1)
.byte <(decode_s0l_al_d0l_mem8-1)
.byte <(decode_s0x_ax_d0x_mem16-1)
.byte <(decode_s0x_modrm_seg16_d0x_modrm_rm16-1)
.byte <(decode_s0x_embed_reg16-1)
.byte <(decode_s0x_embed_seg16-1)
.byte <(decode_d0x_modrm_rm-1)
.byte <(decode_d0x_embed_reg16-1)
.byte <(decode_d0x_embed_seg16-1)
.byte <(decode_s0l_modrm_reg8_s1l_modrm_rm8-1)
.byte <(decode_s0x_modrm_reg16_s1x_modrm_rm16-1)
.byte <(decode_s0x_embed_reg16_s1x_ax-1)
.byte <(decode_s0x_imm8-1)
.byte <(decode_s0x_dx-1)
.byte <(decode_s0l_mem8_bx_al-1)
.byte <(decode_s0x_modrm_m_addr-1)
.byte <(decode_s0x_modrm_m32_lo_s1x_modrm_m32_hi-1)
.byte <(decode_s0l_flags_lo-1)
.byte <(decode_s0l_ah-1)
.byte <(decode_s0x_flags-1)
.byte <(decode_s0l_modrm_rm8_s1l_modrm_reg8-1)
.byte <(decode_s0x_modrm_rm16_s1x_modrm_reg16-1)
.byte <(decode_s0l_al_s1l_imm8-1)
.byte <(decode_s0x_ax_s1x_imm16-1)
.byte <(decode_s0x_embed_reg16_d0x_embed_reg16-1)
.byte <(decode_s0x_ax-1)
.byte <(decode_s0l_al-1)
.byte <(decode_s0l_al_s1l_ah_s2l_imm8-1)
.byte <(decode_s0l_mem8_si-1)
.byte <(decode_s0x_mem16_si-1)
.byte <(decode_s0l_mem8_si_s1l_mem8_di-1)
.byte <(decode_s0x_mem16_si_s1x_mem16_di-1)
.byte <(decode_s0x_al_s1x_mem8_di-1)
.byte <(decode_s0x_ax_s1x_mem16_di-1)
.byte <(decode_s0l_imm8-1)
.byte <(decode_s0x_imm16-1)
.byte <(decode_s0x_imm16_s1x_imm16-1)
.byte <(decode_s0l_modrm_rm8_s1l_imm8-1)
.byte <(decode_s0x_modrm_rm16_s1x_imm16-1)
.byte <(decode_s0x_modrm_rm16_s1x_imm8-1)
.byte <(decode_s0l_modrm_rm8_s1l_1-1)
.byte <(decode_s0x_modrm_rm16_s1l_1-1)
.byte <(decode_s0l_modrm_rm8_s1l_cl-1)
.byte <(decode_s0x_modrm_rm16_s1l_cl-1)
.byte <(decode_s0l_modrm_rm8_opt_s1l_imm8-1)
.byte <(decode_s0x_modrm_rm16_opt_s1x_imm16-1)
.byte <(decode_s0l_modrm_rm8-1)
.byte <(decode_s0x_modrm_rm16_or_s0x_modrm_m32_lo_s1x_modrm_m32_hi-1)
.byte <(decode_s0l_al_d0l_mem8_di-1)
.byte <(decode_s0x_ax_d0x_mem16_di-1)
.byte <(decode_s0l_mem8_si_d0l_mem8_di-1)
.byte <(decode_s0x_mem16_si_d0x_mem16_di-1)
.byte <(decode_s0x_imm8_s1l_al-1)
.byte <(decode_s0x_imm8_s1x_ax-1)
.byte <(decode_s0x_dx_s1l_al-1)
.byte <(decode_s0x_dx_s1x_ax-1)
.byte <(decode_bad-1)
rbaDecodeFuncHi:
.byte >(decode_nothing-1)
.byte >(decode_s0l_modrm_reg8_d0l_modrm_rm8-1)
.byte >(decode_s0x_modrm_reg16_d0x_modrm_rm16-1)
.byte >(decode_s0l_modrm_rm8_d0l_modrm_reg8-1)
.byte >(decode_s0x_modrm_rm16_d0x_modrm_reg16-1)
.byte >(decode_s0l_imm8_d0l_modrm_rm8-1)
.byte >(decode_s0x_imm16_d0x_modrm_rm16-1)
.byte >(decode_s0l_imm8_d0l_embed_reg8-1)
.byte >(decode_s0x_imm16_d0x_embed_reg16-1)
.byte >(decode_s0l_mem8_imm16-1)
.byte >(decode_s0x_mem16_imm16-1)
.byte >(decode_s0l_al_d0l_mem8-1)
.byte >(decode_s0x_ax_d0x_mem16-1)
.byte >(decode_s0x_modrm_seg16_d0x_modrm_rm16-1)
.byte >(decode_s0x_embed_reg16-1)
.byte >(decode_s0x_embed_seg16-1)
.byte >(decode_d0x_modrm_rm-1)
.byte >(decode_d0x_embed_reg16-1)
.byte >(decode_d0x_embed_seg16-1)
.byte >(decode_s0l_modrm_reg8_s1l_modrm_rm8-1)
.byte >(decode_s0x_modrm_reg16_s1x_modrm_rm16-1)
.byte >(decode_s0x_embed_reg16_s1x_ax-1)
.byte >(decode_s0x_imm8-1)
.byte >(decode_s0x_dx-1)
.byte >(decode_s0l_mem8_bx_al-1)
.byte >(decode_s0x_modrm_m_addr-1)
.byte >(decode_s0x_modrm_m32_lo_s1x_modrm_m32_hi-1)
.byte >(decode_s0l_flags_lo-1)
.byte >(decode_s0l_ah-1)
.byte >(decode_s0x_flags-1)
.byte >(decode_s0l_modrm_rm8_s1l_modrm_reg8-1)
.byte >(decode_s0x_modrm_rm16_s1x_modrm_reg16-1)
.byte >(decode_s0l_al_s1l_imm8-1)
.byte >(decode_s0x_ax_s1x_imm16-1)
.byte >(decode_s0x_embed_reg16_d0x_embed_reg16-1)
.byte >(decode_s0x_ax-1)
.byte >(decode_s0l_al-1)
.byte >(decode_s0l_al_s1l_ah_s2l_imm8-1)
.byte >(decode_s0l_mem8_si-1)
.byte >(decode_s0x_mem16_si-1)
.byte >(decode_s0l_mem8_si_s1l_mem8_di-1)
.byte >(decode_s0x_mem16_si_s1x_mem16_di-1)
.byte >(decode_s0x_al_s1x_mem8_di-1)
.byte >(decode_s0x_ax_s1x_mem16_di-1)
.byte >(decode_s0l_imm8-1)
.byte >(decode_s0x_imm16-1)
.byte >(decode_s0x_imm16_s1x_imm16-1)
.byte >(decode_s0l_modrm_rm8_s1l_imm8-1)
.byte >(decode_s0x_modrm_rm16_s1x_imm16-1)
.byte >(decode_s0x_modrm_rm16_s1x_imm8-1)
.byte >(decode_s0l_modrm_rm8_s1l_1-1)
.byte >(decode_s0x_modrm_rm16_s1l_1-1)
.byte >(decode_s0l_modrm_rm8_s1l_cl-1)
.byte >(decode_s0x_modrm_rm16_s1l_cl-1)
.byte >(decode_s0l_modrm_rm8_opt_s1l_imm8-1)
.byte >(decode_s0x_modrm_rm16_opt_s1x_imm16-1)
.byte >(decode_s0l_modrm_rm8-1)
.byte >(decode_s0x_modrm_rm16_or_s0x_modrm_m32_lo_s1x_modrm_m32_hi-1)
.byte >(decode_s0l_al_d0l_mem8_di-1)
.byte >(decode_s0x_ax_d0x_mem16_di-1)
.byte >(decode_s0l_mem8_si_d0l_mem8_di-1)
.byte >(decode_s0x_mem16_si_d0x_mem16_di-1)
.byte >(decode_s0x_imm8_s1l_al-1)
.byte >(decode_s0x_imm8_s1x_ax-1)
.byte >(decode_s0x_dx_s1l_al-1)
.byte >(decode_s0x_dx_s1x_ax-1)
.byte >(decode_bad-1)
rbaDecodeFuncEnd:

.assert (rbaDecodeFuncHi - rbaDecodeFuncLo) = (rbaDecodeFuncEnd - rbaDecodeFuncHi), error, "incomplete decode function"

; instruction encodings
.enum
    D00 ; decode_nothing
    D01 ; decode_s0l_modrm_reg8_d0l_modrm_rm8
    D02 ; decode_s0x_modrm_reg16_d0x_modrm_rm16
    D03 ; decode_s0l_modrm_rm8_d0l_modrm_reg8
    D04 ; decode_s0x_modrm_rm16_d0x_modrm_reg16
    D05 ; decode_s0l_imm8_d0l_modrm_rm8
    D06 ; decode_s0x_imm16_d0x_modrm_rm16
    D07 ; decode_s0l_imm8_d0l_embed_reg8
    D08 ; decode_s0x_imm16_d0x_embed_reg16
    D09 ; decode_s0l_mem8_imm16
    D10 ; decode_s0x_mem16_imm16
    D11 ; decode_s0l_al_d0l_mem8
    D12 ; decode_s0x_ax_d0x_mem16
    D13 ; decode_s0x_modrm_seg16_d0x_modrm_rm16
    D14 ; decode_s0x_embed_reg16
    D15 ; decode_s0x_embed_seg16
    D16 ; decode_d0x_modrm_rm
    D17 ; decode_d0x_embed_reg16
    D18 ; decode_d0x_embed_seg16
    D19 ; decode_s0l_modrm_reg8_s1l_modrm_rm8
    D20 ; decode_s0x_modrm_reg16_s1x_modrm_rm16
    D21 ; decode_s0x_embed_reg16_s1x_ax
    D22 ; decode_s0x_imm8
    D23 ; decode_s0x_dx
    D24 ; decode_s0l_mem8_bx_al
    D25 ; decode_s0x_modrm_m_addr
    D26 ; decode_s0x_modrm_m32_lo_s1x_modrm_m32_hi
    D27 ; decode_s0l_flags_lo
    D28 ; decode_s0l_ah
    D29 ; decode_s0x_flags
    D30 ; decode_s0l_modrm_rm8_s1l_modrm_reg8
    D31 ; decode_s0x_modrm_rm16_s1x_modrm_reg16
    D32 ; decode_s0l_al_s1l_imm8
    D33 ; decode_s0x_ax_s1x_imm16
    D34 ; decode_s0x_embed_reg16_d0x_embed_reg16
    D35 ; decode_s0x_ax
    D36 ; decode_s0l_al
    D37 ; decode_s0l_al_s1l_ah_s2l_imm8
    D38 ; decode_s0l_mem8_si
    D39 ; decode_s0x_mem16_si
    D40 ; decode_s0l_mem8_si_s1l_mem8_di
    D41 ; decode_s0x_mem16_si_s1x_mem16_di
    D42 ; decode_s0x_al_s1x_mem8_di
    D43 ; decode_s0x_ax_s1x_mem16_di
    D44 ; decode_s0l_imm8
    D45 ; decode_s0x_imm16
    D46 ; decode_s0x_imm16_s1x_imm16
    D47 ; decode_s0l_modrm_rm8_s1l_imm8
    D48 ; decode_s0x_modrm_rm16_s1x_imm16
    D49 ; decode_s0x_modrm_rm16_s1x_imm8
    D50 ; decode_s0l_modrm_rm8_s1l_1
    D51 ; decode_s0x_modrm_rm16_s1l_1
    D52 ; decode_s0l_modrm_rm8_s1l_cl
    D53 ; decode_s0x_modrm_rm16_s1l_cl
    D54 ; decode_s0l_modrm_rm8_opt_s1l_imm8
    D55 ; decode_s0x_modrm_rm16_opt_s1x_imm16
    D56 ; decode_s0l_modrm_rm8
    D57 ; decode_s0x_modrm_rm16_or_s0x_modrm_m32_lo_s1x_modrm_m32_hi
    D58 ; decode_s0l_al_d0l_mem8_di
    D59 ; decode_s0x_ax_d0x_mem16_di
    D60 ; decode_s0l_mem8_si_d0l_mem8_di
    D61 ; decode_s0x_mem16_si_d0x_mem16_di
    D62 ; decode_s0x_imm8_s1l_al
    D63 ; decode_s0x_imm8_s1x_ax
    D64 ; decode_s0x_dx_s1l_al
    D65 ; decode_s0x_dx_s1x_ax

    BAD ; used for unimplemented or non-existent instructions
    FUNC_COUNT ; used to check function table size at compile-time
.endenum

.assert (rbaDecodeFuncHi - rbaDecodeFuncLo) = FUNC_COUNT, error, "decode function count"

; map opcodes to instruction encodings
rbaInstrDecode:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte D30,D31,D19,D20,D32,D33,D15,D18,D30,D31,D19,D20,D32,D33,D15,BAD ; 0_
.byte D30,D31,D19,D20,D32,D33,D15,D18,D30,D31,D19,D20,D32,D33,D15,D18 ; 1_
.byte D30,D31,D19,D20,D32,D33,BAD,D36,D30,D31,D19,D20,D32,D33,BAD,D36 ; 2_
.byte D30,D31,D19,D20,D32,D33,BAD,D35,D30,D31,D19,D20,D32,D33,BAD,D35 ; 3_
.byte D34,D34,D34,D34,D34,D34,D34,D34,D34,D34,D34,D34,D34,D34,D34,D34 ; 4_
.byte D14,D14,D14,D14,D14,D14,D14,D14,D17,D17,D17,D17,D17,D17,D17,D17 ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte D44,D44,D44,D44,D44,D44,D44,D44,D44,D44,D44,D44,D44,D44,D44,D44 ; 7_
.byte D47,D48,BAD,D49,D19,D20,D19,D20,D01,D02,D03,D04,D13,D25,D04,D16 ; 8_
.byte D00,D21,D21,D21,D21,D21,D21,D21,D36,D35,D46,D00,D29,D00,D28,D27 ; 9_
.byte D09,D10,D11,D12,D60,D61,D40,D41,D32,D33,D58,D59,D38,D39,D42,D43 ; A_
.byte D07,D07,D07,D07,D07,D07,D07,D07,D08,D08,D08,D08,D08,D08,D08,D08 ; B_
.byte BAD,BAD,D45,D00,D26,D26,D05,D06,BAD,BAD,D45,D00,D00,D44,D00,D00 ; C_
.byte D50,D51,D52,D53,D32,D37,BAD,D24,D00,D00,D00,D00,D00,D00,D00,D00 ; D_
.byte D44,D44,D44,D44,D22,D22,D62,D63,D45,D45,D46,D44,D23,D23,D64,D65 ; E_
.byte BAD,BAD,BAD,BAD,D00,D00,D54,D55,D00,D00,D00,D00,D00,D00,D56,D57 ; F_

rbaModRMAddrFuncLo:
.byte <(get_modrm_m_mode_0-1)
.byte <(get_modrm_m_mode_1-1)
.byte <(get_modrm_m_mode_2-1)
.byte <(get_modrm_r16-1)
rbaModRMAddrFuncHi:
.byte >(get_modrm_m_mode_0-1)
.byte >(get_modrm_m_mode_1-1)
.byte >(get_modrm_m_mode_2-1)
.byte >(get_modrm_r16-1)
rbaModRMAddrFuncEnd:

.assert (rbaModRMAddrFuncHi - rbaModRMAddrFuncLo) = (rbaModRMAddrFuncEnd - rbaModRMAddrFuncHi), error, "incomplete ModR/M address function"

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; determine which registers/memory needs to be accessed.
; move data into pseudo-registers.
; set any public values that might be useful for later steps.
; calls decode handlers with
; < A = garbage
; < X = instruction opcode
; < Y = function index
.proc decode
    ldx Fetch::zbInstrOpcode
    ldy rbaInstrDecode, x
    lda rbaDecodeFuncHi, y
    pha
    lda rbaDecodeFuncLo, y
    pha
    rts
.endproc

; ==============================================================================
; decode handlers
; see "decode" for argument descriptions
; ==============================================================================

; the instruction needs no inputs nor outputs or all inputs and outputs are static.
; return immediately without performing any actions.
; e.g.
;   NOP
;   CBW
.proc decode_nothing
    rts
.endproc


;    reg -> rm
;    rm -> reg
.proc decode_s0x_modrm_reg16_d0x_modrm_rm16
    jsr parse_modrm
    jsr use_modrm_pointer
    jsr get_modrm_reg16
    sta Reg::zwS0X
    stx Reg::zwS0X+1
    rts
.endproc

.proc decode_s0l_modrm_reg8_d0l_modrm_rm8
    jsr parse_modrm
    jsr use_modrm_pointer
    jsr get_modrm_reg8
    sta Reg::zbS0L
    rts
.endproc

decode_s0x_modrm_rm16: ; extended CALL, JMP, PUSH
decode_s0x_modrm_rm16_d0x_modrm_rm16: ; extended INC, DEC
.proc decode_s0x_modrm_rm16_d0x_modrm_reg16
    jsr parse_modrm
    jsr get_modrm_rm16
    sta Reg::zwS0X
    stx Reg::zwS0X+1
    rts
.endproc

.proc decode_s0l_modrm_rm8_d0l_modrm_reg8
    jsr parse_modrm
    jsr get_modrm_rm8
    sta Reg::zbS0L
    rts
.endproc

;    imm -> rm
.proc decode_s0x_imm16_d0x_modrm_rm16
    ldx Fetch::zbInstrLen
    lda Fetch::zbInstrBuffer-2, x
    sta Reg::zwS0X

    lda Fetch::zbInstrBuffer-1, x
    sta Reg::zwS0X+1

    jsr parse_modrm
    jsr use_modrm_pointer
    rts
.endproc

.proc decode_s0l_imm8_d0l_modrm_rm8
    ldx Fetch::zbInstrLen
    lda Fetch::zbInstrBuffer-1, x
    sta Reg::zbS0L

    jsr parse_modrm
    jsr use_modrm_pointer
    rts
.endproc

;    imm -> reg
.proc decode_s0x_imm16_d0x_embed_reg16
    lda Fetch::zaInstrOperands+1
    sta Reg::zwS0X+1
    ; [fall_through]
.endproc

.proc decode_s0l_imm8_d0l_embed_reg8
    lda Fetch::zaInstrOperands
    sta Reg::zbS0L

    ; determine the register that the "write" stage needs
    lda Fetch::zbInstrOpcode
    and #Decode::EMBED_REG_MASK
    sta zbReg

    rts
.endproc

;    mem -> acc
;    acc -> mem
.proc decode_s0x_mem16_imm16
    jsr use_prefix_or_ds_segment

    lda Fetch::zaInstrOperands
    ldx Fetch::zaInstrOperands+1
    jsr Mem::use_pointer

    jsr Mem::get_word
    sta Reg::zwS0X
    stx Reg::zwS0X+1
    rts
.endproc

.proc decode_s0l_mem8_imm16
    jsr use_prefix_or_ds_segment

    lda Fetch::zaInstrOperands
    ldx Fetch::zaInstrOperands+1
    jsr Mem::use_pointer

    jsr Mem::get_byte
    sta Reg::zbS0L
    rts
.endproc

.proc decode_s0x_ax_d0x_mem16
    lda Reg::zwAX+1
    sta Reg::zwS0X+1
    ; [fall_through]
.endproc

.proc decode_s0l_al_d0l_mem8
    lda Reg::zbAL
    sta Reg::zbS0L

    jsr use_prefix_or_ds_segment

    lda Fetch::zaInstrOperands
    ldx Fetch::zaInstrOperands+1
    jmp Mem::use_pointer
    ; [tail_jump]
.endproc

;    seg -> rm
;    rm -> seg
.proc decode_s0x_modrm_seg16_d0x_modrm_rm16
    jsr parse_modrm
    jsr get_modrm_seg
    sta Reg::zwS0X
    stx Reg::zwS0X+1
    jmp use_modrm_pointer
.endproc

; changes: A, X, Y
.proc decode_s0x_embed_reg16
    lda Fetch::zbInstrOpcode
    and #Decode::EMBED_REG_MASK
    tay

    ldx Reg::rzbaReg16Map, y
    lda Const::ZERO_PAGE, x
    sta Reg::zwS0X
    lda Const::ZERO_PAGE+1, x
    sta Reg::zwS0X+1
    rts
.endproc

; changes: A, X, Y
.proc decode_s0x_embed_seg16
    lda Fetch::zbInstrOpcode
    and #Decode::EMBED_SEG_MASK
    lsr
    lsr
    lsr
    tay

    ldx Reg::rzbaSegRegMap, y
    lda Const::ZERO_PAGE, x
    sta Reg::zwS0X
    lda Const::ZERO_PAGE+1, x
    sta Reg::zwS0X+1
    rts
.endproc

.proc decode_d0x_modrm_rm
    jsr parse_modrm
    jmp use_modrm_pointer
    ; [tail_jump]
.endproc

; changes: A, X, Y
.proc decode_d0x_embed_reg16
    lda Fetch::zbInstrOpcode
    and #Decode::EMBED_REG_MASK
    sta zbReg
    rts
.endproc

; changes: A, X, Y
.proc decode_d0x_embed_seg16
    lda Fetch::zbInstrOpcode
    and #Decode::EMBED_SEG_MASK
    lsr
    lsr
    lsr
    sta zbSeg
    rts
.endproc


;    reg -> rm
;    rm -> reg
.proc decode_s0x_modrm_reg16_s1x_modrm_rm16
    jsr parse_modrm

    jsr get_modrm_reg16
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    jsr get_modrm_rm16
    sta Reg::zwS1X
    stx Reg::zwS1X+1
    rts
.endproc

.proc decode_s0l_modrm_reg8_s1l_modrm_rm8
    jsr parse_modrm

    jsr get_modrm_reg8
    sta Reg::zbS0L

    jsr get_modrm_rm8
    sta Reg::zbS1L
    rts
.endproc

; changes: A, X, Y
.proc decode_s0x_embed_reg16_s1x_ax
    lda Fetch::zbInstrOpcode
    and #Decode::EMBED_REG_MASK
    sta zbReg
    tay

    ldx Reg::rzbaReg16Map, y
    lda Const::ZERO_PAGE, x
    sta Reg::zwS0X
    lda Const::ZERO_PAGE+1, x
    sta Reg::zwS0X+1

    lda Reg::zwAX
    sta Reg::zwS1X
    lda Reg::zwAX+1
    sta Reg::zwS1X+1
    rts
.endproc


.proc decode_s0x_imm8_s1x_ax
    lda Reg::zwAX+1
    sta Reg::zwS1X+1
    ; [fall_through]
.endproc

.proc decode_s0x_imm8_s1l_al
    lda Reg::zbAL
    sta Reg::zbS1L
    ; [fall_through]
.endproc

.proc decode_s0x_imm8
    lda Fetch::zaInstrOperands
    sta Reg::zwS0X
    ; convert the 8-bit unsigned int to a 16-bit unsigned int
    lda #0
    sta Reg::zwS0X+1
    rts
.endproc


.proc decode_s0x_dx_s1x_ax
    lda Reg::zwAX+1
    sta Reg::zwS1X+1
    ; [fall_through]
.endproc

.proc decode_s0x_dx_s1l_al
    lda Reg::zbAL
    sta Reg::zbS1L
    ; [fall_through]
.endproc

.proc decode_s0x_dx
    lda Reg::zwDX
    sta Reg::zwS0X
    lda Reg::zwDX+1
    sta Reg::zwS0X+1
    rts
.endproc


.proc decode_s0l_mem8_bx_al
    jsr use_prefix_or_ds_segment

    clc

    lda Reg::zwBX
    adc Reg::zbAL
    pha

    lda Reg::zwBX+1
    adc #0
    tax
    pla

    jsr Mem::use_pointer

    jsr Mem::get_byte
    sta Reg::zbS0L
    rts
.endproc


.proc decode_s0x_modrm_m_addr
    jsr parse_modrm
    jsr get_modrm_m
    lda Tmp::zw0
    sta Reg::zwS0X
    lda Tmp::zw0+1
    sta Reg::zwS0X+1
    rts
.endproc


.proc decode_s0x_modrm_m32_lo_s1x_modrm_m32_hi
    jsr parse_modrm

modrm_parsed:

    jsr use_modrm_pointer

    jsr Mem::get_dword_lo
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    jsr Mem::get_dword_hi
    sta Reg::zwS1X
    stx Reg::zwS1X+1
    rts
.endproc

.proc decode_s0x_flags
    lda Reg::zwFlags+1
    sta Reg::zwS0X+1
    ; [fall_through]
.endproc

.proc decode_s0l_flags_lo
    lda Reg::zbFlagsLo
    sta Reg::zbS0L
    rts
.endproc

.proc decode_s0l_ah
    lda Reg::zbAH
    sta Reg::zbS0L
    rts
.endproc


.proc decode_s0x_modrm_rm16_s1x_modrm_reg16
    jsr parse_modrm

    jsr get_modrm_rm16
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    jsr get_modrm_reg16
    sta Reg::zwS1X
    stx Reg::zwS1X+1
    rts
.endproc

.proc decode_s0l_modrm_rm8_s1l_modrm_reg8
    jsr parse_modrm

    jsr get_modrm_rm8
    sta Reg::zbS0L

    jsr get_modrm_reg8
    sta Reg::zbS1L
    rts
.endproc


.proc decode_s0x_ax_s1x_imm16
    lda Reg::zwAX+1
    sta Reg::zwS0X+1

    lda Fetch::zaInstrOperands+1
    sta Reg::zwS1X+1
    ; [fall_through]
.endproc

.proc decode_s0l_al_s1l_imm8
    lda Reg::zbAL
    sta Reg::zbS0L

    lda Fetch::zaInstrOperands
    sta Reg::zbS1L
    rts
.endproc


.proc decode_s0x_embed_reg16_d0x_embed_reg16
    lda Fetch::zbInstrOpcode
    and #Decode::EMBED_REG_MASK
    sta Decode::zbReg
    tay

    ldx Reg::rzbaReg16Map, y
    lda Const::ZERO_PAGE, x
    sta Reg::zwS0X
    lda Const::ZERO_PAGE+1, x
    sta Reg::zwS0X+1
    rts
.endproc

.proc decode_s0x_ax
    lda Reg::zwAX+1
    sta Reg::zwS0X+1
    ; [fall_through]
.endproc

.proc decode_s0l_al
    lda Reg::zbAL
    sta Reg::zbS0L
    rts
.endproc

.proc decode_s0l_al_s1l_ah_s2l_imm8
    lda Reg::zbAL
    sta Reg::zbS0L

    lda Reg::zbAH
    sta Reg::zbS1L

    lda Fetch::zaInstrOperands
    sta Reg::zbS2L
    rts
.endproc

.proc decode_s0x_mem16_si
    jsr use_prefix_or_ds_segment
    jsr Mem::get_si_word
    sta Reg::zwS0X
    stx Reg::zwS0X+1
    rts
.endproc

.proc decode_s0l_mem8_si
    jsr use_prefix_or_ds_segment
    jsr Mem::get_si_byte
    sta Reg::zbS0L
    rts
.endproc


.proc decode_s0x_mem16_si_s1x_mem16_di
    jsr use_prefix_or_ds_segment

    jsr Mem::get_si_word
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    ldx #Reg::zwES
    jsr Mem::use_segment

    jsr Mem::get_di_word
    sta Reg::zwS1X
    stx Reg::zwS1X+1
    rts
.endproc

.proc decode_s0l_mem8_si_s1l_mem8_di
    jsr use_prefix_or_ds_segment

    jsr Mem::get_si_byte
    sta Reg::zbS0L

    ldx #Reg::zwES
    jsr Mem::use_segment

    jsr Mem::get_di_byte
    sta Reg::zbS1L
    rts
.endproc

.proc decode_s0x_ax_s1x_mem16_di
    lda Reg::zwAX
    sta Reg::zwS0X
    lda Reg::zwAX+1
    sta Reg::zwS0X+1

    ldx #Reg::zwES
    jsr Mem::use_segment

    jsr Mem::get_di_word
    sta Reg::zwS1X
    stx Reg::zwS1X+1
    rts
.endproc

.proc decode_s0x_al_s1x_mem8_di
    lda Reg::zbAL
    sta Reg::zbS0L

    ldx #Reg::zwES
    jsr Mem::use_segment

    jsr Mem::get_di_byte
    sta Reg::zwS1X
    stx Reg::zwS1X+1
    rts
.endproc


.proc decode_s0x_imm16_s1x_imm16
    lda Fetch::zaInstrOperands+2
    sta Reg::zwS1X
    lda Fetch::zaInstrOperands+3
    sta Reg::zwS1X+1
    ; [fall_through]
.endproc

.proc decode_s0x_imm16
    lda Fetch::zaInstrOperands+1
    sta Reg::zwS0X+1
    ; [fall_through]
.endproc

.proc decode_s0l_imm8
    lda Fetch::zaInstrOperands
    sta Reg::zbS0L
    rts
.endproc


.proc decode_s0x_ax_d0x_mem16_di
    lda Reg::zwAX+1
    sta Reg::zwS0X+1
    ; [fall_through]
.endproc

.proc decode_s0l_al_d0l_mem8_di
    lda Reg::zbAL
    sta Reg::zbS0L

    ldx #Reg::zwES
    jsr Mem::use_segment
    rts
.endproc

.proc decode_s0x_mem16_si_d0x_mem16_di
    jsr use_prefix_or_ds_segment
    jsr Mem::get_si_word
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    ldx #Reg::zwES
    jsr Mem::use_segment
    rts
.endproc

.proc decode_s0l_mem8_si_d0l_mem8_di
    jsr use_prefix_or_ds_segment
    jsr Mem::get_si_byte
    sta Reg::zbS0L

    ldx #Reg::zwES
    jsr Mem::use_segment
    rts
.endproc


; =============================================================================
; decode extended instructions
; =============================================================================

; ----------------------------------------
; group 1
; ----------------------------------------

.proc decode_s0l_modrm_rm8_s1l_imm8
    jsr parse_modrm

    jsr get_modrm_rm8
    sta Reg::zbS0L

    ldx Fetch::zbInstrLen
    lda Fetch::zbInstrBuffer-1, x
    sta Reg::zbS1L
    rts
.endproc


.proc decode_s0x_modrm_rm16_s1x_imm16
    jsr parse_modrm

    jsr get_modrm_rm16
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    ldx Fetch::zbInstrLen
    lda Fetch::zbInstrBuffer-2, x
    sta Reg::zwS1X
    lda Fetch::zbInstrBuffer-1, x
    sta Reg::zwS1X+1
    rts
.endproc


.proc decode_s0x_modrm_rm16_s1x_imm8
    jsr parse_modrm

    jsr get_modrm_rm16
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    ldx Fetch::zbInstrLen
    lda Fetch::zbInstrBuffer-1, x
    sta Reg::zwS1X
    jsr Util::get_extend_sign
    sta Reg::zwS1X+1
    rts
.endproc

; ----------------------------------------
; group 2
; ----------------------------------------

.proc decode_s0l_modrm_rm8_s1l_1
    jsr parse_modrm

    jsr get_modrm_rm8
    sta Reg::zbS0L

    lda #1
    sta Reg::zbS1L
    rts
.endproc


.proc decode_s0x_modrm_rm16_s1l_1
    jsr parse_modrm

    jsr get_modrm_rm16
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    lda #1
    sta Reg::zbS1L
    rts
.endproc


.proc decode_s0l_modrm_rm8_s1l_cl
    jsr parse_modrm

    jsr get_modrm_rm8
    sta Reg::zbS0L

    lda Reg::zbCL
    sta Reg::zbS1L
    rts
.endproc


.proc decode_s0x_modrm_rm16_s1l_cl
    jsr parse_modrm

    jsr get_modrm_rm16
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    lda Reg::zbCL
    sta Reg::zbS1L
    rts
.endproc

; ----------------------------------------
; group 3
; ----------------------------------------

.proc decode_s0l_modrm_rm8_opt_s1l_imm8
    jsr parse_modrm

    jsr get_modrm_rm8
    sta Reg::zbS0L

    lda zbExt
    bne done ; branch if the instruction is not TEST.

    ldx Fetch::zbInstrLen
    lda Fetch::zbInstrBuffer-1, x
    sta Reg::zbS1L

done:
    rts
.endproc

.proc decode_s0x_modrm_rm16_opt_s1x_imm16
    jsr parse_modrm

    jsr get_modrm_rm16
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    lda zbExt
    bne done ; branch if the instruction is not TEST.

    ldx Fetch::zbInstrLen
    lda Fetch::zbInstrBuffer-2, x
    sta Reg::zwS1X
    lda Fetch::zbInstrBuffer-1, x
    sta Reg::zwS1X+1

done:
    rts
.endproc

; ----------------------------------------
; group 4
; ----------------------------------------

.proc decode_s0l_modrm_rm8
    jsr parse_modrm

    jsr get_modrm_rm8
    sta Reg::zbS0L
    rts
.endproc


.proc decode_s0x_modrm_rm16_or_s0x_modrm_m32_lo_s1x_modrm_m32_hi
    jsr parse_modrm

    ; we need to get a segment and pointer from memory if the extended instruction is...
    ;   CALL DWORD PTR [pointer]    - index 3
    ;   JMP DWORD PTR [pointer]     - index 5
    ; index 7 is illegal.
    lda zbExt
    lsr

    bcc s0x_modrm_rm16 ; branch if the index was even.
    beq s0x_modrm_rm16 ; branch if the index was 1.
    jmp decode_s0x_modrm_m32_lo_s1x_modrm_m32_hi::modrm_parsed

s0x_modrm_rm16:
    jsr get_modrm_rm16
    sta Reg::zwS0X
    stx Reg::zwS0X+1
    rts
.endproc


; called when an unsupported opcode is decoded
.proc decode_bad
    lda #X86::Err::DECODE_FUNC
    jmp X86::panic
    ; [tail_jump]
.endproc

; ==============================================================================
; utility functions
; ==============================================================================

; get the segment for the current instruction.
; if the instruction has a segment prefix then the indicated segment will be used.
; otherwise, the default segment in X will be used.
; < X = default segment register zero-page address.
; > X = segment register zero-page address.
; get the segment in preparation for calling ""
; if the instruction has a segment prefix then the indicated segment will be used.
; otherwise, the default segment in X will be used.
; < X = default segment register zero-page address.
; > Tmp::zb2 = segment register zero-page address.
; changes: A, X, Y

.proc use_prefix_or_ds_segment
    ldx #Reg::zwDS
    lda Fetch::zbPrefixSegment
    beq use_segment ; branch if there is no segment prefix

    ; get segment register index
    and #Decode::PREFIX_SEG_MASK
    lsr
    lsr
    lsr

    ; get segment register address
    tay
    ldx Reg::rzbaSegRegMap, y

use_segment:
    jmp Mem::use_segment
    ; [tail_jump]
.endproc



; extract the Mod, reg, and R/M fields of a ModR/M byte.
; the fetch stage already set zbMod but callers should act as though it didn't.
; that should make any future changes easier to implement.
; > zbMod = ModR/M Mod field (not actually changed)
; > zbReg, zbSeg, zbExt = ModR/M reg field
; > zbRM = ModR/M R/M field
; changes: A, C
.proc parse_modrm
    lda Fetch::zaInstrOperands
    and #Decode::MODRM_RM_MASK
    sta zbRM

    lda Fetch::zaInstrOperands
    and #Decode::MODRM_REG_MASK
    lsr
    lsr
    lsr
    sta zbReg

    lda Fetch::zaInstrOperands
    and #Decode::MODRM_MOD_MASK
    asl
    rol
    rol
    sta zbMod
    rts
.endproc


; calculate a memory address from a ModR/M byte and relevant operands.
; < zbMod
; > Tmp::zw0 = calculated address
; changes: A, X, Y
.proc get_modrm_m
    ldx zbMod
    lda rbaModRMAddrFuncHi, x
    pha
    lda rbaModRMAddrFuncLo, x
    pha
    rts
.endproc


; calculate a memory address from a ModR/M byte in mode 0.
; < zbRM
; > Tmp::zw0 = calculated address
; changes: A, X, Y
.proc get_modrm_m_mode_0
    ldy zbRM
    cpy #Decode::MODRM_RM_DIRECT
    beq get_modrm_m_direct ; branch if we need to handle a direct 16-bit address.
    ; [tail_branch]
.endproc

; calculate a indirect memory address from 1 or more registers
; indicated by the R/M field of a ModR/M byte.
; < Y = zbRM
; > Tmp::zw0 = calculated address
; changes: A, X, Y
; see also:
;   Reg::rzbaMem0Map
;   Reg::rzbaMem1Map
.proc get_modrm_m_indirect
    ; get register address
    ldx Reg::rzbaMem0Map, y

    ; get register value
    lda Const::ZERO_PAGE, x
    sta Tmp::zw0
    lda Const::ZERO_PAGE+1, x
    sta Tmp::zw0+1

    ; check if we need to add the value of another register.
    cpy #Decode::MODRM_RM_MAP
    bcs done

    ; get register address
    ldx Reg::rzbaMem1Map, y

    ; add register value
    clc
    lda Const::ZERO_PAGE, x
    adc Tmp::zw0
    sta Tmp::zw0
    lda Const::ZERO_PAGE+1, x
    adc Tmp::zw0+1
    sta Tmp::zw0+1

done:
    rts
.endproc


; copy a direct memory address operand.
; > Tmp::zw0 = direct memory address
; changes: A
.proc get_modrm_m_direct
    lda Fetch::zaInstrOperands+1
    sta Tmp::zw0
    lda Fetch::zaInstrOperands+2
    sta Tmp::zw0+1
    rts
.endproc


; calculate a memory address from a ModR/M byte in mode 1.
; < zbRM
; > Tmp::zw0 = calculated address
; changes: A, X, Y
.proc get_modrm_m_mode_1
    ldy zbRM
    jsr get_modrm_m_indirect

    ; sign extend the 8-bit offset and store the high byte in X for later.
    lda Fetch::zaInstrOperands+1
    jsr Util::get_extend_sign
    tax

    ; add the offset to the address
    clc
    lda Fetch::zaInstrOperands+1
    adc Tmp::zw0
    sta Tmp::zw0
    txa
    adc Tmp::zw0+1
    sta Tmp::zw0+1
    rts
.endproc


; calculate a memory address from a ModR/M byte in mode 2.
; < zbRM
; > Tmp::zw0 = calculated address
; changes: A, X, Y
.proc get_modrm_m_mode_2
    ldy zbRM
    jsr get_modrm_m_indirect

    ; add the 16-bit unsigned offset to the address
    clc
    lda Fetch::zaInstrOperands+1
    adc Tmp::zw0
    sta Tmp::zw0
    lda Fetch::zaInstrOperands+2
    adc Tmp::zw0+1
    sta Tmp::zw0+1
    rts
.endproc


; set the  to a memory address indicated by a ModR/M byte.
; if the ModR/M byte indicates that a register should be used then nothing is done.
; < X = default segment register zero-page address.
; > Tmp::zw0 = memory address calculated from a ModR/M byte.
; > Tmp::zb2 = segment register zero-page address.
; changes: A, X, Y
.proc use_modrm_pointer
    lda zbMod
    cmp #Decode::MODRM_MOD_REGISTER
    beq done ; branch if R/M value points to a register, not memory

; this is an alternative entry point.
; it assumes that the ModR/M byte doesn't indicate a register access.
skip_reg_check:
    jsr use_prefix_or_ds_segment
    jsr get_modrm_m
    lda Tmp::zw0
    ldx Tmp::zw0+1
    jsr Mem::use_pointer

done:
    rts
.endproc


; get a 16-bit value from a register or memory
; depending on the state of a ModR/M byte.
; < X = default segment register zero-page address.
; < zbMod
; > A = low byte
; > X = high byte
; changes: A, X, Y
.proc get_modrm_rm16
    lda zbMod
    cmp #Decode::MODRM_MOD_REGISTER
    beq get_modrm_r16 ; branch if the value comes from a register, not memory
    ; [fall_through]
.endproc

; get a 16-bit value from memory.
; < X = default segment register zero-page address.
; < zbMod
; > A = low byte
; > X = high byte
; changes: A, X, Y
.proc get_modrm_m16
    jsr use_modrm_pointer::skip_reg_check
    jmp Mem::get_word
    ; [tail_jump]
.endproc


; get a 16-bit value from a register indicated by the R/M field of a ModR/M byte.
; this is also used by "get_modrm_m" as a fail-safe of sorts.
; < zbRM
; > A = low byte
; > X = high byte
; changes: A, X, Y
.proc get_modrm_r16
    ; get register index
    ldx zbRM

    ; get register address
    ldy Reg::rzbaReg16Map, x

    ; get register value
    lda Const::ZERO_PAGE, y
    ldx Const::ZERO_PAGE+1, y
    rts
.endproc


; get a 8-bit value from a register or memory
; depending on the state of a ModR/M byte.
; < X = default segment register zero-page address.
; < zbMod
; > A
; changes: A, X, Y
.proc get_modrm_rm8
    lda zbMod
    cmp #Decode::MODRM_MOD_REGISTER
    beq get_modrm_r8 ; branch if the value comes from a register, not memory
    ; [fall_through]
.endproc

; get a 8-bit value from memory
; < X = default segment register zero-page address.
; < zbMod
; > A
; changes: A, X, Y
.proc get_modrm_m8
    jsr use_modrm_pointer::skip_reg_check
    jmp Mem::get_byte
    ; [tail_jump]
.endproc


; get a 8-bit value from a register indicated by the R/M field of a ModR/M byte.
; < zbRM
; > A
; changes: A, X, Y
.proc get_modrm_r8
    ; get register index
    ldy zbRM

    ; get register address
    ldx Reg::rzbaReg8Map, y

    ; get register value
    lda Const::ZERO_PAGE, x
    rts
.endproc


; get a 16-bit value from a register indicated by the reg field of a ModR/M byte.
; < zbReg
; > A = low byte
; > X = high byte
; changes: A, X, Y
.proc get_modrm_reg16
    ; get register index
    ldx zbReg

    ; get register address
    ldy Reg::rzbaReg16Map, x

    ; get register value
    lda Const::ZERO_PAGE, y
    ldx Const::ZERO_PAGE+1, y
    rts
.endproc


; get a 8-bit value from a register indicated by the reg field of a ModR/M byte.
; < zbReg
; > A
; changes: A, X, Y
.proc get_modrm_reg8
    ; get register index
    ldy zbReg

    ; get register address
    ldx Reg::rzbaReg8Map, y

    ; get register value
    lda Const::ZERO_PAGE, x
    rts
.endproc


; get a 16-bit value from a segment register indicated by the reg field of a ModR/M byte.
; this function can cause some unintended behavior if ModR/M bit 5 is set.
; compilers/assemblers should generate well formed code that don't set bit 5.
; it also shouldn't break the emulator either so i'm not fixing it.
; unintended behavior is fun.
; < zbSeg
; > A = low byte
; > X = high byte
; changes: A, X, Y
.proc get_modrm_seg

    ; get register index
    ldx zbSeg

    ; get register address
    ldy Reg::rzbaSegRegMap, x

    ; get register value
    lda Const::ZERO_PAGE, y
    ldx Const::ZERO_PAGE+1, y
    rts
.endproc


