/*
;Optimization for Devices with UP TO 256 bytes of RAM , reduce task context to 18 registers
Acorn introduces 2 basic logical levels of code execution:
1.USER mode - the code being executed by the tasks
2.KERNEL mode - the code being executed by the interrupt procedures
User mode is interuptible , it could be preempted by the task schedular or interupt
Kernel mode is NOT interruptible - MCU clears the global interrupt flag on each interrupt so 
any code within interrupt procedure is executed in an atomic fashion.
There are 2 priority levels:
1.PASSIVE level
2.DEVICE level
*/

#define OS TINYACORN

#define VERSION 2.3

;Comment out in production mode!!!!!!!!!!!!!!!!!!!!!!
#define DEBUG 


#ifndef SYSTEM_CLOCK  
.equ SYSTEM_CLOCK= 8000000   ;Hz
#endif


.EQU TASK_TCB_SIZE=3   ;TCB size is see below

;Optimization for Devices with 256 bytes of RAM
;-----------------------;
;1.LSB           Stack Address Low Bytes -to return when restoring the context
;-----------------------;
;2.Task status byte
;6bit->Is task schedulable(0-schedulable(default);1-not schedulable;Idle task is always schedulable)
;7bit->Task wait state(0-Normal state,1-timeout waiting)
;0-3bit-> Task ID number(up to 16 tasks)
;-----------------------
;3.Sleep Timeout - controled by schedular
;-----------------------;

;is high priority
.SET TASK_WAITING_BIT=7       ;task is in waiting with timeout state
;is task shedulable 
.SET TASK_SCHEDULABLE_BIT=6

;***wait timeout related
.EQU TASK_NO_WAITING=0

.EQU TASK_TIMEOUT_WAITING=1

;***scheduling related
.EQU TASK_SCHEDULABLE_ON=0

.EQU TASK_SCHEDULABLE_OFF=1


.SET TASK_CONTEXT=0x00

.SET INTERRUPT_CONTEXT=0x255

.SET TASK_NOT_SCHEDUALABLE=(1<<TASK_WAITING_BIT)+(1<<TASK_SCHEDULABLE_BIT)

/*
MUST be bigger then (TASK_STACK_REGISTER_DEPTH=18reg+SREG+2 return address)
*/
.EQU TASK_STACK_DEPTH=38 

.EQU TASK_STACK_REGISTER_DEPTH=21



#define THREAD_1  TASK_1

#define THREAD_2  TASK_2

#define THREAD_3  TASK_3

.dseg

;use 1 byte address structure for CPU with up to 256 bytes of RAM
pxCurrentTCB: .byte 1   ;keep address of the current TCB

#ifdef THREAD_1
#define TASKS_NUMBER 1   
TCB_1: .byte TASK_TCB_SIZE     ;Stack pointer LSB:MSB to the top of the task stack
#endif

#ifdef THREAD_2
#define TASKS_NUMBER 2
TCB_2: .byte TASK_TCB_SIZE
#endif

#ifdef THREAD_3
#define TASKS_NUMBER 3
TCB_3: .byte TASK_TCB_SIZE
#endif    

#ifdef THREAD_4
#define TASKS_NUMBER 4
TCB_4: .byte TASK_TCB_SIZE
#endif

#ifdef THREAD_5
#define TASKS_NUMBER 5
TCB_5: .byte TASK_TCB_SIZE
#endif

#ifdef THREAD_6
#define TASKS_NUMBER 6
TCB_6: .byte TASK_TCB_SIZE
#endif

.cseg
/*
Add more Threads(Tasks) here but mind the stack usage!!!
*/

.MACRO  _keOS_SAVE_CONTEXT
	push r0
	in r0,SREG
	push r0
	;push r1
	;push r2  
	;push r3
	;push r4
	;push r5 
	;push r6
	;push r7
	;push r8 
	;push r9
	;push r10
	;push r11 
	;push r12
	;push r13
	;push r14 
	push r15
	push r16
	push r17
	push r18
	push r19
	push r20 
	push r21
	push r22
	push r23
	push r24
	push r25
	push r26 
	push r27
	push r28
	push r29
	push r30
	push r31

    lds r26, pxCurrentTCB 
    ;lds r27, pxCurrentTCB + 1 
    ldi r27,0

	in r0, SP
    st x, r0 
    ;in r0, SPH
    ;st x, r0											 
.ENDMACRO

