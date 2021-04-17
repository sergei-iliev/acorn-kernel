/*
Define the number of interrupts that will be processed at DEVICE level
@IMPORTANT - schedule timer does not count.It is processed 
in the interrupt handler as it is.
*/

.CSEG

.ORG        0x00  
	 rjmp    RESET      ;OS entry point

;.ORG INT0addr           	
;     jmp int0INT

;.ORG INT1addr           
;     rjmp int1INT    
	 
;.ORG OVF2addr
;     rjmp T2OVF
;.ORG OC2addr
;	rjmp OC2Int

;.ORG OVF1addr
;     jmp TimerOVF1       ;sleep timer

.ORG OVF0addr
     jmp SystemTickInt  

;.ORG OVF1addr
;     rjmp T1OVF       ;ordinary timer

;.ORG OVF5addr
;     rjmp T5OVF       ;ordinary timer


;.ORG TWIaddr
;    jmp TWI_Int

;.ORG OVF5addr
;     jmp Timer5OverflowInt 
.EXIT 
