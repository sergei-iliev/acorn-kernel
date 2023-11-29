/*
Define the number of interrupts that will be processed at DEVICE level
@IMPORTANT - schedule timer does not count.It is processed 
in the interrupt handler as it is.
*/

.CSEG

.ORG        0x00  
	 rjmp    RESET      ;OS entry point

.ORG RTC_PIT_vect
     rjmp RTC_PIT_Intr
.ORG PORTC_PORT_vect
     rjmp PORTC_Intr

.ORG        TCA0_OVF_vect
     rjmp SystemTickInt


.ORG  USART0_RXC_vect
     rjmp USART0_RXC_Intr

;.ORG        PORTE_INT0_vect
;     rjmp porte_int0

;.ORG        PORTE_INT1_vect
;     rjmp porte_int1
.EXIT 