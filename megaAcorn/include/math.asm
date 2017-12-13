;**********************
;* Input= r23:r22 * r21:r20
;* Usage=r0,r1,r2
;* Output = r19:r18
;*          r17:r16
;****MULTIPLY unsigned 16x16=32bit

mul16x16_32:
	clr r2
	mul r23, r21 ; ah * bh

movw r19:r18, r1:r0
	mul r22, r20 ; al * bl

movw r17:r16, r1:r0
	mul r23, r20 ; ah * bl
	add r17, r0
	adc r18, r1
	adc r19, r2
	mul r21, r22 ; bh * al
	add r17, r0
	adc r18, r1
	adc r19, r2

ret

;***************************************************************************
;*
;* "bin2BCD16" - 16-bit Binary to BCD conversion
;*
;* This subroutine converts a 16-bit number (fbinH:fbinL) to a 5-digit
;* packed BCD number represented by 3 bytes (tBCD2:tBCD1:tBCD0).
;* MSD of the 5-digit number is placed in the lowermost nibble of tBCD2.
;*
;* Number of words	:25
;* Number of cycles	:751/768 (Min/Max)
;* Low registers used	:3 (tBCD0,tBCD1,tBCD2)
;* High registers used  :4(fbinL,fbinH,cnt16a,tmp16a)	
;* Pointers used	:Z
;*
;***************************************************************************

;***** Subroutine Register Variables

;.equ	AtBCD0	=13		;address of tBCD0
;.equ	AtBCD2	=15		;address of tBCD1

;.def	tBCD0	=r13		;BCD value digits 1 and 0
;.def	tBCD1	=r14		;BCD value digits 3 and 2
;.def	tBCD2	=r15		;BCD value digit 4
;.def	fbinL	=r16		;binary value Low byte
;.def	fbinH	=r17		;binary value High byte
;.def	cnt16a	=r18		;loop counter
;.def	tmp16a	=r19		;temporary value

;***** Code

;bin2BCD16:
;	ldi	cnt16a,16	;Init loop counter	
;	clr	tBCD2		;clear result (3 bytes)
;	clr	tBCD1		
;	clr	tBCD0		
;	clr	ZH		;clear ZH (not needed for AT90Sxx0x)
;bBCDx_1:lsl	fbinL		;shift input value
;	rol	fbinH		;through all bytes
;	rol	tBCD0		;
;	rol	tBCD1
;	rol	tBCD2
;	dec	cnt16a		;decrement loop counter
;	brne	bBCDx_2		;if counter not zero
;	ret			;   return
;bBCDx_2:
;       ldi r30,AtBCD2+1	;Z points to result MSB + 1
;      ld  tmp16a,-Z
;       rcall adjBCD
;       ld  tmp16a,-Z
;       rcall adjBCD
;       ld  tmp16a,-Z
;       rcall adjBCD
;       rjmp	bBCDx_1
       
;adjBCD:
;      	subi	tmp16a,-$03	;add 0x03
;	sbrc	tmp16a,3	;if bit 3 not clear
;	st	Z,tmp16a	;	store back
;	ld	tmp16a,Z	;get (Z)
;	subi	tmp16a,-$30	;add 0x30
;	sbrc	tmp16a,7	;if bit 7 not clear
;	st	Z,tmp16a	;	store back
;      ret              
      


;***************************************************************************
;*
;* "bin2BCD16" - 16-bit Binary to BCD conversion
;*
;* This subroutine converts a 16-bit number (fbinH:fbinL) to a 5-digit
;* packed BCD number represented by 3 bytes (tBCD2:tBCD1:tBCD0).
;* MSD of the 5-digit number is placed in the lowermost nibble of tBCD2.
;*
;* Number of words	:25
;* Number of cycles	:751/768 (Min/Max)
;* Low registers used	:3 (tBCD0,tBCD1,tBCD2)
;* High registers used  :4(fbinL,fbinH,cnt16a,tmp16a)	
;* Pointers used	:Z
;*
;***************************************************************************

;***** Subroutine Register Variables

.equ	BCD0	=13		;address of tBCD0
.equ	BCD2	=15		;address of tBCD1

.def	tBCD0	=r13	;BCD value digits 1 and 0
.def	tBCD1	=r14		;BCD value digits 3 and 2
.def	tBCD2	=r15		;BCD value digit 4
.def	fbinL	=r22		;binary value Low byte
.def	fbinH	=r23		;binary value High byte
.def	cnt16a	=r18		;loop counter
.def	tmp16a	=r16		;temporary value

