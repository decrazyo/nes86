
; interrupt descriptor table (IDT)
; type      x86 addr    name
; INT 0     0x00000     divide error
; INT 1     0x00004     single step
; INT 2     0x00008     NMI
; INT 3     0x0000C     breakpoint
; INT 4     0x00010     overflow
; INT 5     0x00014     [reserved]
; ...
; INT 31    0x0007F     [reserved]
; INT 32    0x00080     [available]
; ...
; INT 255   0x003ff     [available]

.include "x86.inc"
.include "x86/interrupt.inc"
.include "x86/fetch.inc"
.include "x86/mem.inc"
.include "x86/pic.inc"
.include "x86/reg.inc"
.include "x86/execute.inc"
.include "tmp.inc"
.include "mmc5.inc"

; this flag may be set to trigger a non-maskable interrupt.
; the flag will be cleared once the interrupt has been acknowledged.
.exportzp zbNmiFlag

.export interrupt
.export int
.export iret
.export skip

.segment "ZEROPAGE"

zbSkipNext: .res 1
zbTrapTemp: .res 1
zbIntType: .res 1
zbIntFlag: .res 1
zbNmiFlag: .res 1
zbFiloIndex: .res 1

.segment "BSS"
; it's probably completely overkill to allocate a full page to each FILO.
; we've got plenty of RAM so why not?
baPrefixFilo: .res 256
baOpcodeFilo: .res 256

.segment "CODE"

; interrupt handler.
; acknowledge interrupts and redirect execution to interrupt service routines.
; changes: A, X, Y
.proc interrupt
    ; interrupts cannot be handled directly after some instructions.
    ; those instructions will set this flag.
    lda zbSkipNext
    bne clear_skip_flag

    ; clear the temporary trap flag.
    sta zbTrapTemp

    ; check for internal interrupts
    lda zbIntFlag
    bne interrupt_int

next:
    ; check for non-maskable interrupts
    lda zbNmiFlag
    bne interrupt_nmi

    ; check for external interrupts if they are enables
    jsr Execute::get_interrupt_flag
    beq interrupts_disabled

    ; docs say that the CPU doesn't latch this signal
    ; so we'll check if the PIC is trying to send an interrupt.
    ; this will acknowledge the interrupt if there is one.
    jsr Pic::intr
    bcs interrupt_intr

interrupts_disabled:
    jsr Execute::get_trap_flag
    ora zbTrapTemp
    bne interrupt_trap

    rts
.endproc


; resume normal interrupt processing after the next instruction.
.proc clear_skip_flag
    lda #0
    sta zbSkipNext
    rts
.endproc


; handle trap interrupts if TF was set.
.proc interrupt_trap
    ; "call_isr" will handle clearing the trap flag.
    lda #Interrupt::eType::SINGLE_STEP
    jmp call_isr
    ; [tail_jump]
.endproc


; handle internal interrupts.
.proc interrupt_int
    ; clear the internal interrupt flag
    ldx #0
    stx zbIntFlag

    lda zbIntType
    jmp call_isr
    ; [tail_jump]
.endproc


; handle NMI interrupts.
.proc interrupt_nmi
    ; clear the non-maskable interrupt flag
    ldx #0
    stx zbNmiFlag

    lda #Interrupt::eType::NMI
    ; [fall_through]
.endproc

; handle external interrupts if IF was set.
.proc interrupt_intr
    ; clear the halt flag.
    ldx #0
    stx X86::zbHalt
    ; [fall_through]
.endproc

