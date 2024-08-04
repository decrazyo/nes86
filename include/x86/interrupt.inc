
.ifndef _X86_INTERRUPT_
_X86_INTERRUPT_ = 1

.scope Interrupt

    .importzp zbNmiFlag

    .import interrupt
    .import int
    .import iret
    .import skip

    .enum
        DIVIDE_ERROR
        SINGLE_STEP
        NMI
        BREAKPOINT
        OVERFLOW
    .endenum

.endscope

.endif
