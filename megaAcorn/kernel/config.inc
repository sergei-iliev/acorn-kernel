/*
Define the frequency value the CPU is running at 
*/
#define SYSTEM_CLOCK= 16000000   ;Hz

/*
*Define the number of tasks. Up to 16 for X and Mega kernel 
*/
#define TASKS_NUMBER 6

/*
Program Counter register size (2 or 3 bytes)
*/
;#define AVR_3_BYTE_PC

#define AVR_2_BYTE_PC    

/*
Interrupt Dispatch Table size - up to 8  (8 tasks max to handle Interrupt Dispatches)
*/
#define IDT_SIZE   2
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
#define DEBUG 

#define DEBUG_MARKER 0x5A

.EXIT