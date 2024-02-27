
.include "x86/mmu.inc"
.include "x86/reg.inc"
.include "x86.inc"

.include "tmp.inc"

.export mmu
.export get_byte

.segment "RODATA"

; TODO: refactor all this shit

; x86 code to execute.
raCode:
.incbin "x86_code.com"
raCodeEnd:

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; initialize the MMU
.proc mmu
    rts
.endproc


; read a byte pointed to by the instruction pointer.
; increment the instruction pointer
; > A = instruction byte
.proc get_byte
    ; save X
    stx Tmp::zb0

    ; TODO: implement this better.
    ;       this is a quick hack to use the low byte of the instruction pointer.
    ;       good enough for basic testing.
    ldx Reg::zdEIP

    ; check that the instruction pointer is still pointing at code.
    cpx #<(raCodeEnd - raCode)
    bcc no_panic
    lda #X86::Err::CODE_END
    jsr X86::panic
no_panic:

    lda raCode, x

    inc Reg::zdEIP
    bne done
    inc Reg::zdEIP+1
done:

    ; restore X
    ldx Tmp::zb0
    rts
.endproc


