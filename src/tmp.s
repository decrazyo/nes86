
.include "tmp.inc"

.exportzp zd0
.exportzp zw0
.exportzp zb0
.exportzp zb1
.exportzp zw1
.exportzp zb2
.exportzp zb3

.export set_zp_ptr0
.export set_zp_ptr1
.export set_ptr0
.export set_ptr1

.export memcpy

.segment "TEMP":zp

zd0:
zw0:
zb0: .res 1
zb1: .res 1
zw1:
zb2: .res 1
zb3: .res 1

; some functions may depend on this fact.
.assert zb0 = 0, error, "temporary memory does not start at address 0"

.segment "LOWCODE"

; copy a zero-page pointer into the 0th temp word.
; < A = address low byte
; changes: X
.proc set_zp_ptr0
    ldx #0
    beq set_ptr0 ; branch always
    ; [tail_branch]
.endproc


; copy a zero-page pointer into the 1st temp word.
; < A = address low byte
; changes: X
.proc set_zp_ptr1
    ldx #0
    beq set_ptr1 ; branch always
    ; [tail_branch]
.endproc


; copy a pointer into the 0th temp word.
; < A = address low byte
; < X = address high byte
.proc set_ptr0
    sta zw0
    stx zw0+1
    rts
.endproc


; copy a pointer into the 1st temp word.
; < A = address low byte
; < X = address high byte
.proc set_ptr1
    sta zw1
    stx zw1+1
    rts
.endproc


; copy Y bytes from the 0th temp pointer to the 1st temp pointer.
; < zw0 = source pointer
; < zw1 = destination pointer
; < Y = number of bytes to copy
; changes: A, Y
.proc memcpy
    dey
loop:
    lda (zw0), y
    sta (zw1), y
    dey
    bpl loop
    rts
.endproc


.proc memset
    ; TODO: implement memset
    ;       might be useful for zeroing out registers
.endproc
