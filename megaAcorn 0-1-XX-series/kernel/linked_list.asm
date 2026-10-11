; =====================================================================
; FILE DESCRIPTION: Static Array-Based Singly Linked List Implementation - 256 Max Items Length
; =====================================================================
;
; OVERVIEW:
; Implementation of dynamic Singly Linked List using a fixed,
; statically allocated array in SRAM based on address pointers .
; It eliminates the need for dynamic 
; heap allocation (malloc/free) which is risky or costly in embedded systems.
;
; MEMORY MANAGEMENT & DUAL-LIST ARCHITECTURE:
; The static array space is split logically into two overlapping lists:
;   1. Active List (Head_Ptr) -> Chains nodes holding valid array addresses
;   2. Free List   (Free_Ptr) -> Chains unused array addresses acting as a pool.
;
; * Nodes move between lists like a stack (LIFO - Last In, First Out).
; * Insertion pulls a node from Free_Ptr and pushes it onto Head_Ptr.
; * Deletion splices a node out of Head_Ptr and recycles it back to Free_Ptr.
;

/*
BYTE Node structure size: 3 bytes
[Data: 1 byte] [Next Address: 2 bytes]
Max 256 size (each element 1 byte length)

WORD Node structure size: 4 bytes
[Data: 2 bytes] [Next Address: 2 bytes]
Max 256 size (each element 2 bytes length)

INTEGER Node structure size: 6 bytes
[Data: 4 byte] [Next Address: 2 bytes]
Max 256 size (each element 4 byte length)

*/
.equ DATA_BYTE_SIZE=1  ;value size is 1 byte long
.equ DATA_WORD_SIZE=2  ;value size is 2 bytes long
.equ DATA_INT_SIZE=4  ;value size is 4 bytes long

.equ HEAD_PTR_OFFSET  = 0       ; Offset for Active List Head Pointer (2 Bytes)
.equ FREE_PTR_OFFSET  = 2       ; Offset for Pool List Free Pointer (2 Bytes)
.equ ARRAY_PTR_OFFSET = 4       ; Offset where the static node blocks start

.equ NODE_BYTE_SIZE        = DATA_BYTE_SIZE + 2       ; Byte Data + 2B Next Pointer Address
.equ NODE_WORD_SIZE        = DATA_WORD_SIZE + 2       ; Word Data + 2B Next Pointer Address
.equ NODE_INT_SIZE         = DATA_INT_SIZE + 2        ; Int Data + 2B Next Pointer Address

#define BYTE_VALUE 
#define WORD_VALUE 
#define INT_VALUE 

#ifdef BYTE_VALUE
;.set NODE_SIZE=NODE_BYTE_SIZE
#define LINKED_LIST8_STORAGE(n) ARRAY_PTR_OFFSET+NODE_BYTE_SIZE*n
#endif
#ifdef WORD_VALUE
#define LINKED_LIST16_STORAGE(n) ARRAY_PTR_OFFSET+NODE_WORD_SIZE*n
;.set NODE_SIZE=NODE_WORD_SIZE
#endif
#ifdef INT_VALUE
;.set NODE_SIZE NODE_INT_SIZE
#define LINKED_LIST32_STORAGE(n) ARRAY_PTR_OFFSET+NODE_INT_SIZE*n
#endif


.cseg
/**********************************************************************8 bit(BYTE data type) data Linked List*****************************************************/
; =====================================================================
; Subroutine: init list
; Links all static array nodes into the Free List. Head List is empty.
;@INPUT: Z - list pointer	
;		 axl - length of backing static array	
;@USAGE: axl,bxl,bxh,X
;@WARNING: length > 0
; =====================================================================
linked_list8_init:
	mov bxh, ZH   ;keep
	mov bxl, ZL

    ; Head_Ptr = NULL (0x0000)
    clr XL
    st Z+, XL
    st Z+, XL
   
	;calculate Free_Ptr pointer to data array right after to header
	ADDI16 bxl,bxh,ARRAY_PTR_OFFSET ; pointer to data array

    ; Free_Ptr = Start of Node_Array 
    st Z+, bxh    
    st Z, bxl

    ; Link all array blocks sequentially
    mov XH, bxh
	mov XL, bxl

   dec axl			; N-1 links; 0 means a single node
   breq ll_01			; N=1: no next node to write


