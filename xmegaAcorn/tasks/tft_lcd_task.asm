/*
LCD consumer task - reads queue and SPI sends it to ST7790
*/

.def    argument=r17
.def    return=r18
.def    counter=r19  

.def	axl=r20
.def	axh=r21

.def	bxl=r22
.def	bxh=r23

.def	dxl=r24
.def	dxh=r25

.def	cxl=r14
.def	cxh=r15

.include "tasks/st7789.asm"

.dseg
	count: .byte 4  ;int size counter	
.cseg
/* tft lcd task to render images comming from web serial interface */
tft_lcd_task:

	_SLEEP_TASK_EXT 255
	rcall st7789_init

	rcall st7789_clear_screen
	
	_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER
	
	;***draw text once
	rcall draw_hello_world_text
	//rcall test_draw_text_orla
	clr temp
	sts count,temp
	sts count+1,temp
	sts count+2,temp
	sts count+3,temp

	 
tft_lcd_main:
  _EVENT_WAIT  RX_EVENT_ID   ;wait untill 
    rcall st7789_clear_screen
	rcall set_window   ;set whole window

	lds temp,PORTB_OUT		
    cbr temp,1<<BLINK_LED
	sts PORTB_OUT,temp
rs_read_loop_00:   //first color byte MSB    
    ;read from queue target lcd chanel
	ldi ZL,low(lcd_queue)
	ldi ZH,high(lcd_queue)	  	
	ldi axl,low(QUEUE_MAX_SIZE)	
	ldi axh,high(QUEUE_MAX_SIZE)		

	call spc_queue16_pop
	brtc rs_read_loop_00					;it is empty nothing to read
	
	mov r11,return   //temp storage in r10

rs_read_loop_01://second color byte LSB
    ;read from queue target lcd chanel
	ldi ZL,low(lcd_queue)
	ldi ZH,high(lcd_queue)	  	
	ldi axl,low(QUEUE_MAX_SIZE)	
	ldi axh,high(QUEUE_MAX_SIZE)		

	call spc_queue16_pop
	brtc rs_read_loop_01					;it is empty nothing to read
	
	mov r10,return		//temp storage in r10


   //color
   mov axh,r11
   mov axl,r10
   rcall ST7789_data_16bits_send

   ;increment size
	
	lds axl,count
	lds axh,count+1
	lds bxl,count+2
	lds bxh,count+3
	ADDI32 axl,axh,bxl,bxh,2
	sts count,axl
	sts count+1,axh
	sts count+2,bxl
	sts count+3,bxh


	CPI32 axl,axh,bxl,bxh,temp,153600	;2*MAX_SIZE*MAX_Y
    brsh rs_read_loop_02
 rjmp  rs_read_loop_00  

 rs_read_loop_02: 
 	
	clr temp
	sts count,temp
	sts count+1,temp
	sts count+2,temp
	sts count+3,temp

	lds temp,PORTB_OUT		
    sbr temp,1<<BLINK_LED
	sts PORTB_OUT,temp


   _EVENT_RESET RX_EVENT_ID   ;clear pending signals
 ;rjmp forever

rjmp tft_lcd_main




//*******************
set_window:
  // set whole window
  //X1
  ldi temp,0
  mov startXH,temp
  mov startXL,temp
   
  //X2
  ldi temp,high(SIZE_X)
  mov endXH,temp
  ldi temp,low(SIZE_X)
  mov endXL,temp
  //Y1
  ldi temp,high(0)
  mov startYH,temp
  ldi temp,low(0)
  mov startYL,temp
  
  //Y2
  ldi temp,high(SIZE_Y)
  mov endYH,temp
  ldi temp,low(SIZE_Y)
  mov endYL,temp
  rcall ST7789_set_window 

   // access to RAM
   ldi argument,RAMWR
   rcall ST7789_command_send
