
.include "nmi.inc"
.include "reset.inc"
.include "irq.inc"

.segment "VECTORS"

.word Nmi::nmi
.word Reset::reset
.word Irq::irq
