
.ifndef _NMI_
_NMI_ = 1

.scope Nmi
    .importzp zbScrollX
    .importzp zbScrollY

    .import nmi
    .import wait
    .import write_addr
    .import write_data
    .import write_done
.endscope

.endif
