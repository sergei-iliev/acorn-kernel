/*
ST7735 TFT LCD driver
1.8' 128x160
*/
.include "tasks/st7735_font.asm"

#define ST7735_MOSI           5 // SDA
#define ST7735_SCK            7 // SCL

#define ST7735_RES		4
#define ST7735_DC		5
#define ST7735_CS		6
#define ST7735_BL		7

/*
1. MOSI_D  PD5	DATA IN
2. SCK_D   PD7	CLOCK
3. CS	   PA4	Chip Select	
4. DC      PA5  Data/Command
5. BL      PA6
6. Reset   PA7  Reset
*/


  // Command definition
  // -----------------------------------
  #define DELAY                 0x80
  
  #define SWRESET               0x01
  #define RDDID                 0x04
  #define RDDST                 0x09

  #define SLPIN                 0x10
  #define SLPOUT                0x11
  #define PTLON                 0x12
  #define NORON                 0x13

  #define INVOFF                0x20
  #define INVON                 0x21
  #define DISPOFF               0x28
  #define DISPON                0x29
  #define RAMRD                 0x2E
  #define CASET                 0x2A
  #define RASET                 0x2B
  #define RAMWR                 0x2C

  #define PTLAR                 0x30
  #define MADCTL                0x36
  #define COLMOD                0x3A

  #define FRMCTR1               0xB1
  #define FRMCTR2               0xB2
  #define FRMCTR3               0xB3
  #define INVCTR                0xB4
  #define DISSET5               0xB6

  #define PWCTR1                0xC0
  #define PWCTR2                0xC1
  #define PWCTR3                0xC2
  #define PWCTR4                0xC3
  #define PWCTR5                0xC4
  #define VMCTR1                0xC5

  #define RDID1                 0xDA
  #define RDID2                 0xDB
  #define RDID3                 0xDC
  #define RDID4                 0xDD

  #define GMCTRP1               0xE0
  #define GMCTRN1               0xE1

  #define PWCTR6                0xFC

  // Colors
  // -----------------------------------
  #define BLACK                 0x0000
  #define WHITE                 0xFFFF
  #define RED                   0xF000
  #define YELLOW                0xFFE0
  #define GREEN					0x07E0
  #define BLUE                  0x001F
  // AREA definition
  // -----------------------------------
  #define MAX_X                 161               // max columns / MV = 0 in MADCTL
  #define MAX_Y                 130               // max rows / MV = 0 in MADCTL
  #define SIZE_X                MAX_X - 1         // columns max counter
  #define SIZE_Y                MAX_Y - 1         // rows max counter
  #define CACHE_SIZE_MEM        (MAX_X * MAX_Y)   // whole pixels
  #define CHARS_COLS_LEN        5                 // number of columns for chars
  #define CHARS_ROWS_LEN        8                 // number of rows for chars

.def	startX=r15
.def	endX=r14
.def	startY=r13
.def	endY=r12

.dseg
PosX:  .byte 1
PosY:  .byte 1
.cseg
/*********************Init st7735 driver******************
@USAGE: ???
************************************************/
ST7735_init:
  // init pins
  rcall ST7735_pins_init
  // init SPI
  rcall ST7735_spi_init
  // hardware reset
  rcall ST7735_reset
  // load list of commands
  rcall ST7735_commands
ret

/*********************Init port pins******************
@USAGE: temp
************************************************/
ST7735_pins_init:
    //DDR
	lds temp,PORTA_DIR		
    ori temp,(1<<ST7735_CS)|(1<<ST7735_BL)|(1<<ST7735_DC)
	sts PORTA_DIR,temp	
	
	//PORT
	lds temp,PORTA_OUTSET  
	ori temp,(1<<ST7735_CS)|(1<<ST7735_BL)   // Chip Select H		// BackLigt ON
	sts PORTA_OUTSET,temp  
ret

/*********************Init SPI******************
@USAGE: temp
************************************************/
ST7735_spi_init:
    lds temp,PORTD_DIR		;MOSI and SCK
    ori temp,(1<<ST7735_MOSI)|(1<<ST7735_SCK)
	STS PORTD_DIR,temp

  // SPE  - SPI Enale
  // MSTR - Master device
  // 8MHz
  ldi temp,(SPI_PRESCALER_DIV4_gc)|(1<<SPI_ENABLE_bp)|(1<<SPI_MASTER_bp)|(SPI_MODE_0_gc)	// SPI master, clock idle low, data setup on trailing edge, data sampled on leading edge, double speed mode enabled
  sts SPID_CTRL,temp

  ;no interrupt
  ldi temp,0x00
  sts SPID_INTCTRL,temp
 
