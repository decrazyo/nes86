
[BITS 16]

    mov sp, 0x80

    mov al, 0x0f
    mov bl, 0x10

    mul byte [0]
    div byte [0]

    hlt