;new context is in pxCurentTCB
.MACRO  _keOS_RESTORE_CONTEXT
	lds r26, pxCurrentTCB
    ;lds r27, pxCurrentTCB + 1
    ldi r27,0

	ld r28, x 
	out SP, r28 
    ;ld r29, x 
	;out SPH, r29
    
	pop r31
	pop r30
	pop r29
	pop r28
    pop r27
	pop r26
	pop r25
	pop r24
    pop r23
	pop r22
	pop r21
	pop r20
    pop r19
	pop r18
	pop r17
	pop r16
    pop r15
	;pop r14
	;pop r13
	;pop r12
    ;pop r11
	;pop r10
	;pop r9
	;pop r8
    ;pop r7
	;pop r6
	;pop r5
	;pop r4
    ;pop r3
	;pop r2
    ;pop r1 
    pop r0 
    out SREG, r0 
    pop r0
.ENDMACRO

;----------------------------------
;KERNEL MODE API
;USAGE:	Used during kernel initialization,use any register
;INPUT:	@0  task label
;		@1  task Id   
;		@2  task control RAM block - TCB
;WARNING: Stack Pointer must be positioned at the end of RAM memory(RAMEND).
;----------------------------------
.MACRO  _REGISTER_TASK 
	ldi XL,low(@0)
	ldi XH,high(@0)
;position at the beginning of task stack	
	in YL,SP
	clr YH
	SUBI16 YL,YH,(@1-1)*TASK_STACK_DEPTH	    
;save inital return address to task begining
	mov r0,XL
	st Y,r0
	mov r0,XH
	st -Y,r0
    
;debug marker for end of tasks stack
#ifdef DEBUG
	in YL,SP
	clr YH
    SUBI16 YL,YH,((@1-1)*TASK_STACK_DEPTH)+TASK_STACK_DEPTH-1    
	ldi temp,0xAA
	st Y,temp
#endif    
;set the end of task stack = gen.regs+SREAG+previous PC
	in YL,SP
	clr YH
    SUBI16 YL,YH,((@1-1)*TASK_STACK_DEPTH)+TASK_STACK_REGISTER_DEPTH    
#ifdef DEBUG
    ldi temp,0xFF
    st Y,temp
#endif
;initial stack pointer position	
    mov r0,YL
	sts @2,r0
	;up to 256 RAM -> no need of YH it is always 0
	;mov r0,YH
	;sts @2+1,r0
    ldi temp,@1     ;set task's ID
	sts @2+1,temp  
.ENDMACRO



;----------------------------------
;USER MODE API
;USAGE:	Yield task (relinquish the quantum) to the next one.
;		RETI will activate the interrupt
;----------------------------------
.MACRO  _YIELD_TASK
    cli
 	rcall TaskSchedular
.ENDMACRO

;-------------------------------------------------------
;USER MODE API
;Start executive mode - ALL interrupts are turned off
;Use this in rear cases like 1-wire protocol.
;-------------------------------------------------------
.MACRO  _START_EXECUTIVE_MODE    
	cli 
.ENDMACRO

.MACRO  _END_EXECUTIVE_MODE
	sei
.ENDMACRO


;---------------DON'T USE(only for R&D)-------------------------------------------
;USER and KERNEL mode API
;USAGE:	Increase or decrease the tasks priority level
;USED:	XL,XH(saved on current task stack)
;		temp is saved on the stack by __PRE_INTERRUPT 	
;       if macro invoked from interrupt handler  
;INPUT:  @0 - context{0=task;0xFF=interrupt}
;        @1 - task number#{1,2,3,4......n} 
;		 @2 - Priority level	
;----------------------------------------------------------
/*
.MACRO	_SET_TASK_PRIORITY_LEVEL
    .IF @0==TASK_CONTEXT   ;no interrupt is possible if in interrupt,sei is NOT used
    cli
	push temp              ;
	.ENDIF

	push XL
	push XH
    ;calculate the target TCB and the byte offset where the priority bit is
    calculate_target_tcb_offset (@1-1)*TASK_TCB_SIZE,1

    ld temp,X	
    .IF @2==TASK_PRIORITY_INTERRUPT
    sbr temp,(1<<TASK_PRIORITY_BIT)         ;DEVICE level
    .ELSE 
    cbr temp,(1<<TASK_PRIORITY_BIT)         ;normal passive level
    .ENDIF
    st X,temp


	pop XH
	pop XL 

	.IF @0==TASK_CONTEXT  ;no interrupt is possible if in interrupt, sei is NOT used
    pop temp       
	sei
	.ENDIF
.ENDMACRO
*/


