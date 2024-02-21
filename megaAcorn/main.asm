.include "kernel/interrupt.inc" 
.include "kernel/kernel.inc"
.include "kernel/hardware.inc"


.include "tasks.asm"
.cseg
RESET:	

	_keBOOT

	_REGISTER_TASK task1,163

	_REGISTER_TASK task2,100

	_REGISTER_TASK task3,100
	//_REGISTER_TASK_STACK Task_2,100  

	//_REGISTER_TASK rs232_ch1_task  

	//_REGISTER_TASK_STACK Test_Event_Queue16_Push_Task,100

	//_REGISTER_TASK_STACK Test_Event_Queue16_Pull_Task,100

	//_REGISTER_TASK Test_Event_Queue_Task,100

	//_REGISTER_TASK_STACK DS1307_Test_polling_Task,4,63

	//_REGISTER_TASK_STACK DS1307_Test_interrupt_Task,4,63

	

;initialize current task pointer with Task #1
	_START_SCHEDULAR



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

