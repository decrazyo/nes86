
.include "boot.inc"

.include "const.inc"
.include "terminal.inc"
.include "keyboard.inc"
.include "chr.inc"
.include "nmi.inc"
.include "apu.inc"
.include "ppu.inc"
.include "tmp.inc"
.include "mmc5.inc"

.export boot

.segment "ZEROPAGE"

.segment "LOWCODE"

; the CHR ROM area that maps to control characters is used for boot graphics.

rsNes86Upper:
.byte "N", "E", $13, $17, $18, $00

rsNes86Lower:
.byte $03, $04, $05, $00



; pallet attributes
; .byte (bottomright << 6) | (bottomleft << 4) | (topright << 2) | (topleft << 0)

rsNes86Attr:
.byte (1 << 6) | (1 << 4) | (1 << 2) | (1 << 0)
.byte $00

rsEnergyAttr0:
.byte (2 << 6) | (0 << 4) | (0 << 2) | (0 << 0)
.byte (2 << 6) | (2 << 4) | (0 << 2) | (0 << 0)
.byte (2 << 6) | (2 << 4) | (0 << 2) | (0 << 0)
.byte (2 << 6) | (2 << 4) | (0 << 2) | (0 << 0)
.byte $00


rsEnergyAttr1:
.byte (3 << 6) | (0 << 4) | (2 << 2) | (0 << 0)
.byte (3 << 6) | (3 << 4) | (2 << 2) | (2 << 0)
.byte (3 << 6) | (3 << 4) | (2 << 2) | (2 << 0)
.byte (0 << 6) | (3 << 4) | (0 << 2) | (2 << 0)
.byte $00


rsEnergy0:
.byte      $01, $02, $20, $20, $03, $04, $05, $06, $07, $08, $00
rsEnergy1:
.byte $09, $0a, $0b, $0c, $0d, $0e, $0f, $10, $11, $12, $13, $00
rsEnergy2:
.byte $14, $15, $16, $17, $18, $20, $19, $1a, $1b, $1c, $00
rsEnergy3:
.byte                               $1d, $20, $1e, $00








rsInefficient:
.asciiz "INEFFICIENT"

; TODO: define the version in the makefile.
rsVersion:
.asciiz "Version 0.1"

rsCopyleft:
.byte "Copyleft (", $1f, ") 2024, Decrazyo", $00

rsProcessor:
.asciiz "Processor: 8086"

rsMemory:
.asciiz "Memory test: "
rsRam:
.asciiz "RAM: "
rsRom:
.asciiz "ROM: "

rsKeyboard:
.asciiz "Keyboard: "

rsSetup:
.asciiz "Press DEL to enter setup"
rsBoot:
.asciiz "Press ENTER to boot ( )"

rsPass:
.asciiz "PASS"
rsFail:
.asciiz "FAIL"

rsFamilyBasic:
.asciiz "Family BASIC"
rsOnScreen:
.asciiz "On screen"

BOOT_MSG_ADDR = $2362
BOOT_COUNT_ADDR = BOOT_MSG_ADDR + 21

rwaStringPosition:
.word $23c1, rsNes86Attr
.word $23c4, rsEnergyAttr0
.word $23cc, rsEnergyAttr1


.word $2042, rsNes86Upper
.word $2064, rsNes86Lower

.word $2054, rsEnergy0
.word $2073, rsEnergy1
.word $2093, rsEnergy2
.word $20b9, rsEnergy3

.word $20d3, rsInefficient


.word $2102, rsVersion

.word $2142, rsCopyleft

.word $21c2, rsProcessor

.word $2202, rsMemory
.word $2224, rsRam
.word $2229, rsPass
.word $2229, rsFail
.word $2244, rsRom
.word $2249, rsPass
.word $2249, rsFail

.word $2282, rsKeyboard
.word $228c, rsFamilyBasic
.word $228c, rsOnScreen

.word BOOT_MSG_ADDR, rsBoot
rwaStringPositionEnd:

.enum eRomString
    NES_86_ATTR
    ENERGY_ATTR_0
    ENERGY_ATTR_1

    NES_86_UPPER
    NES_86_LOWER

    ENERGY_0
    ENERGY_1
    ENERGY_2
    ENERGY_3
    INEFFICIENT


    VERSION

    COPYLEFT

    PROCESSOR

    MEMORY
    RAM
    RAM_PASS
    RAM_FAIL
    ROM
    ROM_PASS
    ROM_FAIL

    KEYBOARD
    FAMILY_BASIC
    ON_SCREEN

    BOOT
.endenum


; rbaPallets:
; ; we're using pink ($24) to indicate unused colors
; .byte $0f, $0f, $30, $38 ; black background with white text
; .byte $0f, $0f, $10, $38 ; black background with gray text
; .byte $0f, $00, $30, $38 ; gray background with white text
; .byte $0f, $00, $10, $38 ; gray background with gray text
; rbaPalletsEnd:

; we're using magenta to indicate unused colors.
rbaPallets:
; normal white on black text colors
.byte Ppu::eColor::BLACK, Ppu::eColor::BLACK, Ppu::eColor::WHITE,       Ppu::eColor::MAGENTA
; "NES86" has white text with a red "86"
.byte Ppu::eColor::BLACK, Ppu::eColor::WHITE, Ppu::eColor::RED,         Ppu::eColor::BLACK
; "energy" graphic should appear yellow
.byte Ppu::eColor::BLACK, Ppu::eColor::BLACK, Ppu::eColor::BLACK,       Ppu::eColor::PALE_YELLOW
; "inefficient" text should appear green
.byte Ppu::eColor::BLACK, Ppu::eColor::BLACK, Ppu::eColor::LIGHT_GREEN, Ppu::eColor::MAGENTA
rbaPalletsEnd:


