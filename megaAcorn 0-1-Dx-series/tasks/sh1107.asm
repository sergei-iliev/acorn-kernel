/******************************************************************************
 SH1107 ID and Command List
 ******************************************************************************/
#define SH1107_WIDTH 128
#define SH1107_HEIGHT 128

#define SH1107_COLS 128
#define SH1107_PAGES 16

#define SH1107_COMMAND 0x00
#define SH1107_DATA_CONTINUE 0x40

#define SET_PAGE_ADDRESS                0xB0 /* sets the page address from 0 to 7 */
#define DISPLAY_OFF                     0xAE
#define DISPLAY_ON                      0xAF
#define SET_MEMORY_ADDRESSING_MODE      0x20
#define SET_COM_OUTPUT_SCAN_DIRECTION   0xC8
#define LOW_COLUMN_ADDRESS              0x00
#define HIGH_COLUMN_ADDRESS             0x10
#define START_LINE_ADDRESS              0x40
#define SET_CONTRAST_CTRL_REG           0x81
#define SET_SEGMENT_REMAP               0xA1 // 0 to 127
#define SET_NORMAL_DISPLAY				0xA6
#define SET_INVERT_DISPLAY				0xA7
#define SET_MULTIPLEX_RATIO             0xA8
#define OUTPUT_FOLLOWS_RAM              0xA4
#define OUTPUT_IGNORES_RAM              0xA5

#define SET_DISPLAY_OFFSET              0xD3
#define SET_DISPLAY_CLOCK_DIVIDE        0xD5
#define SET_PRE_CHARGE_PERIOD           0xD9
#define SET_COM_PINS_HARDWARE_CONFIG    0xDA
#define SET_VCOMH                       0xDB
#define SET_DC_DC_ENABLE                0x8D

#define DEACTIVATE_SCROLL		        0x2E
#define ACTIVATE_SCROLL			        0x2F
#define SCROLL_HORZ_RIGTH               0x26
#define SCROLL_HORZ_LEFT                0x27







#define GRAPHICS_BUFFER_SIZE (SH1107_WIDTH*(SH1107_HEIGHT/8)) 
.dseg
graphics_buffer:   .byte GRAPHICS_BUFFER_SIZE
.cseg



.EQU	SH1107_ADDRESS =0x3C   ;SH1107

.def    argument=r17
.def    axl=r18
.def    axh=r19
.def    XX = r2
.def    YY = r3
.def    char=r4
;***** DIV Subroutine Register Variables

.def	drem8u	=r15		;remainder
.def	dres8u	=r16		;result
.def	dd8u	=r16		;dividend
.def	dv8u	=r17		;divisor
.def	dcnt8u	=r18		;loop counter

/**************************************************************************
;Initialize ssd1306
;@USED: axl,temp
***************************************************************************/
sh1107_setup:
	rcall twi_init	

	ldi axl,0xAE		
	rcall sh1107_send_command
	
    ldi axl,0xA8		
	rcall sh1107_send_command
	
    
    ldi axl,0x7F		
	rcall sh1107_send_command

	ldi axl,0xD3		
	rcall sh1107_send_command

	ldi axl,0x00		
	rcall sh1107_send_command

	ldi axl,0x40		
	rcall sh1107_send_command

	ldi axl,0xA1		
	rcall sh1107_send_command
    
	ldi axl,0xC8		
	rcall sh1107_send_command
    
	ldi axl,0xDA		
	rcall sh1107_send_command

	ldi axl,0x12		
	rcall sh1107_send_command

	ldi axl,0x81		
	rcall sh1107_send_command

	ldi axl,0x80		
	rcall sh1107_send_command

 	ldi axl,0xA4		
	rcall sh1107_send_command

	ldi axl,0xA6		
	rcall sh1107_send_command

	ldi axl,0xD5		
	rcall sh1107_send_command

	ldi axl,0x80		
	rcall sh1107_send_command
 
	ldi axl,0x8D		
	rcall sh1107_send_command
    
	ldi axl,0x14		
	rcall sh1107_send_command
	
	;ldi axl,SET_INVERT_DISPLAY		
	;rcall sh1107_send_command

	ldi axl,DISPLAY_ON		
	rcall sh1107_send_command

