.equ PIN0 = 0
.equ PIN1 = 1
.equ PIN5 = 5
//.equ PIN7 = 7
/*
Use tiny817 explain board LED and Button
*/
task_1:
  //---setup LED pin
  lds temp,PORTC_DIR
  sbr temp,1<<PIN0
  sts PORTC_DIR,temp

  //---setup pin interrupt  
  ;input
   lds temp,PORTC_DIR
   cbr temp,1<<PIN5
   sts PORTC_DIR,temp
  ;interrupt
   lds temp,PORTC_PIN5CTRL
   ori temp,PORT_ISC_FALLING_gc
   sts PORTC_PIN5CTRL,temp

   	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER
main1:
  _YIELD_TASK
rjmp main1



PORTC_Intr:
_PRE_INTERRUPT
  ;is this comming from PIN5
  lds temp,PORTC_INTFLAGS
  sbrs temp, PORT_INT5_bp
  rjmp portc_intr_exit

  lds temp,PORTC_OUTTGL
  sbr temp,1<<PIN0
  sts PORTC_OUTTGL,temp

portc_intr_exit:
  ;clear intr flag
  lds temp,PORTC_INTFLAGS
  sbr temp,1<<PORT_INT5_bp
  sts PORTC_INTFLAGS,temp

  
_POST_INTERRUPT
_RETI
.EXIT