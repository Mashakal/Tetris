
	assume cs:code, ds:code, es

code segment
start:
	mov	ax,1234h
	mov	ax,code
	mov	ds,ax	
	mov	bl,25					;number or rows to display the filler
	mov	ax,0b800h				;get to the first value of the video memory
	mov	es,ax					;move it into ES
	mov	di,000h					;put the address of the first value of VM into si
initialize:
	mov	dl,10					;the width of our play area
	mov	cl,34					;the width of the left and right buffer zones
  leftFill:
	mov	al,'*'					;this is the char to put into VM
	mov	[es:di],al				;saving the char to VM
	inc	di						;to color
	mov	al,0					;the color to be put into VM
	mov	[es:di],al				;saving the color into VM
	inc	di						;to char
	dec	cl						;lower our counter
	cmp	cl,0					;  have we done this 34 times?
	jnz	leftFill				;  if not, do it again
	mov	al,'*'					;DRAW THE LEFT WALL BEGINS HERE, the char to be used in the wall
	mov	[es:di],al				;saving the char to VM
	inc	di						;to color
	mov	al,77h					;the color to be put into VM
	mov	[es:di],al				;saving the color to VM
	inc	di						;to char
	mov	cl,10					;reset the counter
  center:		
	mov	al,' '					;the char to be put into VM in the center
	mov	[es:di],al				;put an ascii space into si
	inc	di						;to color
	mov	al,0					;the color to be put into VM
	mov	[es:di],al				;saving the color to VM
	inc	di						;to char		
	cmp	bl,1					;  check if we are on the bottom row
	jnz	inner1					;  if we are not, we do not need to draw the play area floor
	sub	di,2					;  if we are, move back two tiles in VM to draw the floor 
	mov	al,'*'					;the char to be put into VM for the floor
	mov	[es:di],al				;saving the char to VM
	inc	di						;to color
	mov	al,77h					;the color to be put to into VM
	mov	[es:di],al				;saving the color to VM
	inc	di						;to char
  inner1:	dec	cl				;decrement our counter
	cmp	cl,0					;  have we finished with the center?
	jnz	center					;  if not, do it again
	mov	cl,34					;  if so, reset the counter
	mov	al,'*'					;  and draw the RIGHT WALL HERE
	mov	[es:di],al				;put the char for the right wall into si
	inc	di						;to color
	mov	al,77h					;the color to be put into VM
	mov	[es:di],al				;saving the char to VM
	inc	di						;to char
  rightFill:
	mov	al,'*'					;the char to fill the right buffer zone
	mov	[es:di],al				;saving the char now
	inc	di						;to color
	mov	al,0					;the color to use for the right buffer zone
	mov	[es:di],al				;saving the color to VM
	inc	di						;to char
	dec	cl						;lower the counter
	cmp	cl,0					;  have we done this 34 times?
	jnz	rightFill				;  if not, do it again
	dec	bl						;lower the row counter
	cmp	bl,0					;  have we completed each row?
	jnz	initialize				;  if not, do it again

;**********MAIN CODE**********
;Interrupt Service Routine
	cli 						;turns off interrupt flag
	push es 					;push our registers
	push di
	push ax
;keyboard interrupt
	mov ax,0                    ;move 0 into ax 
	mov es,ax                   ;set es to the beginning of memory
	mov di,24h					;set our pointer to the keyboard interrupt
	mov ax,offset readKeySR 	;offset our keypress handling function to ax
	mov [es:di],ax 				;replace the keyboard interrupt with our readKeySR ISR
	mov ax,cs 					;move our code segment pointer to ax
	mov [es:di+2],ax 			;tell keyboard interrupt where to look for our ISR


	;set up a timer interrupt service routine
    ; set es to interrupt table
    mov ax,0 					;move 0 int oax
    mov es,ax     				;set es to the beginning of memory

    ; redirect interrupt 8
    ; put in the entry: myisr, code segment
    mov di,20h    				;set our pointer to the timer interrupt
    mov ax,offset onTimer 		;offset our onTimer function to ax
    mov [es:di],ax 				;replace timer interrupt with our onTimer ISR
    mov ax,cs 					;move our code segment pointer to ax
    mov [es:di+2],ax  			;tell timer interrupt where to look for our ISR


	mov ch,0 					;piecenumber counter
	mov dh,0 					;rotation counter

    mov si,offset x_line 		;load the 1st spot in pieces array
    call setPiece 				;set our piece
    call showCurrentPiece 		;show our piece
 
