/*
AUTHOR:sergei_iliev@yahoo.com
Optimized for use with devices of more then 256 bytes and 3 bytes Program Counter register!
Acorn introduces 2 basic logical levels of code execution:
1.USER mode - the code being executed by the tasks
2.KERNEL mode - the code being executed by the interrupt procedures
User mode is interuptible , it could be preempted by the task schedular or interupt
Kernel mode is NOT interruptible - MCU clears the global interrupt flag on each interrupt so 
any code within interrupt procedure is executed in an atomic fashion.Use Deffered Procedure Call - like
dispatching to execute interrupt related code at DEVICE level and keep interrupt handle time shorter.
There are 2 priority levels:
1.PASSIVE level
2.DEVICE level

Help,Support,Praise to
sergei_iliev@yahoo.com
*/
#define OS MEGAACORN

#define VERSION 3.0

#define HIGH_RAM_ADDRESS high(SRAM_START)

#define TRUE  1
#define FALSE 0 


.include "kernel/config.inc"
.include "kernel/math.inc"

.cseg
.def    temp=r16    ;temp reg.
/*
Define PC bytes size
*/
#ifndef TASKS_NUMBER
	#error TASKS_NUMBER is not defined. Use config file to do it
#endif 

#ifdef AVR_3_BYTE_PC
	#define AVR_PC_SIZE 3
#else
	#define AVR_PC_SIZE 2
#endif
#message CPU Program Counter is AVR_PC_SIZE bytes long

#if (TASKS_NUMBER>16)
	#error Mega Acorn kernel maximum tasks number is 16
#endif

;Keeping TCB structures as first structures in RAM layout enables
;less instructions in round robin calculations 
#define TCB_MAX_SIZE   low(SRAM_START+1+(TASKS_NUMBER*TASK_TCB_SIZE))


/*
Enable sleep mode 
*/
;#define SLEEP_MODE
;.EQU CONS_TIMER_COMPARE=((SYSTEM_CLOCK/8)/(1000000/SYSTEM_TICK))   ;devider =8

.EQU CONS_TIMER_COMPARE=57000

.EQU TASK_TCB_SIZE=4   ;TCB size is see below

;Compared to previous release - Task ID as added, which implies 16 tasks max
;@CHANGED
;-----------------------;
;1.LSB
;-----------------------;
;2.MSB
;-----------------------;
;3.Task status byte
;7bit -> Is task in waitable state
;6bit->Is task in runable state(0-schedulable(default);1-not schedulable;Idle task is always schedulable)
;@NOTUSED(use IDF instead)
;0-3bit-> Task ID number(up to 16 tasks)
;-----------------------
;4.Sleep Timeout
;-----------------------;


;***Disbale enabel task scheduling in CPU data byte structure bit
.SET CPU_SCHEDULE_BIT=7

;***wait state related
.EQU TASK_WAIT_ON=1
.EQU TASK_WAIT_OFF=0

;is task shedulable runnable bit
.SET TASK_SCHEDULABLE_BIT=6


;***runable state related
.EQU TASK_SCHEDULABLE_ON=0
.EQU TASK_SCHEDULABLE_OFF=1


.SET TASK_CONTEXT=0x00

.SET INTERRUPT_CONTEXT=0xFF

/*
MUST be bigger then TASK_STACK_CPU_CONTEXT_SIZE
*/

.EQU TASK_STACK_SIZE=62  

/*
TASK_STACK_CPU_CONTEXT_SIZE=36(32reg+SREG+PC(3 bytes) Return address)   ;3 bytes PC
TASK_STACK_CPU_CONTEXT_SIZE=35(32reg+SREG+PC(2 bytes) Return address)	;2 bytes PC
*/
.EQU TASK_STACK_CPU_CONTEXT_SIZE=32+1+AVR_PC_SIZE

/*
;Not all devicess start from 0x060 , at90USB starts from 0x100 for example
;I will personally come to your place and flog you if you change the 
;system RAM layout!!!!!!!!!
*/
.dseg
keMemory:
pxCurrentTCB: .byte 1   ;keep address of the current TCB

/*
Keep TCB structure for each defined Task in RAM array
*/
TCB: .byte TASK_TCB_SIZE*TASKS_NUMBER

.cseg

#message **********************OS  VERSION " using " TASKS_NUMBER " tasks.*************************"

.MACRO  _keOS_SAVE_CONTEXT
	push r0
	in r0,SREG
	push r0
	push r1
	push r2  
	push r3
	push r4
	push r5 
	push r6
	push r7
	push r8 
	push r9
	push r10
	push r11 
	push r12
	push r13
	push r14 
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
    ;lds r27, pxCurrentTCB + 1 
    ldi XH,HIGH_RAM_ADDRESS

	in r0, SPL
    st x+, r0 
    in r0, SPH
    st x, r0											 
