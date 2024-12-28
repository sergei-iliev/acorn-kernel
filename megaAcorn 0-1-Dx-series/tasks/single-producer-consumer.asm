/***************************************************THREAD SAFE SINGLE PRODUCER SINGLE CONSUMER CIRCULAR QUEUE 8/16 bit******************************************************************
Circular lock free single producer consumer queue - thread safe
@WARNING: SINGLE PRODUCER task and SINGLE CONSUMER task ONLY
8 bit API is protected without cli/sei pair 
16 bit API is protected by cli/sei pair 
If more tasks are involved on eigther side the thread safe design will be broken
The wait-free nature of the queue gives a fixed number of steps for each operation. 
The lock-free nature of the queue enables two thread communication from a single source thread (the Producer) to a single destination thread (the Consumer) without using any locks.
The power of wait-free and lock-free together makes this type of circular queue attractive in a range of areas, from interrupt and signal handlers to real-time systems or other time sensitive software.
There is one index position unused to mark full queue
https://www.codeproject.com/Articles/43510/Lock-Free-Single-Producer-Single-Consumer-Circular

8 bit memory structure
1.byte - head index points to next occupied slot to be read,starts from 0 index
1.byte - tail index points to next free slot to be written, starts from 0 index
N < 256 size byte array (each element 1 byte long)
*/

#define HEAD_OFFSET 0
#define TAIL_OFFSET 1
#define BUFFER_OFFSET 2

#define HEAD_OFFSET16 0
#define TAIL_OFFSET16 2
#define BUFFER_OFFSET16 4

.cseg
/**********************************************************************16 bit Queue*****************************************************/
/***************************init queue************************
@INPUT: Z - queue pointer		
@USAGE: temp		
*************************************************************/
spc_queue16_init:    
    clr temp

	std Z+(HEAD_OFFSET16),temp     ;head MSB 
	std Z+(HEAD_OFFSET16+1),temp   ;head LSB
	std Z+(TAIL_OFFSET16),temp	 ;tail MSB   
	std Z+(TAIL_OFFSET16+1),temp	 ;tail LSB  	 
	
ret
/******************************Push Item in  queue***********************
@WARNING: Task call only
@INPUT: Z - queue pointer 
		axh:axl - MAX size of backing static array
		dxh:dxl - value
@USAGE: bxl,bxh,r0,r1,r2,r3
@OUTPUT: T flag 0 - failure
				1 - success
*************************************************************/
spc_queue16_push:  
	rcall spc_queue16_is_full	;When the buffer is empty, both indexes will be the same.
	brts spcque16push_0					;it is full

	;preserve buffer 0 index
	mov r0,ZL
	mov r1,ZH	
	
	;!!!!!!single producer PUSH is only call to modify TAIL -> safe call no need of cli
	ldd bxh,Z+TAIL_OFFSET16	;current tail MSB
	ldd bxl,Z+TAIL_OFFSET16+1	;current tail LSB

	adiw ZH:ZL,BUFFER_OFFSET16			;position to beginning of buffer

	;2 byte value -> multiply by 2 to real buffer index
	mov r2,bxl	
	mov r3,bxh
	LSL16 r3,r2

	ADD16 ZL,ZH,r2,r3		;position on next index
;1. store value FIRST
	st Z+,dxh				;store 16 bit value
	st Z,dxl
	;fix tail index->move to next free index slot in array
	ADDI16 bxl,bxh,1
	
	CP16 bxl,bxh,axl,axh		; >MAX
	brlo spcque16enq_1	
	;start from 0 index
	clr bxl
	clr bxh		 
spcque16enq_1:	
	;restore 
	mov ZL,r0
	mov ZH,r1	

;2. store index LAST	
	cli		;Task call only
	std Z+TAIL_OFFSET16,bxh  ;store new tail index
	std Z+TAIL_OFFSET16+1,bxl  ;store new tail index
	sei

	set					;value inserted
