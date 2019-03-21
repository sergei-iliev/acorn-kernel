/*
;Optimization for Devices with UP TO 126 bytes of RAM , reduce task context to 18 registers
Acorn introduces 2 basic logical levels of code execution:
1.USER mode - the code being executed by the tasks
2.KERNEL mode - the code being executed by the interrupt procedures
User mode is interuptible , it could be preempted by the task schedular or interupt
Kernel mode is NOT interruptible - MCU clears the global interrupt flag on each interrupt so 
any code within interrupt procedure is executed in an atomic fashion.
There are 2 priority levels:
1.PASSIVE level
2.DEVICE level

Help,Support,Praise to
sergei_iliev@yahoo.com
*/

#define OS TINYACORN

#define VERSION 2.4

#define HIGH_RAM_ADDRESS high(SRAM_START)

#define TRUE  1
#define FALSE 0 

;Comment out in production mode!!!!!!!!!!!!!!!!!!!!!!
#define DEBUG 


#define TASKS_NUMBER 3
#if (TASKS_NUMBER>3)
	#error Tiny Acorn 128 bit kernel maximum tasks number is 3
#endif
;Keeping TCB structures as first structures in RAM layout enables
;less instructions in round robin calculations 
#define TCB_MAX_SIZE   low(SRAM_START+1+(TASKS_NUMBER*TASK_TCB_SIZE))

.EQU TASK_TCB_SIZE=3   ;TCB size is see below

;Optimization for Devices with 128 bytes of RAM
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

;***Disbale enabel task scheduling in CPU data byte structure bit
.SET CPU_SCHEDULE_BIT=7

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
MUST be bigger then TASK_STACK_CPU_CONTEXT_SIZE
*/
.EQU TASK_STACK_SIZE=38 
/*
TASK_STACK_CPU_CONTEXT_SIZE=21(18reg+SREG+2 bytes Return address)
*/
.EQU TASK_STACK_CPU_CONTEXT_SIZE=21


.dseg

;use 1 byte address structure for CPU with up to 256 bytes of RAM
pxCurrentTCB: .byte 1   ;keep address of the current TCB

#if TASKS_NUMBER>=1
TCB_1: .byte TASK_TCB_SIZE     ;Stack pointer LSB:MSB to the top of the task stack
#endif


#if TASKS_NUMBER>=2  
TCB_2: .byte TASK_TCB_SIZE
#endif


#if TASKS_NUMBER>=3
TCB_3: .byte TASK_TCB_SIZE
#endif    


#if TASKS_NUMBER>=4
TCB_4: .byte TASK_TCB_SIZE
#endif



#if TASKS_NUMBER>=5
TCB_5: .byte TASK_TCB_SIZE
#endif


#if TASKS_NUMBER>=6
TCB_6: .byte TASK_TCB_SIZE
#endif


.cseg

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

	lds XL, pxCurrentTCB  
    ldi XH,HIGH_RAM_ADDRESS

	in r0, SP   ;up to 128 bytes of RAM
    st x, r0 

.ENDMACRO

;new context is in pxCurentTCB
.MACRO  _keOS_RESTORE_CONTEXT
	lds XL, pxCurrentTCB
	ldi XH,HIGH_RAM_ADDRESS
    
	ld r28, x 
	out SP, r28 


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

;----------------------------------------------------------------
;USER MODE API
;@USAGE:	Create task and initialize its TCB and stack resources. Used during kernel boot initialization,uses any register
;@INPUT:
;		@0  task label
;		@1  task number   
;       @2  task stack size -> it must be bigger then CPU context size
;@WARNING:  Use r25:r24 to store current stack offset
;----------------------------------------------------------------

#define TCB_HIGH(i) ldi XH,high(TCB_##i)
#define TCB_LOW(i)  ldi XL,low(TCB_##i)

.MACRO  _REGISTER_TASK_STACK
    .if @2<=TASK_STACK_CPU_CONTEXT_SIZE 
	  .ERROR "****************ARE YOU OK?***********************"
	.endif
;init task's stack 
	ldi XL,low(@0)
	ldi XH,high(@0)

	mov ZL,r24
	mov ZH,r25
	rcall InitStack

#ifdef DEBUG
    ldi temp,low(RAMEND)
	mov YL,temp
	ldi temp,high(RAMEND)
	mov YH,temp


    SUB16 YL,YH,r24,r25
	sbiw YH:YL,@2-1

	ldi temp,0x5A
	st Y,temp
