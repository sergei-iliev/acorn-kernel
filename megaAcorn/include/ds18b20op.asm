/*
12 bit resolution const
*/
	#define ow9bit 0x5;0.5°C, 
	#define ow10bit 0x19;0.25°C, 
	#define ow11bit 0x7D;0.125°C,
	#define ow12bit 0x271;0.0625°C

;DS18B20 ROM commands
	#define SEARCH_ROM 0xF0
	#define READ_ROM 0x33
	#define MATCH_ROM 0x55
	#define SKIP_ROM 0xCC
	#define ALARM_SEARCH 0xEC

;DS18B20 Function Commands 
	#define CONVERT_T 0x44
	#define WRITE_SCRATCHPAD 0x4E
	#define READ_SCRATCHPAD 0xBE
	#define COPY_SCRATCHPAD 0x48
	#define READ_POWER_SUPPLY 0xB4

	#define IDLE_DELAY 20

.set TIMEOUT_EVENT=7

.equ OW_PIN	= PD7 ;PD7

.equ OW_OUT = PORTD
.equ OW_DIR = DDRD
.equ OW_IN=PIND

;PD7

.dseg
ocsr2:	  .byte 1

;DS18B20 ROM pad

ROM:
code:     .byte 1
number:	 .byte 6
crc:	 .byte 1
	
;DS18B20 Scratch pad	

PAD:
TL:  .byte 1
TH:  .byte 1
none: .byte 5
padcrc: .byte 1

.cseg

ow_init:
	
	cbi OW_OUT,OW_PIN	;disable pull up
	cbi OW_DIR,OW_PIN   ;input 
	
	rcall inittimer

ret

inittimer:
// Enable CTC mode (mode 2); TCNT0 counts from 0 to OCR0A inclusive
// Prescaler CLKio/8 = 1 us resolution
	in  temp,TCCR2
	sbr temp,(1<<WGM21)|(1<<CS21 )
	out TCCR2,temp

	// Start counting from 0
	clr temp
	out TCNT2,temp
     
	// Initially, interrupt once every 20us
	;ldi temp,IDLE_DELAY - 1
	;out OCR2,temp

ret

starttimer:
	;perge event
	_EVENT_RESET TIMEOUT_EVENT

	in temp,TIMSK
	sbr temp,(1<<OCIE2)
	out TIMSK,temp

ret

stoptimer:
	in  temp,TCCR2
	cbr temp,(1<<CS22) | (1<<CS21 )|(1<<CS20)
	out TCCR2,temp

	in temp,TIMSK
	cbr temp,(1<<OCIE2)
	out TIMSK,temp

ret

fasttimer:
	rcall stoptimer
	in  temp,TCCR2
	cbr temp,(1<<CS22) | (1<<CS21 )
	sbr temp,(1<<CS20)
	out TCCR2,temp

	// Reset counter, so start counting from the moment the timer is re-enabled
	// Start counting from 0
	clr temp
	out TCNT2,temp

	lds temp,ocsr2
	out OCR2,temp

	// Clear any pending timer interrupt GLOBAL!!!!
	;in temp,TIFR
	;cbr temp,( 1<<OCF2)
	;out TIFR,temp

	rcall starttimer

ret

medtimer:
	rcall stoptimer

	// Reset counter, so start counting from the moment the timer is re-enabled
	// Start counting from 0
	clr temp
	out TCNT2,temp

	lds temp,ocsr2
	out OCR2,temp

	rcall starttimer

	in  temp,TCCR2
	cbr temp,(1<<CS21) | (1<<CS20 )
	sbr temp,(1<<CS22)
	out TCCR2,temp

ret
/**************One Wire Reset********************************** 
*
*  Reset devices on the bus. Wait for the reset process to complete.
*  Return 1 if there are devices on the bus, else 0.
@USAGE:   temp
@OUTPUT:  T flag 0 -> yes, ds18b20 is present
		  T flag 1 -> no device	
*/

ow_reset:
	_START_EXECUTIVE_MODE OW
	set  ;no device
	sbi	OW_DIR, OW_PIN		; Bus Low 
    
	ldi temp,70
	sts ocsr2,temp				 
	rcall	medtimer		; Wait about 500us 
	_EVENT_WAIT TIMEOUT_EVENT
	
	cbi	OW_DIR, OW_PIN		; Bus High
	
	ldi temp,10  
	sts ocsr2,temp
	rcall	medtimer		; Wait about 100us  
	_EVENT_WAIT TIMEOUT_EVENT
	
	;read result
	in	temp, OW_IN 
	bst	temp, OW_PIN		; Store bus status 

	ldi temp,62  
	sts ocsr2,temp
	rcall	medtimer		; Wait about 500us  
	_EVENT_WAIT TIMEOUT_EVENT

	_END_EXECUTIVE_MODE OW

ret


/*Write One Bit
@INPUT:C - status bit
*/

ow_write_bit:
	brcc owwriteb_0

owwriteb_1:
	;1<t<15us
	sbi	OW_DIR, OW_PIN		; Bus low ( 1us to 15us ) 
	rcall ow_wait_2us
	rcall ow_wait_2us
	rcall ow_wait_2us
	rjmp owwriteb_end 

owwriteb_0:
	;60<t<120
	sbi	OW_DIR, OW_PIN	;bus low
	
	ldi temp,6    ;80us
	sts ocsr2,temp
	rcall	medtimer		; Wait more 60us<t<120us  
	_EVENT_WAIT TIMEOUT_EVENT

