
[BITS 16]

    mov sp, 0x80
    mov ax, 0x1234
    mov bx, 0x8765
    mov cx, 0x0000
    xchg ax, bx

    hlt
