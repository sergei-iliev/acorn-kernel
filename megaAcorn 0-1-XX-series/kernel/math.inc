;***************************************************************************
;*
;* "ADD16" - Add two 16-bit register pairs
;*
;* Adds src (MSB:LSB) to dst (MSB:LSB). The sum replaces dst.
;* Argument order is LSB,MSB,LSB,MSB — same as SUB16 and CP16.
;*
;* Call:    ADD16 dst_LSB, dst_MSB, src_LSB, src_MSB
;* Result:  dst_MSB:dst_LSB = dst_MSB:dst_LSB + src_MSB:src_LSB
;* Flags:   C set on 16-bit overflow; Z set if the 16-bit sum is 0
;*
;* Number of words	:2
;* Number of cycles	:2
;*
;* Note: dst is overwritten. src is unchanged.
;*
;* Example:
;*   ; axh:axl (MSB:LSB) = 0x12F0, bxh:bxl (MSB:LSB) = 0x0020
;*   ADD16 axl,axh,bxl,bxh
;*   ; axh:axl (MSB:LSB) = 0x1310
;*
;*   ; pointer + index (used by the 16-bit queue)
;*   ADD16 ZL,ZH,bxl,bxh
;*
;***************************************************************************
.MACRO ADD16 
	add @0,@2 ;Add LSB
	adc @1,@3 ;Add MSB with carry
.ENDMACRO

;***************************************************************************
;*
;* "ADDI16" - Add a 16-bit immediate to a 16-bit register pair
;*
;* Adds the constant k to dst (MSB:LSB). The sum replaces dst.
;* Implemented as subtract-of-negative because AVR has no ADDI/ADCI.
;*
;* Call:    ADDI16 dst_LSB, dst_MSB, k
;* Result:  dst_MSB:dst_LSB = dst_MSB:dst_LSB + k
;* Flags:   C set on 16-bit overflow; Z set if the 16-bit sum is 0
;*
;* Number of words	:2
;* Number of cycles	:2
;*
;* Note: dst is overwritten. k must be an assembler constant expression.
;*
;* Example:
;*   ; bxh:bxl (MSB:LSB) = list base, ARRAY_PTR_OFFSET = 4
;*   ADDI16 bxl,bxh,ARRAY_PTR_OFFSET
;*   ; bxh:bxl (MSB:LSB) now points at the first node
;*
;*   ADDI16 XL,XH,1
;*   ; XH:XL (MSB:LSB) = XH:XL + 1
;*
;***************************************************************************
.MACRO ADDI16
   subi @0,low(-@2)   ;Add k to LSB
   sbci @1,high(-@2)  ;Add k to MSB with carry
.ENDMACRO

;***************************************************************************
;*
;* "SUBI16" - Subtract a 16-bit immediate from a 16-bit register pair
;*
;* Subtracts the constant k from dst (MSB:LSB). The difference replaces dst.
;*
;* Call:    SUBI16 dst_LSB, dst_MSB, k
;* Result:  dst_MSB:dst_LSB = dst_MSB:dst_LSB - k
;* Flags:   C set on 16-bit borrow; Z set if the 16-bit difference is 0
;*
;* Number of words	:2
;* Number of cycles	:2
;*
;* Note: dst is overwritten. k must be an assembler constant expression.
;*
;* Example:
;*   ; axh:axl (MSB:LSB) = 0x1310
;*   SUBI16 axl,axh,0x0020
;*   ; axh:axl (MSB:LSB) = 0x12F0
;*
;*   SUBI16 temp,r17,1
;*   ; r17:temp (MSB:LSB) = r17:temp - 1
;*
;***************************************************************************
.MACRO SUBI16 
	subi @0,low(@2)    ;Subtract k from LSB
	sbci @1,high(@2)   ;Subtract k from MSB with borrow
.ENDMACRO 

;***************************************************************************
;*
;* "DEC16" - Decrement a 16-bit register pair
;*
;* Subtracts 1 from dst (MSB:LSB). The difference replaces dst.
;* Same as SUBI16 dst_LSB, dst_MSB, 1.
;*
;* Call:    DEC16 dst_LSB, dst_MSB
;* Result:  dst_MSB:dst_LSB = dst_MSB:dst_LSB - 1
;* Flags:   C set on 16-bit borrow; Z set if the 16-bit result is 0
;*
;* Number of words	:2
;* Number of cycles	:2
;*
;* Note: dst is overwritten.
;*
;* Example:
;*   ; axh:axl (MSB:LSB) = 0x0100
;*   DEC16 axl,axh
;*   ; axh:axl (MSB:LSB) = 0x00FF
;*
;*   DEC16 bxl,bxh
;*   ; bxh:bxl (MSB:LSB) = bxh:bxl - 1
;*
;***************************************************************************
.MACRO DEC16 
	subi @0,1     ;Subtract 1 from LSB
	sbci @1,0     ;Propagate borrow into MSB