setUpTimer:
    mov al,36h 					
    out 43h,al 					;what kind of timer?
    mov al,0ffh
    out 40h,al 					;parameter?
    mov al,0ffh
    out 40h,al 					;parameter?
    ;hopefully, timer is set to go off in 64k cycles


    pop ax 						;pop our registers
    pop di
    pop es
    sti 	        			;turn interrupt flag on 

hang:
	jmp hang

;**********setPixel**********
setPixel:
	push bx
	push ax
	mov di,000h					;reset memory location
	mov ax,160					;video memory 80*2
	mul bl						;multiply row
	add di,ax					;add row position to memory
	mov ax,2					;video memory 2 per column
	add bh,34					;add our start point
	mul bh
	add di,ax
	inc di						;to color
	mov [es:di],dl				;set video memory to color
	pop ax
	pop bx
	ret

;**********getPixel**********
getPixel:
	push bx
	mov di,000h					;reset our video memory address
	mov ax,160					;video memory has 160 bits per row
	mul bl						;multiply row
	add di,ax					;add row position to memory address
	mov ax,2					;video memory 2 per column
	add bh,34					;offset to get to first play area column
	mul bh						;find out which column we are in 
	add di,ax					;add column position to memory address
	mov	ah,[es:di]				;move the char at this pixel into ah
	inc di						;to color
	mov al,[es:di]				;store color in al
	pop bx
	ret

;**********setPiece**********
setPiece:
	mov cl,0 					;counter to 0
	;mov si,OFFSET x_z			;point si to the memory address for the piece to be rendered
  sploop:
	mov dl,[si]					;set dl to the column or row of the piece to be rendered
	push dx						;push dl onto the stack by way of dx
	inc	si 						;to the next column or row of the piece to be rendered
	inc cl 						;increment counter
	cmp cl,9 					;have we done this 8 times?
	jnz	sploop 					;jump to setpiece
	mov si,OFFSET currentX		;point si to current piece holder
	add si,8 					;add 8 to point to end of current piece, removing from stack in reverse order
  spcurrent:
	pop dx						;pop into dl
	mov [si],dl					;move dl into si
	dec si 						;decrement si
 	dec cl 						;decrement counter
	cmp	cl,0 					;if it didnt happen 8 times
	jnz spcurrent 				;jump back and do it again
	ret

;**********showCurrentPiece**********
showCurrentPiece:
	mov cl,0 					;set counter to 0
	mov si,OFFSET currentX 		;point si to currentpiece
	mov	dl,[si]					;the color to draw the piece
	inc si						;move to the first column value
  scploop:
	mov bl,[si+4] 				;row
	mov bh,[si] 				;column
	call setPixel
	inc si 						;increment si
	inc cl 						;increment counter
	cmp cl,4 					;check if it happened 4 times
	jnz scploop 				;if not do it again
	ret

;**********hideCurrentPiece**********
;sets the color values for the current piece to black (hides the currentPiece)
hideCurrentPiece:
	mov	cl,0					;set the counter to 0
	mov	si,OFFSET currentX		;go to the first memory address of the currentpiece holder
	inc	si						;get to the first column value (the first memory address is the color)
	mov	dl,0					;use black as the new color
  hideLoop:
	mov	bh,[si]					;set the column index to be changed
	mov	bl,[si+4]				;set the row index to be changed
	call setPixel
	inc	si						;move to the next column index to be changed
	inc	cl						;increment the counter
	cmp	cl,4					;  have we already done this 4 times?
	jnz	hideLoop				;  if not, do it again
	ret

