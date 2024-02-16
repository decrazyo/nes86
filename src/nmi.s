
.include "nmi.inc"
.include "const.inc"

.exportzp gzbNmiCount
.exportzp gzbPpuScrollX
.exportzp gzbPpuScrolly
.exportzp gzbPpuBufferIndex

.export gaPpuBuffer

.export nmi

.segment "ZEROPAGE"
gzbNmiCount: .res 1 ; incremented every NMI
gzbPpuScrollX: .res 1
gzbPpuScrolly: .res 1
gzbPpuBufferIndex: .res 1

.segment "BSS"
gaPpuBuffer: .res 256

.segment "CODE"
.proc nmi
    ; save CPU state
    pha ; save a register
    txa
    pha ; save x register
    tya
    pha ; save y register

    ldx #0

parse_buffer:
    cpx gzbPpuBufferIndex
    bcs parsing_done ; branch if we have no more data to transfer

    ; set PPU write address.
    lda gaPpuBuffer, x
    sta PPU_ADDR
    inx

    lda gaPpuBuffer, x
    sta PPU_ADDR
    inx

    ; get data length
    ldy gaPpuBuffer, x
    inx

copy_data:
    lda gaPpuBuffer, x
    sta PPU_DATA
    inx
    dey
    bne copy_data
    beq parse_buffer

parsing_done:

    ; reset buffer index
    lda #0
    sta gzbPpuBufferIndex

    ; set scroll position
    lda gzbPpuScrollX
    sta PPU_SCROLL
    lda gzbPpuScrolly
    sta PPU_SCROLL

    inc gzbNmiCount ; alert the main loop that an NMI finished.

    ; restore CPU state
    pla ; restore y register
    tay
    pla ; restore x register
    tax 
    pla ; restore a register

    rti
.endproc
