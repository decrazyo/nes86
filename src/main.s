
.include "main.inc"

.include "const.inc"
.include "tmp.inc"
.include "con.inc"
.include "nmi.inc"
.include "x86.inc"

.export main

.segment "CODE"

.proc main
    jsr Con::con
    jsr X86::x86

    jsr X86::debug_x86

main_loop:
    ;jsr wait_input

    jsr X86::step

    jsr X86::debug_x86

    jmp main_loop
.endproc


.proc wait_input
    jsr wait_button_press
    jsr wait_button_release
    rts
.endproc

.proc wait_button_press
    jsr check_input
    bcs wait_button_press ; branch if no input received
    rts
.endproc

.proc wait_button_release
    jsr check_input
    bcc wait_button_release ; branch if input received
    rts
.endproc

; > C = 0 input received
;   C = 1 no input received
.proc check_input
; latch the joypad
    lda #$01
    sta Const::JOYPAD1
    lsr a ; A = 0
    sta Const::JOYPAD1
    ldx #8
loop:
    lda Const::JOYPAD1
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