;**********blockPixel**********
;set the chars of a piece to '*' to make it stoic
 blockPixel:
	mov di,000h					;reset memory location
	mov ax,160					;video memory 80*2
	mul bl						;multiply row
	add di,ax					;add row position to memory
	mov ax,2					;video memory 2 per column
	add bh,34					;add our start point
	mul bh
	add di,ax
	mov al,'*'					;move '*' to al
	mov [es:di],al 				;set video memory to char '*'
	inc di						;to color
	;this is where we should comment out below
	mov [es:di],dl				;set video memory to color
	ret

;**********blockPiece**********
;takes the current piece and calls blockPixel on it
blockPiece:
	mov cl,0 					;set counter to 0
	mov si,OFFSET currentX 		;point si to currentpiece
	mov	dl,[si]					;the color to draw the piece
	inc si						;move to the first column value
  bploop:
	mov bl,[si+4] 				;row
	mov bh,[si] 				;column
	call blockPixel				;make piece stoic
	inc si 						;increment si
	inc cl 						;increment counter
	cmp cl,4 					;check if it happened 4 times
	jnz bploop 					;if not do it again
	ret

;**********canMoveDown**********
;Determines if the currentPiece can be moved down
	;parameters passed in to getPixel:  
					;  bl = currentPiece row + 1
					;  bh = column
	;returned by getPixel:	
					;  al = the color value of the bl that was passed in
					;  ah = the char value of the bl that was passed in
	;returns:	
					;  al = 1 if the piece can move down and 0 otherwise
canMoveDown:
	mov	si,OFFSET currentX		;go to the current piece memory address
	inc	si						;move to the location data
	mov	cl,0					;reset our counter
  downLoop:
  	mov	al,1					;move "true" into al, so far we can move
  	cmp	cl,4					;have we looked at each of the row+1 values?
  	jz	clear					;  if so, return true
	mov	bh,[si]					;put the column value into bh
	mov	bl,[si+4]				;move its corresponding row value into bl
	inc	bl						;we want to get the char value for the location immediately below the current row, add 1 to row
	call getPixel
	inc	cl						;increment our counter
	inc	si						;move to the next memory address
	cmp	ah,'*'					;  was the char at the row+1 value blocked? An '*'?
	jz	blocked					;  if so, the way is blocked, return 0
	jnz	downLoop				;  if not, do it again
  blocked:
  	call blockPiece
  	mov al,0
  	ret
  clear:
  	ret

;**********canMoveLeft**********
; Determines whether or not the piece can legally move left in the play area.
	;parameters passed in to getPixel:
					;  bl = currentPiece row
					;  bh = currentPiece column - 1
	;returned by getPixel:	
					;  al = the color value of the bl that was passed in
					;  ah = the char value of the bl that was passed in
	;returns:
					;  al = 1 if moving left is valid and 0 if invalid

canMoveLeft:
	mov	si,OFFSET currentX		;point si to the current piece
	inc	si						;go to the location data	
	mov	cl,0					;reset our counter
 leftLoop:
  	mov	al,1					;we assume we can move left until proven otherwise
  	cmp	cl,4					;have we looked at all 4 left columns?
  	jz	clear					;if so, the move is valid, return true (1)
  	mov	bh,[si]					;move the column value into bh
  	dec	bh						;subtract one from it, we are looking at the columns to the left
  	mov	bl,[si+4]				;move the row value into bl
  	inc	cl						;increment our counter
	inc	si						;move to the next memory address
  	call getPixel
  	cmp	ah,'*'					;was the pixel at the specified location the blocked char, '*'?
  	jz	blockedcml				;if so, the move is invalid, return 0
  	jnz	leftLoop				;if not, do it again
  blockedcml:
  	mov al,0
  	ret

