;****************************************************************************
;* Add 16 bit number in registers to 16 bit number
;*
;****************************************************************************
.MACRO ADD16 
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
.ENDMACRO 

;***************************************************************************
;* 
;* "sub16" - Subtracting 16-bit registers 
;*
;* This example subtracts two pairs of register variables (sub1l,sub1h) 
;* from (sub2l, sub2h)  The result is stored in registers sub1l, sub1h.
;*
;* Number of words	:2
;* Number of cycles	:2
;* Low registers used	:None
;* High registers used	:4
;*
;* Note: The result and "sub1" share the same register.  This causes "sub1"
;* to be overwritten by the result.
;*
;***************************************************************************

;***** Register Variables
;.def sub1l = r16@0
;.def sub1h = r17@1
;.def sub2l = r18@2
;.def sub2h = r19@3

.MACRO SUB16 
	sub	@0,@2		;Subtract low bytes
	sbc	@1,@3		;Add high byte with carry
	;Expected result is 0x4646
.ENDMACRO


;***************************************************************************
;* 
;* "cp16" - Comparing two 16-bit numbers 
;*
;* This example compares the register pairs (cp1l,cp1h) with the register
;* pairs (cp2l,cp2h)  If they are equal the zero flag is set(one) 
;* otherwise it is cleared(zero)
;*
;* Number of words	:2
;* Number of cycles	:2
;* Low registers used	:None
;* High registers used	:4
;*
;* Note: The contents of "cp1" will be overwritten.
;*
;***************************************************************************                                    

                                    
.MACRO CP16
	cp	@0,@2	;Compare low byte
	cpc	@1,@3	;Compare high byte with carry from previous operation
.ENDMACRO

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


;@MACRO LSL16 MSB,LSB
.MACRO LSL16
 lsl @1
 rol @0
.ENDMACRO

/*
32 - bit arithmetic 
*/

.MACRO	LDI32				;load ACCT register with imediate value long
		ldi	@0,low(lwrd(@4))
		ldi	@1,high(lwrd(@4))
		ldi	@2,low(hwrd(@4))
		ldi	@3,high(hwrd(@4))
.ENDMACRO

/*
  SUB INTEGER IMEDIATE TO REGISTER PAIR LONG
*/
.MACRO	SUBI32
	subi	@0,low(lwrd(@4))
	sbci	@1,high(lwrd(@4))
	sbci	@2,low(hwrd(@4))
	sbci	@3,high(hwrd(@4))
.ENDMACRO

/*
 ADD INTEGER IMEDIATE TO REGISTER PAIR LONG
*/
.MACRO	ADDI32
	subi	@0,low(lwrd(-(@4)))
	sbci	@1,high(lwrd(-(@4)))
	sbci	@2,low(hwrd(-(@4)))
	sbci	@3,high(hwrd(-(@4)))
.ENDMACRO

/*
 COMPARE ACC IMEDIATE TO LONG
*/
.MACRO	CPI32
	cpi	@0,low(lwrd(@5))
	ldi	@4,high(lwrd(@5))
	cpc	@1,@4
	ldi	@4,low(hwrd(@5))
	cpc	@2,@4
	ldi	@4,high(hwrd(@5))
	cpc	@3,@4
.ENDMACRO