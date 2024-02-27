
.include "nmi.inc"
.include "ppu.inc"

.exportzp zbScrollX
.exportzp zbScrollY

.export nmi
.export wait
.export write_addr
.export write_data
.export write_done

.segment "ZEROPAGE"

zbScrollX: .res 1
zbScrollY: .res 1

zbNmiCount: .res 1
zbBufferEnd: .res 1
zbReadIndex: .res 1
zbWriteIndex: .res 1

.segment "BSS"

aNmiBuffer: .res 256

.segment "CODE"

; NMI handler
.proc nmi
    ; save CPU state
    pha ; save a register
    txa
    pha ; save x register
    tya
    pha ; save y register

    ldx zbReadIndex
    cpx zbBufferEnd
    beq parsing_done

    ; copying data might take longer than vblank.
    ; disable rendering to prevent corrupting PPU memory.
    ; may cause occasional screen flickering. don't care.
    jsr Ppu::disable_rendering

parse_buffer:
    ; set PPU write address.
    lda aNmiBuffer, x
    sta Ppu::ADDR
    inx
    lda aNmiBuffer, x
    sta Ppu::ADDR
    inx

    ; get data length
    ldy aNmiBuffer, x
    inx

    ; check that there is actually data to copy.
    cpy #0
    beq no_data

copy_data:
    lda aNmiBuffer, x
    sta Ppu::DATA
    inx
    dey
    bne copy_data
no_data:
    cpx zbBufferEnd
    bne parse_buffer

parsing_done:
    ; reset buffer index
    lda zbBufferEnd
    sta zbReadIndex

    ; set scroll position
    lda zbScrollX
    sta Ppu::SCROLL
    lda zbScrollY
    sta Ppu::SCROLL

    jsr Ppu::restore_rendering

    inc zbNmiCount ; alert wait that an NMI finished.

    ; restore CPU state
    pla ; restore y register
    tay
    pla ; restore x register
    tax 
    pla ; restore a register

    rti
.endproc

.proc wait
    lda zbNmiCount
loop:
    ; NMI will increment this to break us out of the loop.
    cmp zbNmiCount
    beq loop
    rts
.endproc

; the following write_* functions must be used to write data to the PPU through NMI.
; example:
;     ; write "x86" to the upper left corner of the screen.
;     lda #$20
;     ldx #$00
;     jsr Nmi::write_addr
;     ldy #0
; loop:
;     lda text, y
;     jsr Nmi::write_data
;     iny
;     cpy #5
;     bne loop
;     jsr Nmi::write_done
; text: .byte "Hello"

; buffer an address to write data to.
; < A = high address byte
; < X = low address byte
; changes: A, Y
.proc write_addr
    ; write the address into the buffer
    ldy zbWriteIndex
    sta aNmiBuffer, y
    txa
    iny
    sta aNmiBuffer, y
    iny
    ; write the data length into the buffer
    lda #0
    sta aNmiBuffer, y
    iny
    ; update our write index
    sty zbWriteIndex
    rts
.endproc

; buffer data to write to an already buffered address.
; < A = data byte
; changes: X
.proc write_data
    ; write a byte of data into the buffer
    ldx zbWriteIndex
    sta aNmiBuffer, x
    ; update our write index
    inc zbWriteIndex
    ; increment the data length
    ; this is kind of wasteful but it keeps the buffered data consistent
    ldx zbBufferEnd
    inx
    inx
    inc aNmiBuffer, x
    rts
.endproc

; indicates that all data has been buffer and it can be rendered on the next frame.
; changes: A
.proc write_done
    lda zbWriteIndex
    sta zbBufferEnd
    rts
.endproc