;**********canMoveRight**********
; Determines whether or not the piece can legally move left in the play area.
	;parameters passed in to getPixel:
					;  bl = currentPiece row
					;  bh = currentPiece column + 1
	;returned by getPixel:	
					;  ah = the char value of the bl that was passed in
	;returns:
					;  al = 1 if moving left is valid and 0 if invalid
canMoveRight:
	mov	si,OFFSET currentX		;point si to the currentPiece
	inc	si						;go to the location data
	mov	cl,0					;reset our counter
  rightLoop:
  	mov	al,1					;assume the way is clear until proved otherwise
  	cmp	cl,4					;have we looked at all 4 column values?
  	jz	clear					; if so, the move is valid, return true
  	mov	bh,[si]					;move the column value into bh
  	inc	bh						;increase it by 1, we are interested in the tile to the right of the piece
  	mov	bl,[si+4]				;put it's corresponding row value into bl
  	inc	cl						;increment our counter
	inc	si						;move to the next memory address
  	call getPixel				;get the char value of the rightmost tile
  	cmp	ah,'*'					;was the char value our block char '*'?
  	jz	blockedcmr				;if so, the move is invalid, return false
  	jnz	rightLoop				;if not, do it again
blockedcmr:
  	mov al,0
  	ret


;**********moveDown**********
 ;Moves the current piece down by 1 row
moveDown:
	mov	si,OFFSET currentX
	mov	dl,[si]					;move the color of the current piece into dl
	inc	si						;move to the location data
	mov	cl,0					;set our counter to 0
  incrRows:
  	inc	cl						;increment our counter
  	mov	bl,[si+4]				;move the row value of the currentPiece into bl
  	inc bl						;increase the value by 1
  	mov	[si+4],bl				;move it back into it's position in memory
  	inc si						;increment the memory address
  	cmp	cl,4					;have we done this 4 times?
  	jnz	incrRows				;if not, do it again
  	ret							

;**********moveLeft**********
 ;Moves the current piece to the left by 1 column
moveLeft:
	mov	si,OFFSET currentX		;point si to our current piece
	inc	si						;get to the location data for our currentPiece
	mov	cl,0					;reset our counter
  incCols:
  	inc	cl						;increment our counter
  	mov	bl,[si]					;store the column value into bl
  	dec	bl						;lower the column value by 1, we are moving to the left
  	mov	[si],bl					;store the new column value back in memory
  	inc	si						;move to the next column value
  	cmp	cl,4					;have we looked at each column value?
  	jnz	incCols					;if not, do it again
  	ret

;**********moveRight**********
 ;Moves the current piece to the right by 1 column
moveRight:
	mov	si,OFFSET currentX		;point si to our current piece
	inc	si						;get to the location data for our currentPiece
	mov	cl,0					;reset our counter
  decCols:
  	inc	cl						;increment our counter
  	mov	bl,[si]					;store the column value into bl
  	inc	bl						;increment the column value by 1, we are moving to the right
  	mov	[si],bl					;store the new column value back in memory
  	inc	si						;move to the next column value
  	cmp	cl,4					;have we looked at each column value?
  	jnz	decCols					;if not, do it again
  	ret

;**********readKeySR**********
readKeySR:
	cli 					 	;disable interrupt flag
	push ax 					;push our registers
	push si
	push cx
	push bx
	push dx
	push di

  	in al,60h   				;read scan code
  	cmp al,4Bh 					;is it a left keypress
  	jz leftSR 					
  	cmp al,4Dh 					;is it a right keypress
  	jz rightSR
  	cmp al,48h
  	jz spaceRot

  	in al,60h   				;read scan code
  	cmp al,4Bh 					;is it a left keypress
  	jz leftSR 					
  	cmp al,4Dh 					;is it a right keypress
  	jz rightSR
  	cmp al,48h
  	jz spaceRot

  	jmp termSR 					;if not jump to terminate
leftSR:
	call canMoveLeft 	     	;can we move left
	cmp al,1
	jnz termSR
