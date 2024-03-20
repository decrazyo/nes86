
[BITS 16]


mov ax, 0x1234
mov [0], ax
mov ax, 0x9876
mov bx, 0
xchg ax, [0]

hlt
