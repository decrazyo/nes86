
.include "x86/mmu.inc"
.include "x86/reg.inc"
.include "x86.inc"

.include "const.inc"
.include "tmp.inc"
.include "con.inc"
.include "nmi.inc"
.include "chr.inc"

.export mmu
.export set_address
.export inc_address

.export get_byte
.export get_next_byte
.export peek_next_byte

.export set_byte

.segment "ZEROPAGE"

; 20-bit address LSB first
; lo                           hi
; 7654 3210  7654 3210  ____ 3210 ;
;            XXX             XXXX ; bank number
; YYYY YYYY     Y YYYY            ; address within bank
; addresses must be adjusted to read/write a particular window

zpAddress:
zbAddressLo: .res 1
zbAddressHi: .res 1

zbBank: .res 1

.segment "RODATA"

RAM = %00000000
ROM = %10000000

; NOTE: this isn't strictly needed but it makes testing/tweaking easier.
rbaBankMap:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte RAM,RAM,RAM,RAM,RAM,RAM,RAM,RAM,RAM,RAM,RAM,RAM,RAM,RAM,RAM,RAM ; 0_
.byte ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM ; 1_
.byte ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM ; 2_
.byte ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM ; 3_
.byte ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM ; 4_
.byte ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM ; 5_
.byte ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM ; 6_
.byte ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM,ROM ; 7_
rbaBankMapEnd:

.segment "X86_ROM"
.incbin "x86_code.com"

.segment "CODE"

PRG_MODE = $5100
CHR_MODE = $5101
PROTECT1 = $5102
PROTECT2 = $5103

WIN0_BANK = $5113
WIN1_BANK = $5114
WIN2_BANK = $5115
WIN3_BANK = $5116
WIN4_BANK = $5117

WINDOW0 = $6000 ; RAM only
WINDOW1 = $8000 ; RAM/ROM
WINDOW2 = $A000 ; RAM/ROM
WINDOW3 = $C000 ; RAM/ROM
WINDOW4 = $E000 ; ROM only

; selects RAM or ROM access
SELECT_MASK = %10000000
; selects which bank is mapped to a window
BANK_MASK = %01111111

; ==============================================================================
; public interface
; ==============================================================================

; TODO: create a special interface just for accessing code.
;       that way the fetch step doesn't have to set the address every time.
;       instructions that change IP can mark the MMU code address as dirty.
;       then the next fetch step can set the address correctly.
;       maybe do the same for stack access?

; initialize the MMU
.proc mmu
    ; configure PRG mode 3
    ; $6000-$7FFF: 8 KB switchable PRG RAM bank
    ; $8000-$9FFF: 8 KB switchable PRG ROM/RAM bank
    ; $A000-$BFFF: 8 KB switchable PRG ROM/RAM bank
    ; $C000-$DFFF: 8 KB switchable PRG ROM/RAM bank
    ; $E000-$FFFF: 8 KB switchable PRG ROM bank
    lda #3
    sta PRG_MODE

    ; configure CHR mode 0
    ; 8KB CHR pages
    ; NOTE: consider switching to mode 3 since most games use that.
    ;       it might give us better compatibility with cheap Famiclones.
    lda #0
    sta CHR_MODE

    ; make PRG RAM writable
    lda #2
    sta PROTECT1
    lsr
    sta PROTECT2

    rts
.endproc


; compute a 20-bit address from a 16-bit address and a segment register.
; < Y = segment index
; < Tmp::zw0 = 16-bit address
; changes: A, Y
.proc set_address
    ; get the zero-page offset of the segment register.
    ldx Reg::rzbaSegRegMap, y

    ; add the segment register to the 16-bit address.
    clc
    lda Tmp::zd0
    adc Const::ZERO_PAGE, x
    sta Tmp::zd0
    inx
    lda Tmp::zd0+1
    adc Const::ZERO_PAGE, x
    sta Tmp::zd0+1
    inx
    lda #0
    adc Const::ZERO_PAGE, x
    sta Tmp::zd0+2

    ; extract a pointer in the range [0, 0x1fff] from the address.
    ; adjust the pointer to point to one of the MMC5 mapper windows.
    lda Tmp::zd0
    sta zbAddressLo
    lda Tmp::zd0+1
    and #%00011111
    ora #>WINDOW1
    sta zbAddressHi

    ; extract the bank number from the address
    lda Tmp::zd0+1
    and #%11100000
    asl
    rol
    rol
    rol
    sta zbBank
    lda Tmp::zd0+2
    and #%00001111
    asl
    asl
    asl
    ora zbBank
    sta zbBank

    rts
.endproc


; increment the address and bank if needed.
; this is faster than setting an address for sequential reads.
; changes: A
.proc inc_address
    inc zbAddressLo
    bne done
    sec
carry:
    lda zbAddressHi
    adc #0
    cmp #>WINDOW2
    bcc set_addr_hi ; branch if the address is still inside window 1
    lda #>WINDOW1
    inc zbBank
set_addr_hi:
    sta zbAddressHi
done:
    rts
.endproc


; read a byte from RAM or ROM at the address specified with set_address.
; > A = byte read from RAM or ROM
; change: A, Y
.proc get_byte
    ; select the necessary bank
    ; TODO: move banking logic to set_address/inc_address
    ldy zbBank
    lda rbaBankMap, y ; determines if we access RAM or ROM
    ora zbBank
    sta WIN1_BANK

    ldy #0
    lda (zpAddress), y
    rts
.endproc


; increment the address that the MMU points to.
; read a byte from RAM or ROM at the address.
; > A = byte read from RAM or ROM
; change: A, Y
.proc get_next_byte
    ; select the necessary bank
    jsr inc_address
    jmp get_byte ; jsr rts -> jmp
.endproc


; read a byte from RAM or ROM that follows the current address.
; > A = byte read from RAM or ROM
; change: A, Y
.proc peek_next_byte
    ; save the current address
    ldy zbAddressLo
    sty Tmp::zd0
    ldy zbAddressHi
    sty Tmp::zd0+1
    ldy zbBank
    sty Tmp::zd0+2

    jsr get_next_byte

    ; restore the previous address
    ldy Tmp::zd0
    sty zbAddressLo
    ldy Tmp::zd0+1
    sty zbAddressHi
    ldy Tmp::zd0+2
    sty zbBank

    rts
.endproc


; write a byte to RAM at the address specified with set_address.
; > A = byte to write to RAM
; change: A, Y
.proc set_byte
    ; select the necessary bank.
    ; defaults to RAM
    ldy zbBank
    sty WIN1_BANK

    ldy #0
    sta (zpAddress), y
    rts
.endproc

; ==============================================================================
; debugging
; ==============================================================================

.ifdef DEBUG
.segment "RODATA"

rsBank:
.byte "bank:\t", 0
rsAddr:
.byte "addr:\t", 0

.segment "CODE"

.export debug_mmu
.proc debug_mmu
    lda #Chr::NEW_LINE
    jsr Con::print_chr

    lda #<rsBank
    ldx #>rsBank
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda zbBank
    jsr Con::print_hex

    lda #Chr::NEW_LINE
    jsr Con::print_chr

    lda #<rsAddr
    ldx #>rsAddr
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zpAddress
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr

    jsr Nmi::wait
    rts
.endproc
.endif
