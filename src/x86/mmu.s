
.include "x86/mmu.inc"
.include "x86/reg.inc"
.include "x86.inc"

.include "const.inc"
.include "tmp.inc"
.include "con.inc"
.include "mmc5.inc"
.include "nmi.inc"
.include "chr.inc"

.exportzp zbStackDirty
.exportzp zbCodeDirty

.export mmu
.export set_address
.export inc_address

.export get_byte
.export get_next_byte
.export peek_next_byte

.export push_word
.export pop_word

.export get_ip_byte

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

zpStackAddress:
zbStackAddressLo: .res 1
zbStackAddressHi: .res 1
zbStackBank: .res 1
zbStackDirty: .res 1

zpCodeAddress:
zbCodeAddressLo: .res 1
zbCodeAddressHi: .res 1
zbCodeBank: .res 1
zbCodeDirty: .res 1

.segment "RODATA"

RAM = Mmc5::RAM
ROM = Mmc5::ROM

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

    jsr Mmc5::mmc5

    ; mark the stack and code addresses as dirty.
    ; this will force the addresses to be set correctly when they are used.
    lda #1
    sta zbStackDirty
    sta zbCodeDirty
    rts
.endproc


; select the required bank for general RAM/ROM access
; this function isn't actually public but it's placed here so the assembler doesn't bitch.
; changes: A, Y
.proc set_bank
    ldy zbBank
skip_load:
    lda rbaBankMap, y ; determines if we access RAM or ROM
    ora zbBank
    sta Mmc5::WIN1_BANK
    rts
.endproc


; compute a 20-bit address from a 16-bit address and a segment register.
; < Y = segment index
; < Tmp::zw0 = 16-bit address
; changes: A, X, Y
.proc set_address
    ; get the zero-page offset of the segment register.
    ldx Reg::rzbaSegRegMap, y

    ; ptr + (seg << 4)
    clc
    ldy #16
    ; shift segment low byte
    lda Const::ZERO_PAGE, x
    sta Mmc5::MULT_LO
    sty Mmc5::MULT_HI

    ; add the pointer low byte
    lda Mmc5::MULT_LO
    adc Tmp::zw0
    sta zbAddressLo

    ; temporarily storage the low nibble of the next byte
    lda Mmc5::MULT_HI
    sta zbAddressHi

    inx

    ; shift segment high byte
    lda Const::ZERO_PAGE, x
    sta Mmc5::MULT_LO
    sty Mmc5::MULT_HI

    ; add the pointer high byte
    lda Mmc5::MULT_LO
    ora zbAddressHi
    adc Tmp::zw0+1
    sta zbAddressHi

    ; handle carry and the last byte
    lda Mmc5::MULT_HI
    adc #0
    sta zbBank

    ; extract the bank number from the address
    lda zbBank
    and #%00001111
    asl
    asl
    asl
    sta zbBank

    lda zbAddressHi
    and #%11100000
    asl
    rol
    rol
    rol
    ora zbBank
    sta zbBank
    tay
    jsr set_bank::skip_load

    ; adjust the pointer to point to one of the MMC5 mapper windows.
    lda zbAddressHi
    and #%00011111
    ora #>Mmc5::WINDOW1
    sta zbAddressHi

    rts
.endproc


; increment the address and bank if needed.
; this is faster than setting an address for sequential reads.
; changes: A, Y
.proc inc_address
    inc zbAddressLo
    bne done
    sec
carry:
    lda zbAddressHi
    adc #0
    cmp #>Mmc5::WINDOW2
    bcc set_addr_hi ; branch if the address is still inside window 1
    lda #>Mmc5::WINDOW1
    inc zbBank
    sta zbAddressHi
    jmp set_bank ; jsr rts -> jmp
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
    sta Mmc5::WIN1_BANK

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
    jmp get_byte
    ; [tail_jump]
.endproc


; read a byte from RAM or ROM that follows the current address.
; > A = byte read from RAM or ROM
; change: A, Y
.proc peek_next_byte
    ; save the current address
    ldy zbAddressLo
    sty Tmp::zd0+1
    ldy zbAddressHi
    sty Tmp::zd0+2
    ldy zbBank
    sty Tmp::zd0+3

    jsr get_next_byte

    ; restore the previous address
    ldy Tmp::zd0+1
    sty zbAddressLo
    ldy Tmp::zd0+2
    sty zbAddressHi
    ldy Tmp::zd0+3
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
    sty Mmc5::WIN1_BANK

    ldy #0
    sta (zpAddress), y
    rts