ret
/*********************Hardware Reset******************
@USAGE: temp,counter
************************************************/
ST7735_reset:
    //DDR
	lds temp,PORTA_DIR		
    ori temp,(1<<ST7735_RES)
	sts PORTA_DIR,temp
	
	//PORT  low
	lds temp,PORTA_OUT  
	cbr temp,1<<ST7735_RES
	sts PORTA_OUT,temp 

	//***wait 10ms x 20 =200ms
    ldi counter,20
	rcall delay_by_10ms	

	//PORT  high
	lds temp,PORTA_OUT  
	sbr temp,1<<ST7735_RES
	sts PORTA_OUT,temp 

ret
/*********************Clear Screen******************
@USAGE: temp,startX,endX,startY,endY,bxh,bxl
************************************************/
ST7735_clear_screen:
  // set whole window
  //X1
  ldi temp,0
  mov startX,temp
   
  //X2
  ldi temp,SIZE_X
  mov endX,temp
  //Y1
  ldi temp,0
  mov startY,temp
  
  //Y2
  ldi temp,SIZE_Y
  mov endY,temp
  
  rcall ST7735_set_window 


  //*** draw individual pixels
  ldi bxh,high(CACHE_SIZE_MEM)			//CRAZY if no loop nothing happens
  ldi bxl,low(CACHE_SIZE_MEM)
  
  ldi axh,high(BLACK)
  ldi axl,low(BLACK)

  rcall ST7735_send_color565
ret 

/*****************Draw pixel*****************
@INPUT: startX
		startY		
        dxh:dxl - color
	
@USED:  endX,
		endY,
		axh:axl	   			      
*********************************/
ST7735_draw_point:
   mov endX,startX  
   mov endY,startY
   
   //size of 1 pixel
   ldi bxh,0
   ldi bxl,1

   rcall ST7735_set_window 

   mov axh,dxh
   mov axl,dxl
   rcall ST7735_send_color565
ret

/**************Draw Char************
@INPUT: argument - character to print
        startX,
        endX,
		
        dxh:dxl - color
		bxh:bxl - size 

@USED: axh:axl	   			      
*********************************/

ST7735_draw_char:
	subi argument,32  // { 0x7e, 0x11, 0x11, 0x11, 0x7e }

ret
/*
@INPUT: startX,
        endX,
		startY,
		endY,
        dxh:dxl - color
		bxh:bxl - size 

@USED: axh:axl	   			      
*/

ST7735_draw_rect:
   rcall ST7735_set_window 

   mov axh,dxh
   mov axl,dxl
   rcall ST7735_send_color565
ret 
/*****Sets Drawing rect
@INPUT: startX,endX,startY,endY
@USED: axh:axl,argument
*/
ST7735_set_window:
  // column address set
  ldi argument,CASET
  rcall ST7735_command_send

  // send start x position
  ldi axh,0
  mov axl,startX
  rcall ST7735_data_16bits_send

   // send end x position
  ldi axh,0
  mov axl,endX
  rcall ST7735_data_16bits_send

  // row address set
  ldi argument,RASET
  rcall ST7735_command_send

  // send start y position
  ldi axh,0
  mov axl,startY
  rcall ST7735_data_16bits_send

   // send end y position
  ldi axh,0
  mov axl,endY
  rcall ST7735_data_16bits_send

ret

/*
@INPUT: bxh:bxl - repeat count times
		axh:axl  - color info
@USED: argument,temp
*/
ST7735_send_color565:
  // access to RAM
  ldi argument,RAMWR
  rcall ST7735_command_send	

clr565_loop:
  rcall ST7735_data_16bits_send
 
  DEC16 bxl,bxh
  CPI16 bxl,bxh,temp,0

  brne clr565_loop

ret