#endif
;2.Set stack pointer to stacks TCB 
	TCB_HIGH(@1)
	TCB_LOW(@1)

	mov ZL,r24
	mov ZH,r25

	adiw ZH:ZL,TASK_STACK_CPU_CONTEXT_SIZE
    
	ldi r17,(@1-1)
	rcall InitTCB

	;increase offset to next free position
	adiw r25:r24,@2
.ENDMACRO

;----------------------------------------------------------
;Internal private use only
;@INPUT: X task label
;        Z initial tasks stack offset
;----------------------------------------------------------    
InitStack:
;position at the beginning of stack
    ldi temp,low(RAMEND)
	mov YL,temp
	ldi temp,high(RAMEND)
	mov YH,temp

	SUB16 YL,YH,ZL,ZH
;save inital return address to task begining
	;mov r0,XL
	st Y,XL
	;mov r0,XH
	st -Y,XH    
ret

;----------------------------------------------------------
;Internal private use only
;@INPUT: X - task control RAM block - TCB
;        Z - set the end of task stack = 18regs+SREAG+previous PC
;		 r17  - task ID	
;---------------------------------------------------------
InitTCB:
;position at the beginning of stack
    ldi temp,low(RAMEND)
	mov YL,temp
	ldi temp,high(RAMEND)
	mov YH,temp
;initial stack pointer position
    SUB16 YL,YH,ZL,ZH
    
	;mov r0,YL
	st X+,YL
	;mov r0,YH
	st X+,YH  
;set task ID
    ;ldi temp,@1     ;set task's ID
	st X,r17 
ret

;----------------------------------
;USER MODE API
;USAGE:	Yield task (relinquish the quantum) to the next one.
;		RETI will activate the interrupt
;----------------------------------
.MACRO  _YIELD_TASK
    cli
 	rcall TaskSchedular
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
	ldi YH,HIGH_RAM_ADDRESS       ;small RAM devices only!!!! 

    	
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
	cpi YL,low(TCB_1+(TASK_TCB_SIZE*(TASKS_NUMBER-1)))      
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
	ldi YH,HIGH_RAM_ADDRESS

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
.MACRO _RESUME_TASK
    .IF @0==TASK_CONTEXT   ;no interrupt is possible if in interrupt,sei is NOT used
    cli
	push temp 
	.ENDIF
	
	push XL
	push XH
    ;calculate the target TCB and the byte offset where the scedualability bit is
    CALCULATE_TARGET_TCB_OFFSET (@1-1)*TASK_TCB_SIZE,2

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
;----------------------------------------------------------------
;PRIVATE helper macro - never call outside of kernel.inc
;INPUT:  @0 - task number#{0,1,2,3,4......n}
;		 @1 - ofset within TCB 	 
;USED: XL,XH
;----------------------------------------------------------------
.MACRO CALCULATE_TARGET_TCB_OFFSET
	ldi XL,low((TCB_1+@0)+@1)
	ldi XH,high((TCB_1+@0)+@1)
.ENDMACRO

;*******************EVENT*************************************
;Event system for up to 8 events kept in EVENT_STATE RAM byte.Requires 1 bit per event.
;use event #{0-7} to identify the event.
;set 1 to event # to tell the rest,the event happened
;set 0 to event # to clear event
;Notification type of event - one task waits on it while many other tasks could signal(awaken) it. 
;It is possible to lose signal if many tasks signal the event

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
	sbr temp,1<<@0


	sts EVENTS_STATE,temp
	
	pop temp

	.IF @1==TASK_CONTEXT  ;no interrupt is possible if in interrupt sei is NOT used
	sei
	.ENDIF
.ENDMACRO

;----------------------------------------------------------------
;USER MODE API
;Used in the context of a thread only!
;Wait indefinitly on an event.
;Auto reset event.
;INPUT: @0 - event #
;USAGE: temp(saved on current task stack)
;WARNING:  A new signal from onather task could come (if more then one task notifies the waiting task) between 
;          code points 1 and 2! The second signal will be swallowed up so mind this when more then one task notifies the waiting task!
;----------------------------------------------------------------           
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
	cbr temp,1<<@0

	sts EVENTS_STATE,temp
	sei
	
	pop temp                  
.ENDMACRO
;----------------------------------------------------------------
;USER MODE API
;Used in the context of a thread only!
;Manual reset event.
;INPUT: @0 - event #
;USAGE: temp(saved on current task stack)
;----------------------------------------------------------------
.MACRO _EVENT_RESET
	push temp
	cli
	lds temp,EVENTS_STATE
	cbr temp,1<<@0
	sts EVENTS_STATE,temp
	sei
	pop temp
.ENDMACRO

;CHANGED**********************MUTEX*********************************
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
;USAGE: temp(saved on current task stack)

