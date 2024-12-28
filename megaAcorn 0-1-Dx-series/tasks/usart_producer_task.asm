;***********************************************USART 0***********************************************
#define BAUD_RATE 57600
#define USART0_BAUD_RATE ((SYSTEM_CLOCK * 64 / (16 * BAUD_RATE)) + 0.5)

/*
Recieve bytes from Web Browser serial port
Use single producer single consumer pattern 
*/

.include "tasks/single-producer-consumer.asm"
#define CLEAR_SCREEN_COMMAND    0x10
#define DRAW_PIXEL_COMMAND    0x20
#define RENDER_SCREEN_COMMAND    0x30
#define DRAW_BUFFER_COMMAND    0x40

#define ROTATE_SCREEN_COMMAND    0x50
#define HORIZONTAL_SCROLL_SCREEN_COMMAND    0x60
#define INVERT_COLOR_SCREEN_COMMAND    0x70

.dseg
#define USART_QUEUE_MAX_SIZE  255 
usart_queue: .byte 2+USART_QUEUE_MAX_SIZE			;8 bit input queue

.cseg

.SET RX_EVENT_ID=7

.def    cxl=r14
.def    cxh=r15

.def    argument=r17
.def    axl=r18
.def    axh=r19
.def    bxl = r20
.def    bxh = r21
.def    dxl=r22
.def    dxh=r23
.def    return=r24

usart_producer_task:
	;init usart queue
	ldi ZL,low(usart_queue)
	ldi ZH,high(usart_queue)
	call spc_queue8_init
   
    _SLEEP_INIT temp
cli
	rcall usart_init
sei
	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER


usart0_main:

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
	    
rs_read_cmd_end:		

	;put the CPU to sleep
    _SLEEP_CPU temp	

    rjmp rs_read_loop_00            ;repeat untill queue is empty
rjmp usart0_main

/******************DRAW BUFFER COMMAND****************************
Execute draw pixel command
Size structure 3 bytes long + Length bytes stream up to 2^16
   1. Command type
   2. Buffer Length byte MSB
   3. Buffer Length byte LSB
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


;3. read size number of bytes
		
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

	
	call sh1107_send_buffer
ret

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



	call sh1107_clear_screen
	;clear local buffer
	call sh1107_clear_buffer

ret



;default is 8N1
usart_init:  

  ;input output   
  lds temp,PORTA_DIR
  sbr temp,(1<<PIN0)  ;output  Tx  PA0
  sts PORTA_DIR,temp
  ;output
  lds temp,PORTA_DIR
  cbr temp,(1<<PIN1)  ;input   Rx  PA1 
  sts PORTA_DIR,temp


  ;8 bit
  ;ERROR FOR SOME REASON I DON:T KNOW
  ;ldi temp,USART_CMODE_ASYNCHRONOUS_gc | USART_NORMAL_CHSIZE_8BIT_gc | USART_NORMAL_PMODE_DISABLED_gc | USART_NORMAL_SBMODE_1BIT_gc
  ;sts USART0_CTRLC,temp
     
  ldi r20,low(USART0_BAUD_RATE)
  ldi r21,high(USART0_BAUD_RATE)
  
  
  ;set baud rate
  sts USART0_BAUDL,r20
  sts USART0_BAUDH,r21

  ;enable Tx and Rx
  ;lds temp,USART0_CTRLB
  ori temp, USART_TXEN_bm | USART_RXEN_bm | USART_RXMODE_NORMAL_gc
  sts USART0_CTRLB,temp

  rcall enable_uart
  
  
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


/*
Rx Recieve Complete interrupt handler
*/
USART0_RXC_Intr:
_PRE_INTERRUPT
    ;store currently interrupted task's CPU context with registers used by queue
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
    lds argument,USART0_RXDATAL  
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

.EXIT