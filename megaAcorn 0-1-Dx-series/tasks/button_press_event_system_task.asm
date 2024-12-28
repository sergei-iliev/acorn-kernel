
;Button debounce using EVENT SYSTEM

button_press_event_system_task:
  //---setup LED pin on PA4
    lds temp,PORTA_DIR
    sbr temp,1<<PIN4
    sts PORTA_DIR,temp
	cli
	rcall init_event_system
	sei
   	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER

main_evsys:


rjmp main_evsys


init_event_system:
  ;input
   lds temp,PORTC_DIR
   cbr temp,(1<<PIN0)	;PORT_INT0_bp
   sts PORTC_DIR,temp
   
   lds temp, PORTC_PIN0CTRL
   sbr temp, 1<<PORT_PULLUPEN_bp
   sts PORTC_PIN0CTRL,temp
  
  ;EVENT SYS
  lds temp, EVSYS_CHANNEL3
  ori temp,EVSYS_CHANNEL3_PORTC_PIN0_gc
  sts EVSYS_CHANNEL3,temp

  lds temp,EVSYS_USERTCB0CAPT 
  ori temp, EVSYS_USER_CHANNEL3_gc
  sts EVSYS_USERTCB0CAPT,temp

  ;TIMER
   	ldi temp,low(0xFFFF)
	ldi r17,high(0xFFFF)
    
	sts TCB0_CCMPL,temp
	sts TCB0_CCMPH,r17
	
	
	lds temp,TCB0_CTRLB 
	ori temp, TCB_CNTMODE_SINGLE_gc
	sts TCB0_CTRLB,temp 
	
	lds temp,TCB0_EVCTRL
	ori temp,TCB_CAPTEI_bm | TCB_EDGE_bm
	sts TCB0_EVCTRL,temp
    
	lds temp,TCB0_CTRLA
	ori temp,TCB_CLKSEL_1_bm | TCB_ENABLE_bm
	sts TCB0_CTRLA,temp

   	ldi temp,low(0xFFFF)
	ldi r17,high(0xFFFF)
    
	sts TCB0_CNTL,temp
	sts TCB0_CNTH,r17
	

	lds temp,TCB0_INTCTRL
	ori temp, TCB_CAPT_bm
	sts TCB0_INTCTRL,temp
ret


TCB0_Intr:
_PRE_INTERRUPT
	;clear intr
	lds temp,TCB0_INTFLAGS
	ori temp, TCB_CAPT_bm
	sts TCB0_INTFLAGS,temp

	;LED toggle
	lds temp,PORTA_OUTTGL
    sbr temp,1<<PIN4
    sts PORTA_OUTTGL,temp	 

_POST_INTERRUPT
_RETI

.EXIT


