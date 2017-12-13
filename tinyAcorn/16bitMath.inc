;****************************************************************************
;* Add 16 bit number in a registers to 16 bit number
;*
;****************************************************************************
.MACRO _ADD16 
	add @0,@2 ;Add low bytes
	adc @1,@3 ;Add high bytes with carry
.ENDMACRO

.MACRO ADDI16
   subi @0,low(-@2)
   sbci @1,high(-@2)
.ENDMACRO

.MACRO SUBI16 
	subi @0,low(@2) 
	sbci @1,high(@2)
.ENDMACRO ; 

;***************************************************************************
;*
;* "cpi16" - Comparing 16-bit register with 16-bit immediate
;*
;* This example compares the register pairs (cpi1l,cpi1h) with the value
;* cpi2.  If they are equal the zero flag is set(one), otherwise it is
;* cleared(zero). This is enabled by the AVR's zero propagation. Carry is
;* also set if the result is negative. This means that all conditional
;* branch instructions can be used after the comparison.
;*
;* Number of words :3
;* Number of cycles :3
;* Low registers used :None
;* High registers used :3
;*
;*
;***************************************************************************

;***** Register Variables
;.def cp1l =r16   ;@0
;.def cp1h =r17   ;@1
;.def c_tmp=r18    ;@2
;.equ cp2 = 0x3412 ;@3  Immediate to compare with

;***** Code
.MACRO CPI16
	cpi @0,low(@3)    ;Compare low byte
	ldi @2,high(@3)  ;
	cpc @1,@2       ;Compare high byte
.ENDMACRO
;Expected result is Z=1, C=
