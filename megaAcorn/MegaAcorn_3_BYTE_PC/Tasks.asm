;*****DON'T PUT INCLUDE FILES BEFORE TASK 1 DEFINITION


System_Task: 
	sbi DDRF,PF0
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main1:

    sbi PORTF,PF0
	_SLEEP_TASK 255
	cbi PORTF,PF0
	_SLEEP_TASK 255
rjmp main1  



Task_UART:		 
;init task
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

main2:
;loop 

rjmp main2 




Task_3:		 
;init task
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

main3:
;loop

rjmp main3  	
