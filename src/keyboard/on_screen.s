
; this module manages the on-screen keyboard together with irq.s
; TODO: refactor this module to be more readable/maintainable.

.include "apu.inc"
.include "chr.inc"
.include "const.inc"
.include "keyboard.inc"
.include "keyboard/on_screen.inc"
.include "mmc5.inc"
.include "nmi.inc"
.include "ppu.inc"
.include "tmp.inc"

.export on_screen

.segment "ZEROPAGE"

; cursor position on screen
zbCursorX: .res 1
zbCursorY: .res 1

; screen scroll position for displaying the keyboard
zbKeyboardScrollX: .res 1
zbKeyboardScrollY: .res 1

; joypad button states
zbJoypadOld: .res 1 ; button state on previous frame
zbJoypadNew: .res 1 ; button state on current frame
zbJoypadPressed: .res 1 ; button that changed state from released to pressed.

; holds the state of modifier keys (CAPS, SHIFT, CTRL, ALT)
zbModifierKeys: .res 1

; indicates if the on-screen keyboard is enabled or not.
; if enabled, then the keyboard is visible and key presses are handles.
zbKeyboardEnabled: .res 1

; indicates if sprite data has been updated, necessitating an OAM DMA.
zbDoOamDma: .res 1

.segment "RODATA"

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

MASK_SPRITE_COUTN = (rbaMaskSpritesEnd - rbaMaskSprites - 1) / .sizeof(Ppu::sSprite)

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

rbaJoypadKeys:
.byte OnScreen::JOYPAD_KEY_A
.byte OnScreen::JOYPAD_KEY_B
.byte 0 ; the "select" button is reserved for toggling the on-screen keyboard.
.byte OnScreen::JOYPAD_KEY_START
.byte OnScreen::JOYPAD_KEY_UP
.byte OnScreen::JOYPAD_KEY_DOWN
.byte OnScreen::JOYPAD_KEY_LEFT
.byte OnScreen::JOYPAD_KEY_RIGHT

CURSOR_UPPER_LEFT =  0 * .sizeof(Ppu::sSprite)
CURSOR_UPPER_RIGHT = 1 * .sizeof(Ppu::sSprite)
CURSOR_LOWER_LEFT =  2 * .sizeof(Ppu::sSprite)
CURSOR_LOWER_RIGHT = 3 * .sizeof(Ppu::sSprite)

.segment "CODE"

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
    sta zbKeyboardScrollX
    ; y offset 0 selects the normal keyboard graphics.
    lda #0
    sta zbKeyboardScrollY

    ; use 7 sprites to mask off the right edge of the screen beside the keyboard.
    ; otherwise fragments of the terminal will appear on screen there.
    ; we'll use the last 7 sprites to ensure that other sprites get drawn in front of them.
    ldx #rbaMaskSpritesEnd - rbaMaskSprites - 1
setup_cover_sprites:
    lda rbaMaskSprites, x
    sta Ppu::aOamBuffer + .sizeof(Ppu::sSprite) * (Ppu::SPRITE_COUNT - MASK_SPRITE_COUTN), x
    dex
    bpl setup_cover_sprites

    ; setup the cursor sprites.
    ; the cursor only uses tile 0.
    lda #0
    sta Ppu::aOamBuffer + CURSOR_UPPER_LEFT + Ppu::sSprite::bTile
    sta Ppu::aOamBuffer + CURSOR_UPPER_RIGHT + Ppu::sSprite::bTile
    sta Ppu::aOamBuffer + CURSOR_LOWER_LEFT + Ppu::sSprite::bTile
    sta Ppu::aOamBuffer + CURSOR_LOWER_RIGHT + Ppu::sSprite::bTile

    ; the sprite attributes never need to change so we'll set them here once.
    ; A = 0
    sta Ppu::aOamBuffer + CURSOR_UPPER_LEFT + Ppu::sSprite::bAttr
    lda #Ppu::SPRITE_ATTR_H
    sta Ppu::aOamBuffer + CURSOR_UPPER_RIGHT + Ppu::sSprite::bAttr
    lda #Ppu::SPRITE_ATTR_V
    sta Ppu::aOamBuffer + CURSOR_LOWER_LEFT + Ppu::sSprite::bAttr
    lda #(Ppu::SPRITE_ATTR_H | Ppu::SPRITE_ATTR_V)
    sta Ppu::aOamBuffer + CURSOR_LOWER_RIGHT + Ppu::sSprite::bAttr

    ; sprites have been updated. OAM DMA is needed.
    lda #1
    sta zbDoOamDma

    ; put the cursor on the spacebar.
    ldx #5
    stx zbCursorX
    dex
    stx zbCursorY

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


; scan the keyboard matrix if the keyboard is enabled.
; if the keyboard is disabled then check if the user is trying to enable it.
.proc scan
    lda zbKeyboardEnabled
    beq keyboard_disabled
    ; [tail_branch]
.endproc

; =============================================================================
; private functions
; =============================================================================