;----------------------------------------------------------
;USER MODE API
;USAGE:	Save time in units to wait on in current task TCB
;		Used in defined thread context
;USED:	temp,YL,YH(saved on current task stack)
;INPUT:   @0 - time in units
;WARNING:  NOT USED IN INTERRUPT,only current thread calls it!!!!!!!!!!!
;----------------------------------------------------------

.MACRO  _SLEEP_TASK
	push temp
	push YL
	push YH 

	lds YL, pxCurrentTCB
	ldi YH,0               ;small RAM devices only!!!! 

    	
	ldi temp,@0 
	std Y+2,temp
;***wait for it
wait:
;***yield processing
    _YIELD_TASK
    ldd temp,Y+2    
    tst temp
	breq end
    rjmp wait
end:
	pop YH
	pop YL 
	pop temp
.ENDMACRO

;----------------------------------------------------------
;KERNEL MODE API 
;USAGE:	Decrement timeout byte in each task's TCB if<>0
;		Walks through all TCB and decrements timeout byte
;USED:	temp,YL,YH(saved on current task stack,temp is saved in _PRE_INTERRUPT)
;INPUT: none
;WARNING: USED IN INTERRUPT ONLY!!!
;---------------------------------------------------------- 

.MACRO _kePROCESS_SLEEP_INTERVAL
	push YL
	push YH 

	ldi YL,low(TCB_1)        
    ldi YH,high(TCB_1)

loop:
    ldd temp,Y+2
    tst temp
	breq skip
    dec temp
    std Y+2,temp    
skip:
/*	
	ldd temp,Y+1 
    andi temp,0x0F
	cpi temp,TASKS_NUMBER
	breq end
*/	   
	cpi YL,low(TCB_1+(TASK_TCB_SIZE*TASKS_NUMBER))      
    breq end

	adiw YH:YL,TASK_TCB_SIZE
	rjmp loop  
end:
	pop YH
	pop YL 
.ENDMACRO

;-------------------------------------------------------------
;USER MODE API 
;USAGE:	 suspend current task or current task suspends itself.
;		 Sets current task schedulability bit to OFF.
;USED:	 YL,YH,temp(saved on current task stack)
;WARNING: CALLED IN CURRENT TASK CONTEXT 
;-------------------------------------------------------------
.MACRO _SUSPEND_TASK
    cli	
	push temp
	push YL
	push YH 

	lds YL, pxCurrentTCB
	ldi YH,0

    ;adiw XH:XL,1

    ;***modify SCHEDULABILITY bit    
	ldd temp,Y+1
    sbr temp,(1<<TASK_SCHEDULABLE_BIT)
	std Y+1,temp	   
    
	pop YH
	pop YL 
	pop temp
	
	sei
    _YIELD_TASK           ;yield in task context only
.ENDMACRO

;-------------------------------------------------------------
;KERNEL and USER MODE API
;Sets any task schedulability bit to ON
;INPUT:  @0 - context{0=task;0xFF=interrupt}
;        @1 - task number#{1,2,3,4......n} 
;USED: XL,XH,temp(saved on current task stack)
;	   temp is saved on the stack by __PRE_INTERRUPT 
;WARNING:  CALLED IN ANY CONTEXT(arbitrary task) if in interrupt handler
;-------------------------------------------------------------

.MACRO	_RESUME_TASK
    .IF @0==TASK_CONTEXT   ;no interrupt is possible if in interrupt,sei is NOT used
    cli
	push temp              ;
	.ENDIF

	push XL
	push XH
    ;calculate the target TCB and the byte offset where the scedualability bit is
    calculate_target_tcb_offset (@1-1)*TASK_TCB_SIZE,1

    ld temp,X	
    cbr temp,(1<<TASK_SCHEDULABLE_BIT)
    st X,temp

	pop XH
	pop XL 

	.IF @0==TASK_CONTEXT  ;no interrupt is possible if in interrupt, sei is NOT used
    pop temp       
	sei
	.ENDIF
