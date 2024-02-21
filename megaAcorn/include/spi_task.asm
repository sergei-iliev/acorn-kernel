/*
Test SPI polling mode to FM25040B
*/
.include "D:/SILIEVPC/Atmel/megaAcorn/megaAcorn_F/test/hc05prog/include/spi_master_polling.asm"
task2:
	rcall rs232_init
	;_SLEEP_TASK 250
	rcall spi_master_init

	
	nop

	sbi DDRC,PC1
	sbi PORTC,PC1
;write in eeprom 
main2:
	rcall test_read_write_buffer_16bit

	
rjmp main2


/************************TEST*******************/

//1.************************************************************
test_write_read_byte:
  ldi addrh,0
  ldi addrl,20
  
  ldi temp,20
  mov val,temp
  rcall spi_master_write
   
;read from eeprom
t1_read:
  ldi addrh,0
  ldi addrl,20
  
  
  rcall spi_master_read
  
  mov argument,bxl
  rcall rs232_send_byte

  _SLEEP_TASK 255
  _SLEEP_TASK 255
  _SLEEP_TASK 255
  rjmp t1_read
ret

//2.*******************************************************
test_read_status:
  rcall spi_master_read_status
  
  mov argument,bxl
  rcall rs232_send_byte

  _SLEEP_TASK 255
  _SLEEP_TASK 255
  _SLEEP_TASK 255
  rjmp test_read_status
	
ret

.dseg
.SET SIZE = 10
TEST_SPI_BUFFER:   .byte SIZE
.cseg
//3.**********************************************************************************
test_read_write_buffer:
  ;fill buffer
  ldi XL,low(TEST_SPI_BUFFER)
  ldi XH,high(TEST_SPI_BUFFER)
  ldi temp,1
  mov val,temp  ;value

  ldi temp,SIZE   ;size
web_fill:  
  
  st X+,val	
  inc val
  
  dec temp
  tst temp
  brne web_fill 
 	
;write 
  ldi addrh,0	;eeprom address
  ldi addrl,200
  
  ldi XL,low(TEST_SPI_BUFFER)  ;local buffer address
  ldi XH,high(TEST_SPI_BUFFER)
  
  ldi temp,SIZE   
  mov val,temp  ;size
  
  rcall spi_master_write_buffer
  
t2_read:
  ;read
  ldi addrh,0	;eeprom address
  ldi addrl,200
  
  ldi XL,low(TEST_SPI_BUFFER)  ;local buffer address
  ldi XH,high(TEST_SPI_BUFFER)
  
  ldi temp,SIZE   
  mov val,temp  ;size
  
  
  rcall spi_master_read_buffer

  ;send to RS232
  ldi axl,SIZE   ;size
  ldi XL,low(TEST_SPI_BUFFER)  ;local buffer address
  ldi XH,high(TEST_SPI_BUFFER)

web_fill_01:  
  _SLEEP_TASK 255
  _SLEEP_TASK 255
  ld argument,X+
  rcall rs232_send_byte  
  
  dec axl
  tst axl
  brne web_fill_01 
rjmp t2_read
ret

//4.***********************************************16 bit buffer test*****************

.dseg
#define WORD_SIZE 1
.SET SIZE_16 = 2*WORD_SIZE

TEST_SPI_BUFFER_16:   .byte SIZE_16
.cseg
test_read_write_buffer_16bit:
  ;1.fill 16 bit buffer
  ldi XL,low(TEST_SPI_BUFFER_16)
  ldi XH,high(TEST_SPI_BUFFER_16)
  
  LDI16 cxl,cxh,0	 ;counter
  LDI16 axl,axh,1000 ;number		
web_fill16:  
  
  //store in 16 bit buffer
  st X+,axl  
  ADDI16 cxl,cxh,1	;increment counter

  st X+,axh  	  
  ADDI16 cxl,cxh,1	;increment counter
  
  ADDI16 axl,axh,1	;increment 16 bit value

  CPI16 cxl,cxh,temp,SIZE_16
  brne web_fill16 

;2.write 
  ;ROM address
  ldi temp,1	
  mov acch,temp
  ldi temp,20
  mov accl,temp
  ;clr acch	;eeprom address
  ;clr accl
  
  ldi XL,low(TEST_SPI_BUFFER_16)  ;local buffer address
  ldi XH,high(TEST_SPI_BUFFER_16)
  
  LDI16 cxl,cxh,SIZE_16	 ;size  
  
  rcall spi_master_write_buffer_16bit
  
;3.read
t3_read:
  ;ROM address
  ldi temp,1	
  mov acch,temp
  ldi temp,20
  mov accl,temp
  ;clr acch	;eeprom address
  ;clr accl
  
  ldi XL,low(TEST_SPI_BUFFER_16)  ;local buffer address
  ldi XH,high(TEST_SPI_BUFFER_16)
  
  LDI16 cxl,cxh,SIZE_16	 ;size  
    
  rcall spi_master_read_buffer_16bit

  ;send to RS232  
  ldi XL,low(TEST_SPI_BUFFER_16)
  ldi XH,high(TEST_SPI_BUFFER_16)
  LDI16 cxl,cxh,SIZE_16	 ;size  

web_fill_02: 
 
  ld bxl,X+
  ld bxh,X+

  _SLEEP_TASK 255
  _SLEEP_TASK 255
  mov argument,bxh
  rcall rs232_send_byte  

  _SLEEP_TASK 255
  _SLEEP_TASK 255
  mov argument,bxl
  rcall rs232_send_byte  
  
  SUBI16 cxl,cxh,2	;decrement counter	
  CPI16 cxl,cxh,temp,0				
  breq web_fill_03

  rjmp  web_fill_02

web_fill_03:
rjmp t3_read

ret
