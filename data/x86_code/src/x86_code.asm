
[BITS 16]

    mov sp, 0x80

    mov ax, 0x1234
    push ax
    pop bx

    mov sp, 0x69

    mov [0x69], ax
    mov cx, [0x69]

    ;jmp short done    ; 8-bit offset
    ;jmp done        ; 16-bit offset
    jmp 0x4433:0x2211 ; absolute address

    call 0x1234        ; 16-bit offset
    call 0x4433:0x2211 ; absolute address

    nop

done:
    hlt