; boot the nes86 emulator and render the boot screen
.proc boot

    jsr Nmi::wait

    ; initialize palette data.
    lda #>Ppu::BACKGROUND_PALLET_ADDR
    sta Ppu::ADDR
    lda #<Ppu::BACKGROUND_PALLET_ADDR
    sta Ppu::ADDR

    ldx #0
loop:
    lda rbaPallets, x
    sta Ppu::DATA
    inx
    cpx #<(rbaPalletsEnd - rbaPallets)
    bcc loop

    ; TODO: update attributes so that tiles display correctly


    ; position sprites for nes86 logo and energy start logo
    ; enable sprites

    ldy #eRomString::NES_86_ATTR * 4
    jsr buffer_rom_string

    ldy #eRomString::ENERGY_ATTR_0 * 4
    jsr buffer_rom_string

    ldy #eRomString::ENERGY_ATTR_1 * 4
    jsr buffer_rom_string


    ldy #eRomString::NES_86_UPPER * 4
    jsr buffer_rom_string

    ldy #eRomString::NES_86_LOWER * 4
    jsr buffer_rom_string

    ldy #eRomString::ENERGY_0 * 4
    jsr buffer_rom_string

    ldy #eRomString::ENERGY_1 * 4
    jsr buffer_rom_string

    ldy #eRomString::ENERGY_2 * 4
    jsr buffer_rom_string

    ldy #eRomString::ENERGY_3 * 4
    jsr buffer_rom_string

    ldy #eRomString::INEFFICIENT * 4
    jsr buffer_rom_string

    ldy #eRomString::VERSION * 4
    jsr buffer_rom_string

    ldy #eRomString::COPYLEFT * 4
    jsr buffer_rom_string

    ldy #eRomString::PROCESSOR * 4
    jsr buffer_rom_string

    ldy #eRomString::MEMORY * 4
    jsr buffer_rom_string

    jsr Mmc5::clear_ram

    ldy #eRomString::RAM * 4
    jsr buffer_rom_string

    jsr Mmc5::test_ram
    bcc ram_pass

    ldy #eRomString::RAM_FAIL * 4
    jmp print_ram_result

ram_pass:
    ldy #eRomString::RAM_PASS * 4

print_ram_result:
    jsr buffer_rom_string


    ldy #eRomString::ROM * 4
    jsr buffer_rom_string

    jsr Mmc5::test_rom
    bcc rom_pass

    ldy #eRomString::ROM_FAIL * 4
    jmp print_rom_result

rom_pass:
    ldy #eRomString::ROM_PASS * 4

print_rom_result:
    jsr buffer_rom_string


    ldy #eRomString::KEYBOARD * 4
    jsr buffer_rom_string


    jsr Keyboard::keyboard
    bcs family_basic

    ldy #eRomString::ON_SCREEN * 4
    jmp print_keyboard_driver

family_basic:
    ldy #eRomString::FAMILY_BASIC * 4

print_keyboard_driver:
    jsr buffer_rom_string


    ldy #eRomString::BOOT * 4
    jsr buffer_rom_string

    jsr Apu::beep


    ldy #'5'
count_down:
    lda #<BOOT_COUNT_ADDR
    ldx #>BOOT_COUNT_ADDR
    jsr Ppu::initialize_write
    tya
    jsr Ppu::write_bytes
    jsr Ppu::finalize_write
    dey

    ldx #60
busy_wait:
    jsr Nmi::wait
    dex
    bne busy_wait

    jsr Keyboard::get_key
    bcs no_key_pressed

    cmp #Chr::LF
    beq exit_loop

no_key_pressed:
    cpy #'0'
    bne count_down

exit_loop:
    ; jmp exit_loop


    jsr Terminal::terminal

    ; lda Ppu::zbMask
    ; and #<~Ppu::MASK_s ; disable sprites
    ; sta Ppu::zbMask
    ; sta Ppu::MASK

    rts
.endproc


.proc buffer_string
    sta Tmp::zw1
    stx Tmp::zw1+1

    ; wait for a new frame before writing a string.
    ; this isn't strictly necessary and it's a little slow
    ; but it makes things look a little nicer
    ; and we don't care too much about speed at this point.
    jsr Nmi::wait

    ldy #0

loop:
    lda (Tmp::zw1), y
    beq exit
    jsr Ppu::write_bytes
    iny
    bne loop ; branch always
exit:

    jmp Ppu::finalize_write
    ; [tail_jump]
.endproc


; < Y string index
.proc buffer_rom_string
    lda rwaStringPosition, y
    iny
    ldx rwaStringPosition, y
    iny
    jsr Ppu::initialize_write

    lda rwaStringPosition, y
    iny
    sta Tmp::zw1
    lda rwaStringPosition, y
    iny
    sta Tmp::zw1+1

    ldy #0
    lda (Tmp::zw1), y
copy_string:
    jsr Ppu::write_bytes
    iny
    lda (Tmp::zw1), y
    bne copy_string

    jsr Ppu::finalize_write
    ; we can't draw everything in 1 frame.
    ; we'll just do one line at a time.
    ; this is kind of slow but it doesn't matter.
    jsr Nmi::wait
    rts
.endproc

