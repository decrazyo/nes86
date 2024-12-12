; this module is used to setup the initial state of the MMC5 and some perform basic tests.
; other code may directly change the state of the MM5.

; NOTE: it would be nice to use features of the MMC5A but emulator support is limited.

; NOTE: it might be smart to port this project to the Sunsoft FME-7 mapper.
;       that would give us 512K or RAM and 512K of ROM.
;       the additional RAM would make the system much more usable.

.include "mmc5.inc"

.include "tmp.inc"

.export mmc5

.export clear_ram
.export test_ram
.export test_rom

; don't expose these in the header.
; nothing else should have a reason to change these.
NT_MAPPING = $5105

PRG_MODE = $5100
CHR_MODE = $5101

PROTECT1 = $5102
PROTECT2 = $5103

.segment "LOWCODE"

; configure the MMC5 as needed for the rest of the program's execution.
; this should be called early in the boot process.
; "clear_ram" must be called separately to initialize PRG RAM.
; changes: A
.proc mmc5
    ; disable interrupt generation
    lda #0
    sta Mmc5::IRQ_STATUS

    ; setup vertical mirroring
    lda #$44
    sta NT_MAPPING

    ; configure PRG mode 1
    lda #1
    sta PRG_MODE

    ; make PRG RAM writable
    lda #2
    sta PROTECT1
    lsr
    sta PROTECT2

    ; configure CHR mode 0
    ; 8KB CHR pages
    lda #0
    sta CHR_MODE

    rts
.endproc


.segment "CODE"

; zero out all of the MMC5's PRG RAM.
; we have 128k of PRG RAM so this will take a while.
; changes: A, X, Y
.proc clear_ram
    ; PRG RAM pointer low byte.
    ldy #0
    sty Tmp::zw0

    ; number of PRG RAM banks to clear.
    ldx #<Mmc5::PRG_RAM_BANKS - 1

select_bank:
    stx Mmc5::WINDOW_0_CTRL

    ; set PRG RAM pointer high byte
    lda #>Mmc5::WINDOW_0
    sta Tmp::zw0+1

    ; zero out all of the PRG RAM visible in window 0.
    ; i.e. an 8k bank of PRG RAM.
clear_ram_window:
    ; A = 0
    tya

    ; zero out a 256 byte page of PRG RAM.
clear_ram_page:
    sta (Tmp::zw0), y
    iny
    bne clear_ram_page ; branch if the page hasn't been cleared yet.

    ; move to the next page
    inc Tmp::zw0+1

    ; check if we have cleared the whole window.
    lda Tmp::zw0+1
    cmp #>Mmc5::WINDOW_1
    bne clear_ram_window ; branch if the window hasn't been cleared yet.

    ; move the pointer back to the start of the window.
    lda #>Mmc5::WINDOW_0
    sta Tmp::zw0+1

    ; select the next next bank.
    dex
    bpl select_bank

    rts
.endproc


; ----------------------------------------
; mapper tests
; ----------------------------------------
; chances are that we are running in an emulator or flash cartridge.
; those tend to not support the cartridge configuration we're using.
; we can perform some basic tests to make sure that everything is working as we expect.

; check that each PRG RAM bank is unique and writable.
; this function assumes that RAM has been cleared by the caller.
; > C = 0 if all tests passed successfully
;   C = 1 if a test failed.
.proc test_ram
    ; write the PRG RAM bank number to each bank.
    ; this gives each bank a unique value that we can check for later.
    ldx #<Mmc5::PRG_RAM_BANKS - 1

write_loop:
    stx Mmc5::WINDOW_0_CTRL
    stx Mmc5::WINDOW_0
    dex
    bpl write_loop

    ; read back the values we just wrote.
    lda #0
    ldx #<Mmc5::PRG_RAM_BANKS - 1

read_loop:
    stx Mmc5::WINDOW_0_CTRL
    ; check that the bank contains the bank number.
    ; if it doesn't then we're probably reading open bus
    ; or we're not reading the bank that we think we are.
    cpx Mmc5::WINDOW_0
    bne error
    ; zero out the byte we changed earlier.
    sta Mmc5::WINDOW_0
    dex
    bpl read_loop

    ; success
    clc
    rts

error:
    sec
    rts
.endproc


; read 1 or more bytes from each PRG ROM bank and check that we aren't reading open bus.
; this isn't a great test since open bus behavior is unreliable and
; there is also a chance that the PRG ROM data happens to match open bus.
; this is about the best we can do though.
; > C = 0 if test passed.
;   C = 1 if test failed.
.proc test_rom
    ldx #<((Mmc5::PRG_ROM_BANKS - 1) | Mmc5::ROM)

    ; select 2 PRG ROM banks in window 1.
    ; we have to check 2 banks at a time because of the PRG ROM mode we're using.
select_bank:
    stx Mmc5::WINDOW_1_CTRL

    ldy #0

    ; check up to 256 bytes of the first bank for open bus behavior.
check_first_bank:
    lda Mmc5::WINDOW_1, y
    cmp #>Mmc5::WINDOW_1
    bne first_bank_success ; branch if the value isn't open bus.
    iny
    bne check_first_bank
    beq error

first_bank_success:
    ldy #0

    ; check up to 256 bytes of the second bank for open bus behavior.
check_second_bank:
    lda Mmc5::WINDOW_1 + Mmc5::BANK_SIZE, y
    cmp #>(Mmc5::WINDOW_1 + Mmc5::BANK_SIZE)
    bne second_bank_success ; branch if the value isn't open bus.
    iny
    bne check_second_bank
    beq error

second_bank_success:
    dex
    dex
    bmi select_bank

    ; success
    clc
    rts

error:
    sec
    rts
.endproc


; test if the MMC5's hardware multiplier is working.
; > C = 0 if test passed.
;   C = 1 if test failed.
.proc test_mult
    ; 0 * 0 = 0
    lda #0
    sta Mmc5::MULT_LO
    sta Mmc5::MULT_HI
    lda Mmc5::MULT_LO
    bne error
    lda Mmc5::MULT_HI
    bne error

    ; $aa * $81 = $55aa
    lda #$81
    sta Mmc5::MULT_LO
    lda #$aa
    sta Mmc5::MULT_HI
    cmp Mmc5::MULT_LO ; $aa
    bne error
    lda #$55
    cmp Mmc5::MULT_HI
    bne error

    ; success
    clc
    rts

error:
    sec
    rts
.endproc
