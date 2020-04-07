/*
 * hc05prog.asm
 *
 */ 

.include "m2560def.inc"
.include "INTERRUPTS.inc" 
.include "Kernel.inc"

.include "HARDWARE.inc"
.cseg

RESET:
    ;One rcall depth for the stack during system init 
	ldi     temp,high(RAMEND-3)        ;Set stack pointer to bottom of RAM-3 for system init
    out     SPH,temp
    ldi     temp,low(RAMEND-3)
    out     SPL,temp
     	       
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

	_REGISTER_TASK_STACK System_Task,1,46

	_REGISTER_TASK_STACK Task_UART,2,60
	  
	_REGISTER_TASK_STACK Task_3,3,50


;set up Timer0
    _INIT_TASKSHEDUAL_TIMER
;start timers

;start Timer0(Schedualing and time ticking)	
	_ENABLE_TASKSHEDUAL_TIMER


;initialize current task pointer with Task_1
	ldi     temp,high(RAMEND)
    out     SPH,temp
    ldi     temp,low(RAMEND)
    out     SPL,temp

    ldi XL,low(TCB_1) 
	
	sts pxCurrentTCB,XL
	
	sei  
//***curent stack pointer is at the begining of Task_1
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


;.dseg
;stacksize: .byte TASK_STACK_DEPTH*TASKS_NUMBER 
;.cseg


.EXIT