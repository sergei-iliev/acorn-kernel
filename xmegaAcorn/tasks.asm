

task1:
	_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER
	_SLEEP_TASK 255
	_SLEEP_TASK 255
	/* Configure PC0 as input, triggered on rising edge. */
	rcall port_configure_int0
	
main1:
	nop
	 
	nop
rjmp main1


task2:
	LDI temp,0x0F		
    STS PORTA_DIR,temp	
	_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER
main2:
	_SLEEP_TASK 255
	_SLEEP_TASK 255
	_SLEEP_TASK 255

	LDI temp,0x02		
    STS PORTA_OUTSET,temp		
	

	_SLEEP_TASK 255
	_SLEEP_TASK 255
	_SLEEP_TASK 255

    LDI temp,0x02		
    STS PORTA_OUTCLR,temp	

rjmp main2





.SET INT1 = 7
task3:
	_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER
	_SLEEP_TASK 255
	_SLEEP_TASK 255


	_INTERRUPT_DISPATCHER_INIT temp,INT1
	/* Configure PC1 as input, triggered on rising edge. */
	rcall port_configure_int1
main3:
    
	_INTERRUPT_WAIT INT1
	    LDI temp,1<<2		
	    STS PORTA_OUTTGL,temp	
	_INTERRUPT_END	INT1

rjmp main3

/*
TCC1
*/
.SET INT2 = 6
task4:
	_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER
	
	_INTERRUPT_DISPATCHER_INIT temp,INT2
;1.set period
	ldi temp,low(0x1000)
	ldi r17,high(0x1000)
	cli
	sts 0x866,r16
	sts 0x867,r17
	sei

;2. set clock source
	lds temp,TCC1_CTRLA
	ori temp,RTC_PRESCALER_DIV1024_gc
	sts TCC1_CTRLA,temp	

;3. enable timer	
    lds temp,TCC1_INTCTRLA
	ori temp,TC_OVFINTLVL_LO_gc			;assign to LOW level
	sts TCC1_INTCTRLA,temp
main4:
    
	_INTERRUPT_WAIT INT2
	    LDI temp,1<<3		
	    STS PORTA_OUTTGL,temp	
	_INTERRUPT_END	INT2

rjmp main4

;******configure PORTE.0
port_configure_int0:
cli
	sbr r17,PORT_OPC_TOTEM_gc|PORT_ISC_RISING_gc
	
	ldi temp,0x01
	sts PORTCFG_MPCMASK,temp

	sts PORTE_PIN0CTRL, r17

	;set pin as input
	sts PORTE_DIRCLR,temp

    ; Configure Interrupt0 to have low interrupt level, triggered by pin 0. 	
	lds r17,PORTE_INTCTRL
	ori r17,PORT_INT0LVL_LO_gc
	sts PORTE_INTCTRL,r17

	ldi r17,0x01
	sts PORTE_INT0MASK,r17


	; Enable medium level interrupts in the PMIC. 
	
	lds temp,PMIC_CTRL
	ori temp,PMIC_MEDLVLEN_bm
	sts PMIC_CTRL,temp
sei
ret

;******configure PORTE.2
port_configure_int1:
cli
	sbr r17,PORT_OPC_TOTEM_gc|PORT_ISC_RISING_gc
	
	ldi temp,(1<<1)
	sts PORTCFG_MPCMASK,temp

	sts PORTE_PIN1CTRL, r17

	;set pin as input
	sts PORTE_DIRCLR,temp

    ; Configure Interrupt1 to have low interrupt level, triggered by pin 0. 	
	lds r17,PORTE_INTCTRL
	ori r17,PORT_INT1LVL_LO_gc
	sts PORTE_INTCTRL,r17

	ldi r17,1<<1
	sts PORTE_INT1MASK,r17


	; Enable medium level interrupts in the PMIC. 
	
	lds temp,PMIC_CTRL
	ori temp,PMIC_MEDLVLEN_bm
	sts PMIC_CTRL,temp
sei
ret

;PORTE.0
porte_int0:
_PRE_INTERRUPT
    LDI temp,1<<0		
    STS PORTA_OUTTGL,temp	
_POST_INTERRUPT
_RETI


;PORTE.1
;porte_int1:
;_PRE_INTERRUPT
;    LDI temp,1<<2		
;    STS PORTA_OUTTGL,temp	
;_POST_INTERRUPT
;_RETI

;PORTE.1
porte_int1:
  _PRE_INTERRUPT

 _keDISPATCH_DPC INT1


TCC1Int:
  _PRE_INTERRUPT
  
 _keDISPATCH_DPC INT2


.EXIT