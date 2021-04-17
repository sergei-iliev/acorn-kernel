/***********LOCK BASED ON TEST_AND_SET ALGORITHM*****************************************
AUTHOR:sergei_iliev@yahoo.com
Simple spin lock synchronization structure implementation based on test-and-set algorithm.
No fairness - a thread spinning can spin forever under contention. Simple spin licks are not fair and may lead to starvation
RAM structure of 1 byte:

1 byte  -> to hold lock status(0x00 released; 0xFF busy)
*/

/************************LOCK************************************** 
;		Set the flag to not signaled on entering the guarded section.
;		called in the context of a thread to mark the BEGIN of the protected code section.
;		Unlimited number of threads could contend for the lock
;INPUT: @0 - lock RAM byte
;USAGE: r16,r17(saved on current task stack)
*******************************************************************/
.MACRO _LOCK
	push r16
	push r17	

spin:
	ldi  r17,0xFF	;busy flag	 
	
	cli				;------>atomic start
	lds r16,@0		;read and keep old value
	sts @0,r17		;set the busy flag
	sei				;------>atomic end
	
	tst r16 
	breq spinend     ;lock is released
	
	_YIELD_TASK 	;lock is busy - keep spinning
    rjmp spin 

spinend:	 
	pop r17
	pop r16
.ENDMACRO

/************************UNLOCK************************************** 
;		Set the flag to signaled on entering the guarded section.
;		Called in the context of a thread to mark the END of the protected code section.
;INPUT: @0 - lock RAM byte
;USAGE: r16(saved on current task stack)
*******************************************************************/

.MACRO _UNLOCK
	push r16

	ldi  r16,0x00	;release flag	
	;atomic instruction
	sts @0,r16
	
	pop r16
.ENDMACRO

.EXIT