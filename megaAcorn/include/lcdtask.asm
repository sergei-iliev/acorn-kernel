.def    argument=r17   
.def    return = r18
.def    t1=r19
.def    t2=r20
.def    counter=r21

;.set LCD_EVENT=6

/*
LCD RAM
*/
.dseg
BCD01: .byte 1		;BCD value digits 1 and 0
BCD23: .byte 1		;BCD value digits 3 and 4  ;meaningfull weather temp
BCD45: .byte 1		;BCD value digits 5 and 6  ;meaningfull weather temp	
BCD67: .byte 1		;BCD value digits 7 and 8
BCD89: .byte 1		;BCD value digit 9
.cseg

.include "include/LCD4bitWinstarDriver.asm"

Task_3:

	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
	
	rcall lcd4_init

	ldi argument,LCD_LINE_1 
	rcall lcd4_command

	ldi	argument,'A'
	rcall lcd4_putchar
	

	ldi	argument,'c'
	rcall lcd4_putchar

	ldi	argument,'o'
	rcall lcd4_putchar

	ldi	argument,'r'
	rcall lcd4_putchar

	ldi	argument,'n'
	rcall lcd4_putchar

	ldi  argument,' '
	rcall lcd4_putchar 

  
	ldi	argument,'1'
	rcall lcd4_putchar

	ldi	argument,'-'
	rcall lcd4_putchar

	ldi	argument,'w'
	rcall lcd4_putchar

	ldi	argument,'i'
	rcall lcd4_putchar

	ldi	argument,'r'
	rcall lcd4_putchar

	ldi	argument,'e'
	rcall lcd4_putchar

main3:

	;_EVENT_WAIT LCD_EVENT
	_SLEEP_TASK 100
	ldi argument,LCD_LINE_2
	rcall lcd4_command

   
   ;check if negative
	ldi	argument,'-'
	lds return,TH
	sbrc return,7
	rcall lcd4_putchar

	lds	argument,BCD45		   
	rcall lcd4_bcd_out_remove_leading_zero
	ldi	argument,'.'
	rcall lcd4_putchar  
	lds	argument,BCD23
	rcall lcd4_BCD_out

   
	ldi argument,0xDF
	rcall lcd4_putchar

	ldi argument,'C'
	rcall lcd4_putchar

	_SLEEP_CPU_READY  VOID_CALLBACK,VOID_CALLBACK,r16,r17
rjmp main3

ret
