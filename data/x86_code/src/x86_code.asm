
[BITS 16]

    mov sp, 0x80

    mov ax, 0x1234
    push ax
    pop bx

    mov cx, 0x5678
    mov [0x80], cx
    pop dx


    hlt
