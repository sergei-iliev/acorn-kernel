;*******************EVENT*************************************
;Event system for up to 8 events kept in EVENT_STATE RAM byte.Requires 1 bit per event.
;use event #{0-7} to identify the event.
;set 1 to event # to tell the rest,the event happened
;set 0 to event # to clear event
;Notification type of event - one task waits on it while many other tasks could signal(awaken) it. 
;It is possible to lose signal if many tasks signal the event

;----------------------------------------------------------------
;KERNEL AND USER MODE API
;INPUT: @0 - event #
;       @1 - context{0=task;0xFF=interrupt}
;USAGE: temp(saved on current task stack)
;----------------------------------------------------------------
.MACRO  _EVENT_SET 
    .IF @1==TASK_CONTEXT   ;no interrupt is possible if in interrupt sei is NOT used
    cli
	.ENDIF
	
    push temp
	
	lds temp,EVENTS_STATE
	sbr temp,1<<@0


	sts EVENTS_STATE,temp
	
	pop temp

	.IF @1==TASK_CONTEXT  ;no interrupt is possible if in interrupt sei is NOT used
	sei
	.ENDIF
.ENDMACRO


;----------------------------------------------------------------
;USER MODE API
;Used in the context of a thread only!
;Wait indefinitly on an event.
;Auto reset event.
;INPUT: @0 - event #
;USAGE: temp(saved on current task stack)
;WARNING:  A new signal from onather task could come (if more then one task notifies the waiting task) between 
;          code points 1 and 2! The second signal will be swallowed up so mind this when more then one task notifies the waiting task!
;----------------------------------------------------------------           
.MACRO _EVENT_WAIT
    push temp

mloop:
	cli
	lds temp,EVENTS_STATE
	sbrc temp,@0
	rjmp event_is_set
	sei
	_YIELD_TASK
	rjmp mloop

event_is_set:               ;1  - a signal has come 
	cbr temp,1<<@0

	sts EVENTS_STATE,temp
	sei
	
	pop temp                  
.ENDMACRO

;----------------------------------------------------------------
;USER MODE API
;Used in the context of a thread only!
;Manual reset event.
;INPUT: @0 - event #
;USAGE: temp(saved on current task stack)
;----------------------------------------------------------------
.MACRO _EVENT_RESET
	push temp
	cli
	lds temp,EVENTS_STATE
	cbr temp,1<<@0
	sts EVENTS_STATE,temp
	sei
	pop temp
.ENDMACRO