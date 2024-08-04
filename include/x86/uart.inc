
.ifndef _X86_UART_
_X86_UART_ = 1

.scope Uart

    .import uart

    .import get_rbr
    .import set_thr

    .import get_ier
    .import set_ier

    .import get_iir
    .import set_fcr

    .import get_lcr
    .import set_lcr

    .import set_mcr

    .import get_lsr

    .import get_msr

    .import get_sr
    .import set_sr

.endscope

.endif
