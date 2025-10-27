

/*Interrupt dispatch vector index demo task*/

#define BUTTON_PRESS_UPDOWN_PORTD_ID 6

/*dummy task no reason to exists just keeps the core running*/
button_task:
	rcall port_configure_int1
	
	_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER
	_INTERRUPT_DISPATCHER_INIT temp,BUTTON_PRESS_UPDOWN_PORTD_ID
		
	

button_main:
 	_INTERRUPT_WAIT BUTTON_PRESS_UPDOWN_PORTD_ID	  

		rcall send_sbyte

		ldi temp,1<<BLINK_LED		
		sts PORTB_OUTTGL,temp

	_INTERRUPT_END BUTTON_PRESS_UPDOWN_PORTD_ID
	
   
rjmp button_main



send_ubyte:
    ldi argument,132
	rcall usart_send_byte_d
ret

send_sbyte:
    ldi argument,1				;NOT SENDING ZERO!!!!!!!!!!!!!
	rcall usart_send_byte_d

ret

send_sword:
	ldi argument,high(100)
	rcall usart_send_byte_d

	ldi argument,low(100)
	rcall usart_send_byte_d

ret


send_uword:
	ldi argument,high(10013)
	rcall usart_send_byte_d

	ldi argument,low(10013)
	rcall usart_send_byte_d

ret


;******configure PORTE.1 connected to BUT2
port_configure_int1:
cli
	sbr r17,PORT_OPC_TOTEM_gc|PORT_ISC_RISING_gc
	
	ldi temp,(1<<1)
	sts PORTCFG_MPCMASK,temp

	sts PORTE_PIN1CTRL, r17

	;set pin as input
	sts PORTE_DIRCLR,temp

    ; Configure Interrupt1 to have low interrupt level, triggered by pin 1 	
	lds r17,PORTE_INTCTRL
	ori r17,PORT_INT1LVL_LO_gc
	sts PORTE_INTCTRL,r17

	ldi r17,1<<1
	sts PORTE_INT1MASK,r17
	
sei
ret


;PORTE.1
porte_int1:
 _PRE_INTERRUPT
	
 _keDISPATCH_DPC BUTTON_PRESS_UPDOWN_PORTD_ID

.EXIT