SCREEN_CENTER = ($2000 + $20*$0e + $0c)

PPU_CTRL = $2000
PPU_MASK = $2001
PPU_STATUS = $2002

PPU_SCROLL = $2005

PPU_ADDR = $2006
PPU_IO = $2007

.segment "HEADER"

.byte "NES",$1a,$01,$01,$01
.byte "DiskDude!"

.segment "ZEROPAGE"

tmp_pointer: ;zeropage pointer for looping through score (look below)
	.res 2

.segment "DATA"

score: ;4 bytes of BCD number displayed on screen
	.res 4
val2add: ;BCD number wich we add every frame
	.res 1
tmp_byte: ;look at score_add procedure
	.res 1
tmp_mask:
	.res 1

.segment "CODE"

reset:
	sei
	cld
	lda #0
	sta PPU_CTRL ;disable nmi
	sta PPU_MASK ;disable rendering
	sta $4010
	lda #$40
	sta $4017

	ldx #0 ;clear/zero the memory
	txa
:	sta $0,x
	sta $100,x
	sta $200,x
	sta $300,x
	sta $400,x
	sta $500,x
	sta $600,x
	sta $700,x
	inx
	bne :-

	ldx #$ff
	txs ;setup stack pointer

	bit PPU_STATUS
	jsr wait4vblank
	jsr wait4vblank ;wait 2 frames!

	jsr load_palette
	jsr score_init
	jsr score_print
	lda #$01 ;CHANGE HERE to increment score faster (remember it's BCD number)
	sta val2add

	lda #$80
	sta PPU_CTRL ;enable nmi back
	lda #$1e
	sta PPU_MASK ;enable rendering back
	jmp mainloop ;jump forever

break:
nmi:
	pha
	txa
	pha
	tya
	pha

	jsr score_add ;score += val2add
	jsr score_print

	pla
	tay
	pla
	tax
	pla
	rti

wait4vblank:
	bit PPU_STATUS
	bpl wait4vblank
	rts

load_palette:
	bit PPU_STATUS
	ldx #$00
	ldy #$3f ;$3f00 = addr of palette memory
	sty PPU_ADDR
	stx PPU_ADDR

	lda #$30 ;White
	ldy #$0f ;Black
	ldx #8 ;8 palettes 4 colors each (3 + transparency)
:	sty PPU_IO ;transparency is black
	sta PPU_IO ;all three else are white
	sta PPU_IO
	sta PPU_IO
	dex
	bne :- ;all palettes are the same

	rts

score_init:
	lda #0
	sta score
	sta score+1
	sta score+2
	sta score+3
	rts

mainloop:
	jmp mainloop ;forever here

score_add:
	;val2add <- value to add

	lda #<score
	sta tmp_pointer
	lda #>score
	sta tmp_pointer+1
	ldy #0

	;FIRST we add the lowest byte according to
	;BCD addition algorithm from wikipedia
	;(with 2 differences).
	lda (tmp_pointer),y
	clc
	adc #$66 ;in wikipedia algorithm we put here $06 and we don't reverse carry flag like below
	sta tmp_byte
	eor val2add
	sta tmp_mask ;sum without carry propagation

	lda tmp_byte
	adc val2add
	sta tmp_byte ;provisional sum
	php ;store carry flag for later
	bcc :+ ;REVERSE CARRY FLAG
	clc
	jmp :++
:	sec
:

	eor tmp_mask
	eor #$ff
	and #$10
	ror
	ror
	sta tmp_mask
	ror
	ora tmp_mask
	sta tmp_mask

	lda tmp_byte
	sec
	sbc tmp_mask
	sta (tmp_pointer),y

	;NEXT we use the fact that we always increment by 1
	plp ;restore carry for check
	bcc @end
	@next:
	sta (tmp_pointer),y
	iny
	cpy #4
	beq @end
	@check:
	lda (tmp_pointer),y
	eor #$99 ;only in this accident we modify next byte
	beq @next
	@finnish:
	lda (tmp_pointer),y
	clc
	adc #1
	sta (tmp_pointer),y
	and #$0f
	cmp #$0a
	bne @end
	lda (tmp_pointer),y
	and #$f0
	clc
	adc #$10
	sta (tmp_pointer),y
	@end:
	rts

score_print:
	lda #<score
	sta tmp_pointer
	lda #>score
	sta tmp_pointer+1

	bit PPU_STATUS
	lda #>SCREEN_CENTER
	sta PPU_ADDR
	lda #<SCREEN_CENTER
	sta PPU_ADDR

	ldy #3
:	lda (tmp_pointer),y
	pha
	lsr
	lsr
	lsr
	lsr
	clc
	adc #'0'
	sta PPU_IO
	pla
	and #$0f
	adc #'0'
	sta PPU_IO

	dey
	bpl :-

	lda #0
	sta PPU_SCROLL
	sta PPU_SCROLL

	rts

.segment "VECTORS"

.word nmi,reset,break

.segment "CHARS"

.incbin "charset.chr"