ll_00:
    adiw XL, DATA_BYTE_SIZE     ; Move X past data to next pointer
    mov bxl, XL
    mov bxh, XH
    ADDI16 bxl,bxh,(NODE_BYTE_SIZE-DATA_BYTE_SIZE)
    st X+, bxh                  ; Store high byte of next node address
    st X+, bxl                  ; Store low byte of next node address
    dec axl
    brne ll_00
ll_01:
    ; Set last node's next pointer to NULL (0x0000)
    adiw XL, DATA_BYTE_SIZE
    clr axl	
    st X+, axl
    st X, axl
ret

; =====================================================================
; Subroutine: insert in front
;@INPUT: Z - list pointer	
;		 argument = value to insert
;@USAGE: Z,argument,X,axl,axh
; Returns: Nothing (Modifies Head_Ptr and Free_Ptr)
; =====================================================================
linked_list8_insert:
    ldd XH, Z+FREE_PTR_OFFSET
    ldd XL, Z+(FREE_PTR_OFFSET+1)
    
	adiw XL, 0                 ; Z flag if X == NULL
    breq ll_ist_00
    
	st X+, argument            ; X -> next-pointer field
    ld axh, X+                 ; Free_Ptr = node->Next
    ld axl, X
    
	std Z+FREE_PTR_OFFSET, axh
    std Z+(FREE_PTR_OFFSET+1), axl
    
	sbiw XL, 1                 ; back to node next-pointer high
    ldd axh, Z+HEAD_PTR_OFFSET ;point to Head_Ptr
    ldd axl, Z+(HEAD_PTR_OFFSET+1)
    
	st X+, axh                 ; node->Next = Head_Ptr
    st X, axl
    
	sbiw XL, DATA_BYTE_SIZE+1  ; back to node start
	std Z+HEAD_PTR_OFFSET, XH  ; Head_Ptr = new node
    std Z+(HEAD_PTR_OFFSET+1), XL

ll_ist_00:

ret

; =====================================================================
; Subroutine: Delete_Node
;@INPUT: Z - list pointer	
;		 argument = value to delete (removes first occurrence)
;@USAGE: Z,argument,X,Y,axl,axh,dxl,dxh,temp
; =====================================================================
linked_list8_delete:
    ldd XH, Z+HEAD_PTR_OFFSET
    ldd XL, Z+(HEAD_PTR_OFFSET+1)
    clr YH                       ; prev = NULL
    clr YL

ll_dlt_00:
    adiw XL, 0
    breq ll_dlt_10               ; not found

    ld temp, X
    cp temp, argument
    breq ll_dlt_01

    mov YH, XH                   ; prev = current
    mov YL, XL
    adiw XL, DATA_BYTE_SIZE      ; current = current->Next
    ld dxh, X+                   ; do not load next through Z
    ld dxl, X
    mov XH, dxh
    mov XL, dxl
    rjmp ll_dlt_00

ll_dlt_01:
    adiw XL, DATA_BYTE_SIZE      ; X was target start
    ld dxh, X+                   ; dx = Target->Next
    ld dxl, X                    ; X at next-pointer low

    adiw YL, 0
    brne ll_dlt_02

    std Z+HEAD_PTR_OFFSET, dxh   ; change head to nodes next pointer
    std Z+(HEAD_PTR_OFFSET+1), dxl
    rjmp ll_dlt_03

ll_dlt_02:
    std Y+DATA_BYTE_SIZE, dxh    ; prev->Next = Target->Next
    std Y+(DATA_BYTE_SIZE+1), dxl

ll_dlt_03:
    sbiw XL, 1                   ; X -> target next-high
    ldd axh, Z+FREE_PTR_OFFSET
    ldd axl, Z+(FREE_PTR_OFFSET+1)
    st X+, axh                   ; Target->Next = Free_Ptr
    st X, axl
    sbiw XL, DATA_BYTE_SIZE+1    ; X -> target start
    std Z+FREE_PTR_OFFSET, XH    ; Free_Ptr = target
    std Z+(FREE_PTR_OFFSET+1), XL

