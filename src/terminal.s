
; this module is a pretty bare bones terminal emulator.
; it includes limited control character and ANSI escape sequence support.

.include "apu.inc"
.include "chr.inc"
.include "const.inc"
.include "mmc5.inc"
.include "nmi.inc"
.include "ppu.inc"
.include "terminal.inc"
.include "tmp.inc"

.export terminal
.export put_char

; number of spaces to inset for a tab "\t" character.
TAB_SIZE = 8

.segment "ZEROPAGE"

; cursor position relative to the screen.
zbCursorX: .res 1
zbCursorY: .res 1

; scroll position of the screen.
zbScrollTileX: .res 1
zbScrollTileY: .res 1

; indicates if text color for subsequent characters should be inverted.
; this gets set if an ANSI escape sequence changes the foreground or background colors.
; it's as close as we can easily get to supporting those ANSI escape sequence.
zbInvertText: .res 1

; tracks the state of the ANSI escape sequence handler.
zbEscapeState: .res 1

.enum eEscapeState
    NONE ; not currently processing an escape sequence.
    ESC ; escape byte $1b
    CSI ; control sequence introducer byte '['
    PARAM ; CSI parameter byte(s) in the ASCII range ['0', '?']
    INTER ; CSI intermediate byte(s) in the ASCII range [' ', '/']
    FINAL ; CSI final byte in the ASCII range ['@', '~']
.endenum

; escape buffer index
zbEscapeIndex: .res 1

.segment "BSS"

; we've plenty of RAM so we'll just use a whole page to store escape sequences.
; this should be more than enough space for any sequence we're likely to receive.
baEscapeBuffer: .res 256

.segment "RODATA"

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
;       this could give us better support for ANSI color escapes.
;       we could support a few colors and independent control over foreground/background colors.

; we're using magenta to indicate unused colors.
rbaPallets:
.byte Ppu::eColor::BLACK, Ppu::eColor::BLACK,     Ppu::eColor::WHITE, Ppu::eColor::MAGENTA
.byte Ppu::eColor::BLACK, Ppu::eColor::BLACK,     Ppu::eColor::GRAY,  Ppu::eColor::MAGENTA
.byte Ppu::eColor::BLACK, Ppu::eColor::DARK_GRAY, Ppu::eColor::WHITE, Ppu::eColor::MAGENTA
.byte Ppu::eColor::BLACK, Ppu::eColor::DARK_GRAY, Ppu::eColor::GRAY,  Ppu::eColor::MAGENTA
rbaPalletsEnd:

.segment "CODE"

; =============================================================================
; public interface
; =============================================================================

; initialize the terminal.
.proc terminal
    jsr clear_screen

    ; initialize pallet data
    lda #<Ppu::BACKGROUND_PALLET_ADDR
    ldx #>Ppu::BACKGROUND_PALLET_ADDR
    jsr Ppu::initialize_write

    ldy #0
loop:
    lda rbaPallets, y
    jsr Ppu::write_bytes
    iny
    cpy #<(rbaPalletsEnd - rbaPallets)
    bcc loop

    jsr Ppu::finalize_write
    jsr Nmi::wait

    ; clear attribute data.
    lda #<Ppu::ATTRIBUTE_0
    ldx #>Ppu::ATTRIBUTE_0
    jsr Ppu::initialize_write

    lda #Chr::NUL
    ldy #64
attr_loop:
    jsr Ppu::write_bytes
    dey
    bne attr_loop

    jsr Ppu::finalize_write
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; write a character to the terminal.
; the character will either be drawn to the screen
; or buffered until more characters are received.
; ANSI escape sequences will be parsed but only a limited subset have any effect.
; < A = ASCII character to write
.proc put_char
    ; NOTE: this a hack to work around NULL bytes in escape sequences.
    cmp #Chr::NUL
    beq control

    ; check if we are in the middle of handling an escape sequence.
    ldx zbEscapeState
    bne continue_escape

    ; check if this is a control character
    cmp #Chr::SPACE
    bcc control ; branch if control character [$00 - $1f]
    cmp #Chr::DEL
    bcs control ; branch if DEL ($7f) or extended ASCII [$80 - $ff]
    ; the character is printable [$20 - $7e]
    ; [tail_branch]
.endproc

; =============================================================================
; high level character handlers
; =============================================================================

