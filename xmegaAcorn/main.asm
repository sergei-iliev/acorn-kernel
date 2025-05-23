;
; xmega-kernel_2.0.asm
;
; Created: 4/11/2025 3:41:43 PM
; Author : Sergey Iliev
;

.include "kernel/interrupt.inc" 
.include "kernel/kernel.inc"
.include "kernel/hardware.inc"

.cseg
RESET:
		_keBOOT
	
	_REGISTER_TASK_STACK blink_led_task,100
	_REGISTER_TASK_STACK button_task,100	
	_REGISTER_TASK tft_lcd_task   
	_REGISTER_TASK usart_D_task 

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



.include "tasks/blink_led_task.asm"
.include "tasks/tft_lcd_task.asm"
.include "tasks/button_task.asm"
.include "tasks/usart_D_task.asm"

.EXIT
    
