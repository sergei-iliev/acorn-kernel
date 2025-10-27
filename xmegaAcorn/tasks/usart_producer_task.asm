

.include "tasks/single-producer-consumer.asm"

#define CLEAR_SCREEN_COMMAND    0x10
#define DRAW_PIXEL_COMMAND    0x20
#define RENDER_SCREEN_COMMAND    0x30
#define DRAW_BUFFER_COMMAND    0x40


.dseg
#define USART_QUEUE_MAX_SIZE  100 
usart_queue: .byte 102			;1 byte  input queue
colorh: .byte 1         ;
colorl: .byte 1         ;
.cseg

.SET RX_EVENT_ID=7

.def    cxl=r14
.def    cxh=r15


/*
Communication protocol in buffer sending
#1 byte Command 
#2 byte MSB size
#3 byte LSB size
#4 byte MSB color 
#5 byte LSB color
#6... bytes content 
*/


usart_D_task:
	/* USARTD0, 8 Data bits, No Parity, 1 Stop bit. */
	rcall usart_init_d_int

	;init usart queue
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)
	call spc_queue8_init
	

    ;setup SLEEP on UART activity -> let the PC Browser wakes the kernel
    _SLEEP_INIT temp

	_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER


usart_D_main:
     
  
rs_read_wait_00:
	  
	_EVENT_WAIT  RX_EVENT_ID

rs_read_loop_00:
    ;read from queue target lcd chanel
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE		

	rcall spc_queue8_pop
	brtc rs_read_wait_00					;it is empty nothing to read

	cpi return,CLEAR_SCREEN_COMMAND
	brne rs_read_cmd_00
	rcall clear_screen_command
	rjmp rs_read_cmd_end


rs_read_cmd_00:
	cpi return,DRAW_BUFFER_COMMAND
	brne rs_read_cmd_01
	rcall draw_buffer_command
	rjmp rs_read_cmd_end

rs_read_cmd_01:
	cpi return,RENDER_SCREEN_COMMAND
	brne rs_read_cmd_end
	rcall render_screen_command
    ;put the CPU to sleep only to be awaken by UART
    _SLEEP_CPU temp
	    
rs_read_cmd_end:		


	rjmp rs_read_loop_00            ;repeat untill queue is empty

rjmp usart_D_main


/******************CLEAR SCREEN****************************
Execute clear screen command and local buffer

***********************************************************/
clear_screen_command:
    ldi temp,2
	mov cxl,temp
;read next 2 bytes from structure
clr_scr_loop_00:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE

		
	rcall spc_queue8_pop
	brtc clr_scr_loop_00					;it is empty nothing to send, keep looping

	dec cxl
	tst cxl
	brne clr_scr_loop_00                    ;not finished keep looping until 2 bytes are read



	call ST7735_clear_screen
	;clear local buffer
	call ST7735_clear_buffer

ret
/******************DRAW BUFFER COMMAND****************************
Execute draw pixel command
Size structure 3 bytes long + Length bytes stream up to 2^16
   1. Command type
   2. Buffer Length byte MSB
   3. Buffer Length byte LSB
   4. Color byte MSB
   5. Color byte LSB
   ... Size bytes stream
   
***********************************************************/

draw_buffer_command:
;read size length
;1. MSB
drw_buff_loop_00:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE
		
	rcall spc_queue8_pop
	brtc drw_buff_loop_00					;it is empty nothing to read, keep looping
	;size MSB 
	mov dxh,return
;2. LSB
drw_buff_loop_02:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE

	rcall spc_queue8_pop
	brtc drw_buff_loop_02					;it is empty nothing to read, keep looping
	;size LSB  
	mov dxl,return

;3. read color in global variable - word size
;MSB
drw_buff_loop_000:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE
		
	rcall spc_queue8_pop
	brtc drw_buff_loop_000					;it is empty nothing to read, keep looping
	;color MSB 
	sts colorh,return
;LSB
drw_buff_loop_002:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE

	rcall spc_queue8_pop
	brtc drw_buff_loop_002					;it is empty nothing to read, keep looping
	;size LSB  
	sts colorl,return



;4. read size number of bytes		
	;position buffer
	ldi YL,low(graphics_buffer)
	ldi YH,high(graphics_buffer)

drw_buff_loop_11:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE

	
		
	rcall spc_queue8_pop
	brtc drw_buff_loop_11					;it is empty nothing to read, keep looping

	mov axl,return
	st Y+,axl								;store in buffer


	;counter decrement	
	SUBI16 dxl,dxh,1
	CPI16 dxl,dxh,temp,0
	brne drw_buff_loop_11                  ;keep looping untill size gets to 0

ret
/******************RENDER SCREEN****************************
Execute render buffer to  screen command
***********************************************************/
render_screen_command:
    ldi temp,2
	mov cxl,temp
;read next 2 bytes from structure
rnd_scr_loop_00:
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE

	
		
	rcall spc_queue8_pop
	brtc rnd_scr_loop_00					;it is empty nothing to send, keep looping

	dec cxl
	tst cxl
	brne rnd_scr_loop_00                    ;not finished keep looping until 2 bytes are read

	lds dxh,colorh
	lds dxl,colorl  
	call ST7735_send_buffer
ret


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
 
    ;read byte
    lds argument,USARTD0_DATA  
	;store in queue
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)	  	
	ldi axl,USART_QUEUE_MAX_SIZE	
	rcall spc_queue8_push	



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

	_EVENT_SET RX_EVENT_ID, INTERRUPT_CONTEXT

_POST_INTERRUPT
_RETI
