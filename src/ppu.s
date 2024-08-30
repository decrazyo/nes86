
.include "ppu.inc"

.include "chr.inc"
.include "nmi.inc"
.include "const.inc"

.import __OAM_LOAD__

.exportzp zbMask
.exportzp zbCtrl

.exportzp zbScrollPixelX
.exportzp zbScrollPixelY

.export aOamBuffer

.export ppu

.export transfer_data
.export scroll
.export oam_dma

.export write_initialized
.export initialize_write
.export write_byte
.export write_bytes
.export finalize_write

.segment "ZEROPAGE"

; mirror of Ppu::MASK
zbMask: .res 1

; mirror of Ppu::CTRL
zbCtrl: .res 1

; screen x and y scroll position, relative to the current nametable.
zbScrollPixelX: .res 1
zbScrollPixelY: .res 1

; aPpuBuffer buffer offsets.
zbReadIndex: .res 1
zbBufferSep: .res 1
zbWriteIndex: .res 1

.segment "OAM"

; sprite data
aOamBuffer: .res 256

.segment "BSS"

aPpuBuffer: .res 256

.segment "LOWCODE"

; =============================================================================
; public functions
; =============================================================================

; initialize the PPU
; some of this code might be a little redundant but it should ensure a reliable state.
; this function is intended to be called before "keyboard".
; changes: A, X
.proc ppu
    ; disable background and sprite rendering.
    ; this will let us access the PPU ADDR register without conflicts.
    lda #0
    sta Ppu::MASK

    ; disable NMI generation.
    ; we'll enable it when we're ready.
    sta Ppu::CTRL

    ; zero out nametable and attribute VRAM
    lda #>Ppu::NAMETABLE_0
    sta Ppu::ADDR
    lda #<Ppu::NAMETABLE_0
    sta Ppu::ADDR

    lda #Chr::NUL
    ldx #0

clear_vram:
    sta Ppu::DATA
    sta Ppu::DATA
    sta Ppu::DATA
    sta Ppu::DATA
    sta Ppu::DATA
    sta Ppu::DATA
    sta Ppu::DATA
    sta Ppu::DATA
    dex
    bne clear_vram

    ; move all sprites off screen so they aren't visible if/when sprites are enabled.
    ; we'll do this be setting all sprite y positions to be below the screen.
    lda #<(Const::SCREEN_PIXEL_HEIGHT + Const::TILE_HEIGHT)
    ; X = 0
hide_sprites:
    dex
    dex
    dex
    dex
    sta aOamBuffer, x ; set y position
    bne hide_sprites

    ; configure the PPU with the following settings.
    ;   NMI generation enabled
    ;   PPU in master mode
    ;   sprite mode 0 (8x8 pixel sprites)
    ;   background pattern table 0 (address $0000)
    ;   sprite pattern table 1 (address $1000)
    ;   address increment mode 0 (add 1)
    ;   select nametable 0 (address $2000)
    lda #(Ppu::CTRL_V | Ppu::CTRL_S)
    sta zbCtrl
    sta Ppu::CTRL

    ; wait for NMI to occur.
    ; that will set the scroll position and update sprite data for us.
    jsr Nmi::wait

    ; we should still be in v-blank.
    ; enable rendering with the following settings.
    ;   no color emphasis for red, green, or blue
    ;   sprites disabled
    ;   background enabled
    ;   left column sprites enabled
    ;   left column background enabled
    ;   greyscale disabled
    lda #Ppu::MASK_b | Ppu::MASK_M | Ppu::MASK_m
    sta zbMask
    sta Ppu::MASK

    ; the on-screen keyboard is currently the only thing that uses sprites.
    ; we'll let it decide whether or not sprites should be enabled.

    rts
.endproc


; copy data from our PPU buffer to the PPU itself.
; this function is intended to be called from "nmi" during v-blank.
; changes: A, X, Y
.proc transfer_data
    ; check if we have any buffered data to work with.
    ldx zbReadIndex
    cpx zbBufferSep
    beq done ; branch if the buffer is empty.

    ; X holds the offset of the first data block in the read buffer.

    ; copy all data blocks from the read buffer to the PPU.
copy_loop:
    ; copy one data block to the PPU/
    jsr transfer_block
    ; check if we have reached the end of the read buffer.
    ; if not, then X should already be pointing at another data block.
    cpx zbBufferSep
    bne copy_loop ; branch if we haven't reached the end of the buffer.

    ; set the start offset of the read buffer to the end offset of the read buffer.
    ; this effectively empties the read buffer.
    stx zbReadIndex

    ; check if there is data in the write buffer.
    ldx zbBufferSep
    cpx zbWriteIndex
    beq done ; branch if the write buffer is empty.

    ; read ahead into the write buffer if it contains data.
    ; the functions that write to this buffer guarantee that it is always in a valid state,
    ; making it safe to read at any time.

    ; we only want to do this if there was data in the read buffer.
    ; if the read buffer is empty then we can relay on the write buffer functions
    ; to move the data block into the read buffer when it is ready.

    ; we can assume that there is only 1 data block in the write buffer.
    ; X holds the offset of the data block in the write buffer.
    ; copy the data block from the write buffer to the PPU.
    jsr transfer_block

done:
    rts
