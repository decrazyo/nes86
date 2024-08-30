
.include "keyboard/on_screen.inc"
.include "keyboard.inc"
.include "keyboard/ram.inc"
.include "ppu.inc"
.include "nmi.inc"
.include "tmp.inc"
.include "mmc5.inc"
.include "const.inc"
.include "terminal.inc"
.include "apu.inc"

.export on_screen

.segment "LOWCODE"

rsRow0:
.asciiz "  ` 1 2 3 4 5 6 7 8 9 0 - = bksp"

rsRow1:
.asciiz " tab q w e r t y u i o p [ ] \\"

rsRow2:
.asciiz " caps a s d f g h j k l ; ' entr"

rsRow3:
.asciiz " shift z x c v b n m , . / shift"

rsRow4:
.asciiz " ctrl   alt   space   alt   ctrl"

rsCapsRow1:
.asciiz " tab Q W E R T Y U I O P [ ] \\"

rsCapsRow2:
.asciiz " caps A S D F G H J K L ; ' entr"

rsCapsRow3:
.asciiz " shift Z X C V B N M , . / shift"

rsShiftRow0:
.asciiz "  ~ ! @ # $ % ^ & * ( ) _ + bksp"

rsShiftRow1:
.asciiz " tab Q W E R T Y U I O P { } |"

rsShiftRow2:
.asciiz " caps A S D F G H J K L : \" entr"

rsShiftRow3:
.asciiz " shift Z X C V B N M < > ? shift"

rwaStringPosition:
; normal keyboard
.word $2420, rsRow0
.word $2440, rsRow1
.word $2460, rsRow2
.word $2480, rsRow3
.word $24a0, rsRow4
; keyboard displayed when "caps" is pressed
.word $2520, rsRow0
.word $2540, rsCapsRow1
.word $2560, rsCapsRow2
.word $2580, rsCapsRow3
.word $25a0, rsRow4
; keyboard displayed when "shift" is pressed
.word $2620, rsShiftRow0
.word $2640, rsShiftRow1
.word $2660, rsShiftRow2
.word $2680, rsShiftRow3
.word $26a0, rsRow4
rwaStringPositionEnd:

rbaCursorIndexX:
.byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d
.byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d
.byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0d, $0d
.byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0d, $0d, $0d
.byte $00, $02, $02, $02, $05, $05, $05, $05, $09, $09, $09, $0d, $0d, $0d

rbaCursorPositionX:
.byte $0a, $1a, $2a, $3a, $4a, $5a, $6a, $7a, $8a, $9a, $aa, $ba, $ca, $da
.byte $02, $22, $32, $42, $52, $62, $72, $82, $92, $a2, $b2, $c2, $d2, $e2
.byte $02, $2a, $3a, $4a, $5a, $6a, $7a, $8a, $9a, $aa, $ba, $ca, $00, $da
.byte $02, $32, $42, $52, $62, $72, $82, $92, $a2, $b2, $c2, $00, $00, $d2
.byte $02, $00, $3a, $00, $00, $6a, $00, $00, $00, $aa, $00, $00, $00, $da

rbaCursorPositionY:
.byte $05, $0d, $15, $1d, $25

rbaCursorWidth:
.byte $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $1b
.byte $13, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03
.byte $1b, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $00, $1b
.byte $23, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $00, $00, $23
.byte $1b, $00, $13, $00, $00, $23, $00, $00, $00, $13, $00, $00, $00, $1b

; the high bit is set to identify these as modifier keys.
; "CAPS" and "SHIFT" must remain numbers 1 and 2 respectively
; since they are used as indexes into "rbaKeyboardScrollY".
CAPS_MASK  = %00000001
SHIFT_MASK = %00000010
CTRL_MASK  = %00000100
ALT_MASK   = %00001000
MOD_MASK   = %10000000

CAPS  = MOD_MASK | CAPS_MASK
SHIFT = MOD_MASK | SHIFT_MASK
CTRL  = MOD_MASK | CTRL_MASK
ALT   = MOD_MASK | ALT_MASK

rbCaps:
.byte CAPS_MASK
rbShift:
.byte SHIFT_MASK
rbCtrl:
.byte CTRL_MASK
rbAlt:
.byte ALT_MASK

