
ORG 100h

    inc ax
    inc ax

    inc bx
    inc bx

    add ax, 0x0420
    add al, 0x69

    sub ax, 0x0420
    sub al, 0x69

    mov ax, 0x1234
    mov bx, 0x2345
    mov cx, 0x3456
    mov dx, 0x4567

    mov al, 0x11
    mov bl, 0x22
    mov cl, 0x33
    mov dl, 0x44

    mov ah, 0x55
    mov bh, 0x66
    mov ch, 0x77
    mov dh, 0x88
