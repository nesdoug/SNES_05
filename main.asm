; example 5 SNES code

.p816
.smart

.include "defines.asm"
.include "macros.asm"
.include "init.asm"






.segment "BSS"

PAL_BUFFER: .res 512

OAM_BUFFER: .res 512 ;low table
OAM_BUFFER2: .res 32 ;high table


.segment "CODE"

; enters here in forced blank
main:
.a16 ; just a standardized setting from init code
.i16
	phk
	plb
	
	jsr clear_sp_buffer
	
	
; COPY PALETTES to PAL_BUFFER	
;	BLOCK_MOVE  length, src_addr, dst_addr
	BLOCK_MOVE  288, BG_Palette, PAL_BUFFER
	
	
; COPY sprites to sprite buffer
	BLOCK_MOVE  12, Sprites, OAM_BUFFER
	
; COPY just 1 high table number	
	A8
	lda #$2A ;= 00101010 = flip all the size bits to large
			 ;will give us 16x16 tiles
	sta OAM_BUFFER2
	
	
; DMA from PAL_BUFFER to CGRAM
	A8
	stz pal_addr ; $2121 cg address = zero

	stz $4300 ; transfer mode 0 = 1 register write once
	lda #$22  ; $2122
	sta $4301 ; destination, pal data
	ldx #.loword(PAL_BUFFER)
	stx $4302 ; source
	lda #^PAL_BUFFER
	sta $4304 ; bank
	ldx #512 ; full palette size
	stx $4305 ; length
	lda #1
	sta $420b ; start dma, channel 0
	
	
; DMA from OAM_BUFFER to the OAM RAM
	ldx #$0000
	stx oam_addr_L ;$2102 (and 2103)
	
	stz $4300 ; transfer mode 0 = 1 register write once
	lda #4 ;$2104 oam data
	sta $4301 ; destination, oam data
	ldx #.loword(OAM_BUFFER)
	stx $4302 ; source
	lda #^OAM_BUFFER
	sta $4304 ; bank
	ldx #544
	stx $4305 ; length
	lda #1
	sta $420b ; start dma, channel 0
	
	
; DMA from Spr_Tiles to VRAM	
	lda #V_INC_1 ; the value $80
	sta vram_inc  ; $2115 = set the increment mode +1
	ldx #$4000
	stx vram_addr ; set an address in the vram of $4000
	
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
	sta $420b ; start dma, channel 0	
	
;$2101 sssnn-bb
;sss = sprite sizes, 000 = 8x8 and 16x16 sprites
;nn = displacement for the 2nd set of sprite tiles, 00 = normal
;-bb = where are the sprite tiles, in steps of $2000
;that upper bit is useless, as usual, so I marked it with a dash -
	lda #2 ;sprite tiles at $4000
	sta spr_addr_size ;= $2101
	
	lda #1 ; mode 1, tilesize 8x8 all
	sta bg_size_mode ; $2105

;allow sprites on the main screen	
	lda #SPR_ON ; $10, only show sprites
	sta main_screen ; $212c
	
	lda #FULL_BRIGHT ; $0f = turn the screen on, full brighness
	sta fb_bright ; $2100


InfiniteLoop:	
	jmp InfiniteLoop
	
	
	
clear_sp_buffer:
.a8
.i16
	php
	A8
	XY16
	lda #224 ;put all y values just below the screen
	ldx #$0000
	ldy #128 ;number of sprites
@loop:
	sta OAM_BUFFER+1, x
	inx
	inx
	inx
	inx ;add 4 to x
	dey
	bne @loop
	plp
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


