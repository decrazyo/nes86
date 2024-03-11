
[BITS 16]

    mov sp, 0x80
    mov ax, 0x1234
    push ax
    pop bx

    hlt
