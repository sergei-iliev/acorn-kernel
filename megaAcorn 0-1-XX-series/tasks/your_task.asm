your_task:

  //init resources
  _THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER

your_task_main:
  nop
  //tasks main loop
rjmp your_task_main