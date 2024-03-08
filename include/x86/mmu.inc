
.ifndef _X86_MMU_
_X86_MMU_ = 1

.scope Mmu
    .import mmu

    .import set_address
    .import inc_address

    .import get_byte
    .import get_next_byte
    .import peek_next_byte

    .import set_byte

    .ifdef DEBUG
    .import debug_mmu
    .endif
.endscope

.endif