owwriteb_end:
	cbi	OW_DIR, OW_PIN	    ;bus high for end of slot
	;60 us
	ldi temp,3  
	sts ocsr2,temp
	rcall	medtimer		; Wait about 60us  
							
	_EVENT_WAIT TIMEOUT_EVENT
	nop

ret
/********************One Wire Write Byte*********
@INPUT: argument - byte to write
@USAGE: temp,counter 
*************************************************/

ow_write:
	_START_EXECUTIVE_MODE OW
	ldi	counter, 8			    ; 8 bits to write 

owwrite_loop:
	ror	argument
	rcall ow_write_bit

	dec counter
	tst counter
	brne owwrite_loop

	_END_EXECUTIVE_MODE OW

ret

/********************One Wire Read Byte*********
@INPUT: argument - byte to write
@OUTPUT: return
@USAGE: temp,counter 
*************************************************/

ow_read:
	_START_EXECUTIVE_MODE OW
	ldi	counter, 8			    ; 8 bits to write 
	clr return

owread_loop: 
	sbi	OW_DIR, OW_PIN		; Bus low ( 1us to 15us ) 
	rcall ow_wait_2us
	rcall ow_wait_2us
	rcall ow_wait_2us

	cbi	OW_DIR, OW_PIN		; Bus high 
	rcall ow_wait_2us
	rcall ow_wait_2us
	rcall ow_wait_2us
	; Get Data Now 

	lsr	return 
	sbic	OW_IN, OW_PIN		; check bit 
	sbr	return, 0x80
	
	
	;80 us
	ldi temp,6  
	sts ocsr2,temp
	rcall	medtimer		; Wait about 80us  
							
	_EVENT_WAIT TIMEOUT_EVENT
									 
	dec	counter 
	breq owread_loop_end
	rjmp owread_loop 

owread_loop_end:	 
	_END_EXECUTIVE_MODE OW

ret

/********************One Wire Read ROM***********
@INPUT: argument
@USAGE: axl,Y,return,argument
@CALL: 
@OUTPUT:  T flag 0 -> yes, crc OK
		  T flag 1 -> crc failure
*************************************************/

ow_read_rom:
	ldi argument,READ_ROM
	rcall ow_write

	
	ldi	YH,high(ROM) 
	ldi	YL,low(ROM)		;init Y-pointer 

	ldi axl,8			;8 bytes rom pad

rrloop:   
	rcall ow_read
	st Y+,return
	dec axl
	brne rrloop

	;run crc check
	ldi	YH,high(ROM) 
	ldi	YL,low(ROM)		;init Y-pointer 
	
	clr return			;global for sub routine
	ldi axl,7

crcloop:
	ld argument,Y+
	rcall ow_crc8
	dec axl
	brne crcloop

	;check validity
	lds argument,crc
	cp argument,return
	brne  exit
	clt ;crc success

ret

exit:
	set  ;crc failure    

ret

/*********************One Wire Temp Conv*****************
@INPUT:   
@USAGE: argument
*****************************************************/

ow_temp_conv:
	ldi	argument, SKIP_ROM		; Skip ROM check 
	rcall	ow_write 

	ldi	argument, CONVERT_T		; Start Temp Conversion 
	rcall	ow_write 

tcwait: 
	sbis	OW_IN, OW_PIN		; Conversion Done! 
	rjmp	tcwait 

ret

/*********************One Wire Read Scratch Pad*****************
@INPUT: argument
@USAGE: axl,Y,return,argument
@CALL: 
@OUTPUT:  T flag 0 -> yes, crc OK
		  T flag 1 -> crc failure
*****************************************************/

ow_read_pad:
	ldi	argument, SKIP_ROM		; Skip ROM check 
	rcall ow_write 

	ldi	argument, READ_SCRATCHPAD		; read Scratch Pad 
	rcall ow_write

	ldi	YH,high(PAD) 
	ldi	YL,low(PAD)		;init Y-pointer 

	ldi axl,8			;8 bytes rom pad

rploop:   
	rcall ow_read
	st Y+,return
	dec axl
	brne rploop

	;run crc check
	ldi	YH,high(PAD) 
	ldi	YL,low(ROM)		;init Y-pointer 
	
	clr return			;global for sub routine
	ldi axl,7

rpcrcloop:
	ld argument,Y+
	rcall ow_crc8
	dec axl
	brne rpcrcloop

	;check validity
	lds argument,crc
	cp argument,return
	brne  rpexit
	clt ;crc success

ret

rpexit:
	set  ;crc failure    

ret

/*********************One Wire CRC-8*****************
@INPUT:   argument,return(accumulated crc)
@USAGE: temp
*****************************************************/

ow_crc8:
	push	argument			; Must save for next bit 
	ldi	temp, 0x08				; 8 bits 

crc8_loop: 
	eor	argument, return		; 
	ror	argument 
	mov	argument, return		; 
	brcc	crc8_skip		; Skip if zero 
	push	temp 
	ldi	temp, 0x18		; 
	eor	argument, temp 
	pop	temp			; 
 

crc8_skip: 
	ror	argument 
	mov	return, argument 
	 
	pop	argument 
	lsr	argument			; Align bits 
	push	argument 
	dec	temp 
	brne	crc8_loop		; Process 8 bits 
	pop	argument			; Clean up stack 

ret


//**********************MIND THE CPU Frequency************
// 1us delay
//********************************************************

ow_wait_2us:               
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	ret  

OC2Int:
	_PRE_INTERRUPT
	rcall stoptimer
	_EVENT_SET TIMEOUT_EVENT,INTERRUPT_CONTEXT
	_keDISPATCH_DPC OW
