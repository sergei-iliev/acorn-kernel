;sergei_iliev@yahoo.com
;Ask questions or give ideas!!!

.include "tn26def.inc"
.include "16bitMath.inc"
.include "Kernel.inc"


.include "INTERRUPTS.inc" 

.cseg
.def    temp=r16    ;temp reg.

.include "HARDWARE.inc"

RESET:     
    /*RAM is up to 256 bytes*/ 
    ldi     temp,low(RAMEND)
    out     SP,temp

           
;clear SRAM
	ldi XL,low(RAMEND+1)
	ldi XH,high(RAMEND+1)    		   
    clr r0
initos:
	st -X,r0
	cpi XH,high(SRAM_START) 
    brne initos
    cpi XL,low(SRAM_START)
	brne initos
	 
;****************init Task_1
	.IFDEF THREAD_1
	_REGISTER_TASK Task_1,1,TCB_1 
    .ENDIF
;********************init Task_2
    .IFDEF THREAD_2
	_REGISTER_TASK Task_2,2,TCB_2 
	.ENDIF
;********************init Task_2
    .IFDEF THREAD_3
	_REGISTER_TASK Task_3,3,TCB_3 
	.ENDIF

;set up Timer0
    _INIT_TASKSHEDUAL_TIMER


;start Timer0(Schedualing)	
	_ENABLE_TASKSHEDUAL_TIMER

;initialize current task pointer with Task_1
    ldi XL,low(TCB_1) 
	
	sts pxCurrentTCB,XL

	sei      

  
.include "Tasks.asm"


DispatchDPCExtension:
	      ;restore temp and SREG to its task's context value
	_POST_INTERRUPT

TaskSchedular:

	_keOS_SAVE_CONTEXT
	 
;start LIMBO state 

;    _DISABLE_TASKSHEDUAL_TIMER
    
   _keSWITCH_TASK
;	_ENABLE_TASKSHEDUAL_TIMER

;end LIMBO state
	_keOS_RESTORE_CONTEXT

reti


SystemTickInt:
  _PRE_INTERRUPT   
   
  _kePROCESS_SLEEP_INTERVAL	
	  
  _POST_INTERRUPT
rjmp TaskSchedular


.EXIT



