
.include "keyboard.inc"

.include "keyboard/family_basic.inc"
.include "keyboard/on_screen.inc"
.include "tmp.inc"
.include "const.inc"

.exportzp zpScanFunc

.export keyboard
.export scan
.export get_key
.export put_key
.export status

.segment "ZEROPAGE"

zbReadIndex: .res 1
zbWriteIndex: .res 1
zpScanFunc: .res 2

.segment "BSS"

baKeyBuffer: .res 256

.segment "LOWCODE"

; detect and initialize a keyboard.
; first try to use a Family BASIC keyboard.
; if that fails then fall back to an on-screen keyboard.
; > C = 1 ; Family BASIC keyboard driver was loaded
;   C = 0 ; on-screen keyboard driver was loaded
; changes: A, X, Y
.proc keyboard
    jsr FamilyBasic::family_basic
    bcs done

    jsr OnScreen::on_screen
    clc

done:
    rts
.endproc


; call the "scan" routine of the currently loaded keyboard driver.
; if no keyboard driver is loaded then return immediately.
; this function is intended to be called from "nmi" during v-blank.
.proc scan
    ; we can assume that the driver's scan function won't be in zero-page.
    ; so if the high byte of the function pointer is 0 then it isn't initialized.
    lda zpScanFunc+1
    beq done ; branch if no scan function is initialized yet
    jmp (zpScanFunc)
done:
    rts
.endproc


; retrieve a key from the key buffer
; > A = ASCII code
; > C = 0 success
;   C = 1 no keys pressed. ignore A.
; changes: A, X
.proc get_key
    lda #0
    ldx zbReadIndex
    cpx zbWriteIndex
    beq done ; branch if the buffer is empty.
    lda baKeyBuffer, x
    inc zbReadIndex
    clc
done:
    rts
.endproc


; put a key into the key buffer.
; < A = ASCII code
; changes: A, X
.proc put_key
    ldx zbWriteIndex
    sta baKeyBuffer, x
    inc zbWriteIndex
    ; TODO: check if the buffer is full.
    ;       if so, decrement the write index.
    rts
.endproc


; check if there is a key available to be read from the key buffer.
; < A = 0 if the key buffer is empty
;   A = 1 if the key buffer is not empty
.proc status
    sec
    lda zbReadIndex
    sbc zbWriteIndex
    beq done
    lda #1
done:
    rts
.endproc