.ENDMACRO 			 		   		  			
;***************************************************************************
;*
;* "LDI16" - Load a 16-bit immediate into a 16-bit register pair
;*
;* Splits constant k into LSB and MSB and loads them into dst.
;*
;* Call:    LDI16 dst_LSB, dst_MSB, k
;* Result:  dst_LSB = low(k), dst_MSB = high(k)
;*          dst_MSB:dst_LSB = k
;*
;* Number of words	:2
;* Number of cycles	:2
;*
;* Note: dst must be high registers (r16-r31); ldi cannot target r0-r15.
;*       k must be an assembler constant expression (value or label).
;*       Flags are unchanged.
;*
;* Example:
;*   LDI16 axl,axh,0x12F0
;*   ; axh:axl (MSB:LSB) = 0x12F0
;*
;*   LDI16 XL,XH,498
;*   ; XH:XL (MSB:LSB) = 498
;*
;*   LDI16 ZL,ZH,fm24c04_buf
;*   ; ZH:ZL (MSB:LSB) = address of fm24c04_buf
;*
;***************************************************************************
.MACRO LDI16 
   ldi	@0,low(@2)    ;Load LSB
   ldi	@1,high(@2)   ;Load MSB
.ENDMACRO
;***************************************************************************
;*
;* "SUB16" - Subtract two 16-bit register pairs
;*
;* Subtracts src (MSB:LSB) from dst (MSB:LSB). The difference replaces dst.
;* Argument order is LSB,MSB,LSB,MSB — same as ADD16 and CP16.
;*
;* Call:    SUB16 dst_LSB, dst_MSB, src_LSB, src_MSB
;* Result:  dst_MSB:dst_LSB = dst_MSB:dst_LSB - src_MSB:src_LSB
;* Flags:   C set on 16-bit borrow; Z set if the 16-bit difference is 0
;*
;* Number of words	:2
;* Number of cycles	:2
;*
;* Note: dst is overwritten. src is unchanged.
;*
;* Example:
;*   ; axh:axl (MSB:LSB) = 0x1310, bxh:bxl (MSB:LSB) = 0x0020
;*   SUB16 axl,axh,bxl,bxh
;*   ; axh:axl (MSB:LSB) = 0x12F0
;*
;*   SUB16 YL,YH,ZL,ZH
;*   ; YH:YL (MSB:LSB) = YH:YL - ZH:ZL
;*
;***************************************************************************
.MACRO SUB16 
	sub	@0,@2		;Subtract LSB
	sbc	@1,@3		;Subtract MSB with borrow
.ENDMACRO


;***************************************************************************
;*
;* "CP16" - Compare two 16-bit register pairs
;*
;* Compares a (MSB:LSB) with b (MSB:LSB). Neither pair is changed.
;* Argument order is LSB,MSB,LSB,MSB — same as ADD16 and SUB16.
;*
;* Call:    CP16 a_LSB, a_MSB, b_LSB, b_MSB
;* Result:  flags from (a_MSB:a_LSB - b_MSB:b_LSB)
;* Flags:   Z set if equal
;*          C set if a < b (unsigned)
;*          All conditional branches are valid after this compare
;*
;* Number of words	:2
;* Number of cycles	:2
;*
;* Example:
;*   ; axh:axl (MSB:LSB) = node value, bxh:bxl (MSB:LSB) = key
;*   CP16 axl,axh,bxl,bxh
;*   breq found           ; equal
;*
;*   CP16 bxl,bxh,axl,axh
;*   brlo below_max       ; bxh:bxl < axh:axl
;*
;***************************************************************************
.MACRO CP16
	cp	@0,@2	;Compare LSB
	cpc	@1,@3	;Compare MSB with carry from LSB
.ENDMACRO

