
.include "x86/write.inc"
.include "x86/reg.inc"
.include "x86.inc"

.export write

.segment "RODATA"

; map encodings to their write-back functions.
rbaWriteFuncLo:
.byte <(write_en0-1)
.byte <(write_en1-1)
.byte <(write_en2-1)
.byte <(write_en3-1)
.byte <(write_en0-1)
rbaWriteFuncHi:
.byte >(write_en0-1)
.byte >(write_en1-1)
.byte >(write_en2-1)
.byte >(write_en3-1)
.byte >(write_en0-1)
rbaWriteFuncEnd:


; write data back to memory or registers after execution.
.proc write
    ldx Reg::zbInstrEnc

    ; check for an unsupported encoding.
    cpx #(rbaWriteFuncEnd - rbaWriteFuncHi)
    bcc func_ok
    lda #X86::Err::WRITE_FUNC
    jsr X86::panic
func_ok:

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


.proc write_en1
    lda #Reg::Reg8::AL
    jmp Reg::dst0_to_reg8 ; jsr rts -> jmp
.endproc


.proc write_en2
    lda #Reg::Reg16::AX
    jmp Reg::dst0_to_reg16 ; jsr rts -> jmp
.endproc


.proc write_en3
    lda Reg::zbInstrOpcode
    and #%00000111
    jmp Reg::dst0_to_reg8 ; jsr rts -> jmp
.endproc
