;sergei_iliev@yahoo.com
;Ask questions or give ideas!!!


.include "kernel/interrupt.inc" 
.include "kernel/kernel.inc"
.include "kernel/hardware.inc"


.cseg
.include "tasks.asm"

; Replace with your application code
RESET:
	_keBOOT
    
	_REGISTER_TASK_STACK Task_1,34 
	
	_REGISTER_TASK_STACK Task_2,34 

	_REGISTER_TASK_STACK Task_3,34 
	
    _START_SCHEDULAR Task_1




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








