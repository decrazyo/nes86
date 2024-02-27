
.include "irq.inc"

.include "const.inc"

.export irq

.segment "CODE"

.proc irq
    .ifdef DEBUG
    KILL
    .endif
    rti
.endproc
