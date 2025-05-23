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

/*
Clock Controller init
*/
.MACRO _INIT_CLOCK_CONTROLLER
    ldi temp,CCP_IOREG_gc		// disable register security for oscillator update
	out CPU_CCP,temp
	ldi temp,OSC_RC32MEN_bm		// enable 32MHz oscillator
	sts OSC_CTRL,temp 
osc_ready:						// wait for oscillator to be ready
	lds temp,OSC_STATUS
	sbrs temp,OSC_RC32MRDY_bp
	rjmp osc_ready

	ldi temp,CCP_IOREG_gc		// disable register security for clock update
	out CPU_CCP,temp
	
	ldi temp,CLK_SCLKSEL_RC32M_gc	// switch to 32MHz clock
	sts CLK_CTRL,temp 

.ENDMACRO


/*
Interrupt Controller init
*/
.MACRO _INIT_INTERRUPT_CONTROLLER
	lds temp,PMIC_CTRL
	ori temp,PMIC_LOLVLEN_bm
	sts PMIC_CTRL,temp
.ENDMACRO
