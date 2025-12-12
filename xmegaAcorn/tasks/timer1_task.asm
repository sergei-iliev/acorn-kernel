/*
16 bit timer task to produce stream of tft lcd screen values
Test if tft could read directly from the producer consumer buffer
*/
#define QUEUE_MAX_SIZE 2048
#define QUEUE_LENGTH  (QUEUE_MAX_SIZE+HEADER_SIZE16)

.dseg
lcd_queue: .byte QUEUE_LENGTH
.cseg

timer1_task:

	//copy from blink task
	lds temp,PORTB_DIR		
    ori temp,1<<BLINK_LED
	sts PORTB_DIR,temp	

	lds temp,PORTB_OUT		
    sbr temp,1<<BLINK_LED
	sts PORTB_OUT,temp

	;init queue
	ldi ZL,low(lcd_queue)
	ldi ZH,high(lcd_queue)
	call spc_queue16_init


	_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER
	rcall init_TCC1
timer1_main:

rjmp timer1_main


//*********Initialize 16 bit timer*******************
init_TCC1:
;1.set period
	ldi temp,low(0x5)
	ldi r17,high(0x5)
	cli
	sts 0x866,r16
	sts 0x867,r17
	sei

;2. set clock source
	lds temp,TCC1_CTRLA
	ori temp,RTC_PRESCALER_DIV256_gc
	sts TCC1_CTRLA,temp	

;3. enable timer	
    lds temp,TCC1_INTCTRLA
	ori temp,TC_OVFINTLVL_LO_gc			;assign to LOW level
	sts TCC1_INTCTRLA,temp
ret

/*
Timer 1 overflow interrupt
*/
TCC1Int:
_PRE_INTERRUPT 


    ;store registers used by queue
	push ZH
	push ZL
	push cxh
	push cxl
	push dxh
	push dxl
	push axh
	push axl
    push argument
	push bxl
	push bxh
	push r0
	push r1
    push r2
	push r3
 
    ldi argument,low(0xFF)
	;store in queue
	ldi ZL,low(lcd_queue)
	ldi ZH,high(lcd_queue)	  	
	ldi axl,low(QUEUE_MAX_SIZE)	
	ldi axh,high(QUEUE_MAX_SIZE)	
	call spc_queue16_push_from_isr	


	pop r3
	pop r2
	pop r1
	pop r0
	pop bxh
	pop bxl
	pop argument
	pop axl
	pop axh
	pop dxl
	pop dxh
	pop cxl
	pop cxh
	pop ZL
	pop ZH
_POST_INTERRUPT
_RETI
