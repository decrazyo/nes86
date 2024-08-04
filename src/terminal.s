
.include "terminal.inc"
.include "tmp.inc"
.include "const.inc"
.include "ppu.inc"
.include "chr.inc"
.include "nmi.inc"
.include "mmc5.inc"
.include "apu.inc"

.export terminal
.export put_char
.export clear_screen
.export cursor_position

.segment "ZEROPAGE"

; cursor position relative to the screen.
zbCursorX: .res 1
zbCursorY: .res 1

; scroll position of the screen.
zbScrollTileX: .res 1
zbScrollTileY: .res 1

zbEscapeIndex: .res 1

; this should be big enough for escape sequences that we actually want to handle.
zbaEscapeBuffer: .res 4

.segment "LOWCODE"

; TODO: use a sprite to show the cursor location.

; NOTE: this module makes heavy use of my weird NMI/PPU interface.
;       great care must be taken to prevent corruption.
;       functions that move the cursor without writing data, like some ANSI escapes,
;       or write data to a non-cursor location, like line feed,
;       must initialize a new data block in order to terminate the previous one.
;       that is done to ensure that future writes go to the correct location.
;       see also:
;           Ppu::write_initialized
;           Ppu::initialize_write
;           Ppu::write_byte

; TODO: use the MMC5's "attribute and tile index expansion"
;       to set pallet attributes for each individual tile.
;       this could give us limited support for ANSI color escapes.
;       we can't support full color.
;       maybe just light gray text and a dark grey background.


; we're using magenta to indicate unused colors.
rbaPallets:
.byte Ppu::eColor::BLACK, Ppu::eColor::BLACK,     Ppu::eColor::WHITE, Ppu::eColor::MAGENTA
.byte Ppu::eColor::BLACK, Ppu::eColor::BLACK,     Ppu::eColor::GRAY,  Ppu::eColor::MAGENTA
.byte Ppu::eColor::BLACK, Ppu::eColor::DARK_GRAY, Ppu::eColor::WHITE, Ppu::eColor::MAGENTA
.byte Ppu::eColor::BLACK, Ppu::eColor::DARK_GRAY, Ppu::eColor::GRAY,  Ppu::eColor::MAGENTA
rbaPalletsEnd:

; =============================================================================
; public interface
; =============================================================================

; initialize the terminal
.proc terminal
    jsr Terminal::clear_screen

    ; initialize palette data.
    lda #>Ppu::BACKGROUND_PALLET_ADDR
    sta Ppu::ADDR
    lda #<Ppu::BACKGROUND_PALLET_ADDR
    sta Ppu::ADDR

    ldx #0
pallet_loop:
    lda rbaPallets, x
    sta Ppu::DATA
    inx
    cpx #<(rbaPalletsEnd - rbaPallets)
    bcc pallet_loop

    ; clear attribute data.
    lda #<Ppu::ATTRIBUTE_0
    ldx #>Ppu::ATTRIBUTE_0
    jsr Ppu::initialize_write

    jsr Ppu::scroll

    lda #0
    ldy #64
attr_loop:
    jsr Ppu::write_bytes
    dey
    bne attr_loop

    jsr Ppu::finalize_write

    jsr Nmi::wait

    rts
.endproc


; write a character to the terminal.
; the character will either be drawn to the screen
; or buffered until more characters are received.
; < A = character to write
.proc put_char
    ; TODO: check if we are in the middle of handling an escape sequence.

    ; check if this is a control character
    cmp #Chr::SPACE
    bcc control ; branch if control character [$00 - $1f]
    cmp #Chr::DEL
    beq control ; branch if DEL ($7f)
    ; the character is printable [$20 - $7e] or extended ASCII [$80 - $ff]
    ; TODO: add extended ASCII to the tile set.
    ; [fall_through]
.endproc

; =============================================================================
; high level character handlers
; =============================================================================

; write a printable character to the screen.
; move the cursor to the right
; wrap to the next line if needed
; scroll the screen if needed
; < A
.proc print
    jsr use_cursor_address
    jsr Ppu::write_byte
    lda #1
    jsr cursor_right_wrap
    rts
.endproc


; handle control characters
; < A
.proc control
    cmp #Chr::BEL
    beq bell
    cmp #Chr::BS
    beq backspace
    cmp #Chr::HT
    beq tab
    cmp #Chr::LF
    beq line_feed
    cmp #Chr::CR
    beq carage_return
    cmp #Chr::ESC
    beq escape

    ; unhandled character.
    ; maybe we should just print it?
    ; jsr print
    rts
.endproc

; start a new escape sequence
; < A = $1b
.proc escape
    sta zbaEscapeBuffer
    inc zbEscapeIndex
    rts