; write a printable character to the screen.
; move the cursor to the right
; wrap to the next line if needed
; scroll the screen if needed
; < A = ASCII character to write
.proc print
    ldx zbInvertText
    beq print_char

    ; use color inverted tiles
    clc
    adc #$80

print_char:
    jsr use_cursor_address
    jsr Ppu::write_byte
    lda #1
    jmp cursor_right_wrap
    ; [tail_jump]
.endproc


; handle control characters
; < A = control character.
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
    rts
.endproc


; =============================================================================
; control character handlers
; =============================================================================

; make a short audible beep
.proc bell
    jmp Apu::beep
    ; [tail_jump]
.endproc


; move the cursor back one space.
; if the cursor is at the left edge of the screen
; then move the cursor to the end of the previous line.
; do nothing if the cursor is at the top left of the screen.
.proc backspace
    ldx zbCursorX
    beq wrap_back
    dex
    lda zbCursorY
    jmp cursor_position

wrap_back:
    ldy zbCursorY
    beq done
    dey
    tya
    ldx #(Const::SCREEN_TILE_WIDTH - 1)
    jmp cursor_position

done:
    rts
.endproc


; print 8 spaces
.proc tab
    lda #TAB_SIZE
    sta Tmp::zb1

loop:
    lda #Chr::SPACE
    jsr print
    dec Tmp::zb1
    bne loop

    rts
.endproc


; move the cursor down to the next line.
; scroll the screen if needed.
.proc line_feed
    lda #1
    jmp cursor_down_wrap
    ; [tail_jump]
.endproc


; move the cursor to the start of the line.
.proc carage_return
    lda zbCursorY
    ldx #0
    stx zbCursorX
    jsr get_address
    jmp Ppu::initialize_write
    ; [tail_jump]
.endproc


; =============================================================================
; escape sequence buffering
; =============================================================================

; start a new escape sequence
; < A = $1b
.proc escape
    ; escape sequences will always start at buffer index 0.
    sta baEscapeBuffer

    ; indicate that we have started an escape sequence.
    ldx #eEscapeState::ESC
    stx zbEscapeState

    .assert eEscapeState::ESC = 1, error, "eEscapeState::ESC must equal 1"

    ; the next byte of the sequence should be placed at index 1.
    stx zbEscapeIndex

    rts
.endproc


; continue processing an escape sequence based on the current escape sequence state.
; < A = escape sequence byte
; < X = escape sequence state
.proc continue_escape
    ldy zbEscapeIndex
    sta baEscapeBuffer, y
    ; the escape buffer is a full page of memory so we don't need to check array bounds.
    ; we'll just let the index wrap around and overwrite the buffer.
    ; this might cause incredibly long escape sequences to be misinterpreted.
    ; that might cause some visual bugs but nothing that would crash the emulator.
    inc zbEscapeIndex

    ; the escape state shouldn't ever be NONE here. don't bother checking.

    cpx #eEscapeState::ESC
    beq continue_escape_esc ; branch if we are at the start of an escape sequence

    cpx #eEscapeState::CSI
    beq continue_escape_csi_param ; branch if we are at the start of a CSI sequence

    cpx #eEscapeState::PARAM
    beq continue_escape_csi_param ; branch if we have received CSI parameters

    cpx #eEscapeState::INTER
    beq continue_escape_csi_inter ; branch if we have received CSI intermediate bytes

    ; we should never get here.
    ; if we do then aborting the escape sequence seems like a good idea.
    ; [tail_branch]
.endproc

; terminate an escape sequence.
.proc end_escape_sequence
    ldx #eEscapeState::NONE
    stx zbEscapeState
    ; no need to change zbEscapeIndex.
    ; that will be reset when we receive a new ESC char.
    rts
.endproc


; processing the byte following an ESC character.
; < A = escape sequence byte
.proc continue_escape_esc
    ; check what type of escape sequence we are receiving.
    ; we're only supporting CSI sequences.
    cmp #'['
    bne end_escape_sequence ; branch if we are not receiving a CSI sequence.

    ldx #eEscapeState::CSI
    stx zbEscapeState

    rts
.endproc


; process CSI parameters.
; if A isn't a parameter byte then call the appropriate handler for the byte.
; < A = escape sequence byte
.proc continue_escape_csi_param
    cmp #'0'
    bcc continue_escape_csi_inter

    cmp #'?' + 1
    bcs continue_escape_final

    ldx #eEscapeState::PARAM
    stx zbEscapeState

    rts
.endproc


