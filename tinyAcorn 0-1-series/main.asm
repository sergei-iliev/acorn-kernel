;
; tiny-acorn.asm
;
; Created: 11/10/2023 5:50:21 PM
; Author : Sergey Iliev
;


.include "kernel/interrupt.inc" 
.include "kernel/hardware.inc" 
.include "kernel/kernel.inc" 

.cseg

RESET:    
	_keBOOT
		
	_REGISTER_TASK_STACK Task_1,60 
	_REGISTER_TASK_STACK Task_2,60 
	_REGISTER_TASK_STACK usart_task,50
	_REGISTER_TASK_STACK rtc_task,50
	

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

_RETI

SystemTickInt:  	 
  _PRE_INTERRUPT   
  
  ;clear int flag AVR 0 1 series only
  _CLEAR_TIMER_INT_FLAG
  #ifdef TASK_SLEEP_EXT
  _kePROCESS_SLEEP_INTERVAL_EXT	
  #else
  _kePROCESS_SLEEP_INTERVAL	
  #endif

  _POST_INTERRUPT
rjmp TaskSchedular

.include "include/but_press_task.asm"
.include "include/blink_led_task.asm"
.include "include/usart_task.asm"
.include "include/rtc_task.asm"

.EXIT

