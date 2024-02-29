
.include "x86/decode.inc"
.include "x86/reg.inc"
.include "x86.inc"

.include "tmp.inc"
.include "const.inc"

.export decode

.segment "RODATA"

; instruction encodings
.enum
    ; no operands. nothing to do.
    DE0
    ; 16-bit register embedded in opcode -> S0
    DE1
    ; AL -> S0 ; imm8 -> S1
    DE2 
    ; AX -> S0 ; imm16 -> S1
    DE3 
    ; imm8 -> S0
    DE4
    ; imm16 -> S0
    DE5
    ; ESP -> S0 ; imm8 -> S1
    DE6

    ; TODO: add ModR/M support

    BAD = <-1 ; used for unimplemented or non-existent instructions
.endenum

; map instruction encodings to their decoding functions.
rbaDecodeFuncLo:
.byte <(decode_nop-1)
.byte <(decode_s0_embed_reg16-1)
.byte <(decode_s0_al_s1_imm8-1)
.byte <(decode_s0_ax_s1_imm16-1)
.byte <(decode_s0_imm8-1)
.byte <(decode_s0_imm16-1)
.byte <(decode_s0_esp_s1_imm8-1)
rbaDecodeFuncHi:
.byte >(decode_nop-1)
.byte >(decode_s0_embed_reg16-1)
.byte >(decode_s0_al_s1_imm8-1)
.byte >(decode_s0_ax_s1_imm16-1)
.byte >(decode_s0_imm8-1)
.byte >(decode_s0_imm16-1)
.byte >(decode_s0_esp_s1_imm8-1)

; map opcodes to instruction encodings
rbaInstrDecode:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte BAD,BAD,BAD,BAD,DE2,DE3,BAD,BAD,BAD,BAD,BAD,BAD,DE2,DE3,BAD,BAD ; 0_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 1_
.byte BAD,BAD,BAD,BAD,DE2,DE3,BAD,BAD,BAD,BAD,BAD,BAD,DE2,DE3,BAD,BAD ; 2_
.byte BAD,BAD,BAD,BAD,DE2,DE3,BAD,BAD,BAD,BAD,BAD,BAD,DE2,DE3,BAD,BAD ; 3_
.byte DE1,DE1,DE1,DE1,DE1,DE1,DE1,DE1,DE1,DE1,DE1,DE1,DE1,DE1,DE1,DE1 ; 4_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte DE6,DE6,DE6,DE6,DE6,DE6,DE6,DE6,DE6,DE6,DE6,DE6,DE6,DE6,DE6,DE6 ; 7_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 8_
.byte DE0,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 9_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; A_
.byte DE4,DE4,DE4,DE4,DE4,DE4,DE4,DE4,DE5,DE5,DE5,DE5,DE5,DE5,DE5,DE5 ; B_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; C_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; D_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; E_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; F_

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; determine which registers/memory addresses need to be accessed.
; move data into temporary working memory.
.proc decode
    ldx Reg::zbInstrOpcode
    ldy rbaInstrDecode, x

    ; check for an unsupported encoding.
    cpy #(rbaDecodeFuncHi - rbaDecodeFuncLo)
    bcc func_ok
    lda #X86::Err::DECODE_FUNC
    jsr X86::panic
func_ok:

    lda rbaDecodeFuncHi, y
    pha
    lda rbaDecodeFuncLo, y
    pha
    rts
.endproc

; ==============================================================================
; decode handlers
; ==============================================================================

.proc decode_nop
    rts
.endproc


.proc decode_s0_embed_reg16
    lda Reg::zbInstrOpcode
    and #Reg::REG_MASK
    jmp Reg::reg16_to_src0
.endproc


.proc decode_s0_al_s1_imm8
    lda Reg::zdEAX
    sta Reg::zdS0
    lda Reg::zbInstrOperands
    sta Reg::zdS1
    rts
.endproc


.proc decode_s0_ax_s1_imm16
    jsr decode_s0_al_s1_imm8
    lda Reg::zdEAX+1
    sta Reg::zdS0+1
    lda Reg::zbInstrOperands+1
    sta Reg::zdS1+1
    rts
.endproc


.proc decode_s0_imm8
    lda Reg::zbInstrOperands
    sta Reg::zdS0
    rts
.endproc


.proc decode_s0_imm16
    jsr decode_s0_imm8
    lda Reg::zbInstrOperands+1
    sta Reg::zdS0+1
    rts
.endproc


.proc decode_s0_esp_s1_imm8
    lda Reg::zdEIP
    sta Reg::zdS0
    lda Reg::zdEIP+1
    sta Reg::zdS0+1
    lda Reg::zdEIP+2
    sta Reg::zdS0+2
    lda Reg::zdEIP+3
    sta Reg::zdS0+3

    lda Reg::zbInstrOperands
    sta Reg::zdS1
    lda #0
    sta Reg::zdS1+1
    sta Reg::zdS1+2
    sta Reg::zdS1+3
    rts
.endproc


; ==============================================================================
; register copying functions
; ==============================================================================
