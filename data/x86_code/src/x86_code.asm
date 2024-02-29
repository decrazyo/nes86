
[BITS 16]

ORG 100h

    mov ax, 0x0000

foo:
    add ax, 0x420
    add ax, 0x69
    jnz foo