; prepare to draw the keyboard on the next frame.
; scan the joypad and check if the user is trying to do something with keyboard like...
; - disabling the keyboard
; - moving the cursor
; - typing a key
; changes: A, X, Y
.proc keyboard_enabled
    ; the keyboard is enabled so it should be drawn next frame.
    jsr draw_keyboard

    ; check for user input.
    jsr scan_joypad

    ; only handle a single pressed button each frame.
    ; this could result in some missed input but the impact should me minimal.

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


; check if the user is trying to enable the keyboard or use joypad keys.
; changes: A
.proc keyboard_disabled
    jsr scan_joypad

    bit rbToggleKeyboard
    bne toggle_keyboard

    ; handle joypad key mapping.
    ; this loop destroys the content of zbJoypadPressed as it's read.
    ldy #8
loop:
    dey
    bmi done
    lsr zbJoypadPressed
    bcc loop
    lda rbaJoypadKeys, y
    jsr Keyboard::put_key
    jmp loop
done:

    rts
.endproc


; toggle the keyboard's state.
; enabled -> disabled
; disabled -> enabled
; changes: A
.proc toggle_keyboard
    lda zbKeyboardEnabled
    eor #1
    sta zbKeyboardEnabled
    rts
.endproc


; move the cursor on the keyboard.
; up, down, left, or right 1 key.
; changes: A, X, Y
.proc move_cursor
    jsr move_cursor_up_down
    jsr move_cursor_left_right
    jmp update_cursor
    ; [tail_jump]
.endproc


; type the enter key.
; this bypasses modifier keys. it probably shouldn't.
; changes: A, X
.proc type_enter
    jsr Apu::boop
    lda #Chr::LF
    jmp Keyboard::put_key
    ; [tail_jump]
.endproc


; type the key at the current cursor position.
; changes: A, X, Y
.proc type_cursor
    jsr Apu::boop

    ; lookup the key under the cursor
    jsr cursor_to_index
    tax
    lda rbaKeyMap, x

    ; check if the key is a modifier key (CAPS, SHIFT, CTRL, ALT).
    ; modifier keys have bit 7 set. normal keys do not.
    bmi toggle_modifier ; branch if this is a modifier key.

    ; apply modifier keys to the key that was typed
    jsr modify_key

    jmp Keyboard::put_key
    ; [tail_jump]
.endproc


; toggle the state of a modifier key (CAPS, SHIFT, CTRL, ALT).
; changes: A, Y
.proc toggle_modifier
    ; strip off the highest bit since we don't want/need it anymore.
    and #<~MOD_MASK
    ; toggle the bit associated with the modifier key we received.
    eor zbModifierKeys
    sta zbModifierKeys

    ; determine which keyboard graphics to display based on the state of caps lock and shift.
    and #%00000011
    tay
    lda rbaKeyboardScrollY, y
    sta zbKeyboardScrollY

    rts
.endproc


; apply modifier keys to the key that was typed
; < A = ascii code
; < X = key index
; > A = modified ascii code
; changes: A, X, Y
.proc modify_key
    ; read the state of the modifier keys
    tay
    lda zbModifierKeys

    ; determine which modifier to apply, if any.
    bit rbCtrl
    bne ctrl_key

    bit rbShift
    bne shift_key

    bit rbCaps
    bne caps_key

    tya
    rts
.endproc


; apply the CTRL key to the key that was typed
; < X = key index
; < Y = ascii code
; changes: A, X, Y
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
    ; toggle the CTRL key off.
    tax
    lda #CTRL_MASK
    jsr toggle_modifier
    txa
    rts
.endproc


; apply the SHIFT key to the key that was typed
; < X = key index
; changes: A, Y
.proc shift_key
    ; toggle the SHIFT key off.
    lda #SHIFT_MASK
    jsr toggle_modifier

    ; shift is hard to implement arithmetically
    ; so we will just use a table lookup.
    lda rbaShiftKeyMap, x
    rts
.endproc


; apply the CAPS key to the key that was typed
; < Y = ascii code
; > A = ascii code
; changes: A
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


; move the cursor up or down 1 row depending on which direction was pressed.
; changes: A, X, Y
.proc move_cursor_up_down
    lda zbJoypadPressed
    and #(Const::JOYPAD_UP | Const::JOYPAD_DOWN)
    beq done
    and #Const::JOYPAD_UP
    bne move_cursor_up
    beq move_cursor_down

done:
    rts
.endproc


; move the cursor left or right 1 key depending on which direction was pressed.
; changes: A, X, Y
.proc move_cursor_left_right
    lda zbJoypadPressed
    and #(Const::JOYPAD_LEFT | Const::JOYPAD_RIGHT)
    beq done
    and #Const::JOYPAD_LEFT
    bne move_cursor_left
    beq move_cursor_right

done:
    rts
.endproc


; move the cursor up 1 row and find the nearest key.
; changes: A, X, Y
.proc move_cursor_up
    ldy zbCursorY
    dey
    bpl move_cursor_y ; branch if the cursor is still inside the bounds of the keyboard.
    rts
.endproc


; move the cursor down 1 row and find the nearest key.
; changes: A, X, Y
.proc move_cursor_down
    ldy zbCursorY
    iny
    cpy #OnScreen::KEYBOARD_ROWS
    bcc move_cursor_y ; branch if the cursor is still inside the bounds of the keyboard.
    rts
