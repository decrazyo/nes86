
.code16
.arch i8086
.intel_mnemonic
.intel_syntax noprefix

.include "cpu.h"

.bss
    cpu_state_ax:
    .lcomm cpu_state_al, 1
    .lcomm cpu_state_ah, 1
    cpu_state_bx:
    .lcomm cpu_state_bl, 1
    .lcomm cpu_state_bh, 1
    cpu_state_cx:
    .lcomm cpu_state_cl, 1
    .lcomm cpu_state_ch, 1
    cpu_state_dx:
    .lcomm cpu_state_dl, 1
    .lcomm cpu_state_dh, 1

    .lcomm cpu_state_si, 1
    .lcomm cpu_state_di, 1
    .lcomm cpu_state_bp, 1
    .lcomm cpu_state_sp, 1

    .lcomm cpu_state_cs, 1
    .lcomm cpu_state_ds, 1
    .lcomm cpu_state_es, 1
    .lcomm cpu_state_ss, 1

.text

cpu_save_state:
    mov word ptr cpu_state_ax, ax
    mov word ptr cpu_state_bx, bx
    mov word ptr cpu_state_cx, cx
    mov word ptr cpu_state_dx, dx

    // adjust sp to account for the call?

    mov word ptr cpu_state_si, si
    mov word ptr cpu_state_di, di
    mov word ptr cpu_state_bp, bp
    mov word ptr cpu_state_sp, sp

    mov word ptr cpu_state_cs, cs
    mov word ptr cpu_state_ds, ds
    mov word ptr cpu_state_es, es
    mov word ptr cpu_state_ss, ss

    // save flags?

    ret

cpu_check_state:
    ret
