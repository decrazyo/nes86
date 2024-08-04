
.arch i8086
.code16
.intel_mnemonic
.intel_syntax noprefix

.text
    // load ISR handler addresses into the IDT

    // INT 0x03
    mov word ptr [0x03 * 4], offset int_03
    mov word ptr [0x03 * 4 + 2], cs

    // INT 0x10
    mov word ptr [0x10 * 4], offset int_10
    mov word ptr [0x10 * 4 + 2], cs

    // INT 0x12
    mov word ptr [0x12 * 4], offset int_12
    mov word ptr [0x12 * 4 + 2], cs

    // INT 0x16
    mov word ptr [0x16 * 4], offset int_16
    mov word ptr [0x16 * 4 + 2], cs

    // setup code
    call 0xE000:0x0003
    // OS boot
    int 0x19

int_03:
    iret

// serial console
int_10:
    pushf
    cmp ah, 0x03
    je get_cursor
    cmp ah, 0x09
    je teletype
    cmp ah, 0x0e
    je teletype
    cmp ah, 0x0f
    je video_mode
    cmp ah, 0x12
    je ega_config
    cmp ah, 0x1a
    je vga_config

    // crash because we don't know what to do
    .byte 0xff, 0xff
    popf
    iret

get_cursor:
    mov dx, 0
    mov cx, 0
    popf
    iret

// write to a teletype
teletype:
    push dx
    mov dx, 0x3F8
    out dx, al
    pop dx
    popf
    iret

// get video mode
video_mode:
    push ax
    push bx
    mov al, 3 // 3=EGA
    mov ah, 80
    mov bh, 0
    pop bx
    pop ax
    popf
    iret

ega_config:
    mov bh, 1 // mono mode
    mov bl, 0 // 64k EGA
    mov ch, 0 // feature bits
    mov cl, 0 // switch settings
    popf
    iret

vga_config:
    mov al, 0
    popf
    iret

// get ram size
int_12:
    mov ax, 128
    iret

int_16:
    // Read Character from Keyboard
    cmp ah, 0x00
    je keyboard_read
    cmp ah, 0x01
    je keyboard_status
    cmp ah, 0x02
    je keyboard_mod
    cmp ah, 0x03
    je keyboard_typematic

    // unknown request
    iret

// block until a key is pressed
// don't actually block
keyboard_read:
    in al, 0x60 // ascii code
    mov ah, 0 // scan code
    iret

// read a key if one is pressed
keyboard_status:
    // if a key is pressed then return it
    // otherwise, set ZF and return
    // ZF is already set
    iret

// read modifier keys
keyboard_mod:
    mov al, 0
    iret

// ignore this
keyboard_typematic:
    iret

// 8086 reset
.org 0xfff0
    jmp 0xF000:0x0000