;***************************************************************************
;*
;* "CPI16" - Compare a 16-bit register pair with a 16-bit immediate
;*
;* Compares a (MSB:LSB) with constant k. a is unchanged.
;* tmp is overwritten with the MSB of k (needed because AVR has no CPCI).
;*
;* Call:    CPI16 a_LSB, a_MSB, tmp, k
;* Result:  flags from (a_MSB:a_LSB - k)
;* Flags:   Z set if equal
;*          C set if a < k (unsigned)
;*          All conditional branches are valid after this compare
;*
;* Number of words	:3
;* Number of cycles	:3
;*
;* Note: a_LSB, a_MSB, and tmp must be high registers (r16-r31).
;*       k must be an assembler constant expression.
;*
;* Example:
;*   ; XH:XL (MSB:LSB) vs max FRAM size
;*   CPI16 XL,XH,temp,512
;*   brsh too_big         ; XH:XL >= 512
;*
;*   CPI16 axl,axh,temp,0
;*   breq is_zero         ; axh:axl == 0
;*
;***************************************************************************
.MACRO CPI16
	cpi @0,low(@3)    ;Compare LSB with low(k)
	ldi @2,high(@3)   ;tmp = MSB of k
	cpc @1,@2         ;Compare MSB with carry from LSB
.ENDMACRO


;***************************************************************************
;*
;* "LSL16" - Logical shift left a 16-bit register pair
;*
;* Shifts dst (MSB:LSB) left by 1 bit. The vacated LSB becomes 0.
;* Argument order is MSB,LSB — opposite of ADD16 / SUB16 / CP16.
;*
;* Call:    LSL16 dst_MSB, dst_LSB
;* Result:  dst_MSB:dst_LSB = dst_MSB:dst_LSB << 1
;* Flags:   C = old MSB (bit 15); Z set if the 16-bit result is 0
;*
;* Number of words	:2
;* Number of cycles	:2
;*
;* Note: dst is overwritten.
;*
;* Example:
;*   ; bxh:bxl (MSB:LSB) = 0x00FF
;*   LSL16 bxh,bxl
;*   ; bxh:bxl (MSB:LSB) = 0x01FE
;*
;*   ; word item count -> byte count
;*   LSL16 bxh,bxl
;*
;***************************************************************************
.MACRO LSL16
 lsl @1              ;Shift LSB, C = old bit 7
 rol @0              ;Shift MSB, C = old bit 15
.ENDMACRO

;***************************************************************************
;*
;* "LSR16" - Logical shift right a 16-bit register pair
;*
;* Shifts dst (MSB:LSB) right by 1 bit. The vacated MSB becomes 0.
;* Argument order is MSB,LSB — same as LSL16, opposite of ADD16 / SUB16 / CP16.
;*
;* Call:    LSR16 dst_MSB, dst_LSB
;* Result:  dst_MSB:dst_LSB = dst_MSB:dst_LSB >> 1
;* Flags:   C = old LSB (bit 0); Z set if the 16-bit result is 0
;*
;* Number of words	:2
;* Number of cycles	:2
;*
;* Note: dst is overwritten.
;*
;* Example:
;*   ; bxh:bxl (MSB:LSB) = 0x01FE
;*   LSR16 bxh,bxl
;*   ; bxh:bxl (MSB:LSB) = 0x00FF
;*
;***************************************************************************
.MACRO LSR16
 lsr @0              ;Shift MSB, C = old bit 8
 ror @1              ;Shift LSB, C = old bit 0
.ENDMACRO
/*
32 - bit arithmetic 
*/

;***************************************************************************
;*
;* "LDI32" - Load a 32-bit immediate into four registers
;*
;* Splits constant k into four bytes and loads them LSB to MSB.
;* Argument order is LSB,b1,b2,MSB — same as ADD32 / SUBI32 / LSL32.
;*
;* Call:    LDI32 dst0, dst1, dst2, dst3, k
;*          dst0 = LSB (bits 7:0), dst3 = MSB (bits 31:24)
;* Result:  dst3:dst2:dst1:dst0 (MSB:...:LSB) = k
;*
;* Number of words	:4
;* Number of cycles	:4
;*
;* Note: all four dst registers must be high registers (r16-r31).
;*       k must be an assembler constant expression.
;*       Flags are unchanged.
;*
;* Example:
;*   LDI32 dxl,dxh,cxl,cxh,0x12345678
;*   ; cxh:cxl:dxh:dxl (MSB:...:LSB) = 0x12345678
;*   ; dxl=0x78, dxh=0x56, cxl=0x34, cxh=0x12
;*
;***************************************************************************
.MACRO	LDI32
		ldi	@0,low(lwrd(@4))    ;Load LSB  bits 7:0
		ldi	@1,high(lwrd(@4))   ;Load      bits 15:8
		ldi	@2,low(hwrd(@4))    ;Load      bits 23:16
		ldi	@3,high(hwrd(@4))   ;Load MSB  bits 31:24
