
[BITS 16]

    mov sp, 0x80
    mov ax, 0xff
    inc ax
    lahf

    hlt
