
.ifndef _NMI_
.define _NMI_

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
