;
; xmega-kernel.asm
;
; Created: 3/29/2022 11:55:18 AM
; Author : Sergey Iliev
;

.include "kernel/interrupt.inc" 
.include "kernel/kernel.inc"
.include "kernel/hardware.inc"

.cseg
.include "tasks.asm"
RESET:
	_keBOOT
	
	_REGISTER_TASK task1
	_REGISTER_TASK_STACK task2,220
	_REGISTER_TASK task3
	_REGISTER_TASK task4

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

_RETI

SystemTickInt:  	 
  _PRE_INTERRUPT   
   
  _kePROCESS_SLEEP_INTERVAL	
  
  _POST_INTERRUPT
rjmp TaskSchedular


/*

; Replace with your application code
main:
	ldi     r16,high(RAMEND)        ;Set stack pointer to bottom of RAM-2 for system init
    out     CPU_SPH,r16
    ldi     r16,low(RAMEND)
    out     CPU_SPL,r16
	//select vector table
    rcall set_vector_application_location

	//select internal clock
	rcall select_32mhz

	rcall enable_low_level
	rcall enable_medium_level
	rcall enable_high_level
	
	ldi r16,0
	sts PORTF_DIR,r16   ;input dir

	ldi r16,0x0F
	sts PORTF_INT0MASK,r16  ;INT0 source

	ldi r16,0x0B    ;high level interrupt
	sts PORTF_INTCTRL,r16

	ldi r16,0x0F
	sts PORTCFG_MPCMASK,r16 ;config simultaniously

	ldi r16,0x02
	sts PORTF_PIN0CTRL,r16   ;int on falling edge


	sei

	;-----set up interrupt vectors in app area
	//lds r16,PMIC_CTRL
	//sbr r16,1<<PMIC_IVSEL_bp
	
	//ldi r17,CCP_IOREG_gc
	//out CPU_CCP,r17

	//sts PMIC_CTRL,r16
	;------------


loop:	
	nop
    rjmp loop

;set vector location to app area
set_vector_application_location:
	lds r17,PMIC_CTRL
	ori r17,PMIC_IVSEL_bm

	ldi r16, CCP_IOREG_gc
	out CPU_CCP, r16      // CCP = CCP_IOREG_gc;

	sts PMIC_CTRL,r17
	
ret

enable_low_level:
 	lds r17,PMIC_CTRL
	ori r17,PMIC_LOLVLEN_bm

	ldi r16, CCP_IOREG_gc
	out CPU_CCP, r16      // CCP = CCP_IOREG_gc;

	sts PMIC_CTRL,r17
ret

enable_medium_level:
	lds r17,PMIC_CTRL
	ori r17,PMIC_MEDLVLEN_bm

	ldi r16, CCP_IOREG_gc
	out CPU_CCP, r16      // CCP = CCP_IOREG_gc;

	sts PMIC_CTRL,r17
ret
 
enable_high_level:
	lds r17,PMIC_CTRL
	ori r17,PMIC_HILVLEN_bm

	ldi r16, CCP_IOREG_gc
	out CPU_CCP, r16      // CCP = CCP_IOREG_gc;

	sts PMIC_CTRL,r17
ret

;setting internal oscilator to 32MHz
select_32mhz:
	ldi r16, CCP_IOREG_gc
	out CPU_CCP, r16      // CCP = CCP_IOREG_gc;

	ldi r16, OSC_RC32MEN_bm
    sts OSC_CTRL, r16       // OSC.CTRL = OSC_RC32MEN_bm;

s32mclk:
    lds       r16, OSC_STATUS
    sbrs      r16, 1
    rjmp      s32mclk

	ldi r16, CCP_IOREG_gc
    out CPU_CCP, r16      // CCP = CCP_IOREG_gc;

	ldi   r16, CLK_SCLKSEL_RC32M_gc
    sts   CLK_CTRL, r16  // CLK.CTRL = CLK_SCLKSEL_RC32M_gc;
ret

PORTF_INT0_handler:
	nop
	nop
reti

*/