.endproc


; move the cursor left 1 key.
; changes: A, X, Y
.proc move_cursor_left
    ldx zbCursorX
    beq done ; branch if we are at the left edge of the keyboard

    jsr cursor_to_index
    tay

    ; move left until we reach a valid index for another key
loop:
    dex
    dey
    lda rbaCursorPositionX, y
    beq loop

    stx zbCursorX

done:
    rts
.endproc


; move the cursor right 1 key.
; changes: A, X, Y
.proc move_cursor_right
    ldx zbCursorX
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

    stx zbCursorX

done:
    rts
.endproc


; move the cursor up or down one row.
; and change the cursor's x position to a valid key
; since keys on different rows are offset from each other.
; changes: A, X, Y
.proc move_cursor_y
    ; store the new cursor y position
    sty zbCursorY

    jsr cursor_to_index
    tay

    ; determine the cursor x position for the row we moved to.
    ldx rbaCursorIndexX, y
    stx zbCursorX
    rts
.endproc


; setup the PPU to display the keyboard.
; enable an interrupt to restore terminal viability after the keyboard is drawn.
; see also: irq.s
; changes: A
.proc draw_keyboard
    ; select nametable 1 which contains the keyboard(s).
    lda Ppu::zbCtrl
    ora #1
    sta Ppu::CTRL

    ; check if sprites have been changed, necessitating an OAM DMA.
    ; avoiding unnecessary OAM DMA saves quite a few cycles.
    lda zbDoOamDma
    beq scroll_screen ; branch if no OAM DMA is needed.

    ; copy sprite data to the PPU.
    jsr Ppu::oam_dma

    ; disable future OAM DMAs until something sprites are updated.
    lda #0
    sta zbDoOamDma

    ; scroll to the appreciate keyboard graphics.
    ; normal keyboard, keyboard with caps lock pressed, or keyboard with shift pressed.
scroll_screen:
    lda zbKeyboardScrollX
    sta Ppu::SCROLL
    lda zbKeyboardScrollY
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


; scan the joypad and determine which buttons are newly pressed this frame.
; < A = newly pressed buttons.
; changes: A
.proc scan_joypad
    ; save the previous button state
    lda zbJoypadNew
    sta zbJoypadOld

    ; continuously reload the button state into the shift register.
    lda #$01
    sta Const::JOYPAD1
    ; bit 0 will serve as a flag to tell us when we've read a full byte.
    sta zbJoypadNew

    ; latch the button state in the shift register so that we can read it.
    lsr
    ; A = 0
    sta Const::JOYPAD1

    ; read the controller state one bit at a time
loop:
    lda Const::JOYPAD1
    lsr
    rol zbJoypadNew
    bcc loop

    ; determine which buttons changed state
    lda zbJoypadNew
    eor zbJoypadOld

    ; determine which buttons changed state from released to pressed
    and zbJoypadNew
    sta zbJoypadPressed

    rts
.endproc


; convert the cursor's x and y position into a table offset.
; > A table offset
; changes: A
.proc cursor_to_index
    ; we need to multiply the cursor's y position by the number of keyboard columns (14)
    ; but we can't use the MMC5's multiplier since we are in an interrupt
    ; and that could overwrite data that the emulator was in the middle of multiplying.

    ; first multiply the cursor's y position by 16 via bit shifting.
    lda zbCursorY
    asl
    asl
    asl
    asl

    ; now subtract the cursor's y position twice, effectively multiplying by 14.
    sec
    sbc zbCursorY
    sbc zbCursorY

    ; add the cursor's x position to get the offset we need.
    clc
    adc zbCursorX
    rts
.endproc


; update the cursor sprites on screen position.
; changes: A, X, Y
.proc update_cursor
    ; set cursor sprite y position
    ldx zbCursorY
    ldy rbaCursorPositionY, x
    sty Ppu::aOamBuffer + CURSOR_UPPER_LEFT + Ppu::sSprite::bPosY
    sty Ppu::aOamBuffer + CURSOR_UPPER_RIGHT + Ppu::sSprite::bPosY
    iny
    iny
    iny
    sty Ppu::aOamBuffer + CURSOR_LOWER_LEFT + Ppu::sSprite::bPosY
    sty Ppu::aOamBuffer + CURSOR_LOWER_RIGHT + Ppu::sSprite::bPosY

    jsr cursor_to_index
    tax

    ; set cursor sprite x position
    lda rbaCursorPositionX, x
    sta Ppu::aOamBuffer + CURSOR_UPPER_LEFT + Ppu::sSprite::bPosX
    sta Ppu::aOamBuffer + CURSOR_LOWER_LEFT + Ppu::sSprite::bPosX
    clc
    adc rbaCursorWidth, x
    sta Ppu::aOamBuffer + CURSOR_UPPER_RIGHT + Ppu::sSprite::bPosX
    sta Ppu::aOamBuffer + CURSOR_LOWER_RIGHT + Ppu::sSprite::bPosX

    ; sprites have been updated. OAM DMA is needed.
    lda #1
    sta zbDoOamDma

    rts
.endproc
