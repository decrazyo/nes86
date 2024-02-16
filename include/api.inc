
; definitions for the audio processing unit (APU).

.ifndef _APU_
.define _APU_

; APU registers

; TODO: define square, triangle, and noise registers

;// DMC channel (write)
APU_DMC_1 = $4010 ;// IL-- FFFF   IRQ enable, loop sample, frequency index
APU_DMC_2 = $4011 ;// -DDD DDDD   Direct load
APU_DMC_3 = $4012 ;// AAAA AAAA   Sample address %11AAAAAA.AA000000
APU_DMC_4 = $4013 ;// LLLL LLLL   Sample length %0000LLLL.LLLL0001
 
;  ---D NT21   Control: DMC enable, length counter enables: noise, triangle, pulse 2, pulse 1 (write)
;  IF-D NT21   Status: DMC interrupt, frame interrupt, length counter status: noise, triangle, pulse 2, pulse 1 (read)
APU_STATUS = $4015

APU_FRAME = $4017 ; SD-- ----   Frame counter: 5-frame sequence, disable frame interrupt (write)

; APU register flags / bit masks.

; APU_DMC_1 register flags
APU_DMC_1_I = %10000000 ; IRQ enable
APU_DMC_1_L = %01000000 ; loop
APU_DMC_1_R = %00001111 ; frequency

; APU_STATUS register flags
APU_STATUS_I = %10000000 ; DMC interrupt
APU_STATUS_F = %01000000 ; frame interrupt
APU_STATUS_D = %00010000 ; DMC active
APU_STATUS_N = %00001000 ; noise length counter > 0
APU_STATUS_T = %00000100 ; triangle length counter > 0
APU_STATUS_2 = %00000010 ; square 2 length counter > 0
APU_STATUS_1 = %00000001 ; square 1 length counter > 0

; APU_FRAME register flags
APU_FRAME_M = %10000000 ; Frame counter: 5-frame sequence
APU_FRAME_I = %01000000 ; disable frame interrupt (write)


.endif
