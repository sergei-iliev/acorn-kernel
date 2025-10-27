.def    argument=r17
.def    return=r18
.def    counter=r19  

.def	axl=r20
.def	axh=r21

.def	bxl=r22
.def	bxh=r23

.def	dxl=r24
.def	dxh=r25



/* LED blinking task */
#define BLINK_LED		3


blink_led_task:		

	lds temp,PORTB_DIR		
    ori temp,1<<BLINK_LED
	sts PORTB_DIR,temp	

	lds temp,PORTB_OUT		
    sbr temp,1<<BLINK_LED
	sts PORTB_OUT,temp	

	_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER

blink_led_main:
	_SLEEP_TASK 255
	_SLEEP_TASK 255
	_SLEEP_TASK 255
	_SLEEP_TASK 255


	ldi temp,1<<BLINK_LED		
    sts PORTB_OUTTGL,temp

	_SLEEP_CPU_TASK VOID_CALLBACK,VOID_CALLBACK,temp

rjmp blink_led_main
