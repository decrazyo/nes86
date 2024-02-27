
.include "x86/write.inc"
.include "x86/reg.inc"
.include "x86.inc"

.export write

.segment "RODATA"

; map encodings to their write-back functions.
rbaWriteFuncLo:
.byte <(write_en0-1)
rbaWriteFuncHi:
.byte >(write_en0-1)
rbaWriteFuncEnd:


; write data back to memory or registers after execution.
.proc write
    ldx Reg::zbInstrEnc

    ; check for an unsupported encoding.
    cpx #(rbaWriteFuncEnd - rbaWriteFuncHi)
    bcc no_panic
    lda #X86::Err::WRITE
    jsr X86::panic
no_panic:

    lda rbaWriteFuncHi, x
    pha
    lda rbaWriteFuncLo, x
    pha
    rts
.endproc

; ==============================================================================
; write back handlers
; ==============================================================================

.proc write_en0
    lda Reg::zbInstrOpcode
    ; isolate the register bits
    and #%00000111
    jmp Reg::dst0_to_reg16 ; jsr rts -> jmp
.endproc