; setup a call to an interrupt service routine (ISR)
; push Flags, CS, and IP onto the stack.
; push the previous repeat prefix and opcode into FILO queues.
; save TF to a temporary location for later use.
; clear TF and IF
; set CS and IP to the address of an ISR from the IDT.
; check for additional interrupts to handle.
; return to the fetch->decode->execute->write loop to handle the ISR.
; < A = interrupt type
.proc call_isr
    pha

    ldx #Reg::zwSS
    jsr Mem::use_segment

    ; push Flags, CS, and IP onto the stack
    lda Reg::zwFlags
    ldx Reg::zwFlags+1
    jsr Mem::push_word

    lda Reg::zwCS
    ldx Reg::zwCS+1
    jsr Mem::push_word

    lda Reg::zwIP
    ldx Reg::zwIP+1
    jsr Mem::push_word

    ; temporarily store TF then clear TF and IF.
    jsr Execute::get_trap_flag
    sta zbTrapTemp
    jsr Execute::clear_trap_flag
    jsr Execute::clear_interrupt_flag

    ; save the repeat prefix and opcode.
    ; if an interrupt occurred during a repeated string instruction then
    ; this will allow us to correctly restore execution when IRET is executed.
    ldx zbFiloIndex
    lda Fetch::zbPrefixRepeat
    sta baPrefixFilo, x
    lda Fetch::zbInstrOpcode
    sta baOpcodeFilo, x
    inc zbFiloIndex

    ; calculate the address of the IDT in the NES's address space.
    ; example:
    ;   type    x86 addr    NES addr
    ;   INT 8   0x0020      0x6020
    pla
    sta Tmp::zw0
    lda #>(Mmc5::WINDOW_0 >> 2)
    sta Tmp::zw0+1

    asl Tmp::zw0
    rol Tmp::zw0+1
    asl Tmp::zw0
    rol Tmp::zw0+1

    ldy #0

    ; remove the previous prefix so the "fetch" stage will operate correctly.
    sty Fetch::zbPrefixRepeat

    ; select the bank containing the IDT.
    ; the IDT is always at the same address so we don't need to access it thought the MMU.
    ; NOTE: Mmc5::mmc5 should have already selected this bank and
    ;       nothing else should have a reason to change it.
    ;       it's probably safe to remove this.
    sty Mmc5::WINDOW_0_CTRL

    ; load IP and CS from the ISR
    lda (Tmp::zw0), y
    sta Reg::zwIP
    iny
    lda (Tmp::zw0), y
    sta Reg::zwIP+1
    iny
    lda (Tmp::zw0), y
    sta Reg::zwCS
    iny
    lda (Tmp::zw0), y
    sta Reg::zwCS+1

    ; handle additional interrupts if there are any.
    jmp interrupt::next
    ; [tail_jump]
.endproc


; trigger an internal interrupt.
; used instructions that may cause an interrupt like INT and DIV.
; changes: A
.proc int
    sta zbIntType
    lda #1
    sta zbIntFlag
    rts
.endproc


; restore IP, CS, Flags, repeat prefix and opcode to a pre-interrupt state.
; restoring the repeat prefix and opcode insures that
; repeated string instructions resume execution correctly.
; some/all of this functionality arguably belongs in the "execute" stage itself
; but keeping it here with "call_isr" feels more appropriate to me.
; changes: A, X, Y
.proc iret
    dec zbFiloIndex
    ldx zbFiloIndex

    ldy baOpcodeFilo, x
    lda baPrefixFilo, x

    sta Fetch::zbPrefixRepeat
    beq no_rep
    sty Fetch::zbInstrOpcode
no_rep:

    ldx #Reg::zwSS
    jsr Mem::use_segment

    jsr Mem::pop_word
    sta Reg::zwIP
    stx Reg::zwIP+1

    jsr Mem::pop_word
    sta Reg::zwCS
    stx Reg::zwCS+1

    jsr Mem::pop_word
    sta Reg::zwFlags
    stx Reg::zwFlags+1
    ; [fall_through]
.endproc

; instruction may set this flag to delay interrupt handling.
; instead of handling interrupts, the flag will be cleared.
; interrupt handling will resume after the next instruction unless the flag is set again.
; this is needed by instructions that change the segment registers as well as STI and IRET.
.proc skip
    lda #1
    sta zbSkipNext
    rts
.endproc
