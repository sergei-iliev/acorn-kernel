/*global counter**/
//.def    counter=r10    ;

task_2:	
  //---setup LED pin on PB0
  lds temp,PORTB_DIR
  sbr temp,1<<PIN0
  sts PORTB_DIR,temp


  	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
main2:  

  lds temp,PORTB_OUT
  sbr temp,1<<PIN0
  sts PORTB_OUT,temp

  _SLEEP_TASK_EXT 2000 

  lds temp,PORTB_OUT
  cbr temp,1<<PIN0
  sts PORTB_OUT,temp

  _SLEEP_TASK_EXT 2000  

rjmp main2