.ENDMACRO

;new context is in pxCurentTCB
.MACRO  _keOS_RESTORE_CONTEXT
	lds XL, pxCurrentTCB
    ;lds r27, pxCurrentTCB + 1
	ldi XH,HIGH_RAM_ADDRESS
	
	ld r28, x+ 
	out SPL, r28 
    ld r29, x 
	out SPH, r29
    
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
	pop r14
	pop r13
	pop r12
    pop r11
	pop r10
	pop r9
	pop r8
    pop r7
	pop r6
	pop r5
	pop r4
    pop r3
	pop r2
    pop r1 
    pop r0 
    out SREG, r0 
    pop r0
.ENDMACRO

;----------------------------------------------------------------
;USER MODE 
;@USAGE:	Init Stack Pointer.Initialize RAM to 0x00 fill 
;			Set BOOT time scoped global variables 
;----------------------------------------------------------------
.MACRO _BOOT
    ;One rcall depth for the stack during system init 
	ldi     temp,high(RAMEND-AVR_PC_SIZE)        ;Set stack pointer to bottom of RAM-(PC bytes size) for system init
    out     SPH,temp
    ldi     temp,low(RAMEND-AVR_PC_SIZE)
    out     SPL,temp
     	       			  
;clear SRAM
	ldi XL,low(RAMEND+1)
	ldi XH,high(RAMEND+1)    		   
    clr r0
initos:
	st -X,r0
	cpi XH,high(SRAM_START) 
    brne initos
    cpi XL,low(SRAM_START)
	brne initos
;check system memory layout -> no static byte allocation before system memory layout
/*
#ifdef DEBUG
	ldi r19,low(keMemory)
	ldi r20,high(keMemory)

	CPI16  r19,r20,temp,SRAM_START
	breq debug_next
	rjmp RESET     ;LOOP forever until you move program memory allocation after system memory layout
debug_next:	 
#endif
*/
;prepare task id increment register (boot time global variable)
	clr r17
;prepare current tasks TCB pointer (boot time global variable)
    ldi XH,high(TCB)
	ldi XL,low(TCB)
.ENDMACRO

;----------------------------------------------------------------
;USER MODE API
;@USAGE:	Create task and initialize its TCB and stack resources. Used during kernel boot initialization,uses any register
;@INPUT:
;		@0  task label(2 or 3 bytes depends on AVR CPU)   
;       @1  task stack size -> it must be bigger then CPU context size
;@WARNING:  Use r25:r24 to store current stack offset
;			Use (r23):r22:r21	for Task label address
;----------------------------------------------------------------
.MACRO  _REGISTER_TASK_STACK
    .if @1<=TASK_STACK_CPU_CONTEXT_SIZE 
	  .ERROR "****************ARE YOU OK?***********************"
	.endif

;1.Save initial return address points at Tasks' begining
	ldi r21,low(@0)
	ldi r22,high(@0)

#ifdef AVR_3_BYTE_PC
	ldi r23,byte3(@0)
#endif
	
	mov ZL,r24
	mov ZH,r25
	rcall InitStack

#ifdef DEBUG
    ldi temp,low(RAMEND)
	mov YL,temp
	ldi temp,high(RAMEND)
	mov YH,temp


    SUB16 YL,YH,r24,r25
	
	SUBI16 YL,YH,(@1-1)

	ldi temp,DEBUG_MARKER
	st Y,temp
#endif
;2.Set stack pointer to tasks stack TCB 	

	mov ZL,r24
	mov ZH,r25

	adiw ZH:ZL,TASK_STACK_CPU_CONTEXT_SIZE
 
	rcall InitTCB
	;increment ID number for next task
	inc r17
	;increment to next tasks TCB (X is incremented 2 times during store/write)
	adiw XH:XL,TASK_TCB_SIZE-2
	
	;increase offset to next free position
	ADDI16 r24,r25,@1
.ENDMACRO
;----------------------------------------------------------------
;USER MODE API
;@USAGE:	Create task and initialize its TCB and stack resources.Uses default stack size per task. Used during kernel boot initialization,uses any register
;@INPUT:	@0  task label(2 or 3 bytes depends on AVR CPU)
;@USAGE:  Use r25:r24 to store current stack offset
;		  Use (r23):r22:r21	for Task label address		
;----------------------------------------------------------------
.MACRO  _REGISTER_TASK
;1.Save initial return address points at Tasks' begining
	ldi r21,low(@0)
	ldi r22,high(@0)