.ENDMACRO
;PRIVATE helper macro - never call outside of kernel.inc
;INPUT:  @0 - task number#{1,2,3,4......n}
;		 @1 - ofset within TCB 	 
;USED: XL,XH
.MACRO calculate_target_tcb_offset
	ldi XL,low((TCB_1+@0)+@1)
	ldi XH,high((TCB_1+@0)+@1)
.ENDMACRO

;*******************EVENT*************************************
;Event system for up to 8 events kept in EVENT_STATE RAM byte.Requires 1 bit per event.
;use event #{0-7} to identify the event.
;set 1 to event # to tell the rest,the event happened
;set 0 to event # to clear event
;Notification type of event - one task waits on it while many other tasks could signal(awaken) it. 


;----------------------------------------------------------------
;KERNEL AND USER MODE API
;INPUT: @0 - event #
;       @1 - context{0=task;0xFF=interrupt}
;USAGE: temp(saved on current task stack)
;----------------------------------------------------------------

.MACRO  _EVENT_SET 
    .IF @1==TASK_CONTEXT   ;no interrupt is possible if in interrupt sei is NOT used
    cli
	.ENDIF
	
    push temp
	
	lds temp,EVENTS_STATE
	set
	bld temp,@0
	sts EVENTS_STATE,temp
	
	pop temp

	.IF @1==TASK_CONTEXT  ;no interrupt is possible if in interrupt sei is NOT used
	sei
	.ENDIF
.ENDMACRO



;USER MODE API
;Used in the context of a thread only!
;Wait indefinitly on an event.
;Auto reset event.
;INPUT: @0 - event #
;USAGE: temp(saved on current task stack)
;WARNING:  A new signal from onather task could come (if more then one task notifies the waiting task) between 
;          code points 1 and 2! The second signal will be swallowed up so mind this when more then one task notifies the waiting task!
            
.MACRO _EVENT_WAIT
    push temp

mloop:
	cli
	lds temp,EVENTS_STATE
	sbrc temp,@0
	rjmp event_is_set
	sei
	_YIELD_TASK
	rjmp mloop

event_is_set:               ;1  - a signal has come 
    clt
	bld temp,@0
	sts EVENTS_STATE,temp
	sei
	
	pop temp                  
.ENDMACRO

;**********************MUTEX*********************************
;It is more like a LOCK then MUTEX.
;A mutex object is a synchronization object whose state is set to signaled when it is not owned by any task, and nonsignaled when it is owned.
;Initial state is signaled - not owned by any task
;Wait for a mutex until it gets signaled.{0->signaled;
;                                          1->not signal}
;Up to 8 different mutexes could be defined in the static MUTEX_STATE byte.


;USER MODE API 
;		Set the flag to not signaled on entering the guarded section.
;		called in the context of a thread to mark the BEGIN of the protected code section.
;INPUT: @0 - mutex #
;USAGE: SREG T flag

.MACRO   _MUTEX_WAIT
  
mloop:
	cli
	sbrs MUTEX_STATE,@0
	rjmp mutex_is_signaled
	sei
	_YIELD_TASK
    rjmp mloop 
mutex_is_signaled:

;set  MUTEX to not signaled    
	set
	bld MUTEX_STATE,@0	
	sei	
.ENDMACRO

;USER MODE API 
;		Set the flag to signaled on exiting the guarded section.
;		called in the context of a thread after the call to _MUTEX_WAIT to mark the END of the protected code section.
;INPUT: @0 - mutex #
;USAGE: SREG T flag

.MACRO   _MUTEX_RELEASE
	cli						;write-protect MUTEX_STATE byte!		
	clt
	bld MUTEX_STATE,@0
	sei
.ENDMACRO

;KERNEL API
;Context switch from one task to onather.
;There are 2 priority levels
;			1.DEVICE LEVEL processing
;			2.NORMAL LEVEL processing 
;A List queue like structure could have been used for the 2 priority levels but this implies RAM usage.
;Finds next task - round robin with 2 priority levels(DEVICE and NORMAL)
;TCB structure is at the begginning of the RAM so no need of YH usage - save space!	
;LIMBO state - use any register yet mind that we are at the recently deschadualed task STACK region!
;WARNING:Having too many tasks executing in DEVICE priority level for a long time will leed to NORMAL level tasks starvation!
;@DANGER - the scheduler will loop forever if all tasks suspended at the same time - so keep one task(Idle Task) free of suspention as a fallback!
;@WORKAROUND - keep at least one/make sure you have at least one task free of suspention.