rbaKeyMap:
.byte "`",   "1",  "2",  "3",  "4",  "5",  "6",  "7",  "8",  "9",  "0",  "-",  "=",  $08
.byte "\t",  "q",  "w",  "e",  "r",  "t",  "y",  "u",  "i",  "o",  "p",  "[",  "]",  "\\"
.byte CAPS,  "a",  "s",  "d",  "f",  "g",  "h",  "j",  "k",  "l",  ";",  "'",  $00,  "\n"
.byte SHIFT, "z",  "x",  "c",  "v",  "b",  "n",  "m",  ",",  ".",  "/",  $00,  $00,  SHIFT
.byte CTRL,  $00,  ALT,  $00,  $00,  " ",  $00,  $00,  $00,  ALT,  $00,  $00,  $00,  CTRL

rbaShiftKeyMap:
.byte "~",   "!",  "@",  "#",  "$",  "%",  "^",  "&",  "*",  "(",  ")",  "_",  "+",  $08
.byte "\t",  "Q",  "W",  "E",  "R",  "T",  "Y",  "U",  "I",  "O",  "P",  "{",  "}",  "|"
.byte CAPS,  "A",  "S",  "D",  "F",  "G",  "H",  "J",  "K",  "L",  ":",  '"',  $00,  "\n"
.byte SHIFT, "Z",  "X",  "C",  "V",  "B",  "N",  "M",  "<",  ">",  "?",  $00,  $00,  SHIFT
.byte CTRL,  $00,  ALT,  $00,  $00,  " ",  $00,  $00,  $00,  ALT,  $00,  $00,  $00,  CTRL

rbaKeyboardScrollY:
.byte $00, $40, $80, $80

; y pos, tile index, attributes, x pos
rbaMaskSprites:
.byte $00, $01, $00, Const::SCREEN_PIXEL_WIDTH - Const::TILE_WIDTH
.byte $08, $01, $00, Const::SCREEN_PIXEL_WIDTH - Const::TILE_WIDTH
.byte $10, $01, $00, Const::SCREEN_PIXEL_WIDTH - Const::TILE_WIDTH
.byte $18, $01, $00, Const::SCREEN_PIXEL_WIDTH - Const::TILE_WIDTH
.byte $20, $01, $00, Const::SCREEN_PIXEL_WIDTH - Const::TILE_WIDTH
.byte $28, $01, $00, Const::SCREEN_PIXEL_WIDTH - Const::TILE_WIDTH
.byte $30, $01, $00, Const::SCREEN_PIXEL_WIDTH - Const::TILE_WIDTH
rbaMaskSpritesEnd:

; we're using magenta to indicate unused colors.
; we only need 1 sprite pallet so we'll make them all the same.
rbaPallets:
.byte Ppu::eColor::BLACK, Ppu::eColor::BLACK, Ppu::eColor::GRAY, Ppu::eColor::MAGENTA
.byte Ppu::eColor::BLACK, Ppu::eColor::BLACK, Ppu::eColor::GRAY, Ppu::eColor::MAGENTA
.byte Ppu::eColor::BLACK, Ppu::eColor::BLACK, Ppu::eColor::GRAY, Ppu::eColor::MAGENTA
.byte Ppu::eColor::BLACK, Ppu::eColor::BLACK, Ppu::eColor::GRAY, Ppu::eColor::MAGENTA
rbaPalletsEnd:

rbToggleKeyboard:
.byte Const::JOYPAD_SELECT
rbMoveCursor:
.byte (Const::JOYPAD_UP | Const::JOYPAD_DOWN | Const::JOYPAD_LEFT | Const::JOYPAD_RIGHT)
rbTypeEnter:
.byte Const::JOYPAD_A
rbTypeCursor:
.byte Const::JOYPAD_B

CURSOR_UPPER_LEFT = Ppu::SPRITE_1
CURSOR_UPPER_RIGHT = Ppu::SPRITE_2
CURSOR_LOWER_LEFT = Ppu::SPRITE_3
CURSOR_LOWER_RIGHT = Ppu::SPRITE_4

; =============================================================================
; public functions
; =============================================================================

; initialize the on-screen keyboard.
; changes: A, X, Y
.proc on_screen
    ; we're going to use sprites so we need to initialize the sprite pallets.
    lda #<Ppu::SPRITE_PALLET_ADDR
    ldx #>Ppu::SPRITE_PALLET_ADDR
    jsr Ppu::initialize_write

    ldy #0
