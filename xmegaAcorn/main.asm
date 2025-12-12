

.include "kernel/interrupt.inc" 
.include "kernel/kernel.inc"
.include "kernel/hardware.inc"

.cseg
RESET:
	_keBOOT
	
	_REGISTER_TASK_STACK usart_D_task,100	
	_REGISTER_TASK tft_lcd_task   
	_REGISTER_TASK lcd_task 

;initialize current task pointer with Task #1
	_keSTART_SCHEDULAR

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

_RETI

SystemTickInt:  	 
  _PRE_INTERRUPT   
   
  _kePROCESS_SLEEP_INTERVAL	
  
  _POST_INTERRUPT
rjmp TaskSchedular


.include "kernel/single-producer-consumer.asm"
.include "tasks/usart_producer_task.asm"
.include "tasks/tft_lcd_task.asm"
.include "tasks/lcd_task.asm"


.EXIT
    