;***** Code

bin2BCD16:
	ldi	cnt16a,16	;Init loop counter
	clr	tBCD2		;clear result (3 bytes)
	clr	tBCD1
	clr	tBCD0
	clr	ZH		;clear ZH (not needed for AT90Sxx0x)

bBCDx_1:lsl	fbinL		;shift input value
	rol	fbinH		;through all bytes
	rol	tBCD0		;
	rol	tBCD1
	rol	tBCD2
	dec	cnt16a		;decrement loop counter
	brne	bBCDx_2		;if counter not zero
	ret			;   return

bBCDx_2:ldi	r30,BCD2+1	;Z points to result MSB + 1

bBCDx_3:
	ld	tmp16a,-Z	;get (Z) with pre-decrement
;----------------------------------------------------------------
;For AT90Sxx0x, substitute the above line with:
;
;	dec	ZL
;	ld	tmp16a,Z
;
;----------------------------------------------------------------
	subi	tmp16a,-$03	;add 0x03
	sbrc	tmp16a,3	;if bit 3 not clear
	st	Z,tmp16a	;	store back
	ld	tmp16a,Z	;get (Z)
	subi	tmp16a,-$30	;add 0x30
	sbrc	tmp16a,7	;if bit 7 not clear
	st	Z,tmp16a	;	store back
	cpi	ZL,BCD0	;done all three?
	brne	bBCDx_3		;loop again if not
	rjmp	bBCDx_1



;***************************************************************************
;*
;* "bin4BCD32" - 32-bit Binary to BCD conversion
;*
;* Low registers used	:5 (tBCD0,tBCD1,tBCD2,tBCD3,tBCD4)
;* High registers used  :4(fbin3,fbin2,fbin1,fbin0)	
;* Pointers used	:Z
;*
;***************************************************************************

;***** Subroutine Register Variables

.equ	AtBCD0	=11		;address of tBCD0
.equ	AtBCD4	=15		;address of tBCD4

.def	tBCD0	=r11		;BCD value digits 1 and 0
.def	tBCD1	=r12		;BCD value digits 3 and 4
.def	tBCD2	=r13		;BCD value digits 5 and 6
.def	tBCD3	=r14		;BCD value digits 7 and 8
.def	tBCD4	=r15		;BCD value digit 9

.def	fbin0	=r16		;binary value Low byte
.def	fbin1	=r17		;binary value  byte
.def	fbin2	=r18		;binary value  byte
.def	fbin3	=r19		;binary value High byte

.def	cnt16a	=r20		;loop counter
.def	tmp16a	=r21		;temporary value

;***** Code

bin4BCD32:
	ldi	cnt16a,32	;Init loop counter
	clr	tBCD4		;clear result (3 bytes)
	clr	tBCD3
	clr	tBCD2
	clr	tBCD1
	clr	tBCD0
		
	clr	ZH		;clear ZH (not needed for AT90Sxx0x)

bBCDx_1_32:

	lsl	fbin0		;shift input value
	rol	fbin1		;through all bytes
	rol	fbin2		;through all bytes
	rol	fbin3		;through all bytes
	rol	tBCD0		;
	rol	tBCD1
	rol	tBCD2
	rol	tBCD3
	rol	tBCD4
	dec	cnt16a		;decrement loop counter
	brne	bBCDx_2_32		;if counter not zero
	ret			;   return

bBCDx_2_32:
	ldi r30,AtBCD4+1	;Z points to result MSB + 1
	ld  tmp16a,-Z
	rcall adjBCD_32
	ld  tmp16a,-Z
	rcall adjBCD_32
	ld  tmp16a,-Z
	rcall adjBCD_32
	ld  tmp16a,-Z
	rcall adjBCD_32
	ld  tmp16a,-Z
	rcall adjBCD_32       
	rjmp	bBCDx_1_32
       

adjBCD_32:
	subi	tmp16a,-$03	;add 0x03
	sbrc	tmp16a,3	;if bit 3 not clear
	st	Z,tmp16a	;	store back
	ld	tmp16a,Z	;get (Z)
	subi	tmp16a,-$30	;add 0x30
	sbrc	tmp16a,7	;if bit 7 not clear
	st	Z,tmp16a	;	store back
	ret                    