ret
/**************************************************************************************
;Scroll entire ecreen to the right
;@INPUT: axl
;@USED: temp,argument
;
***************************************************************************************/
sh1107_scroll_right_screen:

  	ldi axl,SCROLL_HORZ_RIGTH		
	call sh1107_send_command

	ldi axl,0x00
	call sh1107_send_command

	ldi axl,0x00   ;start
	call sh1107_send_command

	ldi axl,0x00   
	call sh1107_send_command

	ldi axl,0x0F  ;end
	call sh1107_send_command

	ldi axl,0x00   
	call sh1107_send_command

	ldi axl,0xFF
	call sh1107_send_command

	ldi axl,ACTIVATE_SCROLL		
	call sh1107_send_command	
ret
/**************************************************************************************
;Send byte command
;@INPUT: axl
;@USED: temp,argument
;
***************************************************************************************/
sh1107_send_command:
	;transmit SLA+W
	ldi argument,(SH1107_ADDRESS<<1)
	rcall twi_send_addr
    
	;command
	ldi argument,SH1107_COMMAND
	rcall twi_send_byte
	
	;value
	mov argument,axl
	rcall twi_send_byte

	;send stop condition
	rcall twi_send_stop

ret

/***********************************************************************************************
;Clear local buffer
;@USED: argument,temp,X,Y
************************************************************************************************/
sh1107_clear_buffer:
	;clear 2048 bytes  128x16
	ldi XL,low(GRAPHICS_BUFFER_SIZE)
	ldi XH,high(GRAPHICS_BUFFER_SIZE)
	
	ldi YL,low(graphics_buffer)
	ldi YH,high(graphics_buffer)

	ldi argument,0x00   ;0 data to clear bit by bit

buf_clr_loop_00:		
	st Y+,argument
	
	
	SUBI16 XL,XH,1
	CPI16 XL,XH,temp,0
	brne buf_clr_loop_00 
ret


#define CHARS_COLS_LEN        6                 // number of columns for chars
#define CHARS_ROWS_LEN        8                 // number of rows for chars
#define CHAR_SIZE        8         //8 bytes according to the table
/******************************************************************************************
;Send single default font char to buffer
;Position 0=<X=<127 and 0=<Y=<127 and draw pixel into buffer
;@INPUT  XX 
;		 YY
;		 argument - default font charecter to draw
 
;@USED:  temp,char,Z,r20,r21,r0,r1,r8,r9,r10,r11
******************************************************************************************/
sh1107_draw_buffer_char:
    ;test if outside of drawing area
	mov temp,XX				;test XX
	subi temp,-1*CHARS_COLS_LEN
	cpi temp,(SH1107_WIDTH)     
	brlo buf_char_yy
ret

buf_char_yy:        
	mov temp,YY				;test YY
	subi temp,-1*CHARS_ROWS_LEN
	cpi temp,(SH1107_HEIGHT)     
	brlo buf_char_ok
ret

buf_char_ok:
	subi argument,32

   ;translate to bytes representation in fonts table
	ldi	ZH,high(default_font*2)
    ldi	ZL,low(default_font*2)

   ldi r20,CHARS_COLS_LEN	   //cols const
   mov r21,argument             //row number variable
   mul r20,r21

   ADD16 ZL,ZH,r0,r1

   ldi temp,CHARS_COLS_LEN   //loop throu 6 columns 
   mov r10,temp              //r10 counter 

   ;preserve YY
   mov r8,YY
buf_char_00:  
   tst r10
   breq buf_char_01

   lpm					;read next col from font 8x6
   mov	r11,r0	        ;r11 is char byte

   ldi temp,8				 //loop through 8 bits
   mov r9,temp               //r9 counter

   ;start from Y init pos for each new letter byte
   mov YY,r8

buf_8bit_loop:			; send bits one by one	
   tst r9
   breq buf_8bit_end

   ror r11
   brcs	black_out_00	
						//WHITE pixel
   clr temp
   mov char,temp
   rcall sh1107_draw_buffer_pixel   ;input=X,Y,char   							
   rjmp black_end_00

black_out_00:			//BLACK pixel
   ser temp
   mov char,temp
   call sh1107_draw_buffer_pixel	;input=X,Y,char

black_end_00:
   ;increment Y pos for next bit
   inc YY

   dec r9
   rjmp buf_8bit_loop

buf_8bit_end:

   adiw ZH:ZL,1         //move to next column
   dec r10
   inc XX
   rjmp buf_char_00

buf_char_01:

ret

#define ROBOTO_CHAR_COLS_LEN        8                 // number of columns for a chars (bits)
#define ROBOTO_CHARS_ROWS_LEN        2*8                 // number of rows for chars   (bits)
#define ROBOTO_CHAR_SIZE        16         //16 bytes according to the table

