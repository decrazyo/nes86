
[BITS 16]

;    mov dl, 0x55
;    mov [0x00], dl
;
;    mov al, 0x44
;    add al, [0x00]

    ;mov dx, cs
    ;mov es, dx

    mov ax, 0x1234
    mov [0], ax
    mov ax, 0x0000
    mov ax, [0]

    hlt
