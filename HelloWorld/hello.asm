LINE14 = ($2000 + $20*$0e + $0a)

.segment "HEADER"

.byte "NES",$1a,$01,$01,$01
.byte "DiskDude!"

.segment "CODE"

reset:
	sei
	cld
	lda #0
	sta $2000
	sta $2001
	sta $4010
	lda #$40
	sta $4017

	ldx #0
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
	txs

	bit $2002
	jsr wait4vblank
	jsr wait4vblank

hello:
	bit $2002
	ldx #$00
	ldy #$3f
	sty $2006
	stx $2006
	lda #$30
	ldy #$0f
	ldx #8
:	sty $2007
	sta $2007
	sta $2007
	sta $2007
	dex
	bne :-

	ldx #<LINE14
	ldy #>LINE14
	sty $2006
	stx $2006
	ldx #0
	lda msg,x
:	sta $2007
	inx
	lda msg,x
	cmp #0
	bne :-

	lda #0
	sta $2005
	sta $2005

	lda #$80
	sta $2000
	lda #$1e
	sta $2001
	cli

	jmp forever

break:
nmi:
	rti

msg:
	.byte "HELLO WORLD!",$00

wait4vblank:
	bit $2002
	bpl wait4vblank
	rts

forever:
	jmp forever

.segment "VECTORS"

.word nmi,reset,break

.segment "CHARS"

.incbin "charset.chr"
