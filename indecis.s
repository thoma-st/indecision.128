; three layer parallax checkerboard in 128b
; by tom/smfx in august 2023

; assumes the following at execution:
; data registers set to 0
; a4 points to section bss
; a5 points to section data


		section	text

demo:
		move.w	#$20,(sp)			; very naughty supervisor mode set
		trap	#1				; it usually works... ;)

		movem.l	(a5)+,d0/d2/d7			; read and set palette, which is at the start of section data
		move.l	d7,a0				; i tried this based around $020 (see first line) but it looked very green.
		movem.l	d0/d2/d7/a0,$ffff8240.w		; so i decided to take the byte hit and use a proper palette.  it's only colours 0-7.

		subq.w	#1,d1				; set bit pattern for top checker - 16 pixels wide, so 32 repeating bits ($0000ffff.l)
		move.w	#%0000111100001111,d2		; set bit pattern for back checker - 4 pixels wide repeated over 16 bits, couldn't cheat here
		subq.b	#1,d3				; set bit pattern for middle layer - 8 pixels wide repeated over 16 bits ($00ff.w)

		moveq	#8,d4				; d4-d6 are counters for when to NOT the bit patterns for each layer to create the checkers (versus stripes...)
		moveq	#4,d5
		moveq	#2,d6
		move.l	a5,$70.w			;i put my vbl code in section data ;)

forever:	bra.s	forever



		section	data

pal:		dc.w	0,$636,$113,$636,$413,$636


vbl:
		ror.l	#3,d1				; rotate top layer by 3 bits/pixels
		ror.w	#2,d3				; middle layer by 2 bits/pixels
		ror.w	#1,d2				; bottom layer by 1 bit/pixel

		move.l	$44e.w,a0			; set a0 to displayed screen area
		moveq	#96-1,d7			; loop for each y line.  why 96 pixels in height?- so i can keep this single buffered with no shearing :)
.yloop:			
			subq.w	#1,d4			; decrement switch counter for top layer (16 pixels high)
			bpl.s	.nx1

				moveq	#15,d4		; if at a switch point, reset,
				not.l	d1		; and invert

.nx1:			subq.w	#1,d5			; same for the other two layers
			bpl.s	.nx2

				moveq	#7,d5
				not.w	d3

.nx2:			subq.w	#1,d6
			bpl.s	.do

				moveq	#3,d6
				not.w	d2

.do:
			moveq	#20-1,d0			; for each 16 pixel column of scanline
.xloop:				swap	d1			; remember top layer is 32 bits, so we only want to draw a word of it each iteration!
				movem.w	d1-d3,52*160(a0)	; write bitplanes 1-3 with each layer data to the correct y-position
				addq.w	#8,a0			; move to next x-column
				dbf	d0,.xloop

			dbf	d7,.yloop

		addq.b	#1,(a4)				; bss [a4] is used for a counter variable - this is for direction change
		bne.s	.out

			move.b	$ffff8209.w,(a4)		; if it's switch time, copy a pseudorandom byte to the counter
			move.l	a5,a3				; remember, a5 points to the vbl routine. remind yourself of the first three instructions!

			move.w	#%0000000100000000,d0		; modify these instructions/opcodes to toggle between ror and rol - causes direction of scrolling to change
			eor.w	d0,(a3)+			; (initially tried changing each layer individually but it looked a mess)			
			eor.w	d0,(a3)+			; ^^
			eor.w	d0,(a3)+			; ^^

.out:		rte


		section	bss
membase:	ds.b	100000