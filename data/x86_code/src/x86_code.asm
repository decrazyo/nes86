
[BITS 16]

    mov ax, 0

; count up to 16
loop1:
    inc ax
    cmp ax, 0x10
    jne loop1

; count back down to 0
loop2:
    dec ax
    jnz loop2

; add some random numbers
    mov bx, 10
loop3:
    add ax, 0x420
    add ax, 0x69
    dec bx
    jnz loop3

; random bitwise operations
    and ax, 0x200a
    or ax, 0x8000
    xor ax, 0x1001