.ENDMACRO

;***************************************************************************
;*
;* "SUBI32" - Subtract a 32-bit immediate from four registers
;*
;* Subtracts constant k from dst (MSB:...:LSB). The difference replaces dst.
;* Argument order is LSB,b1,b2,MSB — same as LDI32 / ADD32 / LSL32.
;*
;* Call:    SUBI32 dst0, dst1, dst2, dst3, k
;*          dst0 = LSB (bits 7:0), dst3 = MSB (bits 31:24)
;* Result:  dst3:dst2:dst1:dst0 (MSB:...:LSB) -= k
;* Flags:   C set on 32-bit borrow; Z set if the 32-bit difference is 0
;*
;* Number of words	:4
;* Number of cycles	:4
;*
;* Note: all four dst registers must be high registers (r16-r31).
;*       k must be an assembler constant expression.
;*       dst is overwritten.
;*
;* Example:
;*   ; cxh:cxl:dxh:dxl (MSB:...:LSB) = 0x12345678
;*   SUBI32 dxl,dxh,cxl,cxh,1
;*   ; cxh:cxl:dxh:dxl (MSB:...:LSB) = 0x12345677
;*
;***************************************************************************
.MACRO	SUBI32
	subi	@0,low(lwrd(@4))    ;Subtract k from LSB  bits 7:0
	sbci	@1,high(lwrd(@4))   ;Subtract             bits 15:8
	sbci	@2,low(hwrd(@4))    ;Subtract             bits 23:16
	sbci	@3,high(hwrd(@4))   ;Subtract k from MSB  bits 31:24
.ENDMACRO

;***************************************************************************
;*
;* "ADDI32" - Add a 32-bit immediate to four registers
;*
;* Adds constant k to dst (MSB:...:LSB). The sum replaces dst.
;* Implemented as subtract-of-negative because AVR has no ADDI/ADCI.
;* Argument order is LSB,b1,b2,MSB — same as LDI32 / SUBI32 / ADD32.
;*
;* Call:    ADDI32 dst0, dst1, dst2, dst3, k
;*          dst0 = LSB (bits 7:0), dst3 = MSB (bits 31:24)
;* Result:  dst3:dst2:dst1:dst0 (MSB:...:LSB) += k
;* Flags:   C set on 32-bit overflow; Z set if the 32-bit sum is 0
;*
;* Number of words	:4
;* Number of cycles	:4
;*
;* Note: all four dst registers must be high registers (r16-r31).
;*       k must be an assembler constant expression.
;*       dst is overwritten.
;*
;* Example:
;*   ; cxh:cxl:dxh:dxl (MSB:...:LSB) = 0x12345678
;*   ADDI32 dxl,dxh,cxl,cxh,1
;*   ; cxh:cxl:dxh:dxl (MSB:...:LSB) = 0x12345679
;*
;***************************************************************************
.MACRO	ADDI32
	subi	@0,low(lwrd(-(@4)))    ;Add k to LSB  bits 7:0
	sbci	@1,high(lwrd(-(@4)))   ;Add           bits 15:8
	sbci	@2,low(hwrd(-(@4)))    ;Add           bits 23:16
	sbci	@3,high(hwrd(-(@4)))   ;Add k to MSB  bits 31:24
.ENDMACRO