.MACRO _keSWITCH_TASK
;1.DEVICE level priority based in regard to IDF byte
devicelevel:
	lds temp,InterruptDispatchFlag
	tst temp
	breq normallevel    ; goto passivelevel
    ldi XL,low(TCB_1-TASK_TCB_SIZE)
	ldi XH,high(TCB_1-TASK_TCB_SIZE)
loop:
    adiw XH:XL,TASK_TCB_SIZE
	lsr temp              ;LSB->MSB order. Task definition order the sooner defined the higher its priority 
	brcc loop
	
	ldi YH,0   ;possible if all TCB structures reside within first 256 RAM bytes
	mov YL,XL 
    
	;there is an interrupt but task to dispatch to is in sleep -> waik it up!	 
    clr temp    
	std Y+2,temp

	rjmp end
;2.NORMAL level round robin(eternal loop if no task is ready)
normallevel:
	lds YL, pxCurrentTCB
	ldi YH,0

	ldd temp,Y+1	;position on priority bit byte
la:
	andi temp,0x0F          ;isolate task ID
	cpi temp,TASKS_NUMBER
    brlo  laa
;round robin to first TCB
	ldi YL, low(TCB_1)	
    rjmp  lab
laa:
;round robin to next TCB
	adiw YH:YL,TASK_TCB_SIZE            
lab:    
	ldd temp,Y+1
	;sbrc temp,TASK_SCHEDULABLE_BIT
    ;rjmp la
	andi temp,TASK_NOT_SCHEDUALABLE  ;if task is in WAITABLE or SUSPENDED state -> goto next task
    brne la

end:		 
	sts pxCurrentTCB,YL

.ENDMACRO

;**********************INTERRUPT PROCESSOR*******************
/*
What is interrupt Processing Task - a task dedicated to processing an interrupt.
The task uses 2 APIs:
   1._INTERRUPT_WAIT - waits on interrupt that will come from an interrupt dispatch.
   2._INTERRUPT_END  - called at the end of the task.It lowers the task priority level and makes 
                       the task schedulable so it can continue to execute at PASSIVE level. 
The portion of code confined within these 2 macros is executed in DEVICE priority level.
A task executes at DEVICE level until it volantarily exits it through _INTERRUPT_END macro. 
It is a good practise to disable the respective interrupt source during the current interrupt processing. 
@WARNING:looping forever between _INTERRUPT_WAIT and _INTERRUPT_END(while in DEVICE level) will break the kernel!
*/

;USER MODE API
;Wait on interrupt dispatch.
;Used in "interrupt processing task",activated by INTERRUPT DISPATCH API
;INPUT: @0 TaskID
;WARNING:interrupt dispatch priority index is the current Task ID
;USED: YL,YH,temp(saved on current task stack)

.MACRO  _INTERRUPT_WAIT
	push temp
	push YL
	push YH 

	lds YL, pxCurrentTCB
	ldi YH,0      ;only for 256b max RAM devices

;1.make task unscheduleable
    cli
	ldd temp,Y+1
	sbr temp,(1<<TASK_SCHEDULABLE_BIT)
	std Y+1,temp
	sei
;2.is the wait over?No need to deschadual
	lds temp,InterruptDispatchFlag 
    sbrc temp,@0-1 
	rjmp end    
;3.wait for DEVICE level by NOT being in runing state.Wait for the interrupt.
    _YIELD_TASK
end:
	pop YH
	pop YL 
	pop temp
.ENDMACRO

;-----------------------------------------------------
;USER MODE API
;Reduce current task level form TASK_PRIORITY_INTERRUPT to TASK_PRIORITY_NORMAL
;Used at the end of each "interrupt processing task"!!!!
;INPUT: TaskID
;USED: YL,YH,temp(saved on current task stack)

.MACRO _INTERRUPT_END
	push temp
	push YL
	push YH 
    cli
	
	lds YL, pxCurrentTCB
	ldi YH,0
		
	;1.***modify SCHEDULABILITY bit    
	ldd temp,Y+1
    cbr temp,(1<<TASK_SCHEDULABLE_BIT) ;set to 0=activate task(we want to run in NORMAL LEVEL where active flag is checked by the schedular)
	std Y+1,temp    

	;2 *** mark IDF off
    lds temp,InterruptDispatchFlag  
	cbr temp,1<<@0-1
    sts InterruptDispatchFlag,temp 
    
	sei
	pop YH
	pop YL 
	pop temp
	_YIELD_TASK    ;Add YIELD_TASK so that waiting DPC of lower priority may be executed

