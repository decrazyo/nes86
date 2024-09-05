
; definitions for the audio processing unit (APU).

.ifndef _APU_
    _APU_ = 1

    .scope Apu

        .import apu
        .import beep
        .import boop

        ; APU registers

        ; TODO: define square, triangle, and noise registers

        ;// DMC channel (write)
        DMC_1 = $4010 ;// IL-- FFFF   IRQ enable, loop sample, frequency index
        DMC_2 = $4011 ;// -DDD DDDD   Direct load
        DMC_3 = $4012 ;// AAAA AAAA   Sample address %11AAAAAA.AA000000
        DMC_4 = $4013 ;// LLLL LLLL   Sample length %0000LLLL.LLLL0001

        ;  ---D NT21   Control: DMC enable, length counter enables: noise, triangle, pulse 2, pulse 1 (write)
        CONTROL = $4015
        ;  IF-D NT21   Status: DMC interrupt, frame interrupt, length counter status: noise, triangle, pulse 2, pulse 1 (read)
        STATUS = $4015

        FRAME = $4017 ; SD-- ----   Frame counter: 5-frame sequence, disable frame interrupt (write)

        ; APU register flags / bit masks.

        ; APU DMC_1 register flags
        DMC_1_I = %10000000 ; IRQ enable
        DMC_1_L = %01000000 ; loop
        DMC_1_R = %00001111 ; frequency

        ; APU status register flags
        STATUS_I = %10000000 ; DMC interrupt
        STATUS_F = %01000000 ; frame interrupt
        STATUS_D = %00010000 ; DMC active
        STATUS_N = %00001000 ; noise length counter > 0
        STATUS_T = %00000100 ; triangle length counter > 0
        STATUS_2 = %00000010 ; square 2 length counter > 0
        STATUS_1 = %00000001 ; square 1 length counter > 0

        ; APU frame register flags
        FRAME_M = %10000000 ; Frame counter: 5-frame sequence
        FRAME_I = %01000000 ; disable frame interrupt (write)

    .endscope

.endif