copy_pallets:
    lda rbaPallets, y
    jsr Ppu::write_bytes
    iny
    cpy #<(rbaPalletsEnd - rbaPallets)
    bcc copy_pallets

    jsr Ppu::finalize_write

    ; draw the keyboard(s) to nametable 1
    ldy #0
copy_all_strings:
    lda rwaStringPosition, y
    iny
    ldx rwaStringPosition, y
    iny
    jsr Ppu::initialize_write

    lda rwaStringPosition, y
    iny
    sta Tmp::zw1
    lda rwaStringPosition, y
    iny
    sta Tmp::zw1+1

    sty Tmp::zb1

    ldy #0
    lda (Tmp::zw1), y
copy_string:
    jsr Ppu::write_bytes
    iny
    lda (Tmp::zw1), y
    bne copy_string

    jsr Ppu::finalize_write

    ; we can't draw everything in 1 frame.
    ; we'll just do one line at a time.
    ; this is kind of slow but it doesn't matter.
    jsr Nmi::wait

    ldy Tmp::zb1
    cpy #<(rwaStringPositionEnd - rwaStringPosition)
    bne copy_all_strings

    ; set the initial position of the on-screen keyboard
    ; x offset centers the keyboard.
    lda #4
    sta Ram::OnScreen::zbKeyboardScrollX
    ; y offset 0 selects the normal keyboard graphics.
    lda #0
    sta Ram::OnScreen::zbKeyboardScrollY

    ; use 7 sprites to mask off the right edge of the screen beside the keyboard.
    ; otherwise fragments of the terminal will appear on screen there.
    ; we'll use the last 7 sprites to ensure that other sprites get drawn in front of them.
    ldx #rbaMaskSpritesEnd - rbaMaskSprites - 1
setup_cover_sprites:
    lda rbaMaskSprites, x
    sta Ppu::aOamBuffer + Ppu::SPRITE_57, x
    dex
    bpl setup_cover_sprites

    ; setup the cursor sprites.
    ; the cursor only uses tile 0.
    lda #0
    sta Ppu::aOamBuffer + CURSOR_UPPER_LEFT + Ppu::SPRITE_TILE
    sta Ppu::aOamBuffer + CURSOR_UPPER_RIGHT + Ppu::SPRITE_TILE
    sta Ppu::aOamBuffer + CURSOR_LOWER_LEFT + Ppu::SPRITE_TILE
    sta Ppu::aOamBuffer + CURSOR_LOWER_RIGHT + Ppu::SPRITE_TILE

    ; the sprite attributes never need to change so we'll set them here once.
    ; A = 0
    sta Ppu::aOamBuffer + CURSOR_UPPER_LEFT + Ppu::SPRITE_ATTR
    lda #Ppu::SPRITE_ATTR_H
    sta Ppu::aOamBuffer + CURSOR_UPPER_RIGHT + Ppu::SPRITE_ATTR
    lda #Ppu::SPRITE_ATTR_V
    sta Ppu::aOamBuffer + CURSOR_LOWER_LEFT + Ppu::SPRITE_ATTR
    lda #(Ppu::SPRITE_ATTR_H | Ppu::SPRITE_ATTR_V)
    sta Ppu::aOamBuffer + CURSOR_LOWER_RIGHT + Ppu::SPRITE_ATTR

    ; put the cursor on the spacebar.
    ldx #5
    stx Ram::OnScreen::zbCursorX
    dex
    stx Ram::OnScreen::zbCursorY

    jsr update_cursor

    ; configure a scanline interrupt to occur after displaying the keyboard
    lda #OnScreen::KEYBOARD_HEIGHT - 2
    sta Mmc5::IRQ_COMPARE

    ; enable CPU interrupt handling.
    cli

    ; install our "scan" routine.
    ldx #<scan
    stx Keyboard::zpScanFunc
    ldx #>scan
    stx Keyboard::zpScanFunc+1 ; must be done last
    rts
.endproc


.proc scan
    lda Ram::OnScreen::zbKeyboardEnabled
    beq keyboard_disabled
    ; [tail_branch]
.endproc

; =============================================================================
; private functions
; =============================================================================

.proc keyboard_enabled
    jsr draw_keyboard

    jsr scan_joypad

    bit rbToggleKeyboard
    bne toggle_keyboard

    bit rbMoveCursor
    bne move_cursor

    bit rbTypeEnter
    bne type_enter

    bit rbTypeCursor
    bne type_cursor

    rts
.endproc


