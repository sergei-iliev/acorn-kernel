;Include all CPU hardware dependancies regarding the ACORN kernel 
;When the kernel is used for onather AVR CPU make sure timers are properly defined here

;Timer0
;Provides the timing for task scheduling

;Executed during kernel init - no task context defined yet
.MACRO _INIT_TASKSHEDUAL_TIMER
	ldi temp,(1<<CS01)  ;preskaler 1/8 ;clock on every 0.5ms     
	out TCCR0,temp
.ENDMACRO

;Executed in the LIMBO state or during CPU init - no context defined
;Use any register
.MACRO _ENABLE_TASKSHEDUAL_TIMER
     in temp,TIMSK
	 sbr temp,(1<<TOIE0)
     out TIMSK,temp
     clr temp
     out TCNT0,temp  
.ENDMACRO

;Executed in the LIMBO state or CPU init - no context defined
;Use any register
.MACRO _DISABLE_TASKSHEDUAL_TIMER
     in temp,TIMSK
	 cbr temp,(1<<TOIE0)
     out TIMSK,temp
.ENDMACRO

;Fills up the timer in order to provoke time overflow interrupt and activate scheduler.
;Context is defined so use a register as a parameter. 
;INPUT: @0 - register to use
.MACRO _SET_TASKSHEDUAL_TIMER
	ldi @0,0xFF
	out TCNT0,@0 
.ENDMACRO
