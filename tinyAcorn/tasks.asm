
.dseg
tasks: .byte 34*TASKS_NUMBER
.cseg

.SET ZERO_DPC=2
.SET ONE_DPC=3

Task_1:
;****INT0
	in temp,MCUCR
    sbr temp,(1<<ISC01)+(1<<ISC00)       ;intr on rising edge INT0
    out MCUCR,temp
  
    in temp,GIMSK
    sbr temp,1<<INT0
    out GIMSK,temp 

;****INT1
	in temp,MCUCR
    sbr temp,(1<<ISC11)+(1<<ISC10)       ;intr on rising edge INT1
    out MCUCR,temp
  
    in temp,GIMSK
    sbr temp,1<<INT1
    out GIMSK,temp 
	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER

main_1:
	nop
	nop

	;_YIELD_TASK
rjmp main_1


Task_2:

	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
main_2:
	nop
	nop
	_INTERRUPT_WAIT ZERO_DPC
	nop
	nop
	nop
	nop
	nop
	nop
	_YIELD_TASK
	nop
	nop
	nop
	_INTERRUPT_END ZERO_DPC
rjmp main_2



Task_3:

	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
main_3:
	nop
	nop
	_INTERRUPT_WAIT ONE_DPC
	nop
	nop
	nop
	nop
	nop
	_YIELD_TASK
	nop
	nop
	nop
	_INTERRUPT_END ONE_DPC
	
rjmp main_3



int0INT:
	_PRE_INTERRUPT		
    nop
	_keDISPATCH_DPC ZERO_DPC



int1INT:
	_PRE_INTERRUPT		
    nop
	_keDISPATCH_DPC ONE_DPC


.EXIT