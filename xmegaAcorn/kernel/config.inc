/*
Define the frequency value the CPU is running at 
*/
#define SYSTEM_CLOCK= 32000000   ;Hz

/*
*Define the number of tasks. Up to 16 for X and Mega kernel 
*/
#define TASKS_NUMBER 4

/*
Program Counter register size (4 or 3 bytes)
*/
#define AVR_3_BYTE_PC    

/*
Default stack size per task.
It is used when default _REGISTER_TASK task registration API is used
MUST be bigger then TASK_STACK_CPU_CONTEXT_SIZE
*/
.EQU TASK_STACK_SIZE=63

/*
Interrupt Dispatch Table size - up to 8  (8 tasks max to handle Interrupt Dispatches)
*/
#define IDT_SIZE   8

#define SET_STACK_TO_KNOWN_VALUE FALSE
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
;#define EVENT

;enable simple mutex synchronization
;#define MUTEX

;Comment out in production mode!!!!!!!!!!!!!!!!!!!!!!
#define DEBUG TRUE

#define DEBUG_MARKER 0x5A

.EXIT