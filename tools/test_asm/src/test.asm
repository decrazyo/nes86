
; this is just here as a playground to test x86 code.
; sometimes it's easier to just execute an instruction instead of reading docs.

section .data
    hello: db 'Hello world!',10
    hello_len: equ $-hello

section .bss
    temp: resb 2
    temp_len: resb 1

section .text
    GLOBAL _start

_start:
    mov byte [temp+1], 0x0a
    mov byte [temp_len], 2

    ; overflow
    mov al, 0b11111111
    add al, 0b10000000
    call print_of

    ; exit
    mov eax, 1
    mov ebx, 0
    int 80h

print_of:
    mov al, 0x30
    jno no_of
    add al, 1
no_of:
    mov byte [temp], al
    mov eax, 4            ; 'write' system call = 4
    mov ebx, 1            ; file descriptor 1 = STDOUT
    mov ecx, temp         ; string to write
    mov edx, temp_len     ; length of string to write
    int 80h               ; call the kernel
    ret