.endproc


; push a 16-bit word onto the stack
; < Tmp::zw0 = value to push to the stack
; changes: A, Y
.proc push_word
    lda zbStackDirty
    beq do_push ; branch if the stack address in the MMU is still valid
    jsr set_stack_address

do_push:
    ldy #0
    jsr dec_stack_address
    lda Tmp::zw0+1
    sta (zpStackAddress), y

    jsr dec_stack_address
    lda Tmp::zw0
    sta (zpStackAddress), y
    rts
.endproc


; pop a 16-bit word from the stack
; > Tmp::zw0 = value popped from the stack
; changes: A, Y
.proc pop_word
    lda zbStackDirty
    beq do_pop ; branch if the stack address in the MMU is still valid
    jsr set_stack_address

do_pop:
    ldy #0
    lda (zpStackAddress), y
    sta Tmp::zw0
    jsr inc_stack_address

    lda (zpStackAddress), y
    sta Tmp::zw0+1
    jmp inc_stack_address
    ; [tail_jump]
.endproc


; get the byte pointed to by CS + IP.
; increment IP and the MMU's internal code address.
; > A = byte read from RAM or ROM
; changes: A, Y
.proc get_ip_byte
    lda zbCodeDirty
    beq do_get_ip_byte ; branch if the code address in the MMU is still valid
    jsr set_code_address
do_get_ip_byte:
    ldy #0
    lda (zpCodeAddress), y
    pha
    jsr inc_code_address
    pla
    rts
.endproc

; ==============================================================================
; utility functions
; ==============================================================================

; set the MMU's stack address based on the value in SP + (SS << 4)
; changes: A
.proc set_stack_address
    ; SP + (SS << 4)
    clc
    ; shift stack segment low byte
    lda Reg::zwSS
    sta Mmc5::MULT_LO
    lda #16
    sta Mmc5::MULT_HI

    ; add the stack pointer low byte
    lda Mmc5::MULT_LO
    adc Reg::zwSP
    sta zbStackAddressLo

    ; temporarily storage the low nibble of the next byte
    lda Mmc5::MULT_HI
    sta zbStackAddressHi

    ; shift stack segment high byte
    lda Reg::zwSS+1
    sta Mmc5::MULT_LO
    lda #16
    sta Mmc5::MULT_HI

    ; add the stack pointer high byte
    lda Mmc5::MULT_LO
    ora zbStackAddressHi
    adc Reg::zwSP+1
    sta zbStackAddressHi

    ; handle carry and the last byte
    lda Mmc5::MULT_HI
    adc #0
    sta zbStackBank

    ; extract the bank number from the address
    lda zbStackBank
    and #%00001111
    asl
    asl
    asl
    sta zbStackBank

    lda zbStackAddressHi
    and #%11100000
    asl
    rol
    rol
    rol
    ora zbStackBank
    sta zbStackBank
    sta Mmc5::WIN0_BANK

    ; adjust the pointer to point to one of the MMC5 mapper windows.
    lda zbStackAddressHi
    and #%00011111
    ora #>Mmc5::WINDOW0
    sta zbStackAddressHi

    ; flag the MMU's stack address as no longer dirty
    lda #0
    sta zbStackDirty
    rts
.endproc


; increment SP and the MMU's internal stack address
; changes: A
.proc inc_stack_address
    inc Reg::zwSP
    inc zbStackAddressLo
    bne done
    inc Reg::zwSP+1
    sec
    lda zbStackAddressHi
    adc #0
    cmp #>Mmc5::WINDOW1
    bcc set_addr_hi ; branch if the address is still inside the window
    lda #>Mmc5::WINDOW0
    inc zbStackBank
    sta zbStackAddressHi
    lda zbStackBank
    sta Mmc5::WIN0_BANK
    rts
set_addr_hi:
    sta zbStackAddressHi
done:
    rts
.endproc

; decrement SP and the MMU's internal stack address
; changes: A
.proc dec_stack_address
    dec Reg::zwSP
    lda zbStackAddressLo
    sec
    sbc #1
    sta zbStackAddressLo
    bcs done
    dec Reg::zwSP+1
    lda zbStackAddressHi
    sbc #0
    cmp #>Mmc5::WINDOW0
    bcs set_addr_hi ; branch if the address is still inside the window
    lda #>Mmc5::WINDOW1-1
    dec zbStackBank
    sta zbStackAddressHi
    lda zbStackBank
    sta Mmc5::WIN0_BANK
    rts