.endproc


; scroll the viewable portion of the screen to the x and y offsets,
; given by zbScrollPixelX and zbScrollPixelY, of the currently selected nametable.
; this function is intended to be called from "nmi" during v-blank.
; changes: A
.proc scroll
    lda zbCtrl
    sta Ppu::CTRL
    lda zbScrollPixelX
    sta Ppu::SCROLL
    lda zbScrollPixelY
    sta Ppu::SCROLL
    rts
.endproc


; copy object attribute memory (OAM) to the PPU via DMA.
; this function is intended to be called from "nmi" during v-blank.
; changes: A
.proc oam_dma
    lda #0
    sta Ppu::OAM_ADDR
    lda #>__OAM_LOAD__
    sta Ppu::OAM_DMA
    rts
.endproc


; ----------------------------------------
; data buffer functions
; ----------------------------------------

; these functions, when used properly, allow data to be buffered and sent to the PPU
; without waiting for an NMI to occur nor risking any sort of data or graphical corruption.

; check the state of the write buffer.
; > Z = 0 the write buffer is ready to receive writes.
;   Z = 1 the write buffer needs to be initialized.
; changes: X
.proc write_initialized
    ldx zbBufferSep
    cpx zbWriteIndex
    rts
.endproc


; initialize a new data block in the write buffer for a specific PPU address.
; if a data block already exists in the write buffer then
; it will be moved to the read buffer and no longer be available for writing.
; < A = PPU address low byte
; < X = PPU address high byte
; changes: A, X
.proc initialize_write
    ; pushing parameters onto the stack is a little inefficient
    ; but it comes with a couple benefits.
    ; 1) maintaining the normal A = low byte, X = high byte calling convention.
    ; 2) preserving Y so that the caller can use it for loops and such.
    pha
    txa
    pha
    ldx zbWriteIndex

    ; set the data block length
    lda #0
    sta aPpuBuffer, x
    inx

    ; store the PPU address high byte
    pla
    sta aPpuBuffer, x
    inx

    ; store the PPU address low byte
    pla
    sta aPpuBuffer, x
    inx

    ; now we have a new valid data block in the buffer.
    ; we can safely adjust offsets without risking NMI exploding.

    ; get the offset to the start of our new data black.
    lda zbWriteIndex

    ; move the write offset to the end of the data block.
    stx zbWriteIndex

    ; there may have been an existing data block in the write buffer.
    ; if so, this will move it into the read buffer.
    ; otherwise this has not effect.
    sta zbBufferSep
    rts
.endproc


; append a byte to an existing data block in the write buffer.
; the caller is responsible for ensuring that the write buffer already contains a data block!
; if the read buffer is empty at time of calling
; then the data block will be moved from the write buffer to the read buffer
; and a new data block will need to be initialized before additional writes are accepted.
; < A = byte to add
; > Z = 0 the data block can accept additional writes.
;   Z = 1 the data block can NOT accept additional writes!
;         the caller must initialize a new data block for further writes.
;         see "initialize_write".
; changes: X
.proc write_byte
    ; write a new byte to the data block
    jsr write_bytes

    ; check if the read buffer is empty or not
    ldx zbBufferSep
    cpx zbReadIndex
    bne done ; branch if the read buffer is not empty

    ; the read buffer is empty.
    ; move this data block from the write buffer to the read buffer.
    ; the caller will be responsible for initializing a new data block.
    ldx zbWriteIndex
    stx zbBufferSep
    ldx #0 ; set Z
done:
    rts
.endproc


; append a byte to an existing data block in the write buffer.
; the caller is responsible for ensuring that the write buffer already contains a data block!
; upon return, additional writes to this data block will be accepted.
; either "finalize_write" or "initialize_write" must be called after
; all write to this data block are complete.
; < A = byte to add
; changes: X
.proc write_bytes
    ; write a new byte to the data block
    ldx zbWriteIndex
    sta aPpuBuffer, x

    ; advance the write offset
    inc zbWriteIndex

    ; increment the data block length
    ; this must be done after after writing the data to the buffer
    ; otherwise, a poorly timed NMI could write garbage to the screen.
    ldx zbBufferSep
    inc aPpuBuffer, x

    rts
.endproc


; move the current data block from the write buffer to the read buffer.
; if the write buffer doesn't contain a data block then this has no effect.
; changes: X
.proc finalize_write
    ldx zbWriteIndex
    stx zbBufferSep
    rts
.endproc


; =============================================================================
; private functions
; =============================================================================

; copy a data block from the read buffer to the PPU.
; < X = aPpuBuffer offset to the start of a data block.
; > X = aPpuBuffer offset following the last byte of the data block.
; changes: A, X, Y
.proc transfer_block
    ; load block length
    ldy aPpuBuffer, x
    inx

    ; set the high byte of the PPU address.
    lda aPpuBuffer, x
    sta Ppu::ADDR
    inx

    ; set the low byte of the PPU address.
    lda aPpuBuffer, x
    sta Ppu::ADDR
    inx

    ; allow for a data length of 0.
    cpy #0
    beq done

    ; copy data to the PPU.
copy_data:
    lda aPpuBuffer, x
    sta Ppu::DATA
    inx
    dey
    bne copy_data

done:
    rts
.endproc
