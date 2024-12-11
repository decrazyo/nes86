
.ifndef _KEYBOARD_ON_SCREEN_
    _KEYBOARD_ON_SCREEN_ = 1

    .include "const.inc"

    .scope OnScreen

        .import on_screen

        KEYBOARD_ROWS = 5
        KEYBOARD_COLS = 14

        ; account for the 2 blank rows. 1 above the keyboard and 1 below.
        KEYBOARD_HEIGHT = ((KEYBOARD_ROWS + 2) * Const::TILE_HEIGHT)

        ; each joypad button can be mapped to a keyboard key when the on-screen keyboard is hidden.
        ; this is mainly here to make it easier to play "ttytetris" without a keyboard.
        JOYPAD_KEY_A = 'k' ; rotate clockwise
        JOYPAD_KEY_B = 'j' ; rotate counterclockwise
        ; the "select" button is reserved for toggling the on-screen keyboard.
        JOYPAD_KEY_START = 'p' ; pause
        JOYPAD_KEY_UP = ' ' ; hard drop
        JOYPAD_KEY_DOWN = 's' ; soft drop
        JOYPAD_KEY_LEFT = 'h' ; move left
        JOYPAD_KEY_RIGHT = 'l' ; move right
        ; 'q' will quite the game

    .endscope

.endif