.proc keyboard_disabled
    jsr scan_joypad

    bit rbToggleKeyboard
    bne toggle_keyboard

    ; TODO: handle arrow keys with the d-pad
    ;       and home and end with b and a

    rts
.endproc


.proc toggle_keyboard
    lda Ram::OnScreen::zbKeyboardEnabled
    eor #1
    sta Ram::OnScreen::zbKeyboardEnabled
    rts
.endproc


.proc move_cursor
    jsr move_cursor_up_down
    jsr move_cursor_left_right
    jsr update_cursor
    rts
.endproc


.proc type_enter
    jsr Apu::click
    lda #$0a
    jmp Keyboard::put_key
    ; [tail_jump]
.endproc


.proc type_cursor
    jsr Apu::click
    jsr cursor_to_index
    tax
    lda rbaKeyMap, x

    bmi toggle_modifier

    jsr modify_key

    jmp Keyboard::put_key
    ; [tail_jump]
.endproc


.proc toggle_modifier
    ; strip off the highest bit since we don't need it anymore.
    and #%01111111
    ; toggle modifier key bits.
    eor Ram::OnScreen::zbModifierKeys
    sta Ram::OnScreen::zbModifierKeys

    ; determine which keyboard graphics to display based on the state of caps lock and shift.
    and #%00000011
    tay
    lda rbaKeyboardScrollY, y
    sta Ram::OnScreen::zbKeyboardScrollY

    rts
.endproc


; < A = ascii code
; < X = key index
.proc modify_key
    tay
    lda Ram::OnScreen::zbModifierKeys
    bit rbCtrl
    bne ctrl_key

    bit rbShift
    bne shift_key

    bit rbCaps
    bne caps_key

    tya
    rts
.endproc


; < X = key index
; < Y = ascii code
.proc ctrl_key
    ; this is a pretty lazy way to interpret control characters.
    ; good enough.
    jsr caps_key
    sec
    sbc #$40

    cmp #$20
    bcc done
    tya

done:
    tax
    lda #CTRL_MASK
    jsr toggle_modifier
    txa
    rts
.endproc


; < X = key index
.proc shift_key
    lda #SHIFT_MASK
    jsr toggle_modifier

    ; shift is hard to implement arithmetically
    ; so we will just use a table lookup.
    lda rbaShiftKeyMap, x
    rts
.endproc


; < Y = ascii code
.proc caps_key
    tya
    cmp #'z' + 1
    bcs done
    cmp #'a'
    bcc done

    sbc #$20

done:
    rts
.endproc


.proc move_cursor_up_down
    lda Ram::OnScreen::zbJoypadPressed
    and #(Const::JOYPAD_UP | Const::JOYPAD_DOWN)
    beq done
    and #Const::JOYPAD_UP
    bne move_cursor_up
    beq move_cursor_down

done:
    rts
.endproc


.proc move_cursor_left_right
    lda Ram::OnScreen::zbJoypadPressed
    and #(Const::JOYPAD_LEFT | Const::JOYPAD_RIGHT)
    beq done
    and #Const::JOYPAD_LEFT
    bne move_cursor_left
    beq move_cursor_right

done:
    rts
.endproc


.proc move_cursor_up
    ldy Ram::OnScreen::zbCursorY
    dey
    bpl move_cursor_y ; branch if the cursor is still inside the bounds of the keyboard.
    rts
.endproc


.proc move_cursor_down
    ldy Ram::OnScreen::zbCursorY
    iny
    cpy #OnScreen::KEYBOARD_ROWS
    bcc move_cursor_y ; branch if the cursor is still inside the bounds of the keyboard.
    rts
.endproc


.proc move_cursor_left
    ldx Ram::OnScreen::zbCursorX
    beq done ; branch if we are at the left edge of the keyboard

    jsr cursor_to_index
    tay

    ; move left until we reach a valid index for another key
loop:
    dex
    dey
    lda rbaCursorPositionX, y
    beq loop

    stx Ram::OnScreen::zbCursorX

done:
    rts
.endproc


.proc move_cursor_right
    ldx Ram::OnScreen::zbCursorX
    cpx #OnScreen::KEYBOARD_COLS - 1
    beq done ; branch if we are at the right edge of the keyboard

    jsr cursor_to_index
    tay

    ; move right until we reach a valid index for another key
loop:
    inx
    iny
    lda rbaCursorPositionX, y
    beq loop

    stx Ram::OnScreen::zbCursorX

done:
    rts
.endproc


