;sergei_iliev@yahoo.com
;Ask questions or give ideas!!!

.include "tn26def.inc"
.include "16bitMath.inc"


.include "INTERRUPTS.inc" 
.include "Kernel.inc"

.cseg
.def    temp=r16    ;temp reg.

.include "HARDWARE.inc"

RESET:     
    /*RAM is up to 256 bytes*/ 
    ldi     temp,low(RAMEND-2)
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
	 

	_REGISTER_TASK_STACK Task_1,1,34  
	_REGISTER_TASK_STACK Task_2,2,39 
	_REGISTER_TASK_STACK Task_3,3,39  




_START_SCHEDULAR Task_1

.include "Tasks.asm"

DispatchDPCExtension:

TaskSchedular:

;is schedular suspended?    
	_keSKIP_SWITCH_TASK task_switch_disabled

	_keOS_SAVE_CONTEXT
;start LIMBO state 
    
	_keSWITCH_TASK

;end LIMBO state
	_keOS_RESTORE_CONTEXT

task_switch_disabled:         ;no task switching

reti

SystemTickInt:
  _PRE_INTERRUPT   
   
  _kePROCESS_SLEEP_INTERVAL	
  
  _POST_INTERRUPT
rjmp TaskSchedular

.EXIT