ret
//*******************
test_draw_text_orla:
  //X1  
  ldi temp,high(50)
  mov startXH,temp
  ldi temp,low(50)
  mov startXL,temp
       
  //Y1
  ldi temp,high(20)
  mov startYH,temp
  ldi temp,low(20)
  mov startYL,temp

  ldi dxh,high(WHITE)
  ldi dxl,low(WHITE)
	
  ldi argument,'!'	
  rcall ST7789_draw_char_orla
ret
//*******************
test_draw_point:
  //X1  
  ldi temp,high(30)
  mov startXH,temp
  ldi temp,low(30)
  mov startXL,temp
       
  //Y1
  ldi temp,high(20)
  mov startYH,temp
  ldi temp,low(20)
  mov startYL,temp

  ldi dxh,high(WHITE)
  ldi dxl,low(WHITE)
  rcall st7789_draw_point

  //X1  
  ldi temp,high(31)
  mov startXH,temp
  ldi temp,low(31)
  mov startXL,temp
       
  //Y1
  ldi temp,high(20)
  mov startYH,temp
  ldi temp,low(20)
  mov startYL,temp

  ldi dxh,high(WHITE)
  ldi dxl,low(WHITE)
  rcall st7789_draw_point    
  //X1  
  ldi temp,high(32)
  mov startXH,temp
  ldi temp,low(32)
  mov startXL,temp
       
  //Y1
  ldi temp,high(20)
  mov startYH,temp
  ldi temp,low(20)
  mov startYL,temp

  ldi dxh,high(WHITE)
  ldi dxl,low(WHITE)
  rcall st7789_draw_point  
ret

//*******************
test_fill_rect:
  //X1  
  ldi temp,high(0)
  mov startXH,temp
  ldi temp,low(0)
  mov startXL,temp
     
  //X2
  ldi temp,high(MAX_X)
  mov endXH,temp
  ldi temp,low(MAX_X)
  mov endXL,temp
  
  //Y1
  ldi temp,high(0)
  mov startYH,temp
  ldi temp,low(0)
  mov startYL,temp  
  
  //Y2
  ldi temp,high(MAX_Y)
  mov endYH,temp
  ldi temp,low(MAX_Y)
  mov endYL,temp
  //color
  ldi dxh,high(0xbfab)
  ldi dxl,low(0xbfab)
  rcall st7789_fill_rect

  
ret
//**************************************
draw_hello_world_text:
   //X	
   ldi XL,low(10)  
   ldi XH,high(10)
   //Y
   ldi temp,10   
   mov startYL,temp

   ldi	ZH,high(hello_world*2)
   ldi	ZL,low(hello_world*2)

dr_ml_loop:

   	     
   lpm argument, Z+ 
   cpi argument,0x0A
   breq dr_ml_nxt_line

   //end of stream?
   cpi argument,0x0C
   breq dr_ml_nxt_ext

   push ZH
   push ZL
   

   ;coordinates for next char
   ;mov temp,startXL
   //subi temp,-1*ROBOTO_CHAR_COLS_LEN  ;next char offset in roboto
   adiw XH:XL,ORLA_CHAR_COLS_LEN
   ;mov startXL,temp ;input

          
   ;color
   ldi dxh,high(YELLOW)
   ldi dxl,low(YELLOW)
   
   mov startXL,XL
   mov startXH,XH
   push startYL  ;it is modified in ST7735_draw_char_roboto
   call ST7789_draw_char_orla
   pop startYL

   pop ZL
   pop ZH   
   rjmp dr_ml_loop

dr_ml_nxt_line:
   
   ;calculate next Y pos
   mov temp,startYL
   subi temp,-1*ORLA_CHARS_ROWS_LEN_BITS  ;next line
   mov startYL,temp 

   ldi XL,low(10)
   ldi XH,high(10)

   rjmp dr_ml_loop

dr_ml_nxt_ext:

   
ret


hello_world:
.db "For GOD so loved ",0x0A
.db "the World that HE",0x0A
.db "gave HIS only SON",0x0A
.db "that whoever ",0x0A
.db "believes in HIM",0x0A
.db "may not perish ",0x0A
.db "but have eternal ",0x0A
.db "live ",0x0C