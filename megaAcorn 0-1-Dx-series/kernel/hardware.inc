;Include all CPU hardware dependancies regarding the ACORN kernel 
;When the kernel is used for onather AVR CPU make sure timers are properly defined here

;Timer TCA
;Provides the timing for task scheduling

;Executed during kernel init - no task context defined yet executed in BOOT sequence no interrupt possible
.MACRO _INIT_TASKSHEDUAL_TIMER
;Setting the corresponding bit in the Interrupt Control register enables the overflow interrupt of TCA
    ldi temp, TCA_SINGLE_OVF_bm
	sts TCA0_SINGLE_INTCTRL,temp

;no waveform must be generated, so the Waveform Generation bit
	ldi temp,TCA_SINGLE_WGMODE_NORMAL_gc
	sts TCA0_SINGLE_CTRLB,temp
	
	lds temp,TCA0_SINGLE_EVCTRL
	cbr temp,(1<<TCA_SINGLE_CNTAEI_bp)
	sts TCA0_SINGLE_EVCTRL,temp

	ldi temp,low(0x10)
	ldi r17,high(0x10)
	;cli
	sts TCA0_SINGLE_PER,r16
	sts TCA0_SINGLE_PER+1,r17
	;sei

;set clock source
	lds temp,TCA0_SINGLE_CTRLA
	ori temp,TCA_SINGLE_CLKSEL_DIV64_gc
	sts TCA0_SINGLE_CTRLA,temp
.ENDMACRO


.MACRO _ENABLE_TASKSHEDUAL_TIMER
    lds @0,TCA0_SINGLE_CTRLA
	sbr @0,1<<TCA_SINGLE_ENABLE_bp
	sts TCA0_SINGLE_CTRLA,@0
.ENDMACRO


.MACRO _DISABLE_TASKSHEDUAL_TIMER
    lds @0,TCA0_SINGLE_CTRLA
	cbr @0,1<<TCA_SINGLE_ENABLE_bp
	sts TCA0_SINGLE_CTRLA,@0
.ENDMACRO

.MACRO _CLEAR_TIMER_INT_FLAG
    lds temp,TCA0_SINGLE_INTFLAGS
	sbr temp,1<<TCA_SINGLE_OVF_bp
	sts TCA0_SINGLE_INTFLAGS,temp

.ENDMACRO
/*
Clock Controller init
*/
.MACRO _INIT_CLOCK_CONTROLLER
    ldi temp,CPU_CCP_IOREG_gc		// disable register security for oscillator update	   
	out CPU_CCP,temp
	
	ldi temp,FUSE_CLKSEL_OSCHF_gc		//enable internal oscillator
	sts CLKCTRL_MCLKCTRLA,temp

    ldi temp,CPU_CCP_IOREG_gc		// disable register security for oscillator update	   
	out CPU_CCP,temp

	ldi temp,CLKCTRL_FRQSEL_24M_gc		//enable 24MHz oscillator
	sts CLKCTRL_OSCHFCTRLA,temp

    ldi temp,CPU_CCP_IOREG_gc		// disable register security for oscillator update	   
	out CPU_CCP,temp
	
	ldi temp,0<<CLKCTRL_PEN_bp		// disable divider full blown 24Mhz
	sts CLKCTRL_MCLKCTRLB,temp    
	
	//wait until oscilator staberlizes
	osc_ready:

	lds temp,CLKCTRL_MCLKSTATUS
	sbrs temp,CLKCTRL_OSCHFS_bp  
	rjmp osc_ready

.ENDMACRO

/*
Interrupt Controller init
*/
.MACRO _INIT_INTERRUPT_CONTROLLER
    ldi temp,CPU_CCP_IOREG_gc		// disable register security for interrupt register update
	out CPU_CCP,temp

	lds temp,CPUINT_CTRLA
	cbr temp,1<<CPUINT_LVL0RR_bp   ;disable round robin
.ENDMACRO