/******************************************************************************************
;Send single ROBOTO font char to buffer
;Position 0=<X=<127 and 0=<Y=<127 and draw pixel into buffer
;@INPUT  XX 
;		 YY
;		 argument - default font charecter to draw
 
;@USED:  temp,char,Z,r20,r21,r0,r1,r6,r7,r8,r9,r10,r11
******************************************************************************************/
sh1107_draw_buffer_char_roboto:
    ;test if outside of drawing area
	mov temp,XX				;test XX
	subi temp,-1*ROBOTO_CHAR_COLS_LEN
	cpi temp,(SH1107_WIDTH)     
	brlo buf_char_roboto_yy
ret
buf_char_roboto_yy:        
	mov temp,YY				;test YY
	subi temp,-1*ROBOTO_CHARS_ROWS_LEN
	cpi temp,(SH1107_HEIGHT)     
	brlo buf_char_roboto_ok
ret

buf_char_roboto_ok:
   subi argument,32
   
   ;translate to bytes representation in fonts table
   ldi	ZH,high(roboto_mono_8x16*2)
   ldi	ZL,low(roboto_mono_8x16*2)

   ldi r20,ROBOTO_CHAR_SIZE	   //cols const in table each char is represented by 16 bytes
   mov r21,argument             //row number variable
   mul r20,r21

   ADD16 ZL,ZH,r0,r1

   ldi temp, 2      //font roboto has 2 rows by 8 bits each or 16 bits height
   mov r6,temp

buf_next_half_char_roboto_00:
   tst r6				//are 2 halfs by 8 bits done?
   breq buf_next_half_char_roboto_end

   ldi temp,ROBOTO_CHAR_COLS_LEN   //loop throu 8 columns 
   mov r10,temp              //r10 counter 

   ;preserve XX
   mov r7,XX


   ;preserve YY
   mov r8,YY

buf_char_roboto_00: 
   tst r10
   breq buf_next_half_char_roboto_01   	

   lpm					;read next col from font 8x8
   mov	r11,r0	        ;r11 is char byte

   ldi temp,8				 //loop through 8 bits
   mov r9,temp               //r9 counter

   ;start from Y init pos for each new letter byte
   mov YY,r8

buf_8bit_roboto_loop:			; send bits one by one	
   tst r9
   breq buf_8bit_roboto_end

   ror r11
   brcs	black_out_roboto_00	
						//WHITE pixel
   clr temp
   mov char,temp
   rcall sh1107_draw_buffer_pixel   ;input=X,Y,char   							
   rjmp black_end_roboto_00

black_out_roboto_00:			//BLACK pixel
   ser temp
   mov char,temp
   call sh1107_draw_buffer_pixel	;input=X,Y,char

black_end_roboto_00:
   ;increment Y pos for next bit
   inc YY

   dec r9
   rjmp buf_8bit_roboto_loop

buf_8bit_roboto_end:
   adiw ZH:ZL,1         //move to next column
   dec r10
   inc XX
   rjmp buf_char_roboto_00

buf_next_half_char_roboto_01:
  dec r6    //next font half
  mov XX,r7
  //subi YY,-1*8

  rjmp buf_next_half_char_roboto_00

buf_next_half_char_roboto_end:

ret

#define PAGESTARTADDRESS 0xB0
#define SETLOWCOLUMN 0x00
#define SETHIGHCOLUMN 0x10
/******************************************************************************************
;Send buffer to oled
;Buffer is sent page by page
;@INPUT: 
;		
;@USED: r15,Y,argument,temp,axl
******************************************************************************************/
sh1107_send_buffer:
    ldi axh,0    ;0<pages<15
	
	;pointer to buffer
	ldi YL,low(graphics_buffer)
	ldi YH,high(graphics_buffer)

shbuf_loop_11:
    	
   	ldi axl,PAGESTARTADDRESS
	or axl,axh					;pageaddress+page

	rcall sh1107_send_command

   	ldi axl,(SETLOWCOLUMN | 2)		;don't ask just use it
	rcall sh1107_send_command

   	ldi axl,(SETHIGHCOLUMN)		
	rcall sh1107_send_command

	;transmit SLA+W
	ldi argument,(SH1107_ADDRESS<<1)
	rcall twi_send_addr

    ;data continue
	ldi argument,SH1107_DATA_CONTINUE
	rcall twi_send_byte

	;send 16x16=OLED_WIDTH	
	ldi temp,SH1107_COLS
	mov r15,temp

