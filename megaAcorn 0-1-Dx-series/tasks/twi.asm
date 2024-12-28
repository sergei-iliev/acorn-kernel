/*AVR1608
I2C MASTER driver implementation to control OLED
@WARNING mind the external oscilator frequency - calculate I2C to 100kHz
DOES NOT INVESTIGATE I2C send/write line status
* POLLING Mode at CPU 20MHz
*/


.equ I2C_INIT  = 0x00
.equ I2C_ACK= 0x01
.equ I2C_NACK= 0x02
.equ I2C_READY = 0x03
.equ I2C_ERROR = 0x04

//#define CLK_PER                                         20000000     // 20MHz default clock no prescaling
#define I2C_SCL_FREQ                                    400000
#define TWI1_BAUD  (((((SYSTEM_CLOCK /I2C_SCL_FREQ))-10-(SYSTEM_CLOCK * 0.3)/1000000))/2) ;100kH clocking

/**************INIT TWI******************
*@USAGE:temp
*/
twi_init:			
	
	ldi temp,TWI1_BAUD
	sts TWI1_MBAUD,temp

    ldi temp,TWI_BUSSTATE_IDLE_gc
	sts TWI1_MSTATUS,temp

	ldi temp,TWI_ENABLE_bm
	sts TWI1_MCTRLA,temp
ret

/**************************TWI WAITING*************************
;Pollimg mode requires waiting on interrupt flag
;@USAGE: temp
;
******************************************************************/
twi_wait:
    lds temp,TWI1_MSTATUS
	andi temp,TWI_BUSSTATE_BUSY_gc
	cpi temp,TWI_BUSSTATE_BUSY_gc
	breq twi_wait	    	
ret

/**************************SEND START TWI*************************
;@USAGE: temp
;@INPUT: argument ADDR+W
;@OUTPUT:  T flag 0 - FAILURE
;				  1 - SUCCESS 	
******************************************************************/
twi_start:
/*
	clt
	//send start
	ldi temp,(1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
	sts TWCR, temp				;//Send START
	
	//wait
	rcall twi_wait							//Wait for TWI interrupt flag set

	lds temp,TWSR
	andi temp, 0xF8
	cpi temp, TWI_REP_START		;repeated start
	brne twistr_00
	set 
ret
twistr_00:
	cpi temp, TWI_START			;start
	brne twiexit
	set
twiexit:
*/
ret
/**************************SEND STOP TWI*************************
;@USAGE: temp
*****************************************************************/
twi_send_stop:
   ldi temp,TWI_MCMD_STOP_gc
   sts TWI1_MCTRLB,temp		
ret

/**************************SEND BYTE TWI*************************
;@INPUT:  argument - byte data to send	
;@OUTPUT: argument - status
****************************************************************/
twi_send_byte:
   sts TWI1_MDATA,argument
   rcall twi_wait_write
ret

/**************************SEND BYTE TWI*************************
;@INPUT:  argument - byte data to send	
;@USAGE: temp
;@OUTPUT: argument - status
****************************************************************/
twi_send_addr:
     sts   TWI1_MADDR,argument 	          
	 rcall twi_wait_write
ret
/**************************WAIT WRITE TWI*************************
;@USAGE: argument,temp
;@OUTPUT:  argument - status				  
****************************************************************/

twi_wait_write:
   ldi argument,I2C_INIT

twiww_00:
   lds temp,TWI1_MSTATUS
   andi temp,(TWI_WIF_bm | TWI_RIF_bm)
   tst temp
   breq twiww_01

   ;good
   lds temp,TWI1_MSTATUS
   andi temp,TWI_RXACK_bm
   tst temp 
   breq twiww_02
   ldi argument,I2C_NACK               //NACK
   rjmp twiww_loop  

twiww_02:                        //ACK
   ldi argument,I2C_ACK
   rjmp twiww_loop

twiww_01:
   lds temp,TWI1_MSTATUS
   andi temp,(TWI_BUSERR_bm | TWI_ARBLOST_bm)
   tst temp
   breq twiww_loop
   
   ;bad
   ldi argument,I2C_ERROR		  //ERROR
twiww_loop:
   cpi argument,0x00
   breq twiww_00   ;keep looping until something happens
   
ret

/**************************READ BYTE TWI*************************
	
;@USAGE: 
;@OUTPUT:  axh - byte read
           argument - status
****************************************************************/
twi_read_byte:
   rcall twi_wait_read
   lds axh,TWI1_MDATA
ret

/**************************WAIT READ TWI*************************
;@USAGE: argument,temp
;@OUTPUT:  argument - status				  
****************************************************************/

twi_wait_read:
   ldi argument,I2C_INIT ;0x00

twiwr_00:
   lds temp,TWI1_MSTATUS
   andi temp,(TWI_WIF_bm | TWI_RIF_bm)
   tst temp
   breq twiwr_01
   ;good
   ldi argument,I2C_READY               
   rjmp twiwr_loop  

twiwr_01:
   lds temp,TWI1_MSTATUS
   andi temp,(TWI_BUSERR_bm | TWI_ARBLOST_bm)
   tst temp
   breq twiwr_loop

   ;bad
   ldi argument,I2C_ERROR		  //ERROR
twiwr_loop:
   cpi argument,0x00
   breq twiwr_00   ;keep looping until something happens

ret
