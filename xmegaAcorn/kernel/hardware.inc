;Include all CPU hardware dependancies regarding the ACORN kernel 
;When the kernel is used for onather AVR CPU make sure timers are properly defined here

;Timer0 TCC0
;Provides the timing for task scheduling

;Executed during kernel init - no task context defined yet executed in BOOT sequence no interrupt possible
.MACRO _INIT_TASKSHEDUAL_TIMER
;1.set period
	ldi temp,low(0x10)
	ldi r17,high(0x10)
	;cli
	sts 0x826,r16
	sts 0x827,r17
	;sei

;2. set clock source
	lds temp,TCC0_CTRLA
	ori temp,RTC_PRESCALER_DIV1024_gc
	sts TCC0_CTRLA,temp
.ENDMACRO

;Executed in the LIMBO state or during CPU init - no context defined
;Use any register
.MACRO _ENABLE_TASKSHEDUAL_TIMER
    lds temp,TCC0_INTCTRLA
	ori temp,TC_OVFINTLVL_LO_gc			;assign to LOW level
	sts TCC0_INTCTRLA,temp

.ENDMACRO

;Executed in the LIMBO state or CPU init - no context defined
;Use any register
.MACRO _DISABLE_TASKSHEDUAL_TIMER
    lds temp,TCC0_INTCTRLA
	cbr temp,TC_OVFINTLVL_LO_gc			;unassign to LOW level
	sts TCC0_INTCTRLA,temp
.ENDMACRO

;Fills up the timer in order to provoke time overflow interrupt and activate scheduler.
;Context is defined so use a register as a parameter. 
;INPUT: @0 - register to use
;.MACRO _SET_TASKSHEDUAL_TIMER
;	ldi @0,0xFF
;	out TCNT0,@0 
;.ENDMACRO