;***************************************************************************
;*
;* "ADD32" - Add two 32-bit values in register sets
;*
;* Adds src (MSB:...:LSB) to dst (MSB:...:LSB). The sum replaces dst.
;* Argument order is LSB,b1,b2,MSB for each operand — same as LDI32 / SUBI32.
;*
;* Call:    ADD32 dst0, dst1, dst2, dst3, src0, src1, src2, src3
;*          dst0/src0 = LSB (bits 7:0), dst3/src3 = MSB (bits 31:24)
;* Result:  dst3:dst2:dst1:dst0 (MSB:...:LSB) += src3:src2:src1:src0
;* Flags:   C set on 32-bit overflow; Z set if the 32-bit sum is 0
;*
;* Number of words	:4
;* Number of cycles	:4
;*
;* Note: dst is overwritten. src is unchanged.
;*
;* Example:
;*   ; cxh:cxl:dxh:dxl (MSB:...:LSB) = 0x00000010  (A)
;*   ; r12:r11:r10:r9  (MSB:...:LSB) = 0x00000020  (B)
;*   ADD32 dxl,dxh,cxl,cxh,r9,r10,r11,r12
;*   ; cxh:cxl:dxh:dxl (MSB:...:LSB) = 0x00000030
;*
/*
 ADD UNSIGNED LSB->MSB
 32+32 Bit Un/Signed Addition
 (+)+(+)
 (-)+(-)
 (-)+(+)
 (+)+(-)
*/
;***************************************************************************
.MACRO	ADD32
	add		@0,@4    ;Add LSB  bits 7:0
	adc		@1,@5    ;Add      bits 15:8
	adc		@2,@6    ;Add      bits 23:16
	adc		@3,@7    ;Add MSB  bits 31:24
.ENDMACRO

;***************************************************************************
;*
;* "CP32" - Compare two 32-bit values in register sets
;*
;* Compares a (MSB:...:LSB) with b (MSB:...:LSB). Neither set is changed.
;* Argument order is LSB,b1,b2,MSB for each operand — same as ADD32 / LDI32.
;*
;* Call:    CP32 a0, a1, a2, a3, b0, b1, b2, b3
;*          a0/b0 = LSB (bits 7:0), a3/b3 = MSB (bits 31:24)
;* Result:  flags from (a3:a2:a1:a0 - b3:b2:b1:b0)
;* Flags:   Z set if equal
;*          C set if a < b (unsigned)
;*          All conditional branches are valid after this compare
;*
;* Number of words	:4
;* Number of cycles	:4
;*
;* Example:
;*   ; axh:axl:dxh:dxl (MSB:...:LSB) = node value
;*   ; cxh:cxl:bxh:bxl (MSB:...:LSB) = key
;*   CP32 dxl,dxh,axl,axh,bxl,bxh,cxl,cxh
;*   breq found           ; equal
;*   brlo below           ; node < key (unsigned)
;*
;***************************************************************************
.MACRO	CP32
	cp	@0,@4    ;Compare LSB  bits 7:0
	cpc	@1,@5    ;Compare      bits 15:8
	cpc	@2,@6    ;Compare      bits 23:16
	cpc	@3,@7    ;Compare MSB  bits 31:24
.ENDMACRO


;***************************************************************************
;*
;* "CPI32" - Compare a 32-bit register set with a 32-bit immediate
;*
;* Compares a (MSB:...:LSB) with constant k. a is unchanged.
;* tmp is overwritten (needed because AVR has no CPCI).
;* Argument order is LSB,b1,b2,MSB — same as CP32 / ADD32 / LDI32.
;*
;* Call:    CPI32 a0, a1, a2, a3, tmp, k
;*          a0 = LSB (bits 7:0), a3 = MSB (bits 31:24)
;* Result:  flags from (a3:a2:a1:a0 - k)
;* Flags:   Z set if equal
;*          C set if a < k (unsigned)
;*          All conditional branches are valid after this compare
;*
;* Number of words	:7
;* Number of cycles	:7
;*
;* Note: a0 and tmp must be high registers (r16-r31).
;*       k must be an assembler constant expression.
;*
;* Example:
;*   ; cxh:cxl:dxh:dxl (MSB:...:LSB) vs 0
;*   CPI32 dxl,dxh,cxl,cxh,temp,0
;*   breq is_zero
;*
;*   CPI32 dxl,dxh,cxl,cxh,temp,0x12345678
;*   brlo below           ; a < 0x12345678 (unsigned)
;*
;***************************************************************************
.MACRO	CPI32
	cpi	@0,low(lwrd(@5))     ;Compare LSB  bits 7:0 with low(k)
	ldi	@4,high(lwrd(@5))    ;tmp = bits 15:8 of k
	cpc	@1,@4
	ldi	@4,low(hwrd(@5))     ;tmp = bits 23:16 of k
	cpc	@2,@4
	ldi	@4,high(hwrd(@5))    ;tmp = MSB of k
	cpc	@3,@4                ;Compare MSB  bits 31:24
.ENDMACRO

