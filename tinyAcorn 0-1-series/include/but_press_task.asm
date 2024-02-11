.equ PIN0 = 0
.equ PIN1 = 1
.equ PIN5 = 5
.equ PIN7 = 7
/*
Use tiny817 explain board LED and Button
*/
.def    counter=r15

#define BUTTON_PRESS_ID 1

button_press_task:
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

   ;setup SLEEP on button press   
   _SLEEP_INIT temp

   	_THRESHOLD_BARRIER_WAIT InitTasksBarrier,TASKS_NUMBER

	clr counter
main1:


	_INTERRUPT_WAIT BUTTON_PRESS_ID
	  lds temp,PORTC_OUTTGL
	  sbr temp,1<<PIN0
	  sts PORTC_OUTTGL,temp

	  
	  lds temp,PORTC_IN
	  sbrs temp,PIN0	  
	  rjmp but_led_on
	  ;here LED is off
	  
	  rjmp but_leg_exit
but_led_on:
	  ;here LED is on

	  ;rcall disable_rtc

but_leg_exit:


	_INTERRUPT_END BUTTON_PRESS_ID


	lds temp,PORTC_IN
	sbrc temp,PIN0	  
	  

	;only at EVEN counter
	_SLEEP_CPU temp

rjmp main1



PORTC_Intr:
_PRE_INTERRUPT

  ;is this comming from PIN5
  lds temp,PORTC_INTFLAGS
  sbrs temp, PORT_INT5_bp
  rjmp portc_intr_exit

  ;is sleep requested
  _IS_SLEEP_CPU_REQUESTED portc_intr_exit,temp


  ;clear intr flag
  lds temp,PORTC_INTFLAGS
  sbr temp,1<<PORT_INT5_bp
  sts PORTC_INTFLAGS,temp
  
  //yes it is pressed - send DPC
  _keDISPATCH_DPC BUTTON_PRESS_ID

portc_intr_exit:
  ;clear intr flag
  lds temp,PORTC_INTFLAGS
  sbr temp,1<<PORT_INT5_bp
  sts PORTC_INTFLAGS,temp

_POST_INTERRUPT
_RETI
.EXIT