.ENDMACRO

;-----------------------------------------------------
;Kernel Mode API
;Call at the beginning of interrupt handler procedure
;INPUT: none
;USAGE: temp
;-----------------------------------------------------
.MACRO _PRE_INTERRUPT
    push temp
	in temp,SREG
    push temp	
.ENDMACRO

;-----------------------------------------------------
;Kernel Mode API
;Call at the end of interrupt handler procedure
;INPUT: none
;USAGE: temp 
;-----------------------------------------------------
.MACRO _POST_INTERRUPT
	pop temp
    out SREG,temp
	pop temp
.ENDMACRO 

/*
KERNEL MODE API
Activates the "interrupt processing task" by setting the corresponding 
interrupt dispatch flag(index).There is no IDT to bind flags to Task's TCB so the very TCB list order in memory is used.
First index corresponds to first TCB,Second index coressponds to second TCB and so on.....
Executed as atomic operation - only within interrupt procedure
Used in interrupt context which happens in arbitrary thread context.
Mind register usage!!!!
In contast to megaAcorn this version does not use IDT due to the limited RAM thus the Task's TCB list is used. 
INPUT: @0 - interrupt dispatch priority index/task id
USED: r17,temp(saved on current arbitrary task stack)
@EXAMPLE:
intX:
  _PRE_INTERRUPT

  ;Do your stuff here (disable interrupt most likely...).Don't forget to push/pop used registers 
  ;never forget that interrupt happens in arbitrary tasks context!
  _keDISPATCH_DPC

  Two points to note:
  1.DPC is queued.Interrupt handling is sort of extended to task schedular where the real dispatching occure.(RET is used) 
  2.DPC is queued.Dispatching may not happen if interrupt of higher priority  is being processed. (RETI)
*/
.MACRO _keDISPATCH_DPC
	;push temp  saved in _PRE_INTERRUPT macro ->save stack usage!
	push r17
	lds temp,InterruptDispatchFlag
    mov r17,temp
	sbr temp,1<<@0-1
    sts InterruptDispatchFlag,temp
	;if no flags then schedual
	tst r17
	breq deschedual1

	ldi temp,1<<@0-1
	cp temp,r17    
	
	brsh  nodeschedual1       ;LSB is with highest priority;avoid dispatching if DPC of higher priority(lower bit set) is being processed	
deschedual1:
    pop r17   ;restore
	ldi temp,low(DispatchDPCExtension)
    push temp
	ldi temp,high(DispatchDPCExtension)
	push temp
    ret           ;1.deschedual/dispatch right away - notice that interrupt flag in SREG is still OFF
	              ;reti in TaskSchedular will enable it              
				  ;2.temp and SREG will be restored between labels "DispatchDPCExtension" and "TaskSchedular"
nodeschedual1:    
    pop r17   ;restore
	pop temp      ;restore temp and SREG to its task's context value/make sure _PRE_INTERRUPT is invoked first!!!!!!!!!!!!!
    out SREG,temp
	pop temp
	reti          ;return to interrupted task   
.ENDMACRO 


.dseg
/*
Interrupt processing is executed at DEVICE level as DPC (Deffred Procedure call).
Instead of puting processing code in the regular interrupt handler, we dispatch the 
processing to a DPC which is executed a bit later at DEVICE level.
Interrupt activity flag records which interrupt is being processed(active) or pending processing. 
Interrupt processing tasks are executed at DEVICE level. The processor remains at 
DEVICE level until all present interrupts are handled.
Since the RAM is limited (up to 256 bytes)Interrupt Dispatch Table (IDT) is missing!
InterruptDispatchFlag keeps record of the Task which is responsible to process DPC - as each set bit corresponds to the Task's ID to process the DPC.
Interrupts are dispatched to tasks in sequential order from MSB to LSB so the higher the Task ID the higher the priority it will have in processing the DPC.
Each set bit is selected by the schedular untill the interrupt processing task behind it is finished - which basically masks
the processing of the interrupts of lower index value.
*/

InterruptDispatchFlag:           .byte 1 ;up to 8 interrupt processing tasks




;EVENTS_STATE: .byte 1           ;up to 8 events application wide


;MUTEX_STATE: .byte 1            ;up to 8 mutexes application wide 

;.def MUTEX_STATE=r1
