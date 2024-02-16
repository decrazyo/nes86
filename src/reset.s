
.include "reset.inc"
.include "const.inc"
.include "main.inc"

.export reset

.segment "CODE"

.proc reset
    sei ; ignore IRQs.
    cld ; disable decimal mode.

    ; disable APU frame IRQ.
    ldx #APU_FRAME_I
    stx APU_FRAME

    ; set up stack.
    ldx #$ff
    txs

    inx ; now X = 0
    stx PPU_CTRL ; disable NMI.
    stx PPU_MASK ; disable rendering.
    stx APU_DMC_1 ; disable DMC IRQs.

    ; The vblank flag is in an unknown state after reset,
    ; so it is cleared here to make sure that @vblank_wait1
    ; does not exit immediately.
    bit PPU_STATUS

    ; First of two waits for vertical blank to make sure that the
    ; PPU has stabilized
@vblank_wait1:
    bit PPU_STATUS
    bpl @vblank_wait1

    ; We now have about 30,000 cycles to burn before the PPU stabilizes.
    ; One thing we can do with this time is put RAM in a known state.
    ; Here we fill it with $00, which matches what (say) a C compiler
    ; expects for BSS.  Conveniently, X is still 0.
    txa
@clear_ram:
    sta $000, x
    sta $100, x
    sta $200, x
    sta $300, x
    sta $400, x
    sta $500, x
    sta $600, x
    sta $700, x
    inx
    bne @clear_ram

@vblank_wait2:
    bit PPU_STATUS
    bpl @vblank_wait2

    jmp main
    ; TODO: locate "main" here to avoid the jump
.endproc