leftyesSR:
  	call hideCurrentPiece
  	call moveLeft
  	call showCurrentPiece

  	jmp termSR
rightSR:
	call canMoveRight 			;can we move right
	cmp al,1
	jnz termSR  	
rightyesSR:
 	call hideCurrentPiece
  	call moveRight
  	call showCurrentPiece

  	jmp termSR

spaceRot:
	call hideCurrentPiece
	call rotatePiece
	call showCurrentPiece
	jmp termSR

termSR:
	in al,60h 					;read keypress to clear buffer
	in al,64h   				;read command to clear buffer
	and al,1 					
	cmp al,1 					;is the buffer clear?
	jz termSR 					;if not re do it

RESET_8259:
	mov    al,20h
    out    20h,al    			;reset timer and go again
	;MOV	dx,20h				;ISSUE END_OF_INTTERRUPT TO RESET FLIP-FLOP IN THE 8259 
	;MOV	AL,20h				;INTERRUPT CONTROLLER CHIP OF THE IBM-PC COMPATIBLES
	;OUT	DX,AL				;SEND EOI TO EOI_REG (I/O ADDRESS 20h)

	pop di 						;pop our registers 
	pop dx 
	pop bx
	pop cx
	pop si
	pop ax

	sti 						;re-enable interrupt flag
  	iret 						;interrupt return

;**********clearRow**********
clearRow:
	push bx 					;push our registers
	push ax
	push dx
	push di
	push es

	mov bl,0                	;row, start at 1st row
	mov bh,1                	;column, start at 1st column
	;mov cl,0
foreachcolumn:
	call getPixel 				;get the char
	cmp ah,'*' 					;if its a char keep going
	jnz foreachrow 				;if not go to next row
	inc bh 						;increase the column
	cmp bh,11 					;did we check 10 columns
	jnz foreachcolumn 			;if not keep checking columns
	mov bh,1  					;reset columns for switch
	jmp crEND 					;jump to our clearing code
foreachrow:
	mov bh,1 					;reset our column counter
	inc bl 						;increase row
	cmp bl,24 					;did we check 24 rows?
	jnz foreachcolumn 			;if not go to checking columns
	jmp cRterm 					;if yes we terminate

crEND:
	dec bl 						;go up a row
	call getPixel 				;get block's char + color
	dec di 						;go to its char
	mov [es:di],' ' 			;replace it with a space
	inc di 						;go back to color(this is redundant i think)
	inc bl 						;go back to row we're clearing
	mov dl,al 					;move color into dl
	call setPixel 				;set our block's color
	dec di 						;go back to block's char
	mov [es:di],ah 				;move the block's char above into the one we're clearing
	inc di 						;go back to color(redundant i think)
	inc bh 						;increase column
	cmp bh,11 					;did we go through 10 columns
	jnz crEND 					;if not do it again
	mov bh,1 					;reset columns
	dec bl 						;go up a row
	cmp bl,0 					;did we go through every row above?
	jnz crEND 					;if not do it again
	jmp cRterm 					;if we did, end
cRterm:
	pop es 						;pop our registers 
	pop di
	pop dx
	pop ax
	pop bx
	ret 						;return

onTimer:
whiletrue3:
	cli
	push si 					;push our registers
	push ax
	push bx
	push dx
	mov	si,OFFSET SLOWDOWN
	mov	al,[si]
	inc	al
	mov	[si],al
	cmp	al,5					; slowdown factor of 5
	jnz	timedone
	mov al,0
	mov	[si],al
	push cx
	call clearRow
	call canMoveDown
	pop cx						;can we move down?
	cmp al,0 					;if not
	jz setNewPiece				;go back + create a new piece

	push cx
	call hideCurrentPiece	 	;hide the piece
	pop cx
	push cx
	call moveDown 				;move it down
	pop cx
	push cx
	call showCurrentPiece 		;show it again
	pop cx

