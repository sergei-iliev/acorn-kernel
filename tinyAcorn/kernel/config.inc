/*
Define the frequency value the CPU is running at 
*/
#define SYSTEM_CLOCK= 16000000   ;Hz

/*
Stack Pointer register size (1 or 2 bytes Tiny2313/Tiny4313) 
Some tiny devices has 1 byte SP like 2313 and some has 2 bytes SP like 4313 
*/
;#define AVR_1_BYTE_SP

#define AVR_2_BYTE_SP    

/*
*Define the number of tasks. Depends on RAM size
128 - max tasks 3
>128 - max tasks 6
*/
#ifdef AVR_1_BYTE_SP
	#define TASK_TCB_SIZE 3			; 1 byte stack pointer
	/*
	Maximum allowed is 3
	*/
	#define TASKS_NUMBER 3			; 1 - 3 tasks

	#define TASK_STATE_OFFSET 1
	#define TASK_TIMEOUT_OFFSET 2
#else
	#define TASK_TCB_SIZE 4			; 2 byte stack pointer 
	/*
	Maximum allowed is 6
	*/
	#define TASKS_NUMBER 3			; 1 - 6 tasks

	#define TASK_STATE_OFFSET 2
	#define TASK_TIMEOUT_OFFSET 3
#endif

/*
Default stack size per task.
It is used when default _REGISTER_TASK task registration API is used
MUST be bigger then TASK_STACK_CPU_CONTEXT_SIZE
*/
;.EQU TASK_STACK_SIZE=38


/*
Enable sleep mode 
*/
;#define SLEEP_MODE

/*
Define Synchronization macros if needed.
*/
#define THRESHOLD_BARRIER_EXTENTION

;enable extended event synchronization
;#define EVENT_EXTENTION

;enable fair lock extended event synchronization
;#define LOCK_EXTENTION

;enable extended barrier synchronization
;#define  CYCLIC_BARRIER_EXTENTION

;enable extended latch synchronization
;#define LATCH_EXTENTION

;enable simple event notification
#define EVENT

;enable simple mutex synchronization
;#define MUTEX

#define SET_STACK_TO_KNOWN_VALUE FALSE
;Comment out in production mode!!!!!!!!!!!!!!!!!!!!!!
#define DEBUG TRUE

#define DEBUG_MARKER 0x5A

.EXIT