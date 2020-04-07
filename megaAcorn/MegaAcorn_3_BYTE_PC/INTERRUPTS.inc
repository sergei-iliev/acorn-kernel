/*
Define the number of interrupts that will be processed at DEVICE level
@IMPORTANT - schedule and clock timers does not count.They are processed 
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

;.ORG OVF1addr
;     rjmp Timer1Int       ;ordinary timer

.ORG OVF0addr
     jmp SystemTickInt  


;.ORG SPIaddr
;     rjmp SPIComplete

;.ORG	URXCaddr		; USART, Rx Complete
;     rjmp RxComplete

;.ORG	UDREaddr		; USART Data Register Empty
;	rjmp TxEmpty

;.ORG	UTXCaddr		; USART, Tx Complete
;	rjmp TxComplete

;.ORG	URXC2addr		; USART, Rx Complete
;     rjmp Rx2Complete

;.ORG	UDRE2addr		; USART Data Register Empty
;	rjmp Tx2Empty

;.ORG	UTXC2addr		; USART, Tx Complete
;	rjmp Tx2Complete

.EXIT 
