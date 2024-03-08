
[BITS 16]

    mov dl, 0x55
    mov [0x00], dl

    mov al, 0x44
    add al, [0x00]

    hlt