.MACRO   _MUTEX_WAIT
	push temp   

mloop:
	cli
   	lds temp,MUTEX_STATE
	sbrs temp,@0
	rjmp mutex_is_signaled
	sei
	_YIELD_TASK
    rjmp mloop 
mutex_is_signaled:

;set  MUTEX to not signaled    
	lds temp,MUTEX_STATE
	set
	bld temp,@0
	sts MUTEX_STATE,temp	
	sei	

	pop temp
.ENDMACRO
;----------------------------------------------------------------
;USER MODE API 
;		Set the flag to signaled on exiting the guarded section.
;		called in the context of a thread after the call to _MUTEX_WAIT to mark the END of the protected code section.
;INPUT: @0 - mutex #
;USAGE: temp(saved on current task stack)
;----------------------------------------------------------------
.MACRO   _MUTEX_RELEASE
	cli						;write-protect MUTEXT_STATE byte!	
	
	push temp 	

	lds temp,MUTEX_STATE
	clt
	bld temp,@0
	sts MUTEX_STATE,temp
	
	pop temp	

	sei
.ENDMACRO

;per CPU register
.dseg
CPU: .byte 1
.cseg
;----------------------------------------------------------------
;USER MODE API 
;Task calling this macro will make the task switch disabled.
;As a result the calling task will execute until it explicitly enables task switching
;@INPUT: @0 - TRUE or FALSE
;@USAGE: temp
;@WARNING: Since RAM is limited - instead of using a separate RAM location for storing CPU wide data, 
;		  OCDR I/O register is used which prevents the usage of debugger
;
;----------------------------------------------------------------

.MACRO _DISABLE_TASK_SWITCH
	
	lds temp,CPU
.IF @0==TRUE       
    sbr temp,1<<CPU_SCHEDULE_BIT	   
.ELSE
	cbr temp,1<<CPU_SCHEDULE_BIT
.ENDIF
	sts CPU,temp
	
.ENDMACRO

;----------------------------------------------------------------
;KERNEL MODE API
;Checks if task switch is disabled. Skips context switch from one task to another. 
;@INPUT: @0  jump target
;@WARNING: Platform dependent
;----------------------------------------------------------------
.MACRO _keSKIP_SWITCH_TASK
  _PRE_INTERRUPT

  lds temp,CPU
  sbrs temp,CPU_SCHEDULE_BIT
  rjmp switch_task_on
  
  _POST_INTERRUPT 
  rjmp @0    ;switch task is OFF

switch_task_on:
_POST_INTERRUPT
.ENDMACRO

;----------------------------------------------------------------
;KERNEL MODE API
;Start the task schedualr
;@INPUT: @0  - first task label
;@WARNING: Platform dependent in regard to Timer being used for scheduling
;----------------------------------------------------------------
.MACRO _START_SCHEDULAR
;set up Timer0
    _INIT_TASKSHEDUAL_TIMER


;start Timer0(Schedualing)	
	_ENABLE_TASKSHEDUAL_TIMER

;initialize current task pointer with Task_1
    ldi YL,low(TCB_1) 		
	sts pxCurrentTCB,YL
	
	/*	
;load start Task address	
	ldi YL,low(RAMEND) 		
	ldi YH,high(RAMEND)

;jump to first Task address(hackish way since we know in advance tasks layout)
	ld temp,Y+
	mov ZL,temp	
	ld temp,Y
	mov ZH,temp
	sei  
    
	ijmp
	*/

	sei
	rjmp @0
.ENDMACRO
;----------------------------------------------------------------
;KERNEL MODE API
;Context switch from one task to another.
;There are 2 priority levels
;			1.DEVICE LEVEL processing
;			2.NORMAL LEVEL processing 
;A List queue like structure could have been used for the 2 priority levels but this implies RAM usage.
;Finds next task - round robin with 2 priority levels(DEVICE and NORMAL)
;LIMBO state - use any register yet mind that we are at the recently deschadualed task STACK region!
;WARNING:Having too many tasks executing in DEVICE priority level for a long time will leed to NORMAL level tasks starvation!
;@DANGER - the scheduler will loop forever if all tasks suspended at the same time - so keep one task(Idle Task) free of suspention as a fallback!
;@WORKAROUND - keep at least one/make sure you have at least one task free of suspention!Usualy System Task will do this for you
;----------------------------------------------------------------

.MACRO _keSWITCH_TASK
;1.DEVICE level priority based in regard to IDF byte
devicelevel:
	lds temp,InterruptDispatchFlag
	tst temp
	breq normallevel    ; goto passivelevel
    ldi YL,low(TCB_1-TASK_TCB_SIZE)
	ldi YH,high(TCB_1-TASK_TCB_SIZE)
