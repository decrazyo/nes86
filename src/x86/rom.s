
.segment "ROMFS"
.incbin "romfs.bin"

.segment "BOOT"
.incbin "Image"
; .incbin "x86_code.com"

.segment "BIOS"
.incbin "bios.bin"
