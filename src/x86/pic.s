
.include "x86/pic.inc"

.export pic
.export intr

.segment "ZEROPAGE"

zbIntrFlag: .res 1
zbIntrType: .res 1

.segment "RODATA"

.segment "CODE"

; < A = int type
.proc pic
    sta zbIntrType
    lda #1
    sta zbIntrFlag
    rts
.endproc


; get the interrupt status.
; if an interrupt has occurred then return the interrupt type.
; this will also acknowledge the interrupt.
; > A = interrupt type
; > C = 0 if no interrupt occurred
;   C = 1 if an interrupt occurred
.proc intr
    lda zbIntrFlag
    lsr
    sta zbIntrFlag
    lda zbIntrType
    rts
.endproc
