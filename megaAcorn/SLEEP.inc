 /*
@WARNING - IN WORKING PROGRESS
SLEEP mode.
Integrating SLEEP mode in a multitasking kernel is a bit tricky by itself.
CPU could either be I/O bound or algorithm bound which may require to finish
before the sleep command is carried out. 
It is required that some/all interrupt processing tasks needs to know when a
sleep mode is about to begin so that they could finish/turn off unnessesary interrupt 
activity.
Current sleep implementation is based on
1.SLEEP is NOT possible in high DEVICE level.
2.SLEEP is executed in USER level from System task 
*/	

 /*
 *SLEEP structure 
 *  |x|x|x|x|x|x|x|x|
 *  x -> count number of tasks ready to sleep
 *  If x=0 no sleep is requested
 *  If x=1 a task has requested a sleep, the other tasks must follow in the sleep sequance
 *  If x=SLEEP_TASKS_REQUEST_NUMBER all tasks are ready to sleep , fire SLEEP instruction
 */

 ;set the number of all tasks to participate in the sleep
.SET SLEEP_TASKS_REQUEST_NUMBER=4

.SET VOID_CALLBACK=0

 .dseg
	sleepmode:	  .byte 1
 .cseg

  /********************************************
  *Initialization routine
  *Called in init routine of the task before other task body execution
  *Usually system task is the one to handle sleep
  *@INPUT: 0-> temp register
  *********************************************/
 .MACRO _SLEEP_CPU_INIT
  	;disable on-chip debug system JTAG
	in @0,MCUCSR
    sbr @0,(1<<JTD)      
    out MCUCSR,@0

	lds @0,sleepmode
	clr @0
	sts sleepmode,@0

	
	_INIT_SLEEP_CPU_EVENT @0
 .ENDMACRO

/************************************************
*Main point to request SLEEP
*Single task designated as MAIN TASK can fire it up
*One point/line of use for the whole app!!!!!!!!!!!!!!!!!
*Pre sleep and post sleep callbacks execute sleep related code - like disabling task's interrupt
*@INPUT: 0-> pre sleep callback to execute  
*	     1-> post sleep callback to execute	
         2-> temp register to be used
*@USAGE:
*		 Z
***********************************************/
 .MACRO _SLEEP_CPU_REQUEST	
	ldi ZL,low(@0)
	ldi ZH,high(@0)
	
	CPI16 ZL,ZH,temp,VOID_CALLBACK    ;empty callback -> skip
    breq prevoid
	icall
prevoid: 
	
	cli
	lds @2,sleepmode
	sbr @2,(1<<0)	;set counter to 1
	sts sleepmode,@2
	sei

	;loop until sleep is finished
macro_loop:
    _YIELD_TASK
					
	lds @2,sleepmode
	tst @2
	brne macro_loop    ;-> _SLEEP is expected to set to 0 counter x

	;post callback execute
	ldi ZL,low(@1)
	ldi ZH,high(@1)
	
	CPI16 ZL,ZH,temp,VOID_CALLBACK    ;empty callback -> skip
    breq postvoid
	icall

postvoid:
 .ENDMACRO

/************************************************
*Task to participate in a sleep.Pre sleep and post sleep callbacks
* execute sleep related code - like disabling task's interrupt
*@INPUT: 0-> pre sleep callback to execute  
*	     1-> post sleep callback to execute	
         2-> temp register to be used		 
*@USAGE:
*		 Z
***********************************************/
 .MACRO _SLEEP_CPU_READY
    //check if sleep is requested
	lds @2,sleepmode
	tst @2
	breq endmacro

	
	ldi ZL,low(@0)
	ldi ZH,high(@0)
	
	CPI16 ZL,ZH,temp,VOID_CALLBACK    ;empty callback -> skip
    breq prevoid
	icall
prevoid: 
	
	
	;increament sleep task counter
	cli	
	lds @2,sleepmode
	inc @2	
	sts sleepmode,@2
	sei

	;loop until sleep is finished
macro_loop:
    _YIELD_TASK	
	lds @2,sleepmode
	tst @2
	brne macro_loop    ;-> _SLEEP is expected to set to 0 counter x

	;post callback execute
	ldi ZL,low(@1)
	ldi ZH,high(@1)
	
	CPI16 ZL,ZH,temp,VOID_CALLBACK    ;empty callback -> skip
    breq postvoid
	icall
postvoid:

endmacro:		
 .ENDMACRO


/************************************************
* Puts CPU in SLEEP IDLE mode
* Single place of call - usually in system task
*@INPUT: 0-> temp register  
*		 1-> temp register	
*************************************************/
 .MACRO _SLEEP_CPU

	lds @0,sleepmode	
	cpi @0,SLEEP_TASKS_REQUEST_NUMBER
	brne endmacro     ; still waiting for other tasks to request sleep

	
	_DISABLE_TASKSHEDUAL_TIMER

	in @0,MCUCR
	cbr @0,(1<<SM0)|(1<<SM1)|(1<<SM2)
	sbr @0,(1<<SE)       ;SM2=0;SM1=0;SM0=0=>IDLE MODE 
	out MCUCR,@0	

	_START_SLEEP_CPU_EVENT	@0,@1
		
	sleep
	
	;reset counter to 0
	cli		
	lds @0,sleepmode
	clr @0
	sts sleepmode,@0    
	_ENABLE_TASKSHEDUAL_TIMER		
	sei

	
    _STOP_SLEEP_CPU_EVENT @0
	

endmacro:
 .ENDMACRO


/************************************************
;Check if CPU is sleeping
;Called in INTERRUPT context
;@INPUT: 
0-> jump {YES}if sleeping
1-> jump {NO}to if NOT sleeping
2-> temp reg
*************************************************/
.MACRO _IS_CPU_SLEEPING
	lds @2,sleepmode		
	tst @2
	brne @0
	rjmp @1
.ENDMACRO
/************************************************
;Hardware and context dependent
;@INPUT 0-> temp reg
*************************************************/
.MACRO _INIT_SLEEP_CPU_EVENT
    in @0,TCCR1B
	sbr @0,(1<CS10)|(1<<CS12)     ;1/1024
	out TCCR1B,@0
.ENDMACRO

/************************************************
;Hardware and context dependent
;@INPUT 0-> temp reg
;		1-> temp reg
************************************************/
.MACRO _START_SLEEP_CPU_EVENT
;set value
	ldi @1,0x00					;3sec at 8MHz , 1/1024 resolution
	ldi @0,0x00
	out TCNT1H,@1
	out TCNT1L,@0
;start
	in @0,TIMSK
	sbr @0,(1<<TOIE1)
	out TIMSK,@0
.ENDMACRO 

/************************************************
;Hardware and context dependent
;@INPUT 0-> temp reg
************************************************/
.MACRO _STOP_SLEEP_CPU_EVENT
	in @0,TIMSK
	cbr @0,(1<<TOIE1)
	out TIMSK,@0
.ENDMACRO 