;***************************************************************************
;*
;* "LSL32" - Logical shift left a 32-bit register set
;*
;* Shifts dst (MSB:...:LSB) left by 1 bit. The vacated LSB becomes 0.
;* Argument order is LSB,b1,b2,MSB — same as ADD32 / LDI32, opposite of LSL16.
;*
;* Call:    LSL32 dst0, dst1, dst2, dst3
;*          dst0 = LSB (bits 7:0), dst3 = MSB (bits 31:24)
;* Result:  dst3:dst2:dst1:dst0 (MSB:...:LSB) << 1
;* Flags:   C = old MSB (bit 31); Z set if the 32-bit result is 0
;*
;* Number of words	:4
;* Number of cycles	:4
;*
;* Note: dst is overwritten.
;*
;* Example:
;*   ; cxh:cxl:dxh:dxl (MSB:...:LSB) = 0x000000FF
;*   LSL32 dxl,dxh,cxl,cxh
;*   ; cxh:cxl:dxh:dxl (MSB:...:LSB) = 0x000001FE
;*
;***************************************************************************
.MACRO LSL32
	lsl @0              ;Shift LSB  bits 7:0,  C = old bit 7
	rol @1              ;Shift      bits 15:8
	rol @2              ;Shift      bits 23:16
	rol @3              ;Shift MSB  bits 31:24, C = old bit 31
.ENDMACRO

;***************************************************************************
;*
;* "LSR32" - Logical shift right a 32-bit register set
;*
;* Shifts dst (MSB:...:LSB) right by 1 bit. The vacated MSB becomes 0.
;* Argument order is LSB,b1,b2,MSB — same as LSL32 / ADD32, opposite of LSR16.
;*
;* Call:    LSR32 dst0, dst1, dst2, dst3
;*          dst0 = LSB (bits 7:0), dst3 = MSB (bits 31:24)
;* Result:  dst3:dst2:dst1:dst0 (MSB:...:LSB) >> 1
;* Flags:   C = old LSB (bit 0); Z set if the 32-bit result is 0
;*
;* Number of words	:4
;* Number of cycles	:4
;*
;* Note: dst is overwritten.
;*
;* Example:
;*   ; cxh:cxl:dxh:dxl (MSB:...:LSB) = 0x000001FE
;*   LSR32 dxl,dxh,cxl,cxh
;*   ; cxh:cxl:dxh:dxl (MSB:...:LSB) = 0x000000FF
;*
;***************************************************************************
.MACRO LSR32
	lsr @3              ;Shift MSB  bits 31:24, C = old bit 24
	ror @2              ;Shift      bits 23:16
	ror @1              ;Shift      bits 15:8
	ror @0              ;Shift LSB  bits 7:0,  C = old bit 0
.ENDMACRO
;***************************************************************************
;*
;* "NEG32" - Two's complement negate a 32-bit register set
;*
;* Replaces dst (MSB:...:LSB) with -dst. Does invert-all-bits then add 1.
;* Argument order is LSB,b1,b2,MSB — same as ADD32 / LDI32 / LSL32.
;*
;* Call:    NEG32 dst0, dst1, dst2, dst3, tmp
;*          dst0 = LSB (bits 7:0), dst3 = MSB (bits 31:24)
;* Result:  dst3:dst2:dst1:dst0 (MSB:...:LSB) = -dst
;* Flags:   from the final adc of the +1 step
;*          Z set if the 32-bit result is 0 (original was 0)
;*          C set if there was carry out of the MSB
;*
;* Number of words	:10
;* Number of cycles	:10
;*
;* Note: dst is overwritten. tmp is overwritten and must be a high
;*       register (r16-r31) because of ldi.
;*
;* Example:
;*   ; r12:r11:r10:r9 (MSB:...:LSB) = 0x00000005
;*   NEG32 r9,r10,r11,r12,temp
;*   ; r12:r11:r10:r9 (MSB:...:LSB) = 0xFFFFFFFB  (-5)
;*
;***************************************************************************
.MACRO NEG32 
    com     @0            ;Invert LSB  bits 7:0
    com     @1            ;Invert      bits 15:8
    com     @2            ;Invert      bits 23:16
    com     @3            ;Invert MSB  bits 31:24

    ldi     @4, 1         ;tmp = 1
    add     @0,@4         ;Add 1 to LSB
    clr     @4            ;tmp = 0
    adc     @1, @4        ;Propagate carry
    adc     @2, @4
    adc     @3, @4        ;Propagate carry into MSB
.ENDMACRO