timedone:
	mov    al,20h
    out    20h,al    			;reset timer and go again
    ;MOV	dx,20h				;ISSUE END_OF_INTTERRUPT TO RESET FLIP-FLOP IN THE 8259 
	;MOV	AL,20h				;INTERRUPT CONTROLLER CHIP OF THE IBM-PC COMPATIBLES
	;OUT	DX,AL

  
	pop dx  					;pop our registers
    pop bx
    pop ax
    pop si
    sti
    iret

setNewPiece:
	push ax 					;push our registers
	push es
	push di

	mov ax,code 				;point our data segment to es
	mov es,ax 
	mov di,offset rotationcount ;make di point to our rotationcount variable
	mov [di],0 					;reset our rotationcount variable to 0

	pop di 						;pop our registers 
	pop es
	pop ax

	inc ch
    cmp ch,7                    ;did we go through 8 different pieces?
	jnz wtcont 					;if not continue
	mov ch,0 					;reset our counter if yes
wtcont:	
	;si=piecenumber*8 + address_of_pieceline
	mov ax,9					;multiply by 9 spots in array(9 because 1 is color)
	mul ch 						;multiply by piecenmber
	mov si,offset x_line 		;load the 1st spot in pieces array
	add si,ax   				;point si to the correct piece
	;inc ch
	;setpiece(si)
	push cx
	call setPiece 				;call setPiece with si
	pop cx
	call showCurrentPiece		;i think this is redundant

	;we check if the piece being set will cause the game to end
	push cx
	call canMoveDown			;can we move down?
	pop cx
	cmp al,0 					;if not
	jz terminate


 	mov    al,20h
    out    20h,al    			;reset timer and go again
	;MOV	dx,20h				;ISSUE END_OF_INTTERRUPT TO RESET FLIP-FLOP IN THE 8259 
	;MOV	AL,20h				;INTERRUPT CONTROLLER CHIP OF THE IBM-PC COMPATIBLES
	;OUT	DX,AL

	pop dx  					;pop our registers
	pop bx
    pop ax
    pop si
	sti
	iret
terminate:
	; mov ah,00h
	; int 21h
	jmp	start

rotatePiece:
	push es 						;push registers
	push di
	push ds
	push si
	push cx
	push ax

	mov ax,code 					;make es point to data segment
	mov es,ax 
	mov di,offset rotationcount 	;set our pointer to our rotationcount variable
	mov dh,[di] 					;move rotationcount's value to dh
	cmp dh,4 						;if we've done 4 rotations
	jnz rpcont 						;else continue
	mov dh,0 						;reset rotationcount

rpcont:
	mov cl,0 						;changes in piece array counter

	mov si,offset currentX 			;make si point to currentpiece array
	inc si 							;we are at number 

	
	mov di,offset r1x_line 			;make di point to rotation array
	inc di 							;we are at 1st row

	mov ax,36 						;we multiply by the length of 4 rotationarrays
	mul ch 				 			;we multiply by piecenumber
	add di,ax 						;add that to our di pointer

	
	mov ax,9 						;we're going to multiply by length of array
	mul dh 							;multiply length of arrays by rotationcount
	add di,ax 						;add result to di, to point to correct rotation array
rotation:
	;add [si],[di]

	mov al,[si] 		 			;move value of currentpiece pointer to al			

	mov ah,[di] 					;move value of rotation pointer to ah	

	add al,ah 						;add value of rotation to curentpiece pointer

	mov [si],al 					;move al into si

	inc si 							;next position in array
	inc di 							;next position in array
	inc cl 							;increment change counter
	cmp cl,8 						;did we change 8 values in the array
	jnz rotation

	inc dh 							;rotation counter incremented
	mov di,offset rotationcount 	;set our pointer to our rotationcount variable
	mov [di],dh 					;change rotationcount value to what is in dh


	pop ax 							;pop our registers
	pop cx
	pop si
	pop ds
	pop di
	pop es
	ret 							;return



