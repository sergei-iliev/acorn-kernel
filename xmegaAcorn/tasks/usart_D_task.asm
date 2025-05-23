


usart_D_task:
	/* USARTD0, 8 Data bits, No Parity, 1 Stop bit. */
	rcall usart_init_d_int

	_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER


usart_D_main:
		nop
rjmp usart_D_main


;***send byte D channel
usart_send_byte_d:
wait_send_int_d:    
	lds temp,USARTD0_STATUS
	sbrs temp,USART_DREIF_bp
	rjmp wait_send_int_d	
	
	sts USARTD0_DATA,argument
ret

;******configure USARTD0 in interrupt mode
usart_init_d_int:
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
	 * Use the default I/O clock fequency that is 12 MHz.	 
	 */
    ldi temp, (3317 & 0xff) << USART_BSEL_gp
    sts USARTD0_BAUDCTRLA, temp
    ldi temp, ((-4) << USART_BSCALE_gp) | ((3317 >> 8) << USART_BSEL_gp)
    sts USARTD0_BAUDCTRLB, temp

	;enable receive interrupt
	lds temp,USARTD0_CTRLA
	cbr temp,USART_RXCINTLVL_gm
	ori temp,USART_RXCINTLVL_LO_gc
	sts USARTD0_CTRLA,temp

	
	lds temp,USARTD0_CTRLB
	ori temp,USART_RXEN_bm|USART_TXEN_bm	
	sts USARTD0_CTRLB,temp
    
ret

