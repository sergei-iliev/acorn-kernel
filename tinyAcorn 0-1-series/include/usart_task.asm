
#define F_CPU 20000000
//PLEASE SET PERIFERAL DEVIDER TO 1
#define PRESCALE 1
#define F_PER (F_CPU/PRESCALE)
#define BAUD_RATE 57600
#define USART0_BAUD_RATE  (F_PER * 4 /BAUD_RATE)  ;8333

//WHY -   because PERIFERAL clock has a devision ; set it to 1 first to use above formula
//#define USART0_BAUD_RATE 8300

.def    argument=r17   
.def    global_byte=r14

.equ PIN2 = 2
.equ PIN3 = 3

#define USART_TASK_ID 3

usart_task:
	rcall usart_init
	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
usart_main:
/*** polling mode
    ;read from Rx
	;Before reading the data, the user must wait for the data to be available by polling the Receive Complete Interrupt Flag, RXCIF.
wait_rx:	
	lds temp,USART0_STATUS
	sbrs temp,USART_RXCIF_bp
	rjmp wait_rx
	
	lds argument,USART0_RXDATAL;
	rcall usart_send
*/    
	

	_INTERRUPT_WAIT USART_TASK_ID
	mov argument,global_byte
	rcall usart_send

	_INTERRUPT_END USART_TASK_ID

rjmp usart_main


;@INPUT: argument
usart_send:
    sts USART0_TXDATAL,argument
wait_send:    
	lds temp,USART0_STATUS
	sbrs temp,USART_DREIF_bp
	rjmp wait_send	
	
	lds temp,USART0_STATUS
	sbr temp, (1<<USART_TXCIF_bp)
	sts USART0_STATUS,temp
	
ret

;default is 8N1
usart_init:
  cli
  
  ldi temp,CPU_CCP_IOREG_gc		// disable register security for oscillator update	   
  out CPU_CCP,temp
  
  ;set periferal devider to 1
  lds temp,CLKCTRL_MCLKCTRLB
  clr temp
  sts CLKCTRL_MCLKCTRLB,temp


  ;input output   
  lds temp,PORTB_DIRSET
  sbr temp,(1<<PIN2)  ;output  Tx  PB2
  cbr temp,(1<<PIN3)  ;input   Rx  PB3 
  sts PORTB_DIRSET,temp

  ;dasable pull up
  lds temp,PORTB_PIN3CTRL
  cbr temp,1<<PORT_PULLUPEN_bp
  sts PORTB_PIN3CTRL,temp

  ;set low level
  lds temp,VPORTB_OUT
  cbr temp,1<<PIN2
  sts VPORTB_OUT,temp

  ldi r20,low(USART0_BAUD_RATE)
  ldi r21,high(USART0_BAUD_RATE)
  
  
  ;set baud rate
  sts USART0_BAUDL,r20
  sts USART0_BAUDH,r21

  ;enable Tx and Rx
  lds temp,USART0_CTRLB
  ori temp, USART_TXEN_bm | USART_RXEN_bm
  sts USART0_CTRLB,temp

  rcall enable_uart
  ;8N1
  //lds temp,USART0_CTRLC
  //ori temp,USART_CMODE_ASYNCHRONOUS_gc 
  /* Asynchronous Mode */
	//		 | USART_CHSIZE_8BIT_gc /* Character size: 8 bit */
	//		 | USART_PMODE_DISABLED_gc /* No Parity */
	//		 | USART_SBMODE_1BIT_gc; /* 1 stop bit */
   
  sei
ret

enable_uart:
//enable Rx interrupt
  lds temp,USART0_CTRLA
  ori temp,USART_RXCIE_bm
  sts USART0_CTRLA,temp
ret

disable_uart:
  lds temp,USART0_CTRLA
  cbr temp,1<<USART_RXCIE_bp
  sts USART0_CTRLA,temp

ret

USART0_RXC_Intr:
_PRE_INTERRUPT

 ;global memory byte r14
 lds temp,USART0_RXDATAL;
 mov global_byte,temp

 _keDISPATCH_DPC USART_TASK_ID

.EXIT