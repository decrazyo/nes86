
.ifndef _KEYBOARD_
    _KEYBOARD_ = 1

    .scope Keyboard

        .importzp zpScanFunc

        .import keyboard
        .import scan
        .import get_key
        .import put_key
        .import buffer_status

    .endscope

.endif
