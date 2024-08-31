
.include "x86/uart.inc"
.include "nmi.inc"
.include "terminal.inc"
.include "tmp.inc"

.export uart

.export get_rbr
.export set_thr

.export get_ier
.export set_ier

.export get_iir
.export set_fcr

.export get_lcr
.export set_lcr

.export set_mcr

.export get_lsr

.export get_msr

.export get_sr
.export set_sr

.segment "ZEROPAGE"

zbInterruptEnable: .res 1
zbInterruptIdentification: .res 1
zbFifoControl: .res 1
zbLineControl: .res 1
zbModemControl: .res 1
zbLineStatus: .res 1
zbModemStatus: .res 1
zbScratch: .res 1

.segment "CODE"

.proc uart
    lda #$00
    sta zbInterruptEnable
    sta zbModemControl

    lda #$c1
    sta zbInterruptIdentification

    lda #$c0
    sta zbFifoControl

    lda #$03
    sta zbLineControl

    ; unknown initial state
    ; leaving at 0
    ; sta zbLineStatus
    ; sta zbModemStatus
    rts
.endproc


; Receiver Buffer Register
.proc get_rbr
    ; lda #$ff ; for testing, act like nothing is connected
    lda #$04 ; for testing, act like nothing is connected
    rts
.endproc


; Transmitter Holding Register
.proc set_thr
    jmp Terminal::put_char
    ; [tail_jump]
.endproc


; Interrupt Enable Register
.proc get_ier
    lda zbInterruptEnable
    rts
.endproc


; Interrupt Enable Register
.proc set_ier
    sta zbInterruptEnable
    rts
.endproc


; Interrupt Identification Register
.proc get_iir
    lda zbInterruptIdentification
    rts
.endproc


; FIFO Control Register
.proc set_fcr
    sta zbFifoControl
    rts
.endproc


; Line Control Register
.proc get_lcr
    lda zbLineControl
    rts
.endproc


; Line Control Register
.proc set_lcr
    sta zbLineControl
    rts
.endproc


; Modem Control Register
.proc set_mcr
    sta zbModemControl
    rts
.endproc


; Line Status Register
.proc get_lsr
    ; TODO: emulate changes to this register
    ; lda zbLineStatus
    rts
.endproc


; Modem Status Register
.proc get_msr
    lda zbModemStatus
    rts
.endproc


; Scratch Register
.proc get_sr
    lda zbScratch
    rts
.endproc


.proc set_sr
    sta zbScratch
    rts
.endproc
