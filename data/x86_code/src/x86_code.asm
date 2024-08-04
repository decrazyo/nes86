
.arch i8086
.code16
.intel_mnemonic
.intel_syntax noprefix



BX_VAL = 0x321
BP_VAL = 0x432
SI_VAL = 0x543
DI_VAL = 0x654
POS8 = 0x76
NEG8 = 0x12
POS16 = 0x9876
CHECK8 = 0xAA
CHECK16 = 0x8321

start:
    nop
    nop
    nop

    mov bx, BX_VAL
    mov bp, BP_VAL
    mov si, SI_VAL
    mov di, DI_VAL
    mov ax, 0x100
    mov es, ax






    // modrm mode 0
    // 1 or more registers
    mov word ptr es:[bx+si], CHECK16
    cmp word ptr es:[BX_VAL+SI_VAL], CHECK16
    call print
    mov word ptr es:[BX_VAL+SI_VAL], 0

    mov word ptr es:[bx+di], CHECK16
    cmp word ptr es:[BX_VAL+DI_VAL], CHECK16
    call print
    mov word ptr word ptr es:[BX_VAL+DI_VAL], 0

    mov word ptr es:[bp+si], CHECK16
    cmp word ptr es:[BP_VAL+SI_VAL], CHECK16
    call print
    mov word ptr word ptr es:[BP_VAL+SI_VAL], 0

    mov word ptr es:[bp+di], CHECK16
    cmp word ptr es:[BP_VAL+DI_VAL], CHECK16
    call print
    mov word ptr word ptr es:[BP_VAL+DI_VAL], 0

    mov word ptr es:[si], CHECK16
    cmp word ptr es:[SI_VAL], CHECK16
    call print
    mov word ptr es:[SI_VAL], 0

    mov word ptr es:[di], CHECK16
    cmp word ptr es:[DI_VAL], CHECK16
    call print
    mov word ptr es:[DI_VAL], 0

    mov word ptr es:[bx], CHECK16
    cmp word ptr es:[BX_VAL], CHECK16
    call print
    mov word ptr es:[BX_VAL], 0


    // modrm mode 1
    // 8-bit signed displacement (positive)
    mov word ptr es:[bx+si+POS8], CHECK16
    cmp word ptr es:[BX_VAL+SI_VAL+POS8], CHECK16
    call print
    mov word ptr es:[BX_VAL+SI_VAL+POS8], 0

    mov word ptr es:[bx+di+POS8], CHECK16
    cmp word ptr es:[BX_VAL+DI_VAL+POS8], CHECK16
    call print
    mov word ptr word ptr es:[BX_VAL+DI_VAL+POS8], 0

    mov word ptr es:[bp+si+POS8], CHECK16
    cmp word ptr es:[BP_VAL+SI_VAL+POS8], CHECK16
    call print
    mov word ptr word ptr es:[BP_VAL+SI_VAL+POS8], 0

    mov word ptr es:[bp+di+POS8], CHECK16
    cmp word ptr es:[BP_VAL+DI_VAL+POS8], CHECK16
    call print
    mov word ptr word ptr es:[BP_VAL+DI_VAL+POS8], 0

    mov word ptr es:[si+POS8], CHECK16
    cmp word ptr es:[SI_VAL+POS8], CHECK16
    call print
    mov word ptr es:[SI_VAL+POS8], 0

    mov word ptr es:[di+POS8], CHECK16
    cmp word ptr es:[DI_VAL+POS8], CHECK16
    call print
    mov word ptr es:[DI_VAL+POS8], 0

    mov word ptr es:[bp+POS8], CHECK16
    cmp word ptr es:[BP_VAL+POS8], CHECK16
    call print
    mov word ptr es:[BP_VAL+POS8], 0

    mov word ptr es:[bx+POS8], CHECK16
    cmp word ptr es:[BX_VAL+POS8], CHECK16
    call print
    mov word ptr es:[BX_VAL+POS8], 0

    // modrm mode 1
    // 8-bit signed displacement (negative)
    mov word ptr es:[bx+si-NEG8], CHECK16
    cmp word ptr es:[BX_VAL+SI_VAL-NEG8], CHECK16
    call print
    mov word ptr es:[BX_VAL+SI_VAL-NEG8], 0

    mov word ptr es:[bx+di-NEG8], CHECK16
    cmp word ptr es:[BX_VAL+DI_VAL-NEG8], CHECK16
    call print
    mov word ptr word ptr es:[BX_VAL+DI_VAL-NEG8], 0

    mov word ptr es:[bp+si-NEG8], CHECK16
    cmp word ptr es:[BP_VAL+SI_VAL-NEG8], CHECK16
    call print
    mov word ptr word ptr es:[BP_VAL+SI_VAL-NEG8], 0

    mov word ptr es:[bp+di-NEG8], CHECK16
    cmp word ptr es:[BP_VAL+DI_VAL-NEG8], CHECK16
    call print
    mov word ptr word ptr es:[BP_VAL+DI_VAL-NEG8], 0

    mov word ptr es:[si-NEG8], CHECK16
    cmp word ptr es:[SI_VAL-NEG8], CHECK16
    call print
    mov word ptr es:[SI_VAL-NEG8], 0

    mov word ptr es:[di-NEG8], CHECK16
    cmp word ptr es:[DI_VAL-NEG8], CHECK16
    call print
    mov word ptr es:[DI_VAL-NEG8], 0

    mov word ptr es:[bp-NEG8], CHECK16
    cmp word ptr es:[BP_VAL-NEG8], CHECK16
    call print
    mov word ptr es:[BP_VAL-NEG8], 0

    mov word ptr es:[bx-NEG8], CHECK16
    cmp word ptr es:[BX_VAL-NEG8], CHECK16
    call print
    mov word ptr es:[BX_VAL-NEG8], 0


    // modrm mode 2
    // 16-bit unsigned displacement

    mov word ptr es:[bx+si+POS16], CHECK16
    cmp word ptr es:[BX_VAL+SI_VAL+POS16], CHECK16
    call print
    mov word ptr es:[BX_VAL+SI_VAL+POS16], 0

    mov word ptr es:[bx+di+POS16], CHECK16
    cmp word ptr es:[BX_VAL+DI_VAL+POS16], CHECK16
    call print
    mov word ptr word ptr es:[BX_VAL+DI_VAL+POS16], 0

    mov word ptr es:[bp+si+POS16], CHECK16
    cmp word ptr es:[BP_VAL+SI_VAL+POS16], CHECK16
    call print
    mov word ptr word ptr es:[BP_VAL+SI_VAL+POS16], 0

    mov word ptr es:[bp+di+POS16], CHECK16
    cmp word ptr es:[BP_VAL+DI_VAL+POS16], CHECK16
    call print
    mov word ptr word ptr es:[BP_VAL+DI_VAL+POS16], 0

    mov word ptr es:[si+POS16], CHECK16
    cmp word ptr es:[SI_VAL+POS16], CHECK16
    call print
    mov word ptr es:[SI_VAL+POS16], 0

    mov word ptr es:[di+POS16], CHECK16
    cmp word ptr es:[DI_VAL+POS16], CHECK16
    call print
    mov word ptr es:[DI_VAL+POS16], 0

    mov word ptr es:[bp+POS16], CHECK16
    cmp word ptr es:[BP_VAL+POS16], CHECK16
    call print
    mov word ptr es:[BP_VAL+POS16], 0

    mov word ptr es:[bx+POS16], CHECK16
    cmp word ptr es:[BX_VAL+POS16], CHECK16
    call print
    mov word ptr es:[BX_VAL+POS16], 0

    // modrm mode 3
    // uses registers and appears to work

    // crash
    .byte 0xff, 0xff
    nop
    nop
    nop

print:
    jz print_zero
    mov al, 0x31
    jnz print_one
print_zero:
    mov al, 0x30
print_one:
    mov ah, 0x0e
    int 0x10
    ret