ret
spcque16push_0:
	clt					;buffer is full
ret

/******************************Push Item in  queue from ISR***********************
@WARNING: ISR call only
@INPUT: Z - queue pointer 
		axh:axl - MAX size of backing static array
		dxh:dxl - value
@USAGE: bxl,bxh,r0,r1,r2,r3
@OUTPUT: T flag 0 - failure
				1 - success
*************************************************************/
spc_queue16_push_from_isr:    
	rcall spc_queue16_is_full_from_isr	;When the buffer is empty, both indexes will be the same.
	brts spcque16pushisr_0					;it is full

	;preserve buffer 0 index
	mov r0,ZL
	mov r1,ZH	
	
	;!!!!!!single producer PUSH is only call to modify TAIL -> safe call no need of cli
	ldd bxh,Z+TAIL_OFFSET16	;current tail MSB
	ldd bxl,Z+TAIL_OFFSET16+1	;current tail LSB

	adiw ZH:ZL,BUFFER_OFFSET16			;position to beginning of buffer

	;2 byte value -> multiply by 2 to real buffer index
	mov r2,bxl	
	mov r3,bxh
	LSL16 r3,r2

	ADD16 ZL,ZH,r2,r3		;position on next index
;1. store value FIRST
	st Z+,dxh				;store 16 bit value
	st Z,dxl
	;fix tail index->move to next free index slot in array
	ADDI16 bxl,bxh,1
	
	CP16 bxl,bxh,axl,axh		; >MAX
	brlo spcque16enqisr_1	
	;start from 0 index
	clr bxl
	clr bxh		 
spcque16enqisr_1:	
	;restore 
	mov ZL,r0
	mov ZH,r1	

;2. store index LAST	
	;cli		;ISR call only no nesting allowed so we are saved since ISR handler is atomic
	std Z+TAIL_OFFSET16,bxh  ;store new tail index
	std Z+TAIL_OFFSET16+1,bxl  ;store new tail index
	;sei

	set					;value inserted
ret
spcque16pushisr_0:
	clt					;buffer is full
ret
/*************************Pop Item from Queue************************
@WARNING: Task call only
@INPUT: Z - queue pointer 
		axh,axl - length of backing static array
@USAGE: bxl,bxh,r0,r1,r2,r3			
@OUTPUT: T flag 0 - failure
				1 - success
		dxh:dxl - value
*********************************************************/
spc_queue16_pop:
	rcall spc_queue16_is_empty
	brts spcque16deq_0					;it is empty

	;preserve buffer 0 index
	mov r0,ZL
	mov r1,ZH
	;!!!!!!single consumer POP is only call to modify HEAD -> safe call no need of cli	
	ldd bxh,Z+HEAD_OFFSET16		;head index MSB
	ldd bxl,Z+HEAD_OFFSET16+1	;head index LSB

	adiw ZH:ZL,BUFFER_OFFSET16			;position to beginning of buffer

	;2 byte value -> multiply by 2 to real buffer position
	mov r2,bxl	
	mov r3,bxh
	LSL16 r3,r2

	ADD16 ZL,ZH,r2,r3
;1. read value FIRST
	ld dxh,Z+				;read 16 bit value
	ld dxl,Z
	;fix tail index->move to next free index slot in array
	ADDI16 bxl,bxh,1
	
	CP16 bxl,bxh,axl,axh		; >MAX
	brlo spcque16deq_1	
	;start from 0 index
	clr bxl
	clr bxh		 
spcque16deq_1:	
	;restore 
	mov ZL,r0
	mov ZH,r1	
;2. store index LAST
	cli	;Task call only
	std Z+HEAD_OFFSET16,bxh  ;store new head index
	std Z+HEAD_OFFSET16+1,bxl  ;store new head index
	sei

	set
ret
spcque16deq_0:		
	clt 
