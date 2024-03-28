
.ifndef _X86_DECODE_
_X86_DECODE_ = 1

.scope Decode

    .importzp zbDir
    .importzp zbWord

    .importzp zbMode

    .importzp zbExt
    .importzp zbSeg
    .importzp zbReg

    .importzp zbRM

    .import decode

    ; bitmask for segment index in instruction prefix
    PREFIX_SEG_MASK = %00011000

    ; bitmask for opcodes with an embedded register index
    OPCODE_REG_MASK = %00000111
    OPCODE_WORD_MASK = %00000001

    ; ModR/M bitmasks
    MODRM_MOD_MASK = %11000000 ; access mode
    MODRM_REG_MASK = %00111000 ; register index
    MODRM_EXT_MASK = %00111000 ; instruction index
    MODRM_SEG_MASK = %00011000 ; segment register index
    MODRM_RM_MASK  = %00000111 ; register index or index to registers to use as pointers

    ; ModR/M R/M field indicates a direct address
    MODRM_RM_DIRECT  = %00000110

.endscope

.endif
