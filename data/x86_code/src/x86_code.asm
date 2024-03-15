
[BITS 16]

    mov sp, 0x80

    mov al, 0x0f
    mov bl, 0x10

    or bx, 1

    hlt