#ifdef AVR_3_BYTE_PC 
	ldi r23,byte3(@0)
#endif

	mov ZL,r24
	mov ZH,r25
	rcall InitStack

	
;3.DEBUG marker form RAM layout defragmentation(marks end of tasks stack)

#ifdef DEBUG
	ldi temp,low(RAMEND)
	mov YL,temp
	ldi temp,high(RAMEND)
	mov YH,temp

    SUB16 YL,YH,r24,r25
	sbiw YH:YL,TASK_STACK_SIZE-1

	ldi temp,DEBUG_MARKER
	st Y,temp
#endif 


;2.Set stack pointer to stacks TCB
	mov ZL,r24
	mov ZH,r25

	adiw ZH:ZL,TASK_STACK_CPU_CONTEXT_SIZE
    
	rcall InitTCB
	;increment ID number for next task
	inc r17
	;increment to next tasks TCB (X is incremented 2 times during store/write)
	adiw XH:XL,TASK_TCB_SIZE-2
	
	;increase offset to next free position using defaul task stack size
	adiw r25:r24,TASK_STACK_SIZE

.ENDMACRO 

;----------------------------------------------------------
;Internal private kernel use only
;@INPUT: (r21:r22:r23) task label
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
	
	st  Y,r21	
	st -Y,r22
#ifdef AVR_3_BYTE_PC 	    
	st -Y,r23
#endif
ret

;----------------------------------------------------------
;Internal private use only
;@INPUT: X - task control RAM block - TCB
;        Z - set the end of task stack = 32regs+SREAG+previous PC
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

;set tasks stack address	
	st X+,YL	
	st X+,YH  
	
;set task ID
	st X,r17 
ret

;----------------------------------------------------------------
;USER MODE API
;USAGE:	Yield task (relinquish the quantum) to the next one.
;		RETI will activate the interrupt flag in status register
;----------------------------------------------------------------
.MACRO  _YIELD_TASK
    cli
 	call TaskSchedular
.ENDMACRO

;----------------------------------------------------------------
;USER MODE API
;Start executive mode - 
;1.elivate task to DEVICE_LEVEL
;2.disable scheduling 
;Use this in rear cases like 1-wire protocol.
;@WARNING: using _INTERRUPT_WAIT/_INTERRUPT_END is not allowed since DPC flag is always on!
;----------------------------------------------------------------
.MACRO  _START_EXECUTIVE_MODE    
	push temp
	
	cli
	lds temp,InterruptDispatchFlag
	sbr temp,1<<@0
    sts InterruptDispatchFlag,temp
	sei

	_DISABLE_TASKSHEDUAL_TIMER
	pop temp
.ENDMACRO

.MACRO  _END_EXECUTIVE_MODE
	push temp

	cli
    lds temp,InterruptDispatchFlag  
	cbr temp,1<<@0
    sts InterruptDispatchFlag,temp 
	sei

	_ENABLE_TASKSHEDUAL_TIMER
	pop temp
.ENDMACRO

;----------------------------------------------------------------
;USER MODE API
;USAGE:	Save time in units to wait on in current task TCB
;		Used in defined thread context
;USED:	temp,YL,YH(saved on current task stack)
;INPUT:   @0 - time in units
;WARNING:  NOT USED IN INTERRUPT or DEVICE level ,only current thread calls it while in PASSIVE mode!!!!!!!!!!!
;----------------------------------------------------------------
.MACRO  _SLEEP_TASK
	push temp
	push YL
	push YH 

	lds YL, pxCurrentTCB
	ldi YH,HIGH_RAM_ADDRESS              

	ldi temp,@0
	std Y+3,temp

;***wait for it
wait:
;***yield processing
    _YIELD_TASK
    ldd temp,Y+3    
    tst temp
	breq end
    rjmp wait
end:

	pop YH
	pop YL 
	pop temp
.ENDMACRO



;----------------------------------------------------------------
;USER MODE API
;USAGE:	Save time in units to wait on in current task TCB
;		Used in defined thread context.
;       Allows to implement simple PWM  
;USED:	16<rX<31,
;       YL,YH(saved on current task stack)
;       temp(saved on current task stack)  

;INPUT:   @0(16<rX<31) - time in units
;WARNING:  NOT USED IN INTERRUPT,only current thread calls it!!!!!!!!!!!
;----------------------------------------------------------------
.MACRO _SLEEP_TASK_EX
	push YL
	push YH 
    push temp
	 

	lds YL, pxCurrentTCB
	ldi YH,HIGH_RAM_ADDRESS

	std Y+3,@0

