
[BITS 16]

    mov sp, 0x80

    mov ax, 0x1234
    push ax
    pop bx

    mov [0x69], ax
    mov cx, [0x69]

    hlt

    call done ; offset
    call 0x4433:0x2211 ; absolute address

    nop


done:
    hlt
