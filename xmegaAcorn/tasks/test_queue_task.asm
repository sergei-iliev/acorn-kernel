.include "kernel/single-producer-consumer.asm"

.def    argument=r17
.def    return=r18
.def    counter=r19  

.def	axl=r20
.def	axh=r21

.def	bxl=r22
.def	bxh=r23

.def	dxl=r24
.def	dxh=r25

.def	cxl=r14
.def	cxh=r15

#define QUEUE_MAX_SIZE  5 

.dseg
;queue8: .byte 2+QUEUE_MAX_SIZE

//16 bit queue
queue16: .byte 4+QUEUE_MAX_SIZE*2
.cseg


Test_Queue_Task:

_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

main_test_queue:

rcall test_16bit_queue
	
rjmp main_test_queue

;****16bit****
test_16bit_queue:
    ldi dxh,0x1f
	
	ldi ZL,low(queue16)
	ldi ZH,high(queue16)

	rcall spc_queue16_init
t16que:
	ldi ZL,low(queue16)
	ldi ZH,high(queue16)	  	
	ldi axl,low(QUEUE_MAX_SIZE)
	ldi axh,high(QUEUE_MAX_SIZE)

	ADDI16 dxl,dxh,1	
	rcall spc_queue16_push	

	ldi ZL,low(queue16)
	ldi ZH,high(queue16)	  	
	ldi axl,low(QUEUE_MAX_SIZE)
	ldi axh,high(QUEUE_MAX_SIZE)		
	rcall spc_queue16_pop	
	
	ldi ZL,low(queue16)
	ldi ZH,high(queue16)	  	
	ldi axl,low(QUEUE_MAX_SIZE)
	ldi axh,high(QUEUE_MAX_SIZE)		
	rcall spc_queue16_pop	
	
	CPI16 dxl,dxh,temp,1

rjmp t16que
ret

;****8bit****
/*
test_8bit_queue:
	ldi ZL,low(queue8)
	ldi ZH,high(queue8)

	rcall spc_queue8_init


	ldi argument,0xA1
t8que:

	ldi ZL,low(queue8)
	ldi ZH,high(queue8)	  	
	ldi axl,QUEUE_MAX_SIZE
	inc argument
	rcall spc_queue8_push	

	ldi ZL,low(queue8)
	ldi ZH,high(queue8)	  	
	ldi axl,QUEUE_MAX_SIZE
	inc argument
	rcall spc_queue8_push	

	ldi ZL,low(queue8)
	ldi ZH,high(queue8)	  	
	ldi axl,QUEUE_MAX_SIZE	
	rcall spc_queue8_pop	

	ldi ZL,low(queue8)
	ldi ZH,high(queue8)	  		
	ldi axl,QUEUE_MAX_SIZE	
	rcall spc_queue8_pop	
rjmp t8que
ret
*/




.EXIT