shbuf_loop_00:		
	ld argument,Y+	         ;send byte to OLED	
	rcall twi_send_byte

	dec r15
	tst r15	
	brne shbuf_loop_00 
	
	inc axh
	cpi axh,SH1107_PAGES
	brne shbuf_loop_11 

shbuf_clr_00:
	rcall twi_send_stop   		

ret

/***********************************************************************************************
;Clear entire screen area
;@USED: axh,axl,argument,temp,r15
************************************************************************************************/
sh1107_clear_screen:
	 ldi axh,0 

shclr_loop_11:
    	
   	ldi axl,PAGESTARTADDRESS
	or axl,axh

	rcall sh1107_send_command

   	ldi axl,(SETLOWCOLUMN | 2)		;don't ask just use it
	rcall sh1107_send_command

   	ldi axl,(SETHIGHCOLUMN)		
	rcall sh1107_send_command



	;transmit SLA+W
	ldi argument,(SH1107_ADDRESS<<1)
	rcall twi_send_addr
	
    ;data continue
	ldi argument,SH1107_DATA_CONTINUE
	rcall twi_send_byte

	;send 16x16=OLED_WIDTH
	
	ldi temp,SH1107_COLS
	mov r15,temp

shclr_loop_00:		
	ldi argument,0x00   ;0 data to clear bit by bit
	rcall twi_send_byte
	
	dec r15
	tst r15	
	brne shclr_loop_00 

	inc axh
	cpi axh,SH1107_PAGES
	brne shclr_loop_11 

	rcall twi_send_stop 

ret
/***************************Set pixel to BLACK***************************************************************
;Position 0=<X=<127 and 0=<Y=<127 and draw pixel into buffer
;@INPUT  XX 
;		 YY
;		 char - pixel color 0x00 BLACK(no light no pixel drawn) 0xFF WHITE
;@USED:  Y,axl,axh,temp,r0,r1,r15,r17,r18,argument
******************************************************************************************/
sh1107_draw_buffer_pixel:
    
	;position buffer at 0
	ldi YL,low(graphics_buffer)
	ldi YH,high(graphics_buffer)
	
	;(pos_x+((pos_y/8)*SSD1306_WIDTH))	
	mov dres8u,YY			;keep result in r16 and remainder in r15
	ldi dv8u,8				;devide by 8
    rcall div8u

    ;multiply by lcd width
	ldi axl,SH1107_WIDTH
	mul axl,r16				;r16 comes from above
	;add it to pointer
	ADD16 YL,YH,r0,r1

	;add pos X to pointer
	clr axh
	ADD16 YL,YH,XX,axh

	//read byte from buffer
	ld argument,Y
	
	mov temp,r15    ;remainder number to byte mask conv
	clr r15
	inc r15         ;start from 1
drpxy_00:    
    tst temp
	breq drpxy_01
	lsl r15 
	dec temp
	rjmp drpxy_00

drpxy_01:
    tst char
	breq drpxy_white
						;WHITE pixel
    or argument,r15		;set bit to color in byte
	;save back in buffer
	st Y,argument


ret

drpxy_white:			
	                    ;BLACK pixel
    com r15						     
	and argument,r15
	;save back in buffer
	st Y,argument
ret
;***************************************************************************
;*
;* "div8u" - 8/8 Bit Unsigned Division
;*
;* This subroutine divides the two register variables "dd8u" (dividend) and
;* "dv8u" (divisor). The result is placed in "dres8u" and the remainder in
;* "drem8u".
;*
;* Number of words	:14
;* Number of cycles	:97
;* Low registers used	:1 (drem8u)
;* High registers used  :3 (dres8u/dd8u,dv8u,dcnt8u)
;*
;***************************************************************************
div8u:	
    sub	drem8u,drem8u	;clear remainder and carry
	ldi	dcnt8u,9	;init loop counter
d8u_1:	rol	dd8u		;shift left dividend
	dec	dcnt8u		;decrement counter
	brne	d8u_2		;if done
	ret			;    return
d8u_2:	rol	drem8u		;shift dividend into remainder
	sub	drem8u,dv8u	;remainder = remainder - divisor
	brcc	d8u_3		;if result negative
	add	drem8u,dv8u	;    restore remainder
	clc			;    clear carry to be shifted into result
	rjmp	d8u_1		;else
d8u_3:	sec			;    set carry to be shifted into result
	rjmp	d8u_1

.include "tasks/font.inc"
.EXIT