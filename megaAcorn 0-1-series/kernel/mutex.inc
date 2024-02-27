;**********************MUTEX*********************************
;It is more like a LOCK then MUTEX.
;A mutex object is a synchronization object whose state is set to signaled when it is not owned by any task, and nonsignaled when it is owned.
;Initial state is signaled - not owned by any task
;Wait for a mutex until it gets signaled.{0->signaled;
;                                          1->not signal}
;Up to 8 different mutexes could be defined in the static MUTEX_STATE byte.


;USER MODE API 
;		Set the flag to not signaled on entering the guarded section.
;		called in the context of a thread to mark the BEGIN of the protected code section.
;INPUT: @0 - mutex #
;USAGE: temp(saved on current task stack)

.MACRO   _MUTEX_WAIT
	push temp   

mloop:
	cli
   	lds temp,MUTEX_STATE
	sbrs temp,@0
	rjmp mutex_is_signaled
	sei
	_YIELD_TASK
    rjmp mloop 
mutex_is_signaled:

;set  MUTEX to not signaled    
	lds temp,MUTEX_STATE
	set
	bld temp,@0
	sts MUTEX_STATE,temp	
	sei	

	pop temp
.ENDMACRO
;----------------------------------------------------------------
;USER MODE API 
;		Set the flag to signaled on exiting the guarded section.
;		called in the context of a thread after the call to _MUTEX_WAIT to mark the END of the protected code section.
;INPUT: @0 - mutex #
;USAGE: temp(saved on current task stack)
;----------------------------------------------------------------
.MACRO   _MUTEX_RELEASE
	cli						;write-protect MUTEXT_STATE byte!	
	
	push temp 	

	lds temp,MUTEX_STATE
	clt
	bld temp,@0
	sts MUTEX_STATE,temp
	
	pop temp	

	sei
.ENDMACRO