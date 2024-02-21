/*
Test SPI interrupt mode to FM25040B
*/
.include "D:/SILIEVPC/Atmel/megaAcorn/megaAcorn_F/test/hc05prog/include/spi_master_intr.asm"

.SET SPI_INDEX=4

task2:
	rcall rs232_init
	_SLEEP_TASK 100
	rcall spi_master_init

	_INTERRUPT_DISPATCHER_INIT temp,SPI_INDEX

	nop

	sbi DDRC,PC1
	sbi PORTC,PC1
;write in eeprom 
main2:
	
rcall test_write_read_byte
	
rjmp main2

/************************TEST*******************/

//1.************************************************************
test_write_read_byte:
  ldi addrh,0
  ldi addrl,233
  
  ldi temp,13
  mov val,temp
  SPI_WRITE SPI_SS_PORT,SPI_SS_01
  //rcall spi_master_write

;read from eeprom
t1_read:
  ldi addrh,0
  ldi addrl,233
  
  
  //rcall spi_master_read
  SPI_READ SPI_SS_PORT,SPI_SS_01

  mov argument,bxl
  rcall rs232_send_byte

  _SLEEP_TASK 255
  _SLEEP_TASK 255
  _SLEEP_TASK 255
  rjmp t1_read
ret



