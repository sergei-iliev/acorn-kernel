 /*
SLEEP mode.
Integrating SLEEP mode in a multitasking kernel is a bit tricky by itself.
Task(s) could either be I/O bound or algorithm bound which may require to finish
before the sleep command is carried out so SLEEP mode must be coordinated with the rest of the tasks 
It may be  required that some/all interrupt processing tasks need to know when a
sleep mode is about to begin so that they could finish/turn off unnessesary interrupt 
activity.
Current sleep implementation is based on
1.SLEEP is NOT possible in high DEVICE level.
2.SLEEP is NOT possible in tasks Intr dispatch handler code aka in between _INTERRUPT_WAIT and _INTERRUPT_END macros
3.SLEEP is executed in USER level from a single task in coordination with other tasks 
*/

 /*
 *SLEEP structure 
 *  |y|0|0|0|x|x|x|x|
 *  y -> set by SLEEP responsible task to 1 if sleep is needed
 *  x -> count number of tasks ready to sleep (up to 16)
 *  If x=SLEEP_TASKS_REQUEST_NUMBER all tasks are ready to sleep , fire SLEEP instruction
 */	


 .SET VOID_CALLBACK=0
 .SET CPU_SLEEP_BIT=7
 .dseg
	sleepmode: .byte 1
 .cseg
 
  /********************************************
  *Initialization routine
  *Called in init routine of the task before other task main loop execution
  *@INPUT: 0-> temp register
  *********************************************/

 .MACRO _SLEEP_INIT
   lds @0,SLPCTRL_CTRLA
   ori @0,SLPCTRL_SMODE_IDLE_gc | SLPCTRL_SEN_bm
   sts SLPCTRL_CTRLA,@0
 .ENDMACRO
 
/************************************************
*Task to initiate sleep - single LEADER task calls it
*@INPUT: 0-> temp reg  		 
*@WARNING: must not be called in Interrupt Dispather handler code 
           
		   _INTERRUPT_WAIT x
		   _SLEEP_CPU   NOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO!DON'T DO THIS
		   _INTERRUPT_END x
***********************************************/
 .MACRO _SLEEP_CPU
	//notify of sleep interest
	lds @0,sleepmode
	clr @0	
	sbr @0,1<<CPU_SLEEP_BIT
	sts sleepmode,@0

sleep_wait:
    _YIELD_TASK
	lds @0,sleepmode
    andi @0,0x0F          ;low nibble holds counter	    
	cpi @0,SLEEP_TASKS_REQUEST_NUMBER
	brlo sleep_wait


;all task ready for sleep 
    _DISABLE_TASKSHEDUAL_TIMER @0

	sleep
;reset
	cli
	lds @0,sleepmode
	clr @0		
	sts sleepmode,@0

	_ENABLE_TASKSHEDUAL_TIMER @0
	sei

 endmacro:
 .ENDMACRO
 


 /************************************************
*Tasks to participate and coordinate their work in a sleep - many tasks calls it
 Pre sleep and post sleep callbacks execute sleep related code - like disabling task's own interrupt
 @INPUT: 0 -> pre sleep callback to execute
           1 -> post callback to execute
		   2 -> temp reg 
 @USAGE: Z           
*/
 .MACRO _SLEEP_CPU_TASK
	lds @2,sleepmode
	sbrs @2,CPU_SLEEP_BIT
	rjmp endmacro

;sleep is requested
;1. run callback
    ldi ZL,low(@0)
	ldi ZH,high(@0)
    CPI16 ZL,ZH,temp,VOID_CALLBACK
	breq skipprecall  
	icall 

 skipprecall:

;2.increment counter
	cli 
	lds @2,sleepmode
	andi @2,0x0F          ;low nibble holds counter	    
	inc @2
	ori @2,0b10000000     ;restore sleep flag
    sts sleepmode,@2
	sei
;3 loop until sleep is over
wait:  
   _YIELD_TASK
   lds @2,sleepmode
   sbrc @2,CPU_SLEEP_BIT
   rjmp wait

;4. run callback
    ldi ZL,low(@1)
	ldi ZH,high(@1)
    CPI16 ZL,ZH,temp,VOID_CALLBACK
	breq skippostcall  
	icall 

 skippostcall:
    
 endmacro:
 .ENDMACRO
/************************************************
*Test if SLEEP_CPU is requested
@INPUT:
0->jump if SLEEPING reuested
1->temp reg to use
************************************************/

  .MACRO _IS_SLEEP_CPU_REQUESTED
  	lds @1,sleepmode		
	sbrc @1,CPU_SLEEP_BIT
	rjmp @0
  .ENDMACRO