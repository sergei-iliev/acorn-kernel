;*****DON'T PUT INCLUDE FILES BEFORE TASK 1 DEFINITION


System_Task:
 //***turn off Watch dog reset for testing purpous
 cli
 ldi temp, (1<<WDTOE)+(1<<WDE)
 out WDTCR, temp
 ldi temp, (1<<WDTOE)
 out WDTCR, temp
 sei

_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 

_SLEEP_CPU_INIT temp

main1:
_SLEEP_CPU r16,r17
nop
_YIELD_TASK 

rjmp main1  
ret

;SOFTWARE interrupt  - autogenerate event to test the new event dispatcher.
;Blink a LED for fun!
.SET INT0_INDEX=3

Task_2:		


  
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 


main2:
nop
nop                    
nop
nop
nop
_SLEEP_CPU_READY  VOID_CALLBACK,VOID_CALLBACK,r16,r17

rjmp main2  	
ret

.include "include/lcdtask.asm"
.include "include/ds18b20task.asm"
.include "include/rs232task.asm"

Task_6:

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main6:

rjmp main6
ret




Task_7:

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main7:

rjmp main7
ret

Task_8:
    
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main8:
rjmp main8

ret

Task_9:
    
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main9:
rjmp main9
ret

Task_10:
    
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main10:
rjmp main10
ret

Task_11:
  
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER     
main11:
rjmp main11
ret

Task_12:
    
 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main12:
rjmp main12
ret

Task_13:

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER     
main13:
rjmp main13
ret

Task_14:

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER    
main14:
rjmp main14
ret



Task_15:

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main15:

rjmp main15
ret


Task_16:

 _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER 
main16:
nop

rjmp main16
ret



TimerOVF1:	
   _PRE_INTERRUPT
      
   
   _POST_INTERRUPT
reti

.EXIT









