OUTPUT_FORMAT(binary)
ENTRY(_start)

SECTIONS {
    . = SEGMENT_START ("text-segment", 0x2000);
    .text : {
        *(.text*)
        *(.rodata*)
        *(.data*)
    }
    .bss : {
        *(.bss)
        *(COMMON)
    }
    /DISCARD/ : {
        *(.comment)
    }
}