.proc move_cursor_y
    ; store the new cursor y position
    sty Ram::OnScreen::zbCursorY

    jsr cursor_to_index
    tay

    ; determine the cursor x position for the row we moved to.
    ldx rbaCursorIndexX, y
    stx Ram::OnScreen::zbCursorX
    rts
.endproc


.proc draw_keyboard
    ; select nametable 1 which contains the keyboard(s).
    lda Ppu::zbCtrl
    ora #1
    sta Ppu::CTRL

    ; update sprite data.
    ; TODO: only call this when the cursor sprite has actually moved.
    ;       that would save quite a few cycles.
    jsr Ppu::oam_dma

    ; scroll to the appreciate keyboard graphics.
    ; normal keyboard, keyboard with caps lock pressed, or keyboard with shift pressed.
    lda Ram::OnScreen::zbKeyboardScrollX
    sta Ppu::SCROLL
    lda Ram::OnScreen::zbKeyboardScrollY
    sta Ppu::SCROLL

    ; enable scanline interrupt generation in the MMC5.
    lda #Mmc5::IRQ_STATUS_E
    sta Mmc5::IRQ_STATUS

    ; enable sprite rendering to display the cursor.
    lda Ppu::zbMask
    ora #Ppu::MASK_s
    sta Ppu::MASK

    rts
.endproc


.proc scan_joypad
    ; save the previous button state
    lda Ram::OnScreen::zbJoypadNew
    sta Ram::OnScreen::zbJoypadOld

    ; continuously reload the button state into the shift register.
    lda #$01
    sta Const::JOYPAD1
    ; bit 0 will serve as a flag to tell us when we've read a full byte.
    sta Ram::OnScreen::zbJoypadNew

    ; latch the button state in the shift register so that we can read it.
    lsr
    ; A = 0
    sta Const::JOYPAD1

    ; read the controller state one bit at a time
loop:
    lda Const::JOYPAD1
    lsr
    rol Ram::OnScreen::zbJoypadNew
    bcc loop

    ; determine which buttons changed state
    lda Ram::OnScreen::zbJoypadNew
    eor Ram::OnScreen::zbJoypadOld

    ; determine which buttons changed state from released to pressed
    and Ram::OnScreen::zbJoypadNew
    sta Ram::OnScreen::zbJoypadPressed

    rts
.endproc


; multiply the cursor x and y position to get a table offset.
; > A table offset
; changes: A
.proc cursor_to_index
    ; we need to multiply the cursor's y position by the number of keyboard columns (14)
    ; but we can't use the MMC5's multiplier since we are in an interrupt
    ; and that could overwrite data that the emulator was in the middle of multiplying.

    ; first multiply the cursor's y position by 16 via bit shifting.
    lda Ram::OnScreen::zbCursorY
    asl
    asl
    asl
    asl

    ; now subtract the cursor's y position twice, effectively multiplying by 14.
    sec
    sbc Ram::OnScreen::zbCursorY
    sbc Ram::OnScreen::zbCursorY

    ; add the cursor's x position to get the offset we need.
    clc
    adc Ram::OnScreen::zbCursorX
    rts
.endproc


.proc update_cursor
    ; set cursor sprite y position
    ldx Ram::OnScreen::zbCursorY
    ldy rbaCursorPositionY, x
    sty Ppu::aOamBuffer + CURSOR_UPPER_LEFT + Ppu::SPRITE_Y
    sty Ppu::aOamBuffer + CURSOR_UPPER_RIGHT + Ppu::SPRITE_Y
    iny
    iny
    iny
    sty Ppu::aOamBuffer + CURSOR_LOWER_LEFT + Ppu::SPRITE_Y
    sty Ppu::aOamBuffer + CURSOR_LOWER_RIGHT + Ppu::SPRITE_Y

    jsr cursor_to_index
    tax

    ; set cursor sprite x position
    lda rbaCursorPositionX, x
    sta Ppu::aOamBuffer + CURSOR_UPPER_LEFT + Ppu::SPRITE_X
    sta Ppu::aOamBuffer + CURSOR_LOWER_LEFT + Ppu::SPRITE_X
    clc
    adc rbaCursorWidth, x
    sta Ppu::aOamBuffer + CURSOR_UPPER_RIGHT + Ppu::SPRITE_X
    sta Ppu::aOamBuffer + CURSOR_LOWER_RIGHT + Ppu::SPRITE_X

    rts
.endproc