/*
@INPUT: argument - command to send
@USED: temp,counter
@OUTPUT: argument - received data
*/
ST7735_commands:
  //1. send software reset
  ldi argument,SWRESET
  rcall ST7735_command_send
  //***wait 150ms
  ldi counter,15
  rcall delay_by_10ms	

  //2. Out of sleep mode
  ldi argument,SLPOUT
  rcall ST7735_command_send
  //***wait 200ms
  ldi counter,20
  rcall delay_by_10ms	

  //3. Set color mode
  ldi argument,COLMOD
  rcall ST7735_command_send
  //arguments
  ldi argument,0x05
  rcall ST7735_data_8bits_send

  //***wait 10ms
  ldi counter,1
  rcall delay_by_10ms	
   
  //4. 
  ldi argument,MADCTL
  rcall ST7735_command_send
  //arguments
  ldi argument,0xA0
  rcall ST7735_data_8bits_send

  //5. Turn screen on  
  ldi argument,DISPON
  rcall ST7735_command_send
  //***wait 200ms
  ldi counter,20
  rcall delay_by_10ms	
    	
ret

/*
@INPUT: argument - command to send
@USED: temp
@OUTPUT: argument - received data
*/
ST7735_command_send:
 // chip enable - active low
 // CLR_BIT (*(lcd->cs->port), lcd->cs->pin);
  	lds temp,PORTA_OUT  
	cbr temp,1<<ST7735_CS
	sts PORTA_OUT,temp 
  
  // command (active low)
  //CLR_BIT (*(lcd->dc->port), lcd->dc->pin);
  	lds temp,PORTA_OUT  
	cbr temp,1<<ST7735_DC
	sts PORTA_OUT,temp 
	
	sts SPID_DATA,argument

	// wait till data transmit    
wait_spic:
	lds temp,SPID_STATUS
	sbrs temp,SPI_IF_bp
	rjmp wait_spic

	/* Read received data. */
	lds argument,SPID_DATA

    // chip disable - idle high
    //SET_BIT (*(lcd->cs->port), lcd->cs->pin);
  	lds temp,PORTA_OUT  
	sbr temp,1<<ST7735_CS
	sts PORTA_OUT,temp 

ret 

/*
@INPUT: argument - data to send
@USED: temp
@OUTPUT: argument - received data
*/
ST7735_data_8bits_send:
 // chip enable - active low
  	lds temp,PORTA_OUT  
	cbr temp,1<<ST7735_CS
	sts PORTA_OUT,temp 

  // data (active high)  
  	lds temp,PORTA_OUT  
	sbr temp,1<<ST7735_DC
	sts PORTA_OUT,temp 
	
	sts SPID_DATA,argument
	// wait till data transmit    
wait_spid:
	lds temp,SPID_STATUS
	sbrs temp,SPI_IF_bp
	rjmp wait_spid

	/* Read received data. */
	lds argument,SPID_DATA

	// chip disable - idle high
  	lds temp,PORTA_OUT  
	sbr temp,1<<ST7735_CS
	sts PORTA_OUT,temp 
ret

/*
@INPUT: axh:axl - data to send
@USED: temp
@OUTPUT: return - received data
*/
ST7735_data_16bits_send:
  // chip enable - active low
  	lds temp,PORTA_OUT  
	cbr temp,1<<ST7735_CS
	sts PORTA_OUT,temp 

  // data (active high)  
    lds temp,PORTA_OUT  
	sbr temp,1<<ST7735_DC
	sts PORTA_OUT,temp 

  // transmitting data high byte
    sts SPID_DATA,axh
wait_spid01:
	lds temp,SPID_STATUS
	sbrs temp,SPI_IF_bp
	rjmp wait_spid01

  // transmitting data low byte
	sts SPID_DATA,axl
wait_spid02:
	lds temp,SPID_STATUS
	sbrs temp,SPI_IF_bp
	rjmp wait_spid02

	
	/* Read received data. */
	lds return,SPID_DATA
 
	// chip disable - idle high
  	lds temp,PORTA_OUT  
	sbr temp,1<<ST7735_CS
	sts PORTA_OUT,temp 
ret
/*
10ms each internal loop
@INPUT: XL,XH
@USAGE: XL,XH,temp
*/
delay_by_10ms:	
	//***wait 10ms
	ldi XL,low(50000)   
	ldi XH,high(50000)
	rcall delay	
	dec counter
	tst counter
	brne delay_by_10ms
ret

/*
0.2us single loop
@INPUT: XL,XH
@USAGE: XL,XH,temp
*/
delay:
	DEC16 XL,XH
	CPI16 XL,XH,temp,0
	brne delay 
ret

.EXIT