loop:
    adiw YH:YL,TASK_TCB_SIZE
	lsr temp              ;MSB->LSB order. Task definition order the sooner defined the higher its priority 
	brcc loop
	
	;mov YH,XH   
	;mov YL,XL 
    
	;there is an interrupt but task to dispatch to is in sleep -> waik it up!	 
    clr temp    
	std Y+2,temp

	rjmp end

;2.NORMAL level round robin(eternal loop if no task is ready,will block if all tasks suspended)
normallevel:
	lds YL, pxCurrentTCB
	ldi YH,HIGH_RAM_ADDRESS

la:
	adiw YH:YL,TASK_TCB_SIZE

	cpi YL,TCB_MAX_SIZE     
	brne lab
	ldi YL, low(TCB_1)
	ldi YH, high(TCB_1)	
lab:
	ldd temp,Y+1
	sbrc temp,TASK_SCHEDULABLE_BIT
    rjmp la	
end:	
	sts pxCurrentTCB,YL
.ENDMACRO

;**********************INTERRUPT PROCESSOR***************************
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

;----------------------------------------------------------------
;USER MODE API
;Wait on interrupt dispatch.
;Used in "interrupt processing task",activated by INTERRUPT DISPATCH API
;INPUT: @0 - interrupt dispatch priority index
;USED: YL,YH,temp(saved on current task stack)
;----------------------------------------------------------------

.MACRO  _INTERRUPT_WAIT
	push temp
	push YL
	push YH 

	lds YL, pxCurrentTCB
	ldi YH,HIGH_RAM_ADDRESS      ;only for 256b max RAM devices

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

;----------------------------------------------------------------
;USER MODE API
;Reduce current task level form TASK_PRIORITY_INTERRUPT to TASK_PRIORITY_NORMAL
;Used at the end of each "interrupt processing task"!!!!
;INPUT: @0 - interrupt dispatch priority index
;USED: YL,YH,temp(saved on current task stack)
;----------------------------------------------------------------

.MACRO _INTERRUPT_END
	push temp
	push YL
	push YH 
    cli
	
	lds YL, pxCurrentTCB
	ldi YH,HIGH_RAM_ADDRESS
		
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

;----------------------------------------------------------------
;Kernel Mode API
;Call at the beginning of interrupt handler procedure
;INPUT: none
;USAGE: temp
;----------------------------------------------------------------
.MACRO _PRE_INTERRUPT
    push temp
	in temp,SREG
    push temp	
.ENDMACRO

;----------------------------------------------------------------
;Kernel Mode API
;Call at the end of interrupt handler procedure
;INPUT: none
;USAGE: temp 
;----------------------------------------------------------------
.MACRO _POST_INTERRUPT
	pop temp
    out SREG,temp
	pop temp
.ENDMACRO 

/*
KERNEL MODE API
Activates the "interrupt processing task" by setting the corresponding 
interrupt dispatch flag(index).There is no IDT to bind flags to Task's TCB so the very TCB list order in memory is used.
Each task has an ID which is saved in TCB when task is registered.It is exactly the ID that corresponds to TCB position in memory. 
Executed as atomic operation - only within interrupt procedure
Used in interrupt context which happens in arbitrary thread context.
Mind register usage!!!!
In contast to megaAcorn this version does not use IDT due to the limited RAM thus the Task's TCB list is used. Tasks id/index value is used
to identify the target task to dispatch to.
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
	breq deschedual

	ldi temp,1<<@0-1
	cp temp,r17    
	
	brsh  nodeschedual       ;LSB is with highest priority;avoid dispatching if DPC of higher priority(lower bit set) is being processed	
deschedual:
	/*
	ldi temp,low(DispatchDPCExtension)
    push temp
	ldi temp,high(DispatchDPCExtension)
	push temp
    ret           ;1.deschedual/dispatch right away - notice that interrupt flag in SREG is still OFF
	              ;reti in TaskSchedular will enable it              
				  ;2.temp and SREG will be restored between labels "DispatchDPCExtension" and "TaskSchedular"

    */
	pop r17   ;restore
	pop temp      ;restore temp and SREG to its task's context value/make sure _PRE_INTERRUPT is invoked first!!!!!!!!!!!!!
    out SREG,temp
	pop temp

	rjmp DispatchDPCExtension
nodeschedual:    
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




EVENTS_STATE: .byte 1           ;up to 8 events application wide


;MUTEX_STATE: .byte 1            ;up to 8 mutexes application wide 

;.def MUTEX_STATE=r1