ret
/*********Read current filled/occupied size*******
@WARNING: Task call only
@INPUT: Z queue pointer 
        axh:axl - MAX size of backing buffer		
@USAGE: bxh,bxl,cxh,chl
@OUTPUT: T flag 0 - not full
				1 - full
***************************************************/
spc_queue16_is_full:
    clt
    
	cli				;Make it ATOMIC within Task context	
	ldd bxh,Z+TAIL_OFFSET16	;current tail MSB
	ldd bxl,Z+TAIL_OFFSET16+1	;current tail LSB

	ldd cxh,Z+HEAD_OFFSET16	;current head MSB
	ldd cxl,Z+HEAD_OFFSET16+1	;current head LSB
	sei
	
	;fix tail index->move to next free index slot in array
	ADDI16 bxl,bxh,1
	
	CP16 bxl,bxh,axl,axh		; >MAX
	brlo spcque16full_1	
	;start from 0 index
	clr bxl
	clr bxh		 
spcque16full_1:
    CP16 bxl,bxh,cxl,cxh    ;compair tail and head index
	brne spcque16full_0     ;not equal	             
	set 
ret
spcque16full_0:
ret
/*********Is queue full from ISR*******
@WARNING: ISR call only 
@INPUT: Z queue pointer 
        axh:axl - MAX size of backing buffer		
@USAGE: bxh,bxl,cxh,chl
@OUTPUT: T flag 0 - not full
				1 - full
***************************************************/
spc_queue16_is_full_from_isr:
    clt
    	
	ldd bxh,Z+TAIL_OFFSET16	;current tail MSB
	ldd bxl,Z+TAIL_OFFSET16+1	;current tail LSB

	ldd cxh,Z+HEAD_OFFSET16	;current head MSB
	ldd cxl,Z+HEAD_OFFSET16+1	;current head LSB	
	
	;fix tail index->move to next free index slot in array
	ADDI16 bxl,bxh,1
	
	CP16 bxl,bxh,axl,axh		; >MAX
	brlo spcque16full_1_isr	
	;start from 0 index
	clr bxl
	clr bxh		 
spcque16full_1_isr:
    CP16 bxl,bxh,cxl,cxh    ;compair tail and head index
	brne spcque16full_0_isr     ;not equal	             
	set 
ret
spcque16full_0_isr:
ret
/*********Is queue empty*******
@WARNING: Task call only
@INPUT: Z queue pointer 	
@USAGE: bxh,bxl,cxh,chl
@OUTPUT: T flag 0 - not empty
				1 - empty
********************************/
spc_queue16_is_empty:
  clt    

  cli	;ATOMIC within Task context				
  ldd bxh,Z+TAIL_OFFSET16	;current tail MSB
  ldd bxl,Z+TAIL_OFFSET16+1	;current tail LSB

  ldd cxh,Z+HEAD_OFFSET16	;current head MSB
  ldd cxl,Z+HEAD_OFFSET16+1	;current head LSB
  sei

  CP16 bxl,bxh,cxl,cxh
  breq spcque16ty_0			;if equal -> empty queue
ret
spcque16ty_0:
  set
ret
/************************************************************8 bit********************************************/

/***************************init queue************************
@INPUT: Z - queue pointer		
@USAGE: temp		
*************************************************************/
spc_queue8_init:    
    clr temp

	std Z+HEAD_OFFSET,temp   ;head
	std Z+TAIL_OFFSET,temp	 ;tail        
ret

