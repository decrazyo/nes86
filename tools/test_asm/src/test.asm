
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
    ; setup the variable for printing the overflow flag
    mov byte [temp+1], 0x0a
    mov byte [temp_len], 2

    ; online documentation of the overflow flag suuuuucks
    ; lets just let the fucking processor tell us how it's supposed to work.

    ; addition tests

    ; no overflow
    mov al, 0x01 ; P
    add al, 0x01 ; P
    call print_of; P

    ; no overflow
    mov al, 0xff ; N
    add al, 0x01 ; P
    call print_of; P

    ; no overflow
    mov al, 0x01 ; P
    add al, 0xff ; N
    call print_of; P

    ; no overflow
    mov al, 0xff ; N
    add al, 0xff ; N
    call print_of; N

    ; overflow!
    mov al, 0x7f ; P
    add al, 0x01 ; P
    call print_of; N

    ; overflow!
    mov al, 0x80 ; N
    add al, 0x80 ; N
    call print_of; P

    ; if the operands have the same sign
    ; and the result has a different sign
    ; then overflow is set

    ; subtract tests

    ; no overflow
    mov al, 0x01 ; P
    sub al, 0x01 ; P
    call print_of; P

    ; no overflow
    mov al, 0xff ; N
    sub al, 0x01 ; P
    call print_of; N

    ; no overflow
    mov al, 0x01 ; P
    sub al, 0xff ; N
    call print_of; P

    ; no overflow
    mov al, 0x00 ; P
    sub al, 0x01 ; P
    call print_of; N

    ; overflow!
    mov al, 0x80 ; N
    sub al, 0x01 ; P
    call print_of; P

    ; overflow!
    mov al, 0x01 ; P
    sub al, 0x80 ; N
    call print_of; N


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