; example 5 SNES code

.p816
.smart

.include "regs.asm"
.include "variables.asm"
.include "macros.asm"
.include "init.asm"




.segment "CODE"

; enters here in forced blank
Main:
.a16 ; the setting from init code
.i16
	phk
	plb

	
	
; COPY PALETTES to PAL_BUFFER	
;	BLOCK_MOVE  length, src_addr, dst_addr
	BLOCK_MOVE  288, BG_Palette, PAL_BUFFER
; 256 for BG palette, 32 for sprite palette	
; DMA from PAL_BUFFER to CGRAM
	jsr DMA_Palette ; in init.asm
	
; COPY sprites to sprite buffer
	BLOCK_MOVE  12, Sprites, OAM_BUFFER
	A8 ;block move will put AXY16. Undo that.
	
; COPY just 1 high table number	
	lda #$6A ;= 01 101010 = flip all the size bits to large
			 ;will give us 16x16 tiles
			 ;leave the 4th sprite small and in negative x
	sta OAM_BUFFER2
	
; DMA from OAM_BUFFER to the OAM RAM
	jsr DMA_OAM ; in init.asm
	
; DMA from Spr_Tiles to VRAM	
	lda #V_INC_1 ; the value $80
	sta VMAIN  ; $2115 = set the increment mode +1
	ldx #$4000
	stx VMADDL ; set an address in the vram of $4000
	
	lda #1
	sta $4300 ; transfer mode, 2 registers 1 write
			  ; $2118 and $2119 are a pair Low/High
	lda #$18  ; $2118
	sta $4301 ; destination, vram data
	ldx #.loword(Spr_Tiles)
	stx $4302 ; source
	lda #^Spr_Tiles
	sta $4304 ; bank
	ldx #(End_Spr_Tiles-Spr_Tiles) ;let the assembler figure out
							   ;the size of the tiles for us
	stx $4305 ; length
	lda #1
	sta MDMAEN ; $420b start dma, channel 0
	
	
;$2101 sssnn-bb
;sss = sprite sizes, 000 = 8x8 and 16x16 sprites
;nn = displacement for the 2nd set of sprite tiles, 00 = normal
;-bb = where are the sprite tiles, in steps of $2000
;that upper bit is useless, as usual, so I marked it with a dash -
	lda #2 ;sprite tiles at $4000
	sta OBSEL ;= $2101
	
	lda #1 ; mode 1, tilesize 8x8 all
	sta BGMODE ; $2105

;allow sprites on the main screen	
	lda #SPR_ON ; $10, only show sprites
	sta TM ; $212c
	
	lda #FULL_BRIGHT ; $0f = turn the screen on, full brighness
	sta INIDISP ; $2100


Infinite_Loop:	
	A8
	XY16
	jsr Wait_NMI
	
	;code goes here

	jmp Infinite_Loop
	
	
	
Wait_NMI:
.a8
.i16
;should work fine regardless of size of A
	lda in_nmi ;load A register with previous in_nmi
@check_again:	
	WAI ;wait for an interrupt
	cmp in_nmi	;compare A to current in_nmi
				;wait for it to change
				;make sure it was an nmi interrupt
	beq @check_again
	rts
	
	
	

	

Sprites:
;4 bytes per sprite = x, y, tile #, attribute
.byte $80, $80, $00, SPR_PRIOR_2	
.byte $80, $90, $20, SPR_PRIOR_2	
.byte $7c, $90, $22, SPR_PRIOR_2	


;the attribute bits are
;vhoo pppN
;N=1st or 2nd set of sprite tiles
;ppp = palette
;oo = sprite priority
;vh = vertical and horizontal flip

;high table attributes, 2 bits
;sx
;x = 9th X bit (set is like off screen to the left)
;s = size, small or large (based on 2101 settings)


;note, high table bits (2 per sprite)
;will always be X=0 and size =1
;0010 1010 = $2A	
	
	
	
	

.include "header.asm"	


.segment "RODATA1"

BG_Palette:
.incbin "default.pal" ;256 bytes
.incbin "sprite.pal" ;is 32 bytes, 256+32=288

Spr_Tiles:
.incbin "sprite.chr"
End_Spr_Tiles:


