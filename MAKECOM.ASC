bdos	equ	#0005

	org	#0100

	ld	de,#8000
	ld	c,26
	call	bdos


	ld	de,fcb_pal
	ld	c,15
	call	bdos
	ld	hl,7
	ld	(fcb_pal+33),hl
	ld	hl,0
	ld	(fcb_pal+35),hl
	inc	hl
	ld	(fcb_pal+14),hl

	ld	de,fcb_pal
	ld	hl,32
	ld	c,39
	call	bdos
	ld	de,fcb_pal
	ld	c,16
	call	bdos

	ld	de,#8020
	ld	c,26
	call	bdos

	ld	de,fcb_pic
	ld	c,15
	call	bdos

	ld	hl,4
	ld	(fcb_pic+33),hl
	ld	hl,0
	ld	(fcb_pic+35),hl
	inc	hl
	ld	(fcb_pic+14),hl

	ld	de,fcb_pic
	ld	hl,12019
	ld	c,39
	call	bdos

	ld	de,fcb_pic
	ld	c,16
	call	bdos

	ld	de,fcb_com
	ld	c,15
	call	bdos
	ld	hl,(fcb_com+16)
	ld	(fcb_com+33),hl
	ld	hl,0
	ld	(fcb_com+35),hl
	inc	hl
	ld	(fcb_com+14),hl

	ld	de,#8000
	ld	c,26
	call	bdos

	ld	de,fcb_com
	ld	hl,12019+32
	ld	c,38
	call	bdos
	ld	de,fcb_com
	ld	c,16
	call	bdos
	ld	c,0
	jp	bdos


fcb_com	db	0,"COMPASS COM"
	ds	25,0
fcb_pal	db	0,"PALET   BIN"
	ds	25,0
fcb_pic	db	0,"CTNG    COP"
	ds	25,0
