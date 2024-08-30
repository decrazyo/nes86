
.include "main.inc"

.include "keyboard.inc"
.include "const.inc"
.include "nmi.inc"
.include "tmp.inc"
.include "ppu.inc"
.include "apu.inc"
.include "boot.inc"
.include "terminal.inc"
.include "x86.inc"
.include "x86/pic.inc"
.include "x86/fetch.inc"

.export main

.segment "ZEROPAGE"

zbJoypadNew: .res 1
zbJoypadOld: .res 1
zbJoypadDiff: .res 1
zbJoypadDown: .res 1
zbIntCount: .res 1

zbContinue: .res 1
zbDebug: .res 1
zbStep: .res 1

.segment "LOWCODE"

.proc main
    jsr Apu::apu
    jsr Ppu::ppu

    jsr Boot::boot

; asdf:
;     jmp asdf

    jsr X86::x86

loop:
    jsr X86::step
    jmp loop

main_loop:
    jsr read_joypad

    ; "B" trigger INT 8
    lda zbJoypadDown
    and #Const::JOYPAD_B
    beq @no_int
    lda #$08
    jsr Pic::pic
@no_int:

    ; "select" toggles the debugger output on (default) and off
    lda zbJoypadDown
    and #Const::JOYPAD_SELECT
    eor zbDebug
    sta zbDebug

    ; "start" toggles continuous execution on and off (default)
    lda zbJoypadDown
    and #Const::JOYPAD_START
    eor zbContinue
    sta zbContinue

    bne no_wait

    ; "A" executes a single instruction
    lda zbJoypadDown
    and #Const::JOYPAD_A
    beq main_loop

no_wait:
;     ; break out of the halt state with an interrupt
;     lda Fetch::zbInstrOpcode
;     cmp #$f4 ; HLT
;     bne @no_hlt
;     inc zbIntCount
; @no_hlt:

;     lda zbIntCount
;     beq @no_int
;     dec zbIntCount
;     lda #$08
;     jsr Pic::pic
; @no_int:

    jsr X86::step

    lda zbDebug
    bne no_debug
no_debug:

    jmp main_loop
    ; [tail_jump]
.endproc


; At the same time that we strobe bit 0, we initialize the ring counter
; so we're hitting two birds with one stone here
.proc read_joypad
    ; save the previous button state
    lda zbJoypadNew
    sta zbJoypadOld

    lda #$01
    ; While the strobe bit is set, buttons will be continuously reloaded.
    ; This means that reading from JOYPAD1 will only return the state of the
    ; first button: button A.
    sta Const::JOYPAD1
    sta zbJoypadNew
    lsr a        ; now A is 0
    ; By storing 0 into Const::JOYPAD1, the strobe bit is cleared and the reloading stops.
    ; This allows all 8 buttons (newly reloaded) to be read from Const::JOYPAD1.
    sta Const::JOYPAD1
loop:
    lda Const::JOYPAD1
    lsr a        ; bit 0 -> Carry
    rol zbJoypadNew  ; Carry -> bit 0; bit 7 -> Carry
    bcc loop

    ; determine which buttons changed state
    lda zbJoypadNew
    eor zbJoypadOld
    sta zbJoypadDiff

    ; determine which buttons changed state from released to pressed
    and zbJoypadNew
    sta zbJoypadDown

    rts
.endproc
