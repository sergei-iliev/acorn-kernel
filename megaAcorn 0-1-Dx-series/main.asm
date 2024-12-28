;
; mega-kernel_2.0.asm
;
; Created: 11/6/2024 4:33:22 PM
; Author : Sergey Iliev
;
.include "kernel/interrupt.inc" 
.include "kernel/hardware.inc" 
.include "kernel/kernel.inc"

; Replace with your application code

.cseg
RESET:
	_keBOOT
	_REGISTER_TASK_STACK blink_led_task,60 
	_REGISTER_TASK_STACK usart_producer_task,50
	_REGISTER_TASK_STACK button_press_event_system_task,50
	_REGISTER_TASK_STACK oled_sh1107_task,100	

	_keSTART_SCHEDULAR
;never get here



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


.include "tasks/blink_led_task.asm"
.include "tasks/usart_producer_task.asm"
.include "tasks/button_press_event_system_task.asm"
.include "tasks/oled_sh1107_task.asm"


.EXIT
