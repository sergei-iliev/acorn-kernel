.include "tasks/st7735.asm"
tft_lcd_task:     
	_THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER

//**** test snipet start
      ;position text cursor
	  ldi temp,20
	  sts PosX,temp
	  sts PosY,temp

	  ;input char from ASCI table 
	  ldi argument,'1'
	  subi argument,32   //calc row number

	  ;translate to bytes representation in fonts table
	  ldi	ZH,high(font*2)
      ldi	ZL,low(font*2)
	   
	  ldi r20,5				//cols const
	  mov r21,argument             //row number variable
	  MUL r20,r21
	  
      ADD16 ZL,ZH,r0,r1
	  //add padding 0's to each row
	  //this will position pointer at beginning left most
	  clr r20
	  ADD16 ZL,ZH,r21,r20
	  //this will position pointer right most -> better since we decrement
	  ADDI16 ZL,ZH,4

	  ldi temp,5       //column number
	  mov r10,temp

	  
lrb_1:
	  tst r10
	  breq lrb_2           ;all columns?
	  
	  lpm					;read next col from font 8x5
	  mov	argument,r0	
	  	  
 	  //loop through 8 row bits
	  ldi temp,8
	  mov r9,temp
lrb_row_1:
      tst r9
	  breq lrb_row_2

	  lsl argument
	  brcc no_pixel
	  //draw black pixel
	  
	  nop
	  nop
no_pixel:
      dec r9
	  rjmp lrb_row_1

lrb_row_2:
	  sbiw ZH:ZL,1         //move to next column

	  dec r10
	  rjmp lrb_1
lrb_2:	
//**** test snipet end
	_SLEEP_TASK 255
	rcall ST7735_init

	rcall ST7735_clear_screen
	
tft_lcd_main:
    rcall draw_hor_line
    rcall draw_slope_line
	//rcall draw_point
	rcall draw_filled_rect
    
stop:rjmp stop

rjmp tft_lcd_main





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

  ldi counter,5    ;X counter
  
  ldi temp,5
  mov startY,temp

line_00:  
  
  mov startX,counter
  rcall ST7735_draw_point

  inc counter
  cpi counter,120
  brlo line_00

ret


draw_point:  
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
  ldi dxh,high(BLUE)
  ldi dxl,low(BLUE)
  

  rcall ST7735_draw_rect

ret



