
.include "main.inc"
.include "const.inc"
.include "tmp.inc"
.include "con.inc"
.include "nmi.inc"
.include "x86.inc"

.export main

.segment "CODE"

.proc main
    jsr con
    jsr x86
    jsr x86_print

main_loop:
    jsr input_wait

    jsr x86_step
    jsr x86_print

    jsr nmi_wait
    jmp main_loop
.endproc


.proc input_wait
    jsr button_press_wait
    jsr button_release_wait
    rts
.endproc

.proc button_press_wait
    jsr check_input
    bcs button_press_wait ; branch if no input received
    rts
.endproc

.proc button_release_wait
    jsr check_input
    bcc button_release_wait ; branch if input received
    rts
.endproc

; > C = 0 input received
;   C = 1 no input received
.proc check_input
; latch the joypad
    lda #$01
    sta JOYPAD1
    lsr a ; A = 0
    sta JOYPAD1
    ldx #8
loop:
    lda JOYPAD1
    ror a
    bcs done
    dex
    bne loop
    sec
    SKIP_BYTE
done:
    clc
    rts
.endproc
