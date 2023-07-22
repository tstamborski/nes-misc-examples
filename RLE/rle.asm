PPU_CTRL = $2000
PPU_MASK = $2001
PPU_STATUS = $2002
PPU_SCROLL = $2005
PPU_ADDR = $2006
PPU_IO = $2007

.segment "HEADER"

.byte "NES",$1a,$01,$01,$01
.byte "DiskDude!"

.segment "DATA"

attr_byte: ;value of an attribute byte in rle compressed data
	.res 1 ;look below at procedure load_rle_data
data_byte:
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

	jsr load_palletes
	jsr load_rle_data ;actual unpacking of the screen

	lda #$80
	sta PPU_CTRL ;enable nmi back
	lda #$1e
	sta PPU_MASK ;enable rendering back
	jmp mainloop ;jump forever

break:
nmi:
	rti

mainloop:
	jmp mainloop ;forever here

wait4vblank:
	bit PPU_STATUS
	bpl wait4vblank
	rts

load_palletes:
	;palettes memory is at $3f00 in a video ram
	bit PPU_STATUS
	lda #$3f
	sta PPU_ADDR
	lda #$00
	sta PPU_ADDR

	;just 4 palettes - just for tiles
	ldx #0
:	lda palette_data,x
	sta PPU_IO
	inx
	cpx #16
	bne :-

	rts

load_rle_data:
	;loads and unzip RLE data of title screen
	;it works but the "screen.nrle" size must be less then 256

	lda rledata
	sta attr_byte

	bit PPU_STATUS
	lda #$20
	sta PPU_ADDR
	lda #$00
	sta PPU_ADDR

	ldy #1
	@loopbegin:
	lda rledata,y
	cmp attr_byte
	bne :+
	beq :++
:	sta data_byte	;if normal/data byte
	sta PPU_IO
	jmp @loopcheck
:	iny				;if attribute byte
	lda rledata,y
	tax
:	lda data_byte
	sta PPU_IO
	dex
	bne :-
	@loopcheck:
	iny
	cpy rledata_size
	bne @loopbegin

	lda #0
	sta PPU_SCROLL
	sta PPU_SCROLL

	rts

rledata:
	.incbin "screen.nrle"
rledata_size:
	.byte *-rledata

palette_data:
	.incbin "palettes.pal"

.segment "VECTORS"

.word nmi,reset,break

.segment "CHARS"

.incbin "charset.chr"
