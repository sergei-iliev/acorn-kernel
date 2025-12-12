/*
ST7789 TFT LCD driver
1.8' 128x160
*/
.include "tasks/st7789_font.asm"

#define ST7789_MOSI           5 // SDA
#define ST7789_SCK            7 // SCL

#define ST7789_RES		4
#define ST7789_DC		5
#define ST7789_CS		6
#define ST7789_BL		7

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
  #define BROWN					0xBC40
  #define CYAN                  0x7FFF
  #define MAGENTA               0xF81F
  #define GRAY                  0x630C
  // AREA definition
  // -----------------------------------
  #define MAX_X                 320               // max columns / MV = 0 in MADCTL
  #define MAX_Y                 240               // max rows / MV = 0 in MADCTL
  #define SIZE_X                MAX_X - 1         // columns max counter
  #define SIZE_Y                MAX_Y - 1         // rows max counter
  #define CACHE_SIZE_MEM        (MAX_X * MAX_Y)   // whole pixels
 


  
.def	startXH=r15
.def	startXL=r14
.def	endXH=r13
.def	endXL=r12
.def	startYH=r11
.def	startYL=r10
.def	endYH=r9
.def	endYL=r8


.dseg

.cseg



/*********************Init ST7789 driver******************
@USAGE: ???
************************************************/
ST7789_init:
  // init pins
  rcall ST7789_pins_init
  // init SPI
  rcall ST7789_spi_init
  // hardware reset
  rcall ST7789_reset
  // load list of commands
  rcall ST7789_commands
ret

/*********************Init port pins******************
@USAGE: temp
************************************************/
ST7789_pins_init:
    //DDR
	lds temp,PORTA_DIR		
    ori temp,(1<<ST7789_CS)|(1<<ST7789_BL)|(1<<ST7789_DC)
	sts PORTA_DIR,temp	
	
	//PORT
	lds temp,PORTA_OUTSET  
	ori temp,(1<<ST7789_CS)|(1<<ST7789_BL)   // Chip Select H		// BackLigt ON
	sts PORTA_OUTSET,temp  
ret

/*********************Init SPI******************
@USAGE: temp
@WARNING: Double speed to 16MHz!!!!
************************************************/
ST7789_spi_init:
    lds temp,PORTD_DIR		;MOSI and SCK
    ori temp,(1<<ST7789_MOSI)|(1<<ST7789_SCK)
	STS PORTD_DIR,temp

  // SPE  - SPI Enale
  // MSTR - Master device
  // 8MHz
  ldi temp,(1<<SPI_CLK2X_bp)|(1<<SPI_ENABLE_bp)|(1<<SPI_MASTER_bp)|(SPI_MODE_0_gc)	//Double speed @16Mh, SPI master, clock idle low, data setup on trailing edge, data sampled on leading edge, double speed mode enabled
  sts SPID_CTRL,temp

  ;no interrupt
  ldi temp,0x00
  sts SPID_INTCTRL,temp
 
ret
/*********************Hardware Reset******************
@USAGE: temp,counter
************************************************/
ST7789_reset:
    //DDR
	lds temp,PORTA_DIR		
    ori temp,(1<<ST7789_RES)
	sts PORTA_DIR,temp
	
	//PORT  low
	lds temp,PORTA_OUT  
	cbr temp,1<<ST7789_RES
	sts PORTA_OUT,temp 

	//***wait 10ms x 20 =200ms
    ldi counter,20
	rcall delay_by_10ms	

	//PORT  high
	lds temp,PORTA_OUT  
	sbr temp,1<<ST7789_RES
	sts PORTA_OUT,temp 

ret

/*******************Fill Rect********************************
Draw rect with coordinates x0,x1,y0,y1
@INPUT: startX,
        endX,
		startY,
		endY,
        dxh:dxl - color
		
@USED: axh:axl,bxl,bxh,,X   			      
*******************************************************/
st7789_fill_rect:
   rcall ST7789_set_window 

     // access to RAM
   ldi argument,RAMWR
   rcall ST7789_command_send

   //we need to pass width  x1-x0
   mov XL,endYL
   mov XH,endYH
   ADDI16 XL,XH,1
   SUB16 XL,XH,startYL,startYH
    
