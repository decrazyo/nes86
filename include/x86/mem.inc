
.include "const.inc"
.include "header.inc"

.ifndef _X86_MEM_
    _X86_MEM_ = 1

    .scope Mem

        .import use_segment
        .import use_pointer

        .import get_ip_byte

        .import pop_word
        .import push_word

        .import get_si_byte
        .import get_si_word

        .import get_di_byte
        .import get_di_word

        .import set_di_byte
        .import set_di_word

        .import get_byte
        .import get_word

        .import get_word_fast
        .import get_dword_lo
        .import get_dword_hi

        .import set_byte
        .import set_word

        .importzp zaSegment


        ; the 8086 has a 1M byte address space
        MEM_SIZE = $100000

        RAM_START = 0
        RAM_SIZE = Header::PRG_RAM

        .if Header::PRG_ROM + Header::PRG_RAM >= MEM_SIZE + Const::EMU_ROM_SIZE
            ; we have enough RAM and ROM to fill out the whole x86 address space.
            ; ROM will start directly after RAM.
            ROM_SIZE = MEM_SIZE - Header::PRG_RAM
            UNMAPPED_SIZE = 0
            ROM_START = Header::PRG_RAM
        .else
            ; we don't have enough RAM and ROM to fill out the x86 address space.
            ; there will be a range of unmapped memory between RAM and ROM.
            ROM_SIZE = Header::PRG_ROM - Const::EMU_ROM_SIZE
            UNMAPPED_SIZE = MEM_SIZE - Header::PRG_RAM - ROM_SIZE
            ROM_START = Header::PRG_RAM + UNMAPPED_SIZE
        .endif

    .endscope

.endif