;**********TETRIS SHAPES WITH COLORS**********
x_line     db      22h,5,5,5,5
y_line     db      0,1,2,3
x_l        db      55h,5,6,7,5
y_l        db      0,0,0,1
x_r        db      33h,5,6,7,7
y_r        db      0,0,0,1

x_s        db      11h,5,6,6,7
y_s        db      1,1,0,0

x_z        db      44h,5,6,6,7
y_z        db      0,0,1,1

x_t        db      22h,5,6,7,6
y_t        db      0,0,0,1
x_box      db      66h,5,6,5,6
y_box      db      0,0,1,1

;**********CURRENT PIECE**********
currentX 	db      0,0,0,0,0		;holds the color & column values of the current piece being rendered
currentY 	db      0,0,0,0			;holds the row values of the current piece being rendered

;**********COLORS**********
midCol		db		77h				;light gray background and text
wallCol		db		88h				;dark gray background and text
black		db		00h				;black background, black text
space		db		32				;the ascii char for an empty space
redBack		db		44h				;the color value for red background
blueBack	db		11h				;the color value for a blue background
cyanBack	db		33h				;the color value for a cyan background
greenBack	db		22h				;the color value for a green background

;**********ROTATIONS**********
;we add these to the current piece array to get rotated pieces
r1x_line     db      0,-1,0,1,2
r1y_line     db      1,0,-1,-2
r2x_line     db      0,1,0,-1,-2
r2y_line     db      -1,0,1,2
r3x_line     db      0,-1,0,1,2
r3y_line     db      1,0,-1,-2
r4x_line     db      0,1,0,-1,-2
r4y_line     db      -1,0,1,2

r1x_l        db      0,0,0,-1,1 		
r1y_l        db      0,0,1,1 		 	
r2x_l        db      0,0,0,1,1
r2y_l        db      1,1,0,-2
r3x_l        db      0,0,-1,-2,-1
r3y_l        db      -1,0,1,2
r4x_l        db      0,0,1,2,-1
r4y_l        db      0,-1,-2,-1

r1x_r      db      0,0,0,-1,-1
r1y_r      db      2,0,1,1
r2x_r      db      0,0,0,1,-1
r2y_r      db      -1,1,0,-2
r3x_r      db      0,0,-1,-2,1
r3y_r      db      -1,0,1,0
r4x_r      db      0,0,1,2,1
r4y_r      db      0,-1,-2,1

r1x_s      db      0,0,-1,0,-1
r1y_s      db      -1,0,1,2
r2x_s      db      0,0,1,0,1
r2y_s      db      1,0,-1,-2
r3x_s      db      0,0,-1,0,-1
r3y_s      db      -1,0,1,2
r4x_s      db      0,0,1,0,1
r4y_s      db      1,0,-1,-2

r1x_z      db      0,0,-1,0,-1
r1y_z      db      1,2,0,-1
r2x_z      db      0,0,1,0,1
r2y_z      db      -1,-2,0,1
r3x_z      db      0,0,-1,0,-1
r3y_z      db      1,2,0,-1
r4x_z      db      0,0,1,0,1
r4y_z      db      -1,-2,0,1

r1x_t      db      0,0,0,-1,0
r1y_t      db      1,0,1,1
r2x_t      db      0,0,0,1,0
r2y_t      db      0,1,0,-2
r3x_t      db      0,0,-1,-2,0
r3y_t      db      -1,0,1,1
r4x_t      db      0,0,1,2,0
r4y_t      db      0,-1,-2,0

r1x_box      db      0,0,0,0,0
r1y_box      db      0,0,0,0
r2x_box      db      0,0,0,0,0
r2y_box      db      0,0,0,0
r3x_box      db      0,0,0,0,0
r3y_box      db      0,0,0,0
r4x_box      db      0,0,0,0,0
r4y_box      db      0,0,0,0

rotationcount db 0

SLOWDOWN	db		0

code	ends
end	start