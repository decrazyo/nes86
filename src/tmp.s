
.include "tmp.inc"

.exportzp gzdTmp0
.exportzp gzwTmp0
.exportzp gzbTmp0
.exportzp gzbTmp1
.exportzp gzwTmp1
.exportzp gzbTmp2
.exportzp gzbTmp3

.segment "ZEROPAGE"
gzdTmp0:
gzwTmp0:
gzbTmp0: .res 1
gzbTmp1: .res 1
gzwTmp1:
gzbTmp2: .res 1
gzbTmp3: .res 1

