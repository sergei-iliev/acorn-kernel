/*
*Host initiates communication. It is the active party of RS232 communication
*/

rs232_processor:
	;transmit or recieve or void
	lds temp,TxRxStatus
	
	cpi temp,STATUS_VOID
	brne proc_TxRx
ret

proc_TxRx:
	cpi temp,STATUS_RX
	brne  proc_Rx
	nop

proc_Rx:    
    ;prpare if ax==0
	CPI16 axl,axh,temp,0
	brne proc_Tx 
	rcall rs232_prepare_temperature

proc_Tx:	
	;start SEND
	rcall rs232_send_temperature
	;save byte to send
	sts TxRxByte,bxl
	brtc proc_send_byte
	
	;packet sent, reset counter
	clr axh
	clr axl
	;reset status
	ldi temp,STATUS_VOID
	sts TxRxStatus,temp
ret

proc_send_byte:	

	;enable transmission to invoke interrupt handler
	in temp,UCSRB
	sbr temp,(1<<UDRIE) 
	out UCSRB,temp

ret

/***************Prepare Temperature*****************
*Send to Rx232 terminal ASCI formated value
* @INPUT: BCD45,BCD23
* @USE: Z
* @OUTPUT: save ASCI chars in rxdata
*/

rs232_prepare_temperature:
	ldi ZH,high(rsdata)
	ldi ZL,low(rsdata)
   		
	lds argument,BCD45
	rcall rs232_bcd_format

   //add '.'
	adiw Z,1
	ldi argument,'.'
	st Z,argument

	lds argument,BCD23
	adiw Z,1
	rcall rs232_bcd_format

ret
/***************Send Temperature*****************
* @INPUT: ax - current letter number up to 2^16 ; global variable
* @USE: temp
* @OUTPUT: T flag 1:No more bytes to send
*				 0:still bytes to send	
*		  bxl - byte to send	
*************************************************/

rs232_send_temperature:
	clt
	ldi ZH, high(rsdata) ; Initialize Z pointer
	ldi ZL, low(rsdata)
	ADD16 ZL,ZH,axl,axh 
	
	ADDI16 axl,axh,1

	ld bxl,Z
	
	CPI16 axl,axh,temp,6
	brne send_end
	set

send_end:

ret

/***************Convert Temperature*****************
* @INPUT: argument,Z place in RAM to save into
* @USE:temp
* @OUTPUT:
****************************************************/

rs232_bcd_format:
	ldi temp,0x30
	push argument
	andi argument,0xF0
	swap argument
	add argument,temp
	st Z+,argument

	ldi temp,0x30
	pop argument
	andi argument,0x0F
	add argument,temp
	st Z,argument

ret