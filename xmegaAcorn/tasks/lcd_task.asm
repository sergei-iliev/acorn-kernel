/*
Task to drive GDSC-0801WP display
It animates acorn micro kernel logo
*/

.SET RS_BIT=1
.SET RW_BIT=2
.SET EN_BIT=3

.include "tasks\GDSC-0801WP.asm"
//lcd frame for animation
.dseg
LCD_FRAME: .byte 8
.cseg

lcd_task:
    _THRESHOLD_BARRIER_WAIT  InitTasksBarrier,TASKS_NUMBER    	
	rcall lcd_init  
main_lcd:
	
	;animate text forever
	rcall lcd_send_rom_text

rjmp main_lcd


/**************SEND LCD ROM TEXT in LOOP******************************
Send static text written FLASH to LCD
@INPUT: Z - ROM pointer to text ,should add count too but ..... it is a dummy driver
@USAGE: Z,X,temp,axl
***********************************************************************/
lcd_send_rom_text:

lcd_rtxt_00:
	ldi ZH,high(TEXT*2)
	ldi ZL,low(TEXT*2)
	
lcd_rtxt_001:
	ldi YH,high(LCD_FRAME)
	ldi YL,low(LCD_FRAME)
	
	ldi counter,8

lcd_rtxt_01:
	lpm temp,Z+
	st Y+,temp
	;test if END terminator
	cpi temp,0
	breq lcd_rtxt_00

	dec counter
	tst counter
	brne lcd_rtxt_01

	;***show frame from RAM
	
	ldi YH,high(LCD_FRAME)
	ldi YL,low(LCD_FRAME)	
	ldi counter,8

lcd_rtxt_02:
	ld argument,Y+
	rcall lcd_send_char
	dec counter
	tst counter
	brne lcd_rtxt_02


	_SLEEP_TASK_EXT 1000
	;lcd clear 
	rcall lcd_clr_screen

	;next frame from Z	
	SUBI16 ZL,ZH,7 
	rjmp lcd_rtxt_001 
 
ret

/*
Send simple text example
*/
lcd_send_text:
    ldi argument,'A'
	rcall lcd_send_char 

    ldi argument, 'C'
	rcall lcd_send_char 

    ldi argument, 'O'
	rcall lcd_send_char 

    ldi argument, 'R'
	rcall lcd_send_char

    ldi argument, 'N'
	rcall lcd_send_char

    ldi argument, ' '
	rcall lcd_send_char

    ldi argument, 'v'
	rcall lcd_send_char

    ldi argument, '3'
	rcall lcd_send_char

ret