ll_dlt_10:
ret

; =====================================================================
; Subroutine: Search_List
;@INPUT: Z - list pointer	
;		 argument = value to find (finds first occurrence)
;@USAGE: Z,argument,X,axl,axh,temp
;OUTPUT: X (XH:XL) = Address of node if found, 0x0000 if not found
; =====================================================================
linked_list8_search:
    ldd XH, Z+HEAD_PTR_OFFSET
    ldd XL, Z+(HEAD_PTR_OFFSET+1)

ll_nfnd_02:
    adiw XL, 0
    breq ll_nfnd_01            ; not found: X already NULL

    ld temp, X
    cp temp, argument
    breq ll_nfnd_01            ; found: X is the node

    adiw XL, DATA_BYTE_SIZE    ; X -> next-pointer field
    ld axh, X+
    ld axl, X
    movw XL, axl               ; X = next (dxl/dxh also fine; matches delete)
    rjmp ll_nfnd_02

ll_nfnd_01:
ret
;=====================================================================================
;@INPUT:  Z - list pointer (used only when X is NULL)
;         X - 0 to start, or current node to advance
;@USAGE:  Z,X,axl,axh,temp
;@OUTPUT: X - node address, or 0x0000 if end/empty
;         T - 1 more nodes, 0 end hit
;@EXAMPLE:
;    clr XL
;    clr XH
;ll_walk:
;    rcall linked_list8_iter
;    brtc ll_walk_done          ; T=0 -> end
;    ld argument, X             ; T=1 -> valid node
;    rjmp ll_walk
;ll_walk_done:
;=====================================================================================

linked_list8_iter:
    mov temp, XH
    or temp, XL
    brne ll_iter_next          ; X != 0 -> current node, take Next

    ldd XH, Z+HEAD_PTR_OFFSET
    ldd XL, Z+(HEAD_PTR_OFFSET+1)
    rjmp ll_iter_flag

ll_iter_next:
    adiw XL, DATA_BYTE_SIZE
    ld axh, X+
    ld axl, X
    movw XL, axl

ll_iter_flag:
    mov temp, XH
    or temp, XL
    breq ll_iter_end           ; X==0 -> T=0
    set                        ; T=1, iteration not finished
ret

ll_iter_end:
    clt                        ; T=0, end hit
ret

; =====================================================================
; Subroutine: Count valid items on the active list
;@INPUT: Z - list pointer
;@USAGE: Z,X,axl,axh,temp,return
;@OUTPUT: return - number of nodes in the Head list (0 if empty)
; =====================================================================
linked_list8_count:
    clr return
    clr XL
    clr XH
ll_cnt_00:
    rcall linked_list8_iter
    brtc ll_cnt_01             ; T=0 -> end of list
    inc return
    rjmp ll_cnt_00
ll_cnt_01:
ret

/**********************************************************************16 bit(WORD data type) data Linked List*****************************************************/
; =====================================================================
; Subroutine: init list
; Links all static array nodes into the Free List. Head List is empty.
; Node: [Data: 2 bytes] [Next Address: 2 bytes]
;@INPUT: Z - list pointer
;		 axl - length of backing static array
;@USAGE: axl,bxl,bxh,X
;@WARNING: length > 0
; =====================================================================
linked_list16_init:
	mov bxh, ZH   ;keep
	mov bxl, ZL

    ; Head_Ptr = NULL (0x0000)
    clr XL
    st Z+, XL
    st Z+, XL

	;calculate Free_Ptr pointer to data array right after to header
	ADDI16 bxl,bxh,ARRAY_PTR_OFFSET ; pointer to data array

    ; Free_Ptr = Start of Node_Array
    st Z+, bxh
    st Z, bxl

    ; Link all array blocks sequentially
    mov XH, bxh
	mov XL, bxl

   dec axl			; N-1 links; 0 means a single node
   breq ll16_01			; N=1: no next node to write


