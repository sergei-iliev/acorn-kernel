my_task:

  	//init resources
	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER

my_task_main:
	nop
   //tasks main loop
rjmp my_task_main