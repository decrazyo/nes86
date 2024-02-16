
.include "nmi.inc"
.include "reset.inc"
.include "irq.inc"

.segment "VECTORS"
.word nmi
.word reset
.word irq
