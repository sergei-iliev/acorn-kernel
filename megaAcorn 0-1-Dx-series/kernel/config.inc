/*
Define the frequency value the CPU is running at 
*/
#define SYSTEM_CLOCK 24000000   ;Hz

/*
*Define the number of tasks. Up to 16 for X and Mega kernel 
*/
#define TASKS_NUMBER 4

/*
Program Counter register size (2 or 3 bytes) 
*/
;#define AVR_3_BYTE_PC

#define AVR_2_BYTE_PC    


#ifdef AVR_3_BYTE_PC
	#define AVR_PC_SIZE 3
#else
	#define AVR_PC_SIZE 2
#endif

/*
Define 2 bytes sleep task interval
*/
#define TASK_SLEEP_EXT
	
#ifdef TASK_SLEEP_EXT
    #define TASK_TCB_SIZE 5			; 2 byte stack pointer , 1 task status and 2 bytes timeout value 
#else
	#define TASK_TCB_SIZE 4			; 2 byte stack pointer 
#endif

#define TASK_STATE_OFFSET 2
#define TASK_TIMEOUT_OFFSET 3

/*
Default stack size per task.
It is used when default _REGISTER_TASK task registration API is used
MUST be bigger then TASK_STACK_CPU_CONTEXT_SIZE
*/
.EQU TASK_STACK_SIZE=63

/*
Interrupt Dispatch Table size - up to 8  (8 tasks max to handle Interrupt Dispatches)
*/
#define IDT_SIZE   3

#define SET_STACK_TO_KNOWN_VALUE FALSE
/*
Enable sleep mode 
*/
#define SLEEP_MODE
#ifdef SLEEP_MODE
/*
Define the maximum number to participate in SLEEP sequence
These are the  tasks which will invoke _SLEEP_TASK macro
*/
 #define SLEEP_TASKS_REQUEST_NUMBER 1
#endif
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

;Comment out in production mode!!!!!!!!!!!!!!!!!!!!!!
#define DEBUG TRUE

#define DEBUG_MARKER 0x5A

.EXIT