/*
GDSC-0801WP
LCD driver
*/

lcd_init:
	
	clr temp
	sbr temp,(1<<7|1<<6|1<<5|1<<4)	;DB4,DB5,DB6,DB7 output
	sts PORTE_OUTCLR,temp

	clr temp
	sbr temp,(1<<7|1<<6|1<<5|1<<4)	;DB4,DB5,DB6,DB7 output
	sts PORTE_DIRSET,temp


	clr temp
	sbr temp,(1<<RS_BIT|1<<RW_BIT|1<<EN_BIT)	;RS,RW,E output
	sts PORTC_DIRSET,temp

	// This first commands have 4 bits Length!!!!! Not Byte!!!
;pass 1

	//***wait 5ms
	ldi XL,low(25000)   
	ldi XH,high(25000)
	rcall lcd_delay

	//RS,RW OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<RS_BIT|1<<RW_BIT) 
	sts PORTC_OUT,temp

	
	lds temp,PORTE_IN;
	andi temp,0x0F  
	ori temp,0x30
	sts PORTE_OUT,temp

	//EN ON
	lds temp,PORTC_OUT
	sbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall lcd_delay

	//EN OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall lcd_delay

;pass 2
	//***wait 5ms
	ldi XL,low(25000)   
	ldi XH,high(25000)
	rcall lcd_delay
	
	lds temp,PORTE_IN;
	andi temp,0x0F  
	ori temp,0x30
	sts PORTE_OUT,temp

	//EN ON
	lds temp,PORTC_OUT
	sbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall lcd_delay

	//EN OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall lcd_delay

;pass 3
	//***wait 5ms
	ldi XL,low(25000)   
	ldi XH,high(25000)
	rcall lcd_delay
	
	lds temp,PORTE_IN;
	andi temp,0x0F  
	ori temp,0x30
	sts PORTE_OUT,temp

	//EN ON
	lds temp,PORTC_OUT
	sbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall lcd_delay

	//EN OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall lcd_delay

;pass 4 - function set
	//***wait 5ms
	ldi XL,low(25000)   
	ldi XH,high(25000)
	rcall lcd_delay
	
	lds temp,PORTE_IN;
	andi temp,0x0F  
	ori temp,0x20
	sts PORTE_OUT,temp

	//EN ON
	lds temp,PORTC_OUT
	sbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall lcd_delay

	//EN OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall lcd_delay

;FUNCTION SET
    ldi argument,0x28
	rcall lcd_send_cmd

;DISPLAY OFF
    ldi argument,0x08
	rcall lcd_send_cmd

;DISPLAY CLEAR
    ldi argument,0x01
	rcall lcd_send_cmd

;ENTRY MODE SET
    ldi argument,0x06
	rcall lcd_send_cmd

;DISPLAY ON
    ldi argument,0x0C
	rcall lcd_send_cmd


ret
/**************LCD CLEAR SCREEN***************************
*/
lcd_clr_screen:
;DISPLAY CLEAR
    ldi argument,0x01
	rcall lcd_send_cmd
ret


/**************SEND LCD CHAR******************************
Send a single char to LCD
@INPUT: argument - character
@USAGE: X,temp,axl
*/
lcd_send_char:
	mov axl,argument
	andi axl,0xF0		//get upper nible	
	
	lds temp,PORTE_IN;
	andi temp,0x0F     //read current port state  to avoid changing lower pins
	or temp,axl
	sts PORTE_OUT,temp

	//RW OFF
	lds temp,PORTC_OUT
	cbr temp,1<<RW_BIT 
	sts PORTC_OUT,temp

	//RS ON
	lds temp,PORTC_OUT
	sbr temp,(1<<RS_BIT) 
	sts PORTC_OUT,temp

	//EN ON
	lds temp,PORTC_OUT
	sbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall lcd_delay

	//EN OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

	mov axl,argument
	andi axl,0x0F		//get lower nible	
	swap axl

	lds temp,PORTE_IN;
	andi temp,0x0F     //read current port state  to avoid changing lower pins
	or temp,axl
	sts PORTE_OUT,temp

	//RW OFF
	lds temp,PORTC_OUT
	cbr temp,1<<RW_BIT
	sts PORTC_OUT,temp

	//RS ON
	lds temp,PORTC_OUT
	sbr temp,(1<<RS_BIT) 
	sts PORTC_OUT,temp

	//EN ON
	lds temp,PORTC_OUT
	sbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall lcd_delay

	//EN OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25000)   
	ldi XH,high(25000)
	rcall lcd_delay

ret

/**************SEND LCD COMMAND******************************
@INPUT: argument
@USAGE: X,temp,axl
*/
lcd_send_cmd:
	//***wait 5ms
	ldi XL,low(25000)   
	ldi XH,high(25000)
	rcall lcd_delay
	
	mov axl,argument
	andi axl,0xF0		//get upper nible	

	lds temp,PORTE_IN;
	andi temp,0x0F     //read current port state  to avoid changing lower pins
	or temp,axl
	sts PORTE_OUT,temp

	//RS,RW OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<RS_BIT|1<<RW_BIT) 
	sts PORTC_OUT,temp

	//EN ON
	lds temp,PORTC_OUT
	sbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall lcd_delay

	//EN OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall lcd_delay

	mov axl,argument
	andi axl,0x0F		//get lower nible	
	swap axl

	lds temp,PORTE_IN;
	andi temp,0x0F     //read current port state  to avoid changing lower pins
	or temp,axl
	sts PORTE_OUT,temp

	//RS,RW OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<RS_BIT|1<<RW_BIT) 
	sts PORTC_OUT,temp

	//EN ON
	lds temp,PORTC_OUT
	sbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall lcd_delay

	//EN OFF
	lds temp,PORTC_OUT
	cbr temp,(1<<EN_BIT)				 
	sts PORTC_OUT,temp

    ldi XL,low(25)   
	ldi XH,high(25)
	rcall lcd_delay


    ldi XL,low(50000)   
	ldi XH,high(50000)
	rcall lcd_delay

ret
/*
0.2us single loop
@INPUT: XL,XH
@USAGE: XL,XH,temp
*/
lcd_delay:
	DEC16 XL,XH
	CPI16 XL,XH,temp,0
	brne lcd_delay 
ret

TEXT: .db "        ACORN micro kernel        ",0