.endproc

; =============================================================================
; control character handlers
; =============================================================================

.proc bell
    jmp Apu::beep
    ; [tail_jump]
.endproc

.proc backspace
    rts
.endproc

.proc tab
    rts
.endproc

.proc line_feed
    lda #1
    jsr cursor_down_wrap
    rts
.endproc

.proc carage_return
    lda zbCursorY
    ldx #0
    stx zbCursorX
    jsr get_address
    jsr Ppu::initialize_write
    rts
.endproc

; =============================================================================
; escape sequence handlers
; =============================================================================

; control sequence introducer (CSI)
.proc escape_csi
    rts
.endproc

.proc cursor_home
    lda #0
    sta zbCursorX
    ldx #0
    stx zbCursorY
    jsr Ppu::finalize_write
    rts
.endproc


; < A = screen y position
; < X = screen x position
.proc cursor_position
    sta zbCursorY
    stx zbCursorX
    jsr Ppu::finalize_write
    rts
.endproc


.proc cursor_up_stop
    ; subtract from the current cursor x position
    eor #$ff
    clc
    adc #1
    adc zbCursorY

    ; check if we passed the edge of the screen
    bpl store_cursor
    ; set the cursor x position at the edge of the screen
    lda #0
store_cursor:
    sta zbCursorY

    jsr Ppu::finalize_write
    rts
.endproc

.proc cursor_down_stop
    ; add to the current cursor x position
    clc
    adc zbCursorY
    ; check if we passed the edge of the screen
    cmp #Const::SCREEN_TILE_HEIGHT
    bcc store_cursor
    ; set the cursor x position at the edge of the screen
    lda #(Const::SCREEN_TILE_HEIGHT - 1)
store_cursor:
    sta zbCursorY

    jsr Ppu::finalize_write
    rts
.endproc

; move the cursor to the down.
; scroll at the bottom of the screen.
; < A = number of characters to move down.
; changes: A, X
.proc cursor_down_wrap
    clc
    adc zbCursorY
    ldx #0

    ; check if we reached the bottom of the screen
    cmp #Const::SCREEN_TILE_HEIGHT
    bcc store_cursor
    ; subtract 1 screen height from the cursor y position.
    ; this gives use now many lines we need to scroll
    sbc #(Const::SCREEN_TILE_HEIGHT - 1)
    tax

    ; set the cursor y position at the bottom of the screen
    lda #(Const::SCREEN_TILE_HEIGHT - 1)

store_cursor:
    sta zbCursorY

    txa
    bne scroll_down_clear ; branch if we need to scroll the screen.

    jsr Ppu::finalize_write
    rts
.endproc

; move the cursor to the left.
; stop at the edge of the screen.
; < A = number of characters to move left.
; changes: A
.proc cursor_left_stop
    ; subtract from the current cursor x position
    eor #$ff
    clc
    adc #1
    adc zbCursorX

    ; check if we passed the edge of the screen
    bpl store_cursor
    ; set the cursor x position at the edge of the screen
    lda #0
store_cursor:
    sta zbCursorX

    jsr Ppu::finalize_write
    rts
.endproc

; move the cursor to the right.
; stop at the edge of the screen.
; < A = number of characters to move right.
; changes: A
.proc cursor_right_stop
    ; add to the current cursor x position
    clc
    adc zbCursorX
    ; check if we passed the edge of the screen
    cmp #Const::SCREEN_TILE_WIDTH
    bcc store_cursor
    ; set the cursor x position at the edge of the screen
    lda #(Const::SCREEN_TILE_WIDTH - 1)
store_cursor:
    sta zbCursorX

    jsr Ppu::finalize_write
    rts
.endproc

; move the cursor to the right.
; wrap to the next line at the edge of the screen.
; scroll the screen if needed.
; < A = number of characters to move right.
; changes: A, X
.proc cursor_right_wrap
    ; add to the current cursor x position
    clc
    adc zbCursorX
    ; X will count how far we need to move the cursor y position.
    ldx #0

loop:
    ; check if we reached the edge of the screen
    cmp #Const::SCREEN_TILE_WIDTH
    bcc store_cursor
    ; subtract 1 screen width from the cursor x position.
    sbc #Const::SCREEN_TILE_WIDTH
    ; count a cursor y change
    inx
    ; repeat until the cursor x position is within the bounds of the screen.
    jmp loop

store_cursor:
    sta zbCursorX

    txa
    bne cursor_down_wrap ; branch if we need to change the cursor y position

    jsr Ppu::finalize_write
    rts
.endproc


