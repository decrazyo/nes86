
.ifndef _X86_MEM_
    _X86_MEM_ = 1

    .scope Mem

        .import mem

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

    .endscope

.endif