ll16_00:
    adiw XL, DATA_WORD_SIZE     ; Move X past data to next pointer
    mov bxl, XL
    mov bxh, XH
    ADDI16 bxl,bxh,(NODE_WORD_SIZE-DATA_WORD_SIZE)
    st X+, bxh                  ; Store high byte of next node address
    st X+, bxl                  ; Store low byte of next node address
    dec axl
    brne ll16_00
ll16_01:
    ; Set last node's next pointer to NULL (0x0000)
    adiw XL, DATA_WORD_SIZE
    clr axl
    st X+, axl
    st X, axl
ret

; =====================================================================
; Subroutine: insert in front
; Node: [Data: 2 bytes] [Next Address: 2 bytes]
;@INPUT: Z - list pointer
;		 bxh:bxl = value to insert
;@USAGE: Z,bxh,bxl,X,axl,axh
; Returns: Nothing (Modifies Head_Ptr and Free_Ptr)
; =====================================================================
linked_list16_insert:
    ldd XH, Z+FREE_PTR_OFFSET
    ldd XL, Z+(FREE_PTR_OFFSET+1)

	adiw XL, 0                 ; Z flag if X == NULL
    breq ll16_ist_00

	st X+, bxh                 ; X -> second data byte
	st X+, bxl                 ; X -> next-pointer field
    ld axh, X+                 ; Free_Ptr = node->Next
    ld axl, X

	std Z+FREE_PTR_OFFSET, axh
    std Z+(FREE_PTR_OFFSET+1), axl

	sbiw XL, 1                 ; back to node next-pointer high
    ldd axh, Z+HEAD_PTR_OFFSET ;point to Head_Ptr
    ldd axl, Z+(HEAD_PTR_OFFSET+1)

	st X+, axh                 ; node->Next = Head_Ptr
    st X, axl

	sbiw XL, DATA_WORD_SIZE+1  ; back to node start
	std Z+HEAD_PTR_OFFSET, XH  ; Head_Ptr = new node
    std Z+(HEAD_PTR_OFFSET+1), XL

ll16_ist_00:

ret

; =====================================================================
; Subroutine: Delete_Node
; Node: [Data: 2 bytes] [Next Address: 2 bytes]
;@INPUT: Z - list pointer
;		 bxh:bxl = value to delete (removes first occurrence)
;@USAGE: Z,bxh,bxl,X,Y,axl,axh,dxl,dxh
; =====================================================================
linked_list16_delete:
    ldd XH, Z+HEAD_PTR_OFFSET
    ldd XL, Z+(HEAD_PTR_OFFSET+1)
    clr YH                       ; prev = NULL
    clr YL

ll16_dlt_00:
    adiw XL, 0
    breq ll16_dlt_10             ; not found

    ld axh, X+             ; node MSB, X -> LSB
    ld axl, X              ; node LSB
    sbiw XL, 1             ; X back to node start
    CP16 axl,axh,bxl,bxh
    breq ll16_dlt_01


    mov YH, XH                   ; prev = current
    mov YL, XL
    adiw XL, DATA_WORD_SIZE      ; current = current->Next
    ld dxh, X+                   ; do not load next through Z
    ld dxl, X
    mov XH, dxh
    mov XL, dxl
    rjmp ll16_dlt_00

ll16_dlt_01:
    adiw XL, DATA_WORD_SIZE      ; X was target start
    ld dxh, X+                   ; dx = Target->Next
    ld dxl, X                    ; X at next-pointer low

    adiw YL, 0
    brne ll16_dlt_02

    std Z+HEAD_PTR_OFFSET, dxh   ; change head to nodes next pointer
    std Z+(HEAD_PTR_OFFSET+1), dxl
    rjmp ll16_dlt_03

ll16_dlt_02:
    std Y+DATA_WORD_SIZE, dxh    ; prev->Next = Target->Next
    std Y+(DATA_WORD_SIZE+1), dxl

ll16_dlt_03:
    sbiw XL, 1                   ; X -> target next-high
    ldd axh, Z+FREE_PTR_OFFSET
    ldd axl, Z+(FREE_PTR_OFFSET+1)
    st X+, axh                   ; Target->Next = Free_Ptr
    st X, axl
    sbiw XL, DATA_WORD_SIZE+1    ; X -> target start
    std Z+FREE_PTR_OFFSET, XH    ; Free_Ptr = target
    std Z+(FREE_PTR_OFFSET+1), XL

ll16_dlt_10:
ret

; =====================================================================
; Subroutine: Search_List
; Node: [Data: 2 bytes] [Next Address: 2 bytes]
;@INPUT: Z - list pointer
;		 bxh:bxl = value to find (finds first occurrence)
;@USAGE: Z,bxh,bxl,X,axl,axh
;@OUTPUT: X (XH:XL) = Address of node if found, 0x0000 if not found
; =====================================================================
linked_list16_search:
    ldd XH, Z+HEAD_PTR_OFFSET
    ldd XL, Z+(HEAD_PTR_OFFSET+1)

ll16_nfnd_02:
    adiw XL, 0
    breq ll16_nfnd_01            ; not found: X already NULL

    ld axh, X+                   ; node MSB, X -> LSB
    ld axl, X                    ; node LSB
    sbiw XL, 1                   ; X back to node start
    CP16 axl,axh,bxl,bxh
    breq ll16_nfnd_01            ; found: X is the node

    adiw XL, DATA_WORD_SIZE      ; X -> next-pointer field
    ld axh, X+
    ld axl, X
    movw XL, axl                 ; X = next
    rjmp ll16_nfnd_02

ll16_nfnd_01:
ret

;=====================================================================================
;@INPUT:  Z - list pointer (used only when X is NULL)
;         X - 0 to start, or current node to advance
;@USAGE:  Z,X,axl,axh,temp
;@OUTPUT: X - node address, or 0x0000 if end/empty
;         T - 1 more nodes, 0 end hit
;@EXAMPLE:
;    clr XL
;    clr XH
;ll16_walk:
;    rcall linked_list16_iter
;    brtc ll16_walk_done         ; T=0 -> end
;    ld axh, X+                  ; T=1 -> valid node (MSB)
;    ld axl, X                   ; LSB
;    sbiw XL, 1
;    rjmp ll16_walk
;ll16_walk_done:
;=====================================================================================
linked_list16_iter:
    mov temp, XH
    or temp, XL
    brne ll16_iter_next        ; X != 0 -> current node, take Next

    ldd XH, Z+HEAD_PTR_OFFSET
    ldd XL, Z+(HEAD_PTR_OFFSET+1)
    rjmp ll16_iter_flag

ll16_iter_next:
    adiw XL, DATA_WORD_SIZE
    ld axh, X+
    ld axl, X
    movw XL, axl

ll16_iter_flag:
    mov temp, XH
    or temp, XL
    breq ll16_iter_end         ; X==0 -> T=0
    set                        ; T=1, iteration not finished
ret

ll16_iter_end:
    clt                        ; T=0, end hit
ret

; =====================================================================
; Subroutine: Count valid items on the active list
;@INPUT: Z - list pointer
;@USAGE: Z,X,axl,axh,temp,return
;@OUTPUT: return - number of nodes in the Head list (0 if empty)
; =====================================================================
linked_list16_count:
    clr return
    clr XL
    clr XH
ll16_cnt_00:
    rcall linked_list16_iter
    brtc ll16_cnt_01           ; T=0 -> end of list
    inc return
    rjmp ll16_cnt_00
ll16_cnt_01:
ret


/**********************************************************************32 bit(INT data type) data Linked List*****************************************************/
; Node: [Data: 4 bytes] [Next Address: 2 bytes]
; Value in SRAM is MSB first. Insert uses cxh:cxl:bxh:bxl.
; =====================================================================
; Subroutine: init list
; Links all static array nodes into the Free List. Head List is empty.
;@INPUT: Z - list pointer
;		 axl - length of backing static array
;@USAGE: axl,bxl,bxh,X
;@WARNING: length > 0
; =====================================================================
linked_list32_init:
	mov bxh, ZH   ;keep
	mov bxl, ZL

    ; Head_Ptr = NULL (0x0000)
    clr XL
    st Z+, XL
    st Z+, XL

	;calculate Free_Ptr pointer to data array right after to header
	ADDI16 bxl,bxh,ARRAY_PTR_OFFSET ; pointer to data array

    ; Free_Ptr = Start of Node_Array
    st Z+, bxh
    st Z, bxl

    ; Link all array blocks sequentially
    mov XH, bxh
	mov XL, bxl

   dec axl			; N-1 links; 0 means a single node
   breq ll32_01			; N=1: no next node to write


ll32_00:
    adiw XL, DATA_INT_SIZE      ; Move X past data to next pointer
    mov bxl, XL
    mov bxh, XH
    ADDI16 bxl,bxh,(NODE_INT_SIZE-DATA_INT_SIZE)
    st X+, bxh                  ; Store high byte of next node address
    st X+, bxl                  ; Store low byte of next node address
    dec axl
    brne ll32_00
ll32_01:
    ; Set last node's next pointer to NULL (0x0000)
    adiw XL, DATA_INT_SIZE
    clr axl
    st X+, axl
    st X, axl
ret

; =====================================================================
; Subroutine: insert in front
;@INPUT: Z - list pointer
;		 cxh:cxl:bxh:bxl = value to insert (MSB to LSB)
;@USAGE: Z,cxh,cxl,bxh,bxl,X,axl,axh
; Returns: Nothing (Modifies Head_Ptr and Free_Ptr)
; =====================================================================
linked_list32_insert:
    ldd XH, Z+FREE_PTR_OFFSET
    ldd XL, Z+(FREE_PTR_OFFSET+1)

	adiw XL, 0                 ; Z flag if X == NULL
    breq ll32_ist_00

	st X+, cxh                 ; data byte 3 (MSB)
	st X+, cxl
	st X+, bxh
	st X+, bxl                 ; X -> next-pointer field
    ld axh, X+                 ; Free_Ptr = node->Next
    ld axl, X

	std Z+FREE_PTR_OFFSET, axh
    std Z+(FREE_PTR_OFFSET+1), axl

	sbiw XL, 1                 ; back to node next-pointer high
    ldd axh, Z+HEAD_PTR_OFFSET ;point to Head_Ptr
    ldd axl, Z+(HEAD_PTR_OFFSET+1)

	st X+, axh                 ; node->Next = Head_Ptr
    st X, axl

	sbiw XL, DATA_INT_SIZE+1   ; back to node start
	std Z+HEAD_PTR_OFFSET, XH  ; Head_Ptr = new node
    std Z+(HEAD_PTR_OFFSET+1), XL

ll32_ist_00:

ret

; =====================================================================
; Subroutine: Delete_Node
;@INPUT: Z - list pointer
;		 cxh:cxl:bxh:bxl = value to delete (MSB to LSB, first occurrence)
;@USAGE: Z,cxh,cxl,bxh,bxl,X,Y,axl,axh,dxl,dxh
; =====================================================================
linked_list32_delete:
    ldd XH, Z+HEAD_PTR_OFFSET
    ldd XL, Z+(HEAD_PTR_OFFSET+1)
    clr YH                       ; prev = NULL
    clr YL

ll32_dlt_00:
    adiw XL, 0
    breq ll32_dlt_10             ; not found

    ld axh, X+                   ; node MSB
    ld axl, X+
    ld dxh, X+
    ld dxl, X                    ; node LSB
    sbiw XL, 3                   ; X back to node start
    CP32 dxl,dxh,axl,axh,bxl,bxh,cxl,cxh
    breq ll32_dlt_01

    mov YH, XH                   ; prev = current
    mov YL, XL
    adiw XL, DATA_INT_SIZE       ; current = current->Next
    ld axh, X+                   ; do not load next through Z
    ld axl, X
    movw XL, axl
    rjmp ll32_dlt_00

ll32_dlt_01:
    adiw XL, DATA_INT_SIZE       ; X was target start
    ld axh, X+                   ; ax = Target->Next
    ld axl, X                    ; X at next-pointer low

    adiw YL, 0
    brne ll32_dlt_02

    std Z+HEAD_PTR_OFFSET, axh   ; change head to nodes next pointer
    std Z+(HEAD_PTR_OFFSET+1), axl
    rjmp ll32_dlt_03

