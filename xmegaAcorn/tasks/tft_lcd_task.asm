.include "tasks/st7735.asm"

/* tft lcd task to render images comming from web serial interface */
tft_lcd_task:

	_SLEEP_TASK 255
	rcall ST7735_init

	rcall ST7735_clear_screen
	
	//draw text once
	rcall draw_hello_world_text

	_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER


tft_lcd_main:

	
    _YIELD_TASK
	
rjmp tft_lcd_main



;**************draw default font text
draw_text_default:
	ldi temp,10
    mov startX,temp  
    ldi temp,10
    mov startY,temp 
	ldi argument,'S'
	  //COLOR
	ldi dxh,high(RED)
	ldi dxl,low(RED)  
	rcall ST7735_draw_char

	ldi temp,16
    mov startX,temp  
    ldi temp,10
    mov startY,temp 
	ldi argument,'e'
	  //COLOR
	;ldi dxh,high(RED)
	;ldi dxl,low(RED)  

	rcall ST7735_draw_char

	ldi temp,22
    mov startX,temp  
    ldi temp,10
    mov startY,temp 
	ldi argument,'r'
	rcall ST7735_draw_char

	ldi temp,28
    mov startX,temp  
    ldi temp,10
    mov startY,temp 
	ldi argument,'g'
	rcall ST7735_draw_char

	
	ldi temp,34
    mov startX,temp  
    ldi temp,10
    mov startY,temp 
	ldi argument,'e'
	rcall ST7735_draw_char

	
	ldi temp,40
    mov startX,temp  
    ldi temp,10
    mov startY,temp 
	ldi argument,'y'
	rcall ST7735_draw_char

ret


;sloped line
draw_slope_line:
  //COLOR
  ldi dxh,high(RED)
  ldi dxl,low(RED)  

  ldi counter,5    ;Y counter
  
  
  ldi temp,20    
  mov r10,temp

  slpline_00:  
  mov startX,r10
  mov startY,counter
  rcall ST7735_draw_point

  inc r10

  inc counter
  cpi counter,100
  brlo slpline_00

ret

;horizontal line
draw_hor_line:
  
  //COLOR
  ldi dxh,high(RED)
  ldi dxl,low(RED)  

  ldi counter,0    ;X counter
  
  ldi temp,129
  mov startY,temp

line_00:  
  
  mov startX,counter
  rcall ST7735_draw_point

  inc counter
  cpi counter,160
  brlo line_00

ret

;draw several points
draw_points:  
  ldi temp,45
  mov startX,temp
  
  ldi temp,15
  mov startY,temp
  
    //COLOR
  ldi dxh,high(YELLOW)
  ldi dxl,low(YELLOW)

  rcall ST7735_draw_point

  ldi temp,46
  mov startX,temp
  
  ldi temp,16
  mov startY,temp
  
  //COLOR
  ldi dxh,high(YELLOW)
  ldi dxl,low(YELLOW)

  rcall ST7735_draw_point

  ldi temp,47
  mov startX,temp
  
  ldi temp,17
  mov startY,temp
  
  //COLOR
  ldi dxh,high(YELLOW)
  ldi dxl,low(YELLOW)

  rcall ST7735_draw_point

ret

draw_filled_rect:
  //X1
  ldi temp,50
  mov startX,temp
  //X2
  ldi temp,100
  mov endX,temp
  //Y1
  ldi temp,50
  mov startY,temp
  //Y2
  ldi temp,80
  mov endY,temp
  
  //SIZE
  ldi bxh,high((51*31))  //(rows+1)*(cols+1)
  ldi bxl,low((51*31))
  
  //COLOR
  ldi dxh,high(CYAN)
  ldi dxl,low(CYAN)
  

  rcall ST7735_draw_rect

ret

/*****************************************
TEST col and page positioning for text roboto
******************************************/
draw_hello_world_text:

   clr startX
   clr startY   


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
   mov temp,startX
   subi temp,-1*ROBOTO_CHAR_COLS_LEN  ;next char offset in roboto
   mov startX,temp ;input

          
   ;color
   ldi dxh,high(YELLOW)
   ldi dxl,low(YELLOW)
   
   push startY  ;it is modified in ST7735_draw_char_roboto
   call ST7735_draw_char_roboto
   pop startY

   pop ZL
   pop ZH   
   rjmp dr_ml_loop

dr_ml_nxt_line:
   
   ;calculate next Y pos
   mov temp,startY
   subi temp,-1*ROBOTO_CHARS_ROWS_LEN  ;next line
   mov startY,temp 

   clr startX

   rjmp dr_ml_loop

dr_ml_nxt_ext:

   
ret


hello_world:
.db "FOR GOD SO LOVED ",0x0A
.db "THE WORLD THAT HE",0x0A
.db "GAVE HIS ONLY SON",0x0A
.db "THAT WHOEVER ",0x0A
.db "BELIEVES IN HIM",0x0A
.db "MAY NOT PERISH ",0x0A
.db "BUT HAVE ETERNAL ",0x0A
.db "LIVE ",0x0C