fill_rect_00:
  //*** draw individual pixels
  //we need to pass height  y1-y0
  mov bxh,endXH			//inner X loop
  mov bxl,endXL
  ADDI16 bxl,bxh,1     
  SUB16 bxl,bxh,startXL,startXH
  
  //color
  mov axh,dxh
  mov axl,dxl
	

fill_rect_01:
  rcall ST7789_data_16bits_send
 
  DEC16 bxl,bxh
  CPI16 bxl,bxh,temp,0
  brne fill_rect_01

  
  DEC16 XL,XH
  CPI16 XL,XH,temp,0     	//outer Y loop
  brne fill_rect_00

ret 
/*****************Draw pixel point*****************
@INPUT: startX
		startY		
        dxh:dxl - color
	
@USED:  endX,
		endY,
		axh:axl	   			      
*********************************/
ST7789_draw_point:
   mov endXH,startXH  
   mov endXL,startXL
     
   mov endYH,startYH
   mov endYL,startYL

   rcall ST7789_set_window 

   // access to RAM
   ldi argument,RAMWR
   rcall ST7789_command_send

   //color
   mov axh,dxh
   mov axl,dxl
   rcall ST7789_data_16bits_send
ret
/*********************************Draw Char ORLA***************************************
@INPUT: argument - character to print
        startX - word size,
        startYL - byte size,		
        dxh:dxl - color
 
;@USED:  bxl,bxh,temp,char,Z,axl,axh,r0,r1,r2,r3,r4,r5,r6
***************************************************************************************/
ST7789_draw_char_orla:
   subi argument,32
   ;translate to bytes representation in fonts table
   ldi	ZH,high(orla_16x24*2)
   ldi	ZL,low(orla_16x24*2)

   ldi axl,ORLA_CHAR_SIZE	   //cols const in table each char is represented by 16 bytes
   mov axh,argument             //row number variable
   mul axl,axh

   ADD16 ZL,ZH,r0,r1

   ldi temp, ORLA_CHARS_ROWS_LEN      //font orla has 3 rows by 8 bits each or 24 bits height
   mov r6,temp

buf_next_half_char_orla_00:
   tst r6				//are 3 halfs(rows) by 8 bits done?
   breq buf_next_half_char_orla_end

   ldi temp,ORLA_CHAR_COLS_LEN   //loop throu 16 columns 
   mov r3,temp              //r3 counter 

   ;preserve XX
   mov bxl,startXL
   mov bxh,startXH

   ;preserve YY
   mov r5,startYL

buf_char_orla_00: 
   tst r3
   breq buf_next_half_char_orla_01   	

   lpm					;read next col from font
   mov	r2,r0	        ;r2 is char byte

   ldi temp,8				 //loop through 8 bits
   mov r4,temp               //r4 counter

   ;start from Y init pos for each new letter byte
   mov startYL,r5

buf_8bit_orla_loop:			; send bits one by one	to 8 -> LSB bit goes first!
   tst r4
   breq buf_8bit_orla_end

   ror r2
   brcs	black_out_orla_00	

   rjmp black_end_orla_00

black_out_orla_00:			
   call ST7789_draw_point	;input=X,Y,color

black_end_orla_00:
   ;increment Y pos for next bit
   inc startYL

   dec r4
   rjmp buf_8bit_orla_loop

buf_8bit_orla_end:
   adiw ZH:ZL,1         //move to next column
   dec r3
   
   ;inc startX
   push bxl
   push bxh
   mov bxl,startXL
   mov bxh,startXH
   ADDI16 bxl,bxh,1
   mov startXL,bxl
   mov startXH,bxh
   pop bxh
   pop bxl

   rjmp buf_char_orla_00

buf_next_half_char_orla_01:
  dec r6    //next font half
  mov startXL,bxl
  mov startXH,bxh


  rjmp buf_next_half_char_orla_00

