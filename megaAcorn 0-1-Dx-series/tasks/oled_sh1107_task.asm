.include "tasks/twi.asm"
.include "tasks/sh1107.asm"

oled_sh1107_task:

	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER

   	_SLEEP_TASK_EXT 255		 

	call sh1107_setup  
	call sh1107_clear_screen

main_oled:

    ;rcall test_buffer_text_out
	;rcall test_buffer_text_roboto_out
	rcall hello_buffer_multiline_text

	;put the CPU to sleep
    _SLEEP_CPU temp	
stop: rjmp stop	;stay here forever
rjmp main_oled

/*
TEST buffer text roboto out
Render text on buffer first and then send buffer to OLED
Loop through char changes
*/
test_buffer_text_roboto_out:
   ;X and Y  
   ldi temp,11
   mov XX,temp  
   ldi temp,100
   mov YY,temp 

   ldi argument,'N'
  
   call sh1107_draw_buffer_char_roboto 
   
   ldi temp,11+8
   mov XX,temp  
   ldi temp,100
   mov YY,temp 

   ldi argument,'G'
  
   call sh1107_draw_buffer_char_roboto 
   
   ldi temp,11+8+8
   mov XX,temp  
   ldi temp,100
   mov YY,temp 

   ldi argument,'I'
  
   call sh1107_draw_buffer_char_roboto 

   ldi temp,11+8+8+8
   mov XX,temp  
   ldi temp,100
   mov YY,temp 

   ldi argument,'N'
  
   call sh1107_draw_buffer_char_roboto 
   ldi temp,11+8+8+8+8
   mov XX,temp  
   ldi temp,100
   mov YY,temp 

   ldi argument,'X'
  
   call sh1107_draw_buffer_char_roboto 
   
   
   ldi temp,11+8+8+8+8+8+8
   mov XX,temp  
   ldi temp,100
   mov YY,temp 

   ldi argument,'$'  
   call sh1107_draw_buffer_char_roboto 
   
  ;update buffer
   call sh1107_send_buffer
   
ret


/*
TEST buffer text out
Render text on buffer first and then send buffer to OLED
Loop through char changes
*/
test_buffer_text_out:
   ;X and Y  
   ldi temp,12
   mov XX,temp  
   ldi temp,100
   mov YY,temp 

   ldi argument,'y'
   call sh1107_draw_buffer_char
  ;update buffer
   call sh1107_send_buffer

_SLEEP_TASK_EXT 255

   ldi temp,50
   mov XX,temp  
   ldi temp,7
   mov YY,temp 

   ldi argument,'Q'
   call sh1107_draw_buffer_char

  ;update buffer
   call sh1107_send_buffer

_SLEEP_TASK_EXT 255
ret


/*
TEST col and page positioning for text
*/
hello_buffer_multiline_text:

   clr XX
   clr YY
   clr r14 ;counter


   ldi	ZH,high(hello_world*2)
   ldi	ZL,low(hello_world*2)

hello_loop_00:

   	     
   lpm argument, Z+ 
   cpi argument,0x0A
   breq nxt_line

   push ZH
   push ZL

   ;coordinates for next char
   mov temp,XX
   subi temp,-8  ;next char offset in roboto
   mov XX,temp ;input

   mov temp,r14
   mov YY,temp  ;input
       
   ;input   argument 
   call sh1107_draw_buffer_char_roboto

   pop ZL
   pop ZH   
   rjmp hello_loop_00
nxt_line:
   
   ;calculate next Y pos
   mov temp,r14
   subi temp,-15  ;next line
   mov r14,temp 

   cpi temp,(128-16)
   brsh nxt_ext

   clr XX

   rjmp hello_loop_00

nxt_ext:

  ;update buffer
   call sh1107_send_buffer
ret

hello_world:
.db "FOR GOD SO ",0x0A,"LOVED THE WORLD",0x0A,"THAT HE GAVE",0x0A,"HIS ONLY SON",0x0A
.db "THAT WHOEVER",0x0A,"BELIEVES IN HIM",0x0A,"MAY NOT PERISH",0x0A,"BUT HAVE ETERNAL LIVE",0x0A

.EXIT