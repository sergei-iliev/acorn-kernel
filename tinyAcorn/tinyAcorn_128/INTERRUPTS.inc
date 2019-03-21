
.CSEG
.ORG        0x00  
	 rjmp    RESET      ;OS entry point

;.ORG INT0addr
;    rjmp int0INT
	 
;.ORG PCI0addr
;    rjmp PCIInt

;.ORG OVF1addr
;    rjmp OVF1addrInt    ;PWM interrupt

.ORG OVF0addr
     rjmp SystemTickInt  ;kernel timer

;.ORG USI_OVFaddr
;     rjmp USI_OVFaddrInt
.EXIT 