;***wait for it
wait:
;***yield processing
    _YIELD_TASK
    ldd temp,Y+3    
    tst temp

	breq end
    rjmp wait
end:
    pop temp
	pop YH
	pop YL 
.ENDMACRO
;----------------------------------------------------------------
;KERNEL MODE API 
;USAGE:	Decrement timeout byte in each task's TCB if<>0
;		Walks through all TCB and decrements timeout byte
;		Fired by 16bit system timer      
;USED:	temp,YL,YH(saved on current task stack,temp is saved in _PRE_INTERRUPT)
;INPUT: none
;WARNING: USED IN INTERRUPT ONLY!!!
;----------------------------------------------------------------

.MACRO _kePROCESS_SLEEP_INTERVAL
	push YL
	push YH 

	ldi YL,low(TCB)        
    ldi YH,high(TCB)

loop:
    ldd temp,Y+3
    tst temp
	breq skip
    dec temp
    std Y+3,temp    
skip:	   
	cpi YL,low(TCB+(TASK_TCB_SIZE*(TASKS_NUMBER-1)))      
    breq end

	adiw YH:YL,TASK_TCB_SIZE
	rjmp loop  
end:
	pop YH
	pop YL 

.ENDMACRO
;----------------------------------------------------------------
;USER MODE API 
;USAGE:	 suspend current task or current task suspends itself.
;		 Sets current task schedulability bit to OFF.
;USED:	 YL,YH,temp(saved on current task stack)
;WARNING: CALLED IN CURRENT TASK CONTEXT 
;----------------------------------------------------------------
.MACRO _SUSPEND_TASK
    cli	
	push temp
	push YL
	push YH 
	
	lds YL, pxCurrentTCB
	ldi YH,HIGH_RAM_ADDRESS

    ;***modify SCHEDULABILITY bit    
	ldd temp,Y+2
    sbr temp,(1<<TASK_SCHEDULABLE_BIT)
	std Y+2,temp	   
    
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
	ldi XL,low((TCB+@0)+@1)
	ldi XH,high((TCB+@0)+@1)
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
;Start the task schedular
							   
;@WARNING: Platform dependent in regard to Timer being used for scheduling
;----------------------------------------------------------------
.MACRO _START_SCHEDULAR
;set up Timer0
    _INIT_TASKSHEDUAL_TIMER


;start Timer0(Schedualing)	
	_ENABLE_TASKSHEDUAL_TIMER

;initialize current task pointer with Task #1
    ldi YL,low(SRAM_START+1) 		
	sts pxCurrentTCB,YL
	
	_keOS_RESTORE_CONTEXT
	reti
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
    ldi XL,low(IDT-1)
	ldi XH,high(IDT-1)
loop:
    adiw XH:XL,1
	lsl temp
	brcc loop
	
	ldi YH,high(TCB)   ;possible if all TCB structures reside within same 256 RAM page
	ld YL,X 
    
	;there is an interrupt but task to dispatch to is in sleep -> waik it up!	 
    clr temp    
	std Y+3,temp

	rjmp end

;2.NORMAL level round robin(eternal loop if no task is ready,will block if all tasks suspended)
normallevel:
	lds YL, pxCurrentTCB
	ldi YH,HIGH_RAM_ADDRESS

la:
	adiw YH:YL,TASK_TCB_SIZE

	cpi YL,TCB_MAX_SIZE     
	brne lab
	ldi YL, low(TCB)
	ldi YH, high(TCB)	
lab:
	ldd temp,Y+2
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
;Registers the calling task with Interrupt Dispatcher.
;Makes the calling task - interrupt handling one.
;Must be called in the INIT part of the task while the interrupt 
;source is still disabled.
;INPUT:
;        @0 - temp register,
;        @1 - interrupt dispatch priority index(7/highest/ through 0/lowest/)
;----------------------------------------------------------------

.MACRO _INTERRUPT_DISPATCHER_INIT
    #ifdef DEBUG
	.if (7-@1) > (IDT_SIZE-1) 
		.error "ITD size is too small to accomodate requested lavel. Increase the size."
	.endif
	#endif

	lds @0,pxCurrentTCB
	sts IDT+(7-@1),@0    
	
.ENDMACRO

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
    ldi YH, HIGH_RAM_ADDRESS
	
;1.make task unscheduleable
    cli
	ldd temp,Y+2
	sbr temp,(1<<TASK_SCHEDULABLE_BIT)
	std Y+2,temp
	sei
