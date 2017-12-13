
.include "include/rs232op.asm"

.def    argument=r17  
.def    return = r18
.def    axl=r19
.def    axh=r20

.def	bxl=r21
.def    bxh=r22
	

	#define UBRR_VAL	51	;s600



.SET RTXF=6

.SET STATUS_VOID=0
.SET STATUS_RX=1
.SET STATUS_TX=2
.SET STATUS_ERROR=3

.dseg

rsdata:  .byte 5

DEBUG_BYTE: .byte 1

TxRxByte: .byte 1
TxRxStatus: .byte 1
.cseg

;****RS232 task

Task_5:
   	sbi DDRB,PORTB0
	sbi PORTB,PORTB0

   ;reset status
	ldi temp,STATUS_VOID
	sts TxRxStatus,temp


	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

	_INTERRUPT_DISPATCHER_INIT temp,RTXF	  

;clear ax pointer
	clr axh
	clr axl

	rcall usart_init 
   

main5: 
	nop

	_INTERRUPT_WAIT	RTXF
	;in return, UDR
	
	in argument,UCSRA
;investigate for error
	sbrs argument,FE 
	rjmp checkdorerror
	;frame error
	rjmp error

checkdorerror:
	sbrs argument,DOR 
	rjmp checkpeerror
	;dor error
	rjmp error

checkpeerror:
	sbrs argument,PE 
	rjmp success
	;pe error
	rjmp error

success:
	
	rjmp end	   

error:
    ;mark error
	ldi temp,STATUS_ERROR
	sts TxRxStatus,temp

	in temp,UCSRA
	cbr temp,(1<<FE)|(1<<DOR)|(1<<PE)
	out UCSRA,temp
	rcall usart_flush

end:

	_INTERRUPT_END RTXF

	rcall rs232_processor
	
	;is this the end of rs232 work?
	lds temp,TxRxStatus	
	cpi temp,STATUS_VOID
	
	brne gotomain5
		
	_SLEEP_CPU_REQUEST VOID_CALLBACK,VOID_CALLBACK,temp
			

gotomain5:
	rjmp main5  
ret

/*****USART Init********************
*@USAGE:temp
*/

usart_init:
	ldi temp,high(UBRR_VAL)
	out UBRRH,temp 

	ldi temp,low(UBRR_VAL)
	out UBRRL,temp

	; Enable receiver and tranciever interrupt
	ldi temp, (1 << RXCIE)|(1<<RXEN)|(1<<TXEN)
	out UCSRB,temp

	; Set frame format: 8data,EVEN parity check,1stop bit by default
	ldi temp, (1<<URSEL)|(1<<UPM1)|(1 << UCSZ1) | (1 << UCSZ0);
	out UCSRC,temp

ret
/*
*@USAGE:temp
*/

usart_flush:
	sbis UCSRA, RXC

ret
	in temp, UDR
	rjmp usart_flush

RxComplete:
	_PRE_INTERRUPT 
	;MUST read in interrupt according to documentation
	in return, UDR
	  
	ldi temp,STATUS_RX
	sts TxRxStatus,temp

;debug----	
	lds temp,InterruptDispatchFlag
	cpi temp,1<<RTXF
	brne deoff
	
	  
	lds temp,DEBUG_BYTE
	tst temp	
	breq deon
	sbi PORTB,PORTB0
	clr temp
	sts DEBUG_BYTE,temp
	rjmp deoff
deon:
    cbi PORTB,PORTB0
	ser temp
	sts DEBUG_BYTE,temp

deoff:
;-------------------
	;!Is my task sleeping?
	;is spu sleeping?
	_IS_CPU_SLEEPING yessleep,nosleep,temp
yessleep:		
	_POST_INTERRUPT
    reti
nosleep:	 
	
	_keDISPATCH_DPC RTXF

TxEmpty:
	_PRE_INTERRUPT
	
	;disable transmission
	in temp,UCSRB
	cbr temp,(1<<UDRIE) 
	out UCSRB,temp

	lds temp,TxRxByte
	out UDR,temp

	ldi temp,STATUS_TX
	sts TxRxStatus,temp
	
	_keDISPATCH_DPC RTXF



