
.code16
.arch i8086
.intel_mnemonic
.intel_syntax noprefix

.include "test_mov.h"

.global _start

.text

_start:
    .byte 0xff, 0xff
    call test_mov

