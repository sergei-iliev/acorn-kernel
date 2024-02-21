
.dseg

var1: .byte 1
var2: .byte 1

.cseg


task1:
	sbi DDRD,PD3
	sbi DDRD,PD2
	nop  
main1:
	
    sbi PORTD,PD2	
	_SLEEP_TASK 255
	cbi PORTD,PD2	
	_SLEEP_TASK 255
	
rjmp main1


.include "include/rs232.asm"
.include "include/spi_task_intr.asm"
;.include "D:/SILIEVPC/Atmel/algorithms-and-structures/queue.asm"


.def	accl=r14
.def	acch=r15
 
.def    argument=r17

.def    addrl=r17
.def    addrh=r18


.def    axl=r20
.def    axh=r21

.def    bxl=r22
.def    bxh=r23

.def    cxl=r24
.def    cxh=r25

.def    val=r15




task3:
  
main3:
rjmp main3
