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

/* LED blinking task */
#define BLINK_LED		0
#define DEBUG_LED		1

blink_led_task:		

	lds temp,PORTA_DIR		
    ori temp,1<<BLINK_LED
	sts PORTA_DIR,temp	


	_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER

blink_led_main:
	_SLEEP_TASK 255
	_SLEEP_TASK 255
	

	lds temp,PORTA_OUT		
    cbr temp,1<<BLINK_LED
	sts PORTA_OUT,temp			
	

	
	_SLEEP_TASK 255
	_SLEEP_TASK 255

    lds temp,PORTA_OUT		
    sbr temp,1<<BLINK_LED
	sts PORTA_OUT,temp	

rjmp blink_led_main