/******************************Push Item in Queue***********************
Executed by Producer task only
Producer adds new item at the position indexed by the tail. 
After writing, the tail is incremented one step, or wrapped to the beginning if at end of the queue.
The queue grows with the tail.
When queue is full, there is one position difference between tail and head
 
@INPUT: Z - queue pointer 
		axl - length of backing static array
		argument - value
@USAGE: bxl,bxh,r0,r1
@OUTPUT: T flag 0 - failure
				1 - success
*************************************************************/
spc_queue8_push:    
	rcall spc_queue8_is_full	;When the buffer is empty, both indexes will be the same.
	brts spcque8push_0					;it is full
    
	;preserve buffer 0 index
	mov r0,ZL
	mov r1,ZH

	ldd bxl,Z+TAIL_OFFSET  ;tail index
	adiw ZH:ZL,BUFFER_OFFSET			;position to beginning of buffer

	clr bxh
	ADD16 ZL,ZH,bxl,bxh
;1. store value FIRST
	st Z,argument
	;move to next free index slot in array
	inc bxl
	cp bxl,axl		; >MAX
	brlo spcque8enq_1	
	//start from 0 index
	clr bxl			 
spcque8enq_1:	
	mov ZL,r0
	mov ZH,r1
;2. store index LAST	
	std Z+TAIL_OFFSET,bxl  ;store new tail index	ATOMIC
	set					;value inserted
ret
spcque8push_0:
	clt					;buffer is full
ret

/*************************Pop Item from Queue************************
The Consumer retrieves, pop(), the item indexed by the head. 
The head is moved toward the tail as it is incremented one step. 
The queue shrinks with the head.
When the queue is full, there will be a one slot difference between head and tail. 
At this point, any writes by the Producer will fail. 
Yes it must even fail since otherwise the empty queue criterion i.e. head == tail would come true.
@INPUT: Z - queue pointer 
		axl - length of backing static array
@USAGE: bxl,bxh,r0,r1			
@OUTPUT: T flag 0 - failure
				1 - success
		return - value
*********************************************************/
spc_queue8_pop:
	rcall spc_queue8_is_empty
	brts spcque8deq_0					;it is empty
	
	;preserve buffer 0 index
	mov r0,ZL
	mov r1,ZH

	ldd bxl,Z+HEAD_OFFSET  ;head index
	adiw ZH:ZL,BUFFER_OFFSET			;position to beginning of buffer

	clr bxh
	ADD16 ZL,ZH,bxl,bxh
;1. read value FIRST
	ld return,Z
	;move to next data index slot in array
	inc bxl
	cp bxl,axl		; >MAX
	brlo spcque8deq_1	
	//start from 0 index
	clr bxl			 
spcque8deq_1:	
	mov ZL,r0
	mov ZH,r1
;2. store index LAST
	std Z+HEAD_OFFSET,bxl  ;store new head index	ATOMIC
	set
ret
spcque8deq_0:		
	clt  
ret

/*********Is Queue Full*******
When the queue is full, there will be a one slot difference between head and tail. 
At this point, any writes by the Producer will fail. 
Yes it must even fail since otherwise the empty queue criterion i.e. head == tail would come true.
@INPUT: Z queue pointer         
		axl - length of backing static array
@USAGE: bxl - tail
		bxh - head
@OUTPUT: T flag 0 - not full
				1 - full
***************************************************/

spc_queue8_is_full:
    clt
    ldd bxl,Z+TAIL_OFFSET	;current tail
	ldd bxh,Z+HEAD_OFFSET	;current head

	;increment tail and fix index position
	inc bxl
	cp bxl,axl		; >MAX
	brlo spcque8full_1	
	//start from 0 index
	clr bxl
spcque8full_1:
    cp bxl,bxh
	brne spcque8full_0     ;not equal	
	set 
ret
spcque8full_0:
ret

/*********Is queue empty*******
@INPUT: Z queue pointer 
@USAGE: bxl - tail
		bxh - head
@OUTPUT: T flag 0 - not empty
				1 - empty
********************************/

spc_queue8_is_empty:
  clt
  ldd bxl,Z+HEAD_OFFSET	;current head
  ldd bxh,Z+TAIL_OFFSET	;current tail
  
  cp bxl,bxh
  breq spcque8ty_0			;if equal -> empty queue
ret
spcque8ty_0:
  set
ret