; process CSI intermediate bytes.
; if A isn't an intermediate byte then call the appropriate handler for the byte.
; < A = escape sequence byte
.proc continue_escape_csi_inter
    cmp #Chr::SPACE
    bcc end_escape_sequence

    cmp #'/' + 1
    bcs continue_escape_final

    ldx #eEscapeState::INTER
    stx zbEscapeState

    rts
.endproc


; process the final escape sequence byte.
; then perform the action specified by the escape sequence.
; < A = escape sequence byte
.proc continue_escape_final
    cmp #'@'
    bcc end_escape_sequence

    cmp #'~' + 1
    bcs end_escape_sequence

    ; this is the end of the escape sequence.
    jsr end_escape_sequence

    ; check for each function that the terminal supports.
    cmp #'H'
    beq escape_cursor_position

    cmp #'J'
    beq escape_clear_screen

    cmp #'m'
    beq escape_sgr

    rts
.endproc


; =============================================================================
; escape sequence handlers
; =============================================================================

; set the cursor position with an escape sequence.
; example: ^[[10;3H
.proc escape_cursor_position
    ldx #2
    jsr get_escape_arg
    bmi done
    pha

    jsr get_escape_arg
    bmi done

    tax
    pla
    jmp cursor_position

done:
    rts
.endproc


; clear the screen with an escape sequence.
; the cursor is left at the top left of the screen.
; example: ^[[2J
.proc escape_clear_screen
    ldx #2
    jsr get_escape_arg
    bmi done

    ; if A == 0, clear from the cursor to the end of the screen.
    ; if A == 1, clear from cursor the to the beginning of the screen.
    ; if A == 2, clear the entire screen (and move the cursor to the upper left?)
    ; if A == 3, clear the entire screen (and clear the scrollback buffer which we don't have)

    ; only handle clearing the whole screen
    cmp #2
    bcc done ; branch if the argument is 0 or 1
    cmp #4
    bcs done ; branch if the argument is greater than 3
    jsr clear_screen
    jmp cursor_home

done:
    rts
.endproc


; select graphic rendition.
; change the foreground and background colors with an escape sequence.
; the best we can easily do is invert the text color.
; example: ^[[41m
.proc escape_sgr
    ldx #2

get_next_arg:
    jsr get_escape_arg
    bmi done

    ; check if we need to reset attributes
    cmp #0
    beq store_flag

    ; check if we need to set the foreground color
    cmp #30
    bcc check_if_done
    cmp #37 + 1
    bcc store_flag

    ; check if we need to set the background color
    cmp #40
    bcc check_if_done
    cmp #47 + 1
    bcs check_if_done

store_flag:
    sta zbInvertText

check_if_done:
    lda baEscapeBuffer, x
    cmp #'m'
    bne get_next_arg

done:
    rts
.endproc


; =============================================================================
; cursor positioning and screen scrolling
; =============================================================================

; move the cursor to the top left of the screen
.proc cursor_home
    lda #0
    sta zbCursorX
    ldx #0
    stx zbCursorY
    jmp Ppu::finalize_write
    ; [tail_jump]
.endproc


; set the cursor position
; < A = screen y position
; < X = screen x position
.proc cursor_position
    sta zbCursorY
    stx zbCursorX
    jmp Ppu::finalize_write
    ; [tail_jump]
.endproc


; unused/untested
; move the cursor up. stop at the top of the screen.
; < A = number of characters to move up.
; changes: A, X
.proc cursor_up_stop
    ; subtract from the current cursor y position
    eor #$ff
    clc
    adc #1
    adc zbCursorY

    ; check if we passed the edge of the screen
    bpl store_cursor
    ; set the cursor y position at the edge of the screen
    lda #0
store_cursor:
    sta zbCursorY

    jmp Ppu::finalize_write
    ; [tail_jump]
.endproc


; unused/untested
; move the cursor down. stop at the bottom of the screen.
; < A = number of characters to move down.
; changes: A, X
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

    jmp Ppu::finalize_write
    ; [tail_jump]
.endproc


; move the cursor down.
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

    jmp Ppu::finalize_write
    ; [tail_jump]
.endproc


; unused/untested
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

    jmp Ppu::finalize_write
    ; [tail_jump]
.endproc


; unused/untested
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

    jmp Ppu::finalize_write
    ; [tail_jump]
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

    jmp Ppu::finalize_write
    ; [tail_jump]
.endproc


; clear the whole screen. leave the cursor position unchanged.
; changes: A, X
.proc clear_screen
    lda #Const::SCREEN_TILE_HEIGHT
    sta Tmp::zb1

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
    jmp Ppu::finalize_write
    ; [tail_jump]
.endproc


; =============================================================================
; utility functions
; =============================================================================

; parse an escape sequence parameter from baEscapeBuffer.
; < X = index of the next argument in baEscapeBuffer.
; > A = retrieved argument
; > X = index of the following argument in baEscapeBuffer.
; > N = 0 if argument valid
;   N = 1 if argument invalid
; changes: Y
.proc get_escape_arg
    ; Y will count the number of argument bytes we push on the stack.
    ldy #0
    ; temp byte 3 is used as an error flag.
    ; initialize it to indicate no error.
    sty Tmp::zb3
    ; start parsing the argument.
    beq parse_arg ; branch always

    INVALID_ARG = $80

invalid_arg_byte:
    lda #INVALID_ARG
    sta Tmp::zb3

    ; this will parse an entire argument and leave X pointing at the next argument.
parse_arg:
    ; get a byte that may or may not be part of the argument.
    lda baEscapeBuffer, x
    ; increment the buffer index.
    inx

    ; check if the byte is an intermediate byte.
    cmp #'/' + 1
    bcc end_of_last_arg ; branch if the byte is an intermediate byte. i.e. end of arguments.

    ; check if the byte is the final byte.
    cmp #'@'
    bcs end_of_last_arg ; branch if the byte is the final byte of the sequence.

    ; check if we've reached an argument boundary
    cmp #';'
    beq end_of_arg ; branch if we have reached the end of the current argument.

    ; our caller will expect the argument to be in the range [0, 255]
    ; if we have more than 3 digits then we will assume that the value is outside of that range.
    ; this avoids needing to pop a bunch of extra data off the stack later
    ; and it prevents a possible stack overflow caused by very large arguments.
    cpy #3
    beq invalid_arg_byte

    ; if we get a byte that isn't an ASCII digit then we'll flag the argument as invalid.
    ; we only want integer arguments.
    cmp #'9' + 1
    bcs invalid_arg_byte
    cmp #'0'
    bcc invalid_arg_byte

    ; convert the ASCII digit to an integer.
    ; C is necessarily set by the previous "cmp" instruction.
    sbc #'0'
    ; push it onto the stack for later processing.
    pha
    ; count the number of bytes we have pushed.
    iny

    bne parse_arg ; branch always

    ; we've reached the end of the last argument.
end_of_last_arg:
    ; decrement the buffer index.
    ; this enables the caller to call this function again and get the default argument.
    dex

    ; we've reached the end of an argument.
end_of_arg:
    ; check if we have received no argument bytes
    cpy #0
    beq use_default_arg ; branch if there are no argument bytes.

    ; arguments are supplied as ASCII representations of base-10 numbers.
    ; each digit has already been converted from ASCII to a integer.
    ; now we need to combine the digits into a single integer.

    ; get the 1s place digit.
    pla

    dey
    beq done ; branch if there are no more digits

    ; store the 1s place digit for later.
    sta Tmp::zb2

    ; multiply the 10s place digit by 10.
    lda #10
    sta Mmc5::MULT_LO
    pla
    sta Mmc5::MULT_HI

    ; add the 10s place digit to the 1s place digit.
    clc
    lda Mmc5::MULT_LO
    adc Tmp::zb2

    dey
    beq done ; branch if there are no more digits

    ; store the combined 10s and 1s place digits for later.
    sta Tmp::zb2

    ; multiply the 100s digit by 100.
    lda #100
    sta Mmc5::MULT_LO
    pla
    sta Mmc5::MULT_HI

    ; check if the 100s place digit alone is larger than a byte.
    lda Mmc5::MULT_HI
    bne arg_overflows_byte

    ; add the 100s place digit to the 10s and 1s place digits.
    lda Mmc5::MULT_LO
    adc Tmp::zb2
    bcc done ; branch if the result fits in a byte.

arg_overflows_byte:
    lda #INVALID_ARG
    sta Tmp::zb3

use_default_arg:
    lda #0

done:
    ; clear or set N to indicate if the argument is valid or not
    ldy Tmp::zb3
    rts
.endproc


; clear the line that the cursor is on.
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

    jmp Ppu::finalize_write
    ; [tail_jump]
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
