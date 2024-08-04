
.code16
.arch i8086
.intel_mnemonic
.intel_syntax noprefix

.include "test_mov.h"
.include "test.h"
.include "cpu.h"

.data

mnemonic_mov:
    .asciz "mov"

ops_al_imm8:
    .asciz "al, imm8"

.text

test_mov:
    call test_begin
    call mov_al_imm8
    call mov_ah_imm8

mov_al_imm8:
    call test_case
    call cpu_save_state

    .set ZERO, 0x00
    mov byte ptr cpu_state_al, ZERO
    mov al, ZERO
    call cpu_check_state

    .set MAX_BYTE, 0xff
    mov byte ptr cpu_state_al, MAX_BYTE
    mov al, MAX_BYTE
    call cpu_check_state

    ret


mov_ah_imm8:
    // call test_case
    // call cpu_save_state
    // mov al, 0
    // call cpu_expect_al
    // call cpu_check_state
    ret
