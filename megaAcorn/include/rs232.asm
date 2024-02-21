//Arduino at 16MHz
#define UBRR_VAL    51 /* 19200 at   16 MHz*/ 

/*****USART Init Interrupt mode********************
*Enable Interrupt at recieve byte only
*@USAGE:temp
*/
rs232_init:
	;disable power reduction on USART (enable USART)
	lds temp,PRR
	cbr temp,1<<PRUSART0
	sts PRR,temp

	ldi temp,high(UBRR_VAL)
	sts UBRR0H,temp 

	ldi temp,low(UBRR_VAL)
	sts UBRR0L,temp


	; Enable receiver	
	ldi   temp,(1<<RXEN0)|(1<<TXEN0) 
	sts UCSR0B,temp
	
	; Set frame format: Async, no parity, 8 data bits, 1 stop bit	
	ldi temp, (1 << UCSZ01) | (1 << UCSZ00)	
	sts UCSR0C,temp

ret
/***********Send byte in polling mode**********************
*@INPUT: argument
*@USAGE: temp 
*/
rs232_send_byte:
	; Wait for empty transmit buffer
	lds temp,UCSR0A
	sbrs temp,UDRE0
	rjmp rs232_send_byte
	; Put data into buffer, sends the data
	sts UDR0,argument
ret