.proc clear_screen
    ; disable sprite and background rendering
    ; lda Ppu::zbMask
    ; and #<~(Ppu::MASK_s | Ppu::MASK_b)
    ; sta Ppu::MASK

    lda #Const::SCREEN_TILE_HEIGHT
    sta Tmp::zb1

    ; TODO: optimize this. we don't need to wait 1 frame for each line we clear.
clear_screen_loop:
    lda Tmp::zb1
    ldx #0
    ldy #Const::SCREEN_TILE_WIDTH

    jsr get_address
    jsr Ppu::initialize_write

clear_line_loop:
    lda #Chr::NUL
    jsr Ppu::write_bytes

    dey
    bne clear_line_loop
    jsr Ppu::finalize_write
    jsr Nmi::wait

    dec Tmp::zb1
    bne clear_screen_loop

    ; restore rendering
    ; lda Ppu::zbMask
    ; sta Ppu::MASK

    rts
.endproc


; scroll the screen down and clear lines as we go.
; < A = number of lines to scroll down.
.proc scroll_down_clear
    ; determine which row is about to be scrolled onto the screen
    clc
    adc zbScrollTileY

    cmp #Const::SCREEN_TILE_HEIGHT
    bcc done
    sbc #Const::SCREEN_TILE_HEIGHT

done:
    sta zbScrollTileY
    asl
    asl
    asl
    sta Ppu::zbScrollPixelY

    jsr clear_line
    jsr Ppu::finalize_write
    rts
.endproc

; =============================================================================
; low level cursor position and PPU functions
; =============================================================================

.proc clear_line
    lda zbCursorY
    ldx #0

    jsr get_address
    jsr Ppu::initialize_write

    lda #Chr::NUL
    ldy #Const::SCREEN_TILE_WIDTH

loop:
    jsr Ppu::write_bytes
    dey
    bne loop

    jsr Ppu::finalize_write

    rts
.endproc


; initialize a new data block at the cursor address if no data block is available.
; if a data block is available then it is assumed to be at the correct address.
; changes: X
.proc use_cursor_address
    jsr Ppu::write_initialized
    bne ready
    ; there is a good change that our caller needs the data in A. don't destroy it.
    pha
    jsr get_cursor_address
    jsr Ppu::initialize_write
    pla
ready:
    rts
.endproc


; calculate the PPU address of the cursor.
; > A = PPU address low byte
; > X = PPU address high byte
; changes: A, X
.proc get_cursor_address
    lda zbCursorY
    ldx zbCursorX
    ; [fall_through]
.endproc

; calculate the PPU address of some screen coordinates.
; < A = screen y position
; < X = screen x position
; > A = PPU address low byte
; > X = PPU address high byte
; changes: A, X
.proc get_address
    ; add the scroll y position to the screen y position.
    ; this gives us the nametable row of the screen y position.
    clc
    ; A = screen y position
    adc zbScrollTileY

    ; multiply that by the number of tiles in each row.
    ; this gives us the nametable offset of the first column of that row.
    sta Mmc5::MULT_LO
    lda #Const::SCREEN_TILE_WIDTH
    sta Mmc5::MULT_HI

    ; add the screen x position.
    ; this gives us the nametable offset of the screen x/y position.
    clc
    txa ; screen x position
    adc Mmc5::MULT_LO
    sta Tmp::zw1

    ; add the nametable base address to get a PPU address.
    ; the nametable base address low byte is 0. no need to add it.
    lda Mmc5::MULT_HI
    adc #>Ppu::NAMETABLE_0
    sta Tmp::zw1+1

    ; Tmp::zw1 now contains a PPU address.
    ; check the high byte of the address to see if the address is valid.
    ; A still contains the high byte.
loop:
    cmp #>Ppu::ATTRIBUTE_0
    bcc done ; branch if the address is inside of nametable 0. (valid)
    bne adjust_address ; branch if the address in outside of nametable 0. (invalid)
    ; the address may or may not be valid.
    ; check the low byte of the address.
    ; NOTE: don't use A here. it will save us a single cycle later.
    ldx Tmp::zw1
    cpx #<Ppu::ATTRIBUTE_0
    bcc done ; branch if the address in inside of nametable 0. (valid)

    ; the address is outside of nametable 0.
    ; adjust the address by subtracting the screen area.
adjust_address:
    sec
    lda Tmp::zw1
    sbc #<Const::SCREEN_TILE_AREA
    sta Tmp::zw1
    lda Tmp::zw1+1
    sbc #>Const::SCREEN_TILE_AREA
    sta Tmp::zw1+1
    ; repeat until the address is inside of nametable 0.
    jmp loop

done:
    ; A already holds the high byte of the address but we want it in X.
    tax
    ; load the low byte.
    lda Tmp::zw1
    rts
.endproc

