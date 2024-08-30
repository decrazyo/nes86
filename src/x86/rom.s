
.segment "ROMFS"
.incbin "romfs.bin"

.segment "BOOT"
.incbin "Image"

.segment "BIOS"
.incbin "bios.bin"
