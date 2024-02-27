
.include "x86/decode.inc"
.include "x86/reg.inc"
.include "x86.inc"

.include "tmp.inc"

.export decode

.segment "RODATA"

; map encodings to their decoding functions.
rbaDecodeFuncLo:
.byte <(decode_en0-1)
rbaDecodeFuncHi:
.byte >(decode_en0-1)
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
    bcc no_panic
    lda #X86::Err::DECODE
    jsr X86::panic
no_panic:

    lda rbaDecodeFuncHi, x
    pha
    lda rbaDecodeFuncLo, x
    pha
    rts
.endproc

; ==============================================================================
; decode handlers
; ==============================================================================

.proc decode_en0
    lda Reg::zbInstrOpcode
    ; isolate the register bits
    and #%00000111
    jsr Reg::reg16_to_src0
    rts
.endproc