ll32_dlt_02:
    std Y+DATA_INT_SIZE, axh     ; prev->Next = Target->Next
    std Y+(DATA_INT_SIZE+1), axl

ll32_dlt_03:
    sbiw XL, 1                   ; X -> target next-high
    ldd axh, Z+FREE_PTR_OFFSET
    ldd axl, Z+(FREE_PTR_OFFSET+1)
    st X+, axh                   ; Target->Next = Free_Ptr
    st X, axl
    sbiw XL, DATA_INT_SIZE+1     ; X -> target start
    std Z+FREE_PTR_OFFSET, XH    ; Free_Ptr = target
    std Z+(FREE_PTR_OFFSET+1), XL

ll32_dlt_10:
ret

; =====================================================================
; Subroutine: Search_List
;@INPUT: Z - list pointer
;		 cxh:cxl:bxh:bxl = value to find (MSB to LSB, first occurrence)
;@USAGE: Z,cxh,cxl,bxh,bxl,X,axl,axh,dxl,dxh
;@OUTPUT: X (XH:XL) = Address of node if found, 0x0000 if not found
; =====================================================================
linked_list32_search:
    ldd XH, Z+HEAD_PTR_OFFSET
    ldd XL, Z+(HEAD_PTR_OFFSET+1)

ll32_nfnd_02:
    adiw XL, 0
    breq ll32_nfnd_01            ; not found: X already NULL

    ld axh, X+                   ; node MSB
    ld axl, X+
    ld dxh, X+
    ld dxl, X                    ; node LSB
    sbiw XL, 3                   ; X back to node start
    CP32 dxl,dxh,axl,axh,bxl,bxh,cxl,cxh
    breq ll32_nfnd_01            ; found: X is the node

    adiw XL, DATA_INT_SIZE       ; X -> next-pointer field
    ld axh, X+
    ld axl, X
    movw XL, axl                 ; X = next
    rjmp ll32_nfnd_02

ll32_nfnd_01:
ret

;=====================================================================================
;@INPUT:  Z - list pointer (used only when X is NULL)
;         X - 0 to start, or current node to advance
;@USAGE:  Z,X,axl,axh,temp
;@OUTPUT: X - node address, or 0x0000 if end/empty
;         T - 1 more nodes, 0 end hit
;@EXAMPLE:
;    clr XL
;    clr XH
;ll32_walk:
;    rcall linked_list32_iter
;    brtc ll32_walk_done         ; T=0 -> end
;    ld cxh, X+                  ; T=1 -> valid node (MSB)
;    ld cxl, X+
;    ld dxh, X+
;    ld dxl, X
;    sbiw XL, 3
;    rjmp ll32_walk
;ll32_walk_done:
;=====================================================================================
linked_list32_iter:
    mov temp, XH
    or temp, XL
    brne ll32_iter_next        ; X != 0 -> current node, take Next

    ldd XH, Z+HEAD_PTR_OFFSET
    ldd XL, Z+(HEAD_PTR_OFFSET+1)
    rjmp ll32_iter_flag

ll32_iter_next:
    adiw XL, DATA_INT_SIZE
    ld axh, X+
    ld axl, X
    movw XL, axl

ll32_iter_flag:
    mov temp, XH
    or temp, XL
    breq ll32_iter_end         ; X==0 -> T=0
    set                        ; T=1, iteration not finished
ret

ll32_iter_end:
    clt                        ; T=0, end hit
ret

; =====================================================================
; Subroutine: Count valid items on the active list
;@INPUT: Z - list pointer
;@USAGE: Z,X,axl,axh,temp,return
;@OUTPUT: return - number of nodes in the Head list (0 if empty)
; =====================================================================
linked_list32_count:
    clr return
    clr XL
    clr XH
ll32_cnt_00:
    rcall linked_list32_iter
    brtc ll32_cnt_01           ; T=0 -> end of list
    inc return
    rjmp ll32_cnt_00
ll32_cnt_01:
ret
