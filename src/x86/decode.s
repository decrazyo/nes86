
.include "x86/decode.inc"
.include "x86/reg.inc"
.include "x86.inc"

.include "tmp.inc"

.export decode

.segment "RODATA"

; map encodings to their decoding functions.
rbaDecodeFuncLo:
.byte <(decode_en0-1)
.byte <(decode_en1-1)
.byte <(decode_en2-1)
.byte <(decode_en3-1)
.byte <(decode_en4-1)
rbaDecodeFuncHi:
.byte >(decode_en0-1)
.byte >(decode_en1-1)
.byte >(decode_en2-1)
.byte >(decode_en3-1)
.byte >(decode_en4-1)
rbaDecodeFuncEnd:

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; determine which registers/memory addresses need to be accessed.
; move data into temporary working memory.
.proc decode
    ldx Reg::zbInstrEnc

    ; check for an unsupported encoding.
    cpx #(rbaDecodeFuncEnd - rbaDecodeFuncHi)
    bcc func_ok
    lda #X86::Err::DECODE_FUNC
    jsr X86::panic
func_ok:

    lda rbaDecodeFuncHi, x
    pha
    lda rbaDecodeFuncLo, x
    pha
    rts
.endproc

; ==============================================================================
; decode handlers
; ==============================================================================

; TODO: generalize some of these functions
; TODO: optimize jsr rts

.proc decode_en0
    lda Reg::zbInstrOpcode
    ; isolate the register bits
    and #%00000111
    jsr Reg::reg16_to_src0
    rts
.endproc


.proc decode_en1
    lda #Reg::Reg8::AL
    jsr Reg::reg8_to_src0
    lda Reg::zbInstrOperands
    sta Reg::zdS1
    rts
.endproc


.proc decode_en2
    lda #Reg::Reg16::AX
    jsr Reg::reg16_to_src0
    lda Reg::zbInstrOperands
    sta Reg::zdS1
    lda Reg::zbInstrOperands+1
    sta Reg::zdS1+1
    rts
.endproc


.proc decode_en3
    lda Reg::zbInstrOperands
    sta Reg::zdD0
    rts
.endproc


.proc decode_en4
    lda Reg::zbInstrOperands
    sta Reg::zdD0
    lda Reg::zbInstrOperands+1
    sta Reg::zdD0+1
    rts
.endproc
