;*****DON'T PUT INCLUDE FILES BEFORE TASK 1 DEFINITION


System_Task:
 //***turn off Watch dog reset for testing purpous
 cli
; Reset Watchdog Timer
 wdr
 ; Clear WDRF in MCUSR
 in temp, MCUSR
 andi temp, (0xff & (0<<WDRF))
 out MCUSR, temp
 ; Write '1' to WDCE and WDE
 ; Keep old prescaler setting to prevent unintentional time-out
 lds temp, WDTCSR
 ori temp, (1<<WDCE) | (1<<WDE)
 sts WDTCSR, temp
 ; Turn off WDT
 ldi temp, (0<<WDE)
 sts WDTCSR, temp
 ; Turn on global interrupt
 sei

_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 



main1:

nop
_YIELD_TASK 

rjmp main1  
ret


Task_2:		 
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 


main2:
nop
nop                    

_YIELD_TASK 

rjmp main2  	

Task_3:		 
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 


main3:
nop
nop                    
nop
nop
_YIELD_TASK 

rjmp main3  	

Task_4:		 
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 


main4:
nop
nop                    
nop
nop
nop

rjmp main4  	

Task_5:		 
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 


main5:
nop
nop                    
nop
nop
nop

rjmp main5  	


Task_6:

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main6:

rjmp main6





Task_7:

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main7:

rjmp main7


Task_8:
    
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main8:
rjmp main8


Task_9:
    
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main9:
rjmp main9


Task_10:
    
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main10:
rjmp main10


Task_11:
  
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER     
main11:
rjmp main11


Task_12:
    
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main12:
rjmp main12


Task_13:

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER     
main13:
rjmp main13


Task_14:

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER    
main14:
rjmp main14




Task_15:

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main15:

rjmp main15



Task_16:

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main16:
nop

rjmp main16


.EXIT









