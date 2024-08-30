
.ifndef _X86_TERMINAL_
    _X86_TERMINAL_ = 1

    .scope Terminal

        .import terminal
        .import put_char
        .import clear_screen
        .import cursor_position

        TAB_SIZE = 8

    .endscope

.endif