;2.wait for INTERRUPT DISPATCH priority flag
wait:
	lds temp,InterruptDispatchFlag 
    sbrc temp,@0 
	rjmp end
;***yield processing
    _YIELD_TASK
    rjmp wait
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
	ldd temp,Y+2
    cbr temp,(1<<TASK_SCHEDULABLE_BIT) ;set to 0=activate task(we want to run in NORMAL LEVEL where active flag is checked by the schedular)
	std Y+2,temp    

	;2 *** mark IDF off
    lds temp,InterruptDispatchFlag  
	cbr temp,1<<@0
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
In search of a faster interrupt dispatcher to dispatch to interrupt handling task as fast as possible
Differered Procedure Call/DPC semantic
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
	sbr temp,1<<@0
    sts InterruptDispatchFlag,temp
	cpi r17,1<<@0
    pop r17
	
	brsh  nodeschedual       ;avoid dispatching if DPC of higher priority is being processed
	/*
	ldi temp,low(DispatchDPCExtension)
    push temp
	ldi temp,high(DispatchDPCExtension)
	push temp
    ret           ;1.deschedual/dispatch right away - notice that interrupt flag in SREG is still OFF
	              ;reti in TaskSchedular will enable it              
				  ;2.temp and SREG will be restored between labels "DispatchDPCExtension" and "TaskSchedular"

    */
	pop temp      ;restore temp and SREG to its task's context value/make sure _PRE_INTERRUPT is invoked first!!!!!!!!!!!!!
    out SREG,temp
	pop temp

	jmp DispatchDPCExtension

nodeschedual:    
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
Interrupt Dispatch Table (IDT) keeps record of all registered interrupt processing tasks by preserving LSB address of TCB.
Most of the AVRs has SRAM starting from 0x060 but others like AT90USB162 has it at 0x100.
KEEPING ONLY THE LSB WORKS FOR ALL AVRs IF TCB_1 - TCB_16 RESIDE WITHIN SAME 256 byte PAGE=>MSB IS THE SAME, SO NO NEED TO KEEP IT,JUST EXTRACT IT FROM TCB_1 
Interrupt activity flag records which interrupt is being processed(active) or pending processing. 
Interrupt processing tasks are executed at DEVICE level. The processor remains at 
DEVICE level until all present interrupts are handled.
Each item in ITD will keep Task ID that is meant to process the interrupt.
IDT dispatches interrupts to tasks in sequential order from the highest to lowest index.
Each index is selected by the schedular untill the interrupt processing task behind it is finished - which basically masks
the processing of the interrupts of lower index value.

---------------------
1. Interrupt Index Activity        
------IDT------------
N. Task ID 
---------------------
*/

InterruptDispatchFlag:           .byte 1 ;up to 8 interrupt processing tasks

IDT:   							 .byte IDT_SIZE

#ifdef EVENT
.include "kernel/event.inc"
EVENTS_STATE: .byte 1           ;up to 8 events applic;ation wide
#endif

#ifdef MUTEX
.include "kernel/mutex.inc"
MUTEX_STATE: .byte 1            ;up to 8 mutexes application wide 
#endif

#ifdef THRESHOLD_BARRIER_EXTENTION
.include "kernel/threshold-barrier.inc" 
;BARRIER straucture
; ________________
;|y|-|-|-|x|x|x|x|
;~~~~~~~~~~~~~~~~~
;y->leader bit
;---not used 
;xxxx ->total number of tasks to wait on the barrier
InitTasksBarrier:   .byte 1
#endif

/*
Extended Event system definition
*/
#ifdef EVENT_EXTENTION
.include "EventExt.inc"  
;Extended event straucture
; ________________
;|y|-|-|-|v|v|v|v|
;|-|-|-|-|t|t|t|t|
;~~~~~~~~~~~~~~~~~
;y  	->signaled/not signaled bit
;-  	->not used 
;vvvv 	->next valid ticket number
;tttt	->ticket number




GUI_EVENT:           .byte 2 
#endif

/*
Lock synchronization definition
*/
#ifdef LOCK_EXTENTION
.include "Lock.inc"

datalock:            .byte 2

#endif

/*
Cyclic Barrier synchronization definition 
*/
#ifdef CYCLIC_BARRIER_EXTENTION
.include "CyclicBarrier.inc"

demobarrier:         .byte 1

#endif

/*
Latch synchronization definition 
*/
#ifdef LATCH_EXTENTION
.include "CountDownLatch.inc"

demolatch:         .byte 1

#endif

/*
SLEEP mode
*/
#ifdef SLEEP_MODE
.include "SLEEP.inc"
#endif