buf_next_half_char_orla_end:
ret
/*********************************Draw Char ROBOTO***************************************
@INPUT: argument - character to print
        startX - word size,
        startYL - byte size,		
        dxh:dxl - color
 
;@USED:  bxl,bxh,temp,char,Z,axl,axh,r0,r1,r2,r3,r4,r5,r6
******************************************************************************************/
ST7789_draw_char_roboto:
	mov temp,startYL				;test YY
	cpi temp,MAX_Y-ROBOTO_CHARS_ROWS_LEN
	brlo buf_char_roboto_ok	
ret
buf_char_roboto_ok:
   subi argument,32
   
   ;translate to bytes representation in fonts table
   ldi	ZH,high(roboto_mono_8x16*2)
   ldi	ZL,low(roboto_mono_8x16*2)

   ldi axl,ROBOTO_CHAR_SIZE	   //cols const in table each char is represented by 16 bytes
   mov axh,argument             //row number variable
   mul axl,axh

   ADD16 ZL,ZH,r0,r1

   ldi temp, 2      //font roboto has 2 rows by 8 bits each or 16 bits height
   mov r6,temp

buf_next_half_char_roboto_00:
   tst r6				//are 2 halfs by 8 bits done?
   breq buf_next_half_char_roboto_end

   ldi temp,ROBOTO_CHAR_COLS_LEN   //loop throu 8 columns 
   mov r3,temp              //r3 counter 

   ;preserve XX
   mov bxl,startXL
   mov bxh,startXH

   ;preserve YY
   mov r5,startYL

buf_char_roboto_00: 
   tst r3
   breq buf_next_half_char_roboto_01   	

   lpm					;read next col from font 8x8
   mov	r2,r0	        ;r2 is char byte

   ldi temp,8				 //loop through 8 bits
   mov r4,temp               //r4 counter

   ;start from Y init pos for each new letter byte
   mov startYL,r5

buf_8bit_roboto_loop:			; send bits one by one	-> LSB bit goes first!
   tst r4
   breq buf_8bit_roboto_end

   ror r2
   brcs	black_out_roboto_00	

   rjmp black_end_roboto_00

black_out_roboto_00:			
   call ST7789_draw_point	;input=X,Y,color

black_end_roboto_00:
   ;increment Y pos for next bit
   inc startYL

   dec r4
   rjmp buf_8bit_roboto_loop

buf_8bit_roboto_end:
   adiw ZH:ZL,1         //move to next column
   dec r3
   
   ;inc startX
   push bxl
   push bxh
   mov bxl,startXL
   mov bxh,startXH
   ADDI16 bxl,bxh,1
   mov startXL,bxl
   mov startXH,bxh
   pop bxh
   pop bxl

   rjmp buf_char_roboto_00

buf_next_half_char_roboto_01:
  dec r6    //next font half
  mov startXL,bxl
  mov startXH,bxh


  rjmp buf_next_half_char_roboto_00

buf_next_half_char_roboto_end:

ret

/*********************Clear Screen******************
@USAGE: temp,startX,endX,startY,endY,bxh,bxl
************************************************/
ST7789_clear_screen:
  // set whole window
  //X1
  ldi temp,0
  mov startXH,temp
  mov startXL,temp
   
  //X2
  ldi temp,high(SIZE_X)
  mov endXH,temp
  ldi temp,low(SIZE_X)
  mov endXL,temp
  //Y1
  ldi temp,0
  mov startYH,temp
  mov startYL,temp
  
  //Y2
  ldi temp,high(SIZE_Y)
  mov endYH,temp
  ldi temp,low(SIZE_Y)
  mov endYL,temp
  rcall ST7789_set_window 

  // access to RAM
  ldi argument,RAMWR
  rcall ST7789_command_send

  ldi counter,SIZE_Y+1
clscr_00:
  //*** draw individual pixels
  ldi bxh,high(SIZE_X+1)			//inner X loop
  ldi bxl,low(SIZE_X+1)
  
  ldi axh,high(BLACK)
  ldi axl,low(BLACK)
	

clscr_01:
  rcall ST7789_data_16bits_send
 
  DEC16 bxl,bxh
  CPI16 bxl,bxh,temp,0
  brne clscr_01

  dec counter				//outer Y loop
  tst counter
  brne clscr_00
ret 

