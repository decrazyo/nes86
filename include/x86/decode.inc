
.ifndef _X86_DECODE_
_X86_DECODE_ = 1

.scope Decode

    .importzp zbWord

    .importzp zbMod

    .importzp zbExt
    .importzp zbSeg
    .importzp zbReg

    .importzp zbRM

    .import decode

    ; bitmask for segment prefix index
    PREFIX_SEG_MASK = %00011000

    ; bitmask for opcodes with an embedded register index
    OPCODE_REG_MASK  = %00000111

    ; bitmasks for opcode direction and byte/word flags
    OPCODE_DIR_MASK  = %00000010
    OPCODE_WORD_MASK = %00000001

    ; opcode embedded register bitmasks
    EMBED_SEG_MASK = %00011000 ; segment register index embedded in an opcode
    EMBED_REG_MASK = %00000111 ; register index embedded in an opcode

    ; ModR/M bitmasks
    MODRM_MOD_MASK = %11000000 ; access mode
    MODRM_REG_MASK = %00111000 ; register index
    MODRM_EXT_MASK = %00111000 ; extended instruction index
    MODRM_SEG_MASK = %00011000 ; segment register index
    MODRM_RM_MASK  = %00000111 ; register index or index to registers to use as pointers

    ; ModR/M Mod field indicates that the value comes from a register instead of main memory.
    MODRM_MOD_REGISTER = %00000011

    ; extended instruction indexes for special cases.
    MODRM_EXT_TEST = 0 ; test instruction needs an immediate value
    MODRM_EXT_CALL = 3 ; call instruction needs a pointer
    MODRM_EXT_JMP = 5 ; jmp instruction that needs a pointer

    ; ModR/M R/M field indicates a direct address
    MODRM_RM_DIRECT = %00000110

    ; for ModR/M mode 0-2, this bit indicates weather 1 or 2 registers
    ; are needed to calculate an indirect address.
    MODRM_RM_MAP = %00000100

.endscope

.endif
