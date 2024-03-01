; Tiny acorn micro kernel - series 0/1
; Author : Sergey Iliev
;


.include "kernel/interrupt.inc" 
.include "kernel/hardware.inc" 
.include "kernel/kernel.inc" 

.cseg

RESET:    
	_keBOOT
		
	_REGISTER_TASK_STACK button_press_task,60 
	_REGISTER_TASK_STACK task_2,60 
	_REGISTER_TASK_STACK usart_task,50
	_REGISTER_TASK_STACK rtc_task,50
	

	_START_SCHEDULAR temp



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
  
  ;clear int flag AVR 0 1 series only
  _CLEAR_TIMER_INT_FLAG

  _kePROCESS_SLEEP_INTERVAL


  _POST_INTERRUPT
rjmp TaskSchedular

.include "tasks/but_press_task.asm"
.include "tasks/blink_led_task.asm"
.include "tasks/usart_task.asm"
.include "tasks/rtc_task.asm"

.EXIT


