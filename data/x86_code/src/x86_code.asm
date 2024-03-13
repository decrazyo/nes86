
[BITS 16]

    mov sp, 0x80

    mov ax, 0x1111
    push ax
    push ax
    push ax
    call func
    mov cx, 0x3333
    hlt

func:
    mov bx, 0x2222
    ret 3
