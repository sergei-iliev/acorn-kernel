/***************************************************THREAD SAFE SINGLE PRODUCER SINGLE CONSUMER Condition Variable******************************************************************
Condition variable enables a thread to sleep until another thread signals that a condition has changed.
It’s used alongside a mutex to protect shared state and coordinate access.
Current implementation is a simplified condition variable - single task to single task notification/synchronization without the need of using mutex


RAM usage -  memory structure
|P|W|-|-|T|T|T|T|

P -> Predicate flag bit 1 - TRUE , 0 - FALSE
W -> Task is waiting on cv flag bit 1 -> there is a task waiitng, 0 -> no task is waiting 
T -> Task Id waiting on the condition predicate number (up to 15) 
*/

.equ CV_PREDICATE_BIT = 7
.equ CV_TASKWAITING_BIT = 6

/***************************init queue************************
@INPUT: Z - condition variable RAM pointer		
@USAGE: temp
*************************************************************/
cv_init:
	clr temp
	st Z,temp    	
ret

/***************************wait************************
@INPUT: Z - condition variable RAM pointer		
@USAGE: temp,r17
@STACK: Look in _SUSPEND_TASK	
@WARNING: Task calling it will suspend -> NOT RUNNABLE	
*************************************************************/
cv_wait:
 ; --- STEP 1: Block Preemption ---    
    CLI                           ; Disable interrupts (Acorn scheduler stops)

 ; --- STEP 2: Check Predicate ---
    ld     r17, Z
    sbrc   r17,CV_PREDICATE_BIT
    rjmp   cv_wait_00     ; If data is ready, jump out
 ; --- STEP 3: Atomic Suspend Registration ---
    ; Register this task as waiting and block it BEFORE turning interrupts back on!
	_GET_TASK_ID r17
	;set task waiting bit along side task id
	sbr r17,1<<CV_TASKWAITING_BIT
    ;store
	st Z,r17
    
	_SUSPEND_TASK   ;will enable interrupt SEI
	;SEI is ON here
	rjmp    cv_wait   ; When awakened, start over (re-check)
cv_wait_00:
    ; Clear predicate and task id
    ldi     r17, 0
    st		Z,r17    
	SEI
ret

/***************************wait************************
@INPUT: Z - condition variable RAM pointer				
@USAGE: temp,r17,Y
@STACK: 	
*************************************************************/
cv_signal:
    ; --- STEP 1: Guard State Change ---
    
    CLI

	; --- STEP 2: Predicate is ON ---
    ld     r17, Z	
	sbr	   r17,(1<<CV_PREDICATE_BIT)
    st     Z, r17   ; Signal that data is ready

    ; --- STEP 3: Signal Waking ---
    sbrs    r17, CV_TASKWAITING_BIT
	rjmp    cv_signal_00   
	 
	; Wake up the consumer task        
    andi    r17, 0x0F    ;extract task id
	ldi		temp,TASK_TCB_SIZE
    mul		temp,r17   ;r1:r0 result
    ldi		YH,high(TCB)
	ldi		YL,low(TCB)
	ADD16	YL,YH,r0,r1
        
	;Y points to waiting task TCB 
	ldd r17,Y+TASK_STATE_OFFSET
	;set to runnable	
	cbr r17,(1<<TASK_SCHEDULABLE_BIT) ;set to 0=activate task(we want to run in NORMAL LEVEL where active flag is checked by the schedular)
    ;store
	std Y+TASK_STATE_OFFSET,r17
	
cv_signal_00:   
   SEI
   _YIELD_TASK  
ret

