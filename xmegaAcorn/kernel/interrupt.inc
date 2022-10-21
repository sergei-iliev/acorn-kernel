/*
Define the number of interrupts that will be processed at DEVICE level
@IMPORTANT - schedule timer does not count.It is processed 
in the interrupt handler as it is.
*/

.CSEG

.ORG        0x00  
	 rjmp    RESET      ;OS entry point
.ORG        TCC0_OVF_vect
     rjmp SystemTickInt
.ORG        TCC1_OVF_vect
     rjmp TCC1Int

.ORG        PORTE_INT0_vect
     rjmp porte_int0

.ORG        PORTE_INT1_vect
     rjmp porte_int1
.EXIT 