/*****Sets Drawing rect************************
@INPUT: startX,endX,startY,endY
@USED: axh:axl,argument
*************************************************/
ST7789_set_window:
  // column address set
  ldi argument,CASET
  rcall ST7789_command_send

  // send start x position
  mov axh,startXH
  mov axl,startXL
  rcall ST7789_data_16bits_send

   // send end x position
  mov axh,endXH
  mov axl,endXL
  rcall ST7789_data_16bits_send

  // row address set
  ldi argument,RASET
  rcall ST7789_command_send

  // send start y position
  mov axh,startYH
  mov axl,startYL
  rcall ST7789_data_16bits_send

   // send end y position
  mov axh,endYH
  mov axl,endYL
  rcall ST7789_data_16bits_send

ret

/*****************************************************
@INPUT: bxh:bxl - repeat count times
		axh:axl  - color info
@USED: argument,temp
********************************************************/
ST7789_send_color565:
  // access to RAM
  ldi argument,RAMWR
  rcall ST7789_command_send	

clr565_loop:
  rcall ST7789_data_16bits_send
 
  DEC16 bxl,bxh
  CPI16 bxl,bxh,temp,0

  brne clr565_loop

ret
/********************************************************
@INPUT: argument - command to send
@USED: temp,counter
@OUTPUT: argument - received data
*********************************************************/
ST7789_commands:
  //1. send software reset
  ldi argument,SWRESET
  rcall ST7789_command_send
  //***wait 150ms
  ldi counter,15
  rcall delay_by_10ms	

  //2. Out of sleep mode
  ldi argument,SLPOUT
  rcall ST7789_command_send
  //***wait 200ms
  ldi counter,20
  rcall delay_by_10ms	

  //3. Set color mode
  ldi argument,COLMOD
  rcall ST7789_command_send
  //arguments
  ldi argument,0x55
  rcall ST7789_data_8bits_send

  
  ldi argument,INVON
  rcall ST7789_command_send
  //arguments
  ldi argument,0x00
  rcall ST7789_data_8bits_send


  //***wait 10ms
  ldi counter,1
  rcall delay_by_10ms	
   
  //4. 
  ldi argument,MADCTL
  rcall ST7789_command_send
  //arguments
  ldi argument,0xA0
  rcall ST7789_data_8bits_send

  //5. Turn screen on  
  ldi argument,DISPON
  rcall ST7789_command_send
  //***wait 200ms
  ldi counter,20
  rcall delay_by_10ms	
    	
ret

/******************************************************
@INPUT: argument - command to send
@USED: temp
@OUTPUT: argument - received data
*******************************************************/
ST7789_command_send:
 // chip enable - active low
 // CLR_BIT (*(lcd->cs->port), lcd->cs->pin);
  	lds temp,PORTA_OUT  
	cbr temp,1<<ST7789_CS
	sts PORTA_OUT,temp 
  
  // command (active low)
  //CLR_BIT (*(lcd->dc->port), lcd->dc->pin);
  	lds temp,PORTA_OUT  
	cbr temp,1<<ST7789_DC
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
	sbr temp,1<<ST7789_CS
	sts PORTA_OUT,temp 

ret 

/*********************************************************
@INPUT: argument - data to send
@USED: temp
@OUTPUT: argument - received data
**********************************************************/
ST7789_data_8bits_send:
 // chip enable - active low
  	lds temp,PORTA_OUT  
	cbr temp,1<<ST7789_CS
	sts PORTA_OUT,temp 

  // data (active high)  
  	lds temp,PORTA_OUT  
	sbr temp,1<<ST7789_DC
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
	sbr temp,1<<ST7789_CS
	sts PORTA_OUT,temp 
ret

/*****************************************************
@INPUT: axh:axl - data to send
@USED: temp
@OUTPUT: return - received data
******************************************************/
ST7789_data_16bits_send:
  // chip enable - active low
  	lds temp,PORTA_OUT  
	cbr temp,1<<ST7789_CS
	sts PORTA_OUT,temp 

  // data (active high)  
    lds temp,PORTA_OUT  
	sbr temp,1<<ST7789_DC
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
	sbr temp,1<<ST7789_CS
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