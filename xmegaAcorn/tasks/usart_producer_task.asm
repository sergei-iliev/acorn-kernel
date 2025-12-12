/*
UART producer task - reads the stream from web serial into a queue to be consumed from LCD
*/
#define BLINK_LED		3
.SET RX_EVENT_ID=7

.dseg
#define QUEUE_MAX_SIZE 6000
#define QUEUE_LENGTH  (QUEUE_MAX_SIZE+HEADER_SIZE16)

lcd_queue: .byte QUEUE_LENGTH


.cseg


usart_D_task:
//copy from blinker
	lds temp,PORTB_DIR		
    ori temp,1<<BLINK_LED
	sts PORTB_DIR,temp	

	lds temp,PORTB_OUT		
    sbr temp,1<<BLINK_LED
	sts PORTB_OUT,temp

	/* USARTD0, 8 Data bits, No Parity, 1 Stop bit. */
	rcall usart_init_D_int


	;init queue
	ldi ZL,low(lcd_queue)
	ldi ZH,high(lcd_queue)
	call spc_queue16_init
	

    ;setup SLEEP on UART activity -> let the PC Browser wakes the kernel
    ;_SLEEP_INIT temp

	_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER


usart_D_main:
     
  
rs_read_wait_00:
	  
  _YIELD_TASK

rjmp usart_D_main



;***send byte D channel
;@INPUT:argument
usart_send_byte_d:
wait_send_int_d:    
	lds temp,USARTD0_STATUS
	sbrs temp,USART_DREIF_bp
	rjmp wait_send_int_d	
	
	sts USARTD0_DATA,argument
ret

;******configure USARTD0 in interrupt mode
usart_init_D_int:
		/* PIN3 (TXD0) as output. */
	ldi temp,1<<3
	sts PORTD_DIR,temp
	
	/* PIN2 (RXD0) as input. */
	ldi temp,1<<2
	sts PORTD_DIRCLR,temp

    /* USARTD0, 8 Data bits, No Parity, 1 Stop bit. */
	ldi temp,USART_CHSIZE_8BIT_gc|USART_PMODE_DISABLED_gc|(0<<USART_SBMODE_bp)
	sts USARTD0_CTRLC,temp

	/* Set Baudrate to 9600 bps:
	 * Use the default I/O clock fequency that is 32 MHz.	 
	 *
    ldi temp, (3317 & 0xff) << USART_BSEL_gp
    sts USARTD0_BAUDCTRLA, temp
    ldi temp, ((-4) << USART_BSCALE_gp) | ((3317 >> 8) << USART_BSEL_gp)
    sts USARTD0_BAUDCTRLB, temp
	*/
	//19200
    ;ldi temp, (3301 & 0xff) << USART_BSEL_gp
    ;sts USARTD0_BAUDCTRLA, temp
    ;ldi temp, ((-5) << USART_BSCALE_gp) | ((3301 >> 8) << USART_BSEL_gp)
    ;sts USARTD0_BAUDCTRLB, temp

	//38400
	;ldi r16, (3269 & 0xff) << USART_BSEL_gp
    ;sts USARTD0_BAUDCTRLA, r16
    ;ldi r16, ((-6) << USART_BSCALE_gp) | ((3269 >> 8) << USART_BSEL_gp)
    ;sts USARTD0_BAUDCTRLB, r16

	//57600
	;ldi r16, (2158 & 0xff) << USART_BSEL_gp
    ;sts USARTD0_BAUDCTRLA, r16
    ;ldi r16, ((-6) << USART_BSCALE_gp) | ((2158 >> 8) << USART_BSEL_gp)
    ;sts USARTD0_BAUDCTRLB, r16
	
	//115200
	ldi r16, (2094 & 0xff) << USART_BSEL_gp
    sts USARTD0_BAUDCTRLA, r16
    ldi r16, ((-7) << USART_BSCALE_gp) | ((2094 >> 8) << USART_BSEL_gp)
    sts USARTD0_BAUDCTRLB, r16

	;enable receive interrupt
	lds temp,USARTD0_CTRLA
	cbr temp,USART_RXCINTLVL_gm
	ori temp,USART_RXCINTLVL_LO_gc
	sts USARTD0_CTRLA,temp

	
	lds temp,USARTD0_CTRLB
	ori temp,USART_RXEN_bm|USART_TXEN_bm	
	sts USARTD0_CTRLB,temp
    
ret

/*
Rx Recieve Complete interrupt handler
*/
USART0_RXC_Intr:
_PRE_INTERRUPT
	
       ;store registers used by queue
	push ZH
	push ZL
	push cxh
	push cxl
	push dxh
	push dxl
	push axh
	push axl
    push argument
	push bxl
	push bxh
	push r0
	push r1
    push r2
	push r3
 
	;send signal if empty buffer
	lds axl,count
	lds axh,count+1
	lds bxl,count+2
	lds bxh,count+3
	CPI32 axl,axh,bxl,bxh,temp,0
	brne usart0_rxc_00
	_EVENT_SET RX_EVENT_ID, INTERRUPT_CONTEXT
usart0_rxc_00:
    
	;read byte color
    lds argument,USARTD0_DATA 
	;store in queue
	ldi ZL,low(lcd_queue)
	ldi ZH,high(lcd_queue)	  	
	ldi axl,low(QUEUE_MAX_SIZE)	
	ldi axh,high(QUEUE_MAX_SIZE)	
	call spc_queue16_push_from_isr	
    

	pop r3
	pop r2
	pop r1
	pop r0
	pop bxh
	pop bxl
	pop argument
	pop axl
	pop axh
	pop dxl
	pop dxh
	pop cxl
	pop cxh
	pop ZL
	pop ZH


_POST_INTERRUPT
_RETI
