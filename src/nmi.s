
.include "nmi.inc"

.include "ppu.inc"
.include "keyboard.inc"

.export nmi
.export wait

.segment "ZEROPAGE"

zbNmiCount: .res 1

.segment "LOWCODE"

; global NMI handler
.proc nmi
    ; save CPU state
    pha ; save A register
    txa
    pha ; save X register
    tya
    pha ; save Y register

    ; update the PPU
    jsr Ppu::transfer_data
    jsr Ppu::scroll

    ; read the keyboard
    jsr Keyboard::scan

    ; alert "wait" that an NMI finished.
    inc zbNmiCount

    ; restore CPU state
    pla ; restore Y register
    tay
    pla ; restore X register
    tax 
    pla ; restore A register

    rti
.endproc


; wait for an NMI to occur and finish.
; upon return, we may or may not still be in v-blank.
; changes: A
.proc wait
    lda zbNmiCount
loop:
    ; NMI will increment this to break us out of the loop.
    cmp zbNmiCount
    beq loop
    rts
.endproc