set_addr_hi:
    sta zbStackAddressHi
done:
    rts
.endproc


; select the necessary bank in the code segment window
; changes: A, Y
.proc set_code_bank
    ldy zbCodeBank
skip_load:
    lda rbaBankMap, y ; determines if we access RAM or ROM
    ora zbCodeBank
    sta Mmc5::WIN2_BANK
    rts
.endproc


; set the MMU's code address based on the value in IP + (CS << 4)
; changes: A, Y
.proc set_code_address
    ; IP + (CS << 4)
    clc
    ldy #16
    ; shift code segment low byte
    lda Reg::zwCS
    sta Mmc5::MULT_LO
    sty Mmc5::MULT_HI

    ; add the code pointer low byte
    lda Mmc5::MULT_LO
    adc Reg::zwIP
    sta zbCodeAddressLo

    ; temporarily storage the low nibble of the next byte
    lda Mmc5::MULT_HI
    sta zbCodeAddressHi

    ; shift code segment high byte
    lda Reg::zwCS+1
    sta Mmc5::MULT_LO
    sty Mmc5::MULT_HI

    ; add the code pointer high byte
    lda Mmc5::MULT_LO
    ora zbCodeAddressHi
    adc Reg::zwIP+1
    sta zbCodeAddressHi

    ; handle carry and the last byte
    lda Mmc5::MULT_HI
    adc #0
    sta zbCodeBank

    ; extract the bank number from the address
    lda zbCodeBank
    and #%00001111
    asl
    asl
    asl
    sta zbCodeBank

    lda zbCodeAddressHi
    and #%11100000
    asl
    rol
    rol
    rol
    ora zbCodeBank
    sta zbCodeBank
    tay
    jsr set_code_bank::skip_load

    ; adjust the pointer to point to one of the MMC5 mapper windows.
    lda zbCodeAddressHi
    and #%00011111
    ora #>Mmc5::WINDOW2
    sta zbCodeAddressHi

    ; flag the code address as no longer dirty
    lda #0
    sta zbCodeDirty
    rts
.endproc


; increment IP and the MMU's internal code address
; changes: A, Y
.proc inc_code_address
    inc Reg::zwIP
    inc zbCodeAddressLo
    bne done
    inc Reg::zwIP+1
    ldy zbCodeAddressHi
    iny
    cpy #>Mmc5::WINDOW3
    bcc set_addr_hi ; branch if the address is still inside the window
    ldy #>Mmc5::WINDOW2
    inc zbCodeBank
    sty zbCodeAddressHi
    jmp set_code_bank ; jsr rts -> jmp
set_addr_hi:
    sty zbCodeAddressHi
done:
    rts
.endproc

; ==============================================================================
; debugging
; ==============================================================================

.ifdef DEBUG
.segment "RODATA"


rsHeader:
.byte "\t\tcode\tstack\tother", 0
rsBank:
.byte "bank:\t", 0
rsAddr:
.byte "addr:\t", 0
rsDirty:
.byte "dirty:\t", 0

.segment "CODE"

.export debug_mmu
.proc debug_mmu
    lda #Chr::NEW_LINE
    jsr Con::print_chr

    lda #<rsHeader
    ldx #>rsHeader
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #Chr::NEW_LINE
    jsr Con::print_chr

    lda #<rsBank
    ldx #>rsBank
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda zbCodeBank
    jsr Con::print_hex

    lda #Chr::TAB
    jsr Con::print_chr
    lda #Chr::TAB
    jsr Con::print_chr

    lda zbStackBank
    jsr Con::print_hex

    lda #Chr::TAB
    jsr Con::print_chr
    lda #Chr::TAB
    jsr Con::print_chr

    lda zbBank
    jsr Con::print_hex

    lda #Chr::NEW_LINE
    jsr Con::print_chr

    jsr Nmi::wait

    lda #<rsAddr
    ldx #>rsAddr
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zpCodeAddress
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::TAB
    jsr Con::print_chr

    lda #<zpStackAddress
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::TAB
    jsr Con::print_chr

    lda #<zpAddress
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr

    lda #<rsDirty
    ldx #>rsDirty
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda zbCodeDirty
    jsr Con::print_hex

    lda #Chr::TAB
    jsr Con::print_chr
    lda #Chr::TAB
    jsr Con::print_chr

    lda zbStackDirty
    jsr Con::print_hex

    lda #Chr::NEW_LINE
    jsr Con::print_chr

    jsr Nmi::wait
    rts
.endproc
.endif
