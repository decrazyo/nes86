; utility functions that don't neatly fit into other parts of the emulator.

.include "x86/util.inc"

.export get_extend_sign

; extend the sign bit of A by copying bit A.7 to all bits in A.
; < A = byte to sign extend.
; > A = extended sign. $ff or $00.
; changes: A
.proc get_extend_sign
    eor #%10000000 ; invert the sign bit
    asl ; move the sign bit into C
    lda #$ff
    ; if negative add 0.
    ; if positive add 1.
    adc #0
    rts
.endproc
