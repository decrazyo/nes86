
.ifndef _KEYBOARD_RAM_
    _KEYBOARD_RAM_ = 1

    .scope Ram

        .scope FamilyBasic
            .importzp zbJoypad1State
            .importzp zbaMatrixState
            .importzp zbaRowState
            .importzp zbaRowKeys
            .importzp zbKeyIndex
        .endscope

        .scope OnScreen
            .importzp zbKeyboardScrollX
            .importzp zbKeyboardScrollY
            .importzp zbKeyboardEnabled

            .importzp zbJoypadNew
            .importzp zbJoypadOld
            .importzp zbJoypadPressed

            .importzp zbCursorX
            .importzp zbCursorY

            .importzp zbModifierKeys
        .endscope

    .endscope

.endif
