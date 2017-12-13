/*
 * ds18b20.asm driver at 8MHz
 *
 */

.def    argument=r17  
.def    return = r18
.def    axl=r19
.def    axh=r20

.def	bxl=r21
.def    bxh=r22

.include "include/ds18b20op.asm"
.include "include/math.asm"

.SET OW=7

Task_4:  	 	    

	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

	_INTERRUPT_DISPATCHER_INIT temp,OW
	rcall ow_init


main4:

	/*isolate first measurement*/
	rcall ow_reset
	brts main4    ;no presence
	rcall ow_temp_conv

	rcall ow_reset
	brts main4    ;no presence
	rcall ow_read_pad
	brts main4    ;wrong temp read

m4loop:
	_SLEEP_TASK 200
	_SLEEP_TASK 200

	
		
	rcall ow_reset
	brts nopresense    ;no presence	

	
	rcall ow_temp_conv


	rcall ow_reset
	brts nopresense    ;no presence
    
	rcall ow_read_pad
	brts nopresense    ;wrong temp read
	;now that we have a valid temp->go to calculations
	
	;mul
	ldi r20,low(ow12bit)
	ldi r21,high(ow12bit)

	lds argument,TL
	mov r22,argument
	;filter sign out
	lds argument,TH
	andi argument,0b00000111
	mov r23,argument        
  	
	rcall mul16x16_32
	
	rcall bin4BCD32
	sts BCD01,tBCD0
	sts BCD23,tBCD1
	sts BCD45,tBCD2
	sts BCD67,tBCD3
	sts BCD89,tBCD4


	;signal lcd display and wait to finish relatively
	;_EVENT_SET LCD_EVENT,TASK_CONTEXT
	
	rjmp gosleep
	 

nopresense: 	
	 

	clr temp
	sts BCD01,temp
	sts BCD23,temp
	sts BCD45,temp
	sts BCD67,temp
	sts BCD89,temp

	;_EVENT_SET LCD_EVENT,TASK_CONTEXT

gosleep:

_SLEEP_CPU_READY VOID_CALLBACK,VOID_CALLBACK,r16,r17
rjmp m4loop
 
  
