
; this module contains the low level initialization code for the NES.
; this puts the NES into a known good state with memory cleared and all interrupts disabled.
; further initialization code is located in main.s and various modules.

.include "apu.inc"
.include "main.inc"
.include "mmc5.inc"
.include "ppu.inc"
.include "reset.inc"

.export reset

.segment "LOWCODE"

; largely standard init code borrowed from nesdev.org
; https://www.nesdev.org/wiki/Init_code
.proc reset
    sei ; ignore IRQs.
    cld ; disable decimal mode.

    ; disable APU frame IRQ.
    ldx #Apu::FRAME_I
    stx Apu::FRAME

    ; set up stack.
    ldx #$ff
    txs

    inx ; now X = 0
    stx Ppu::CTRL ; disable NMI.
    stx Ppu::MASK ; disable rendering.
    stx Apu::DMC_1 ; disable DMC IRQs.

    ; The vblank flag is in an unknown state after reset,
    ; so it is cleared here to make sure that vblank_wait1
    ; does not exit immediately.
    bit Ppu::STATUS

    ; First of two waits for vertical blank to make sure that the
    ; PPU has stabilized
vblank_wait1:
    bit Ppu::STATUS
    bpl vblank_wait1

    ; We now have about 30,000 cycles to burn before the PPU stabilizes.
    ; One thing we can do with this time is put RAM in a known state.
    ; Here we fill it with $00, which matches what (say) a C compiler
    ; expects for BSS.  Conveniently, X is still 0.
    txa
clear_ram:
    sta $000, x
    sta $100, x
    sta $200, x
    sta $300, x
    sta $400, x
    sta $500, x
    sta $600, x
    sta $700, x
    inx
    bne clear_ram

    ; at this point, only code stored in the "LOWCODE" segment is guaranteed to be available.
    ; we'll initialize out mapper chip here so that all code is available going forward.
    jsr Mmc5::mmc5

vblank_wait2:
    bit Ppu::STATUS
    bpl vblank_wait2

    ; call main to handle higher level initialization.
    jmp Main::main
    ; [tail_jump]
.endproc
