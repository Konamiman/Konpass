
bdos	equ	#0005

_FOPEN	equ 0Fh
_FCLOSE	equ 10h
_SETDTA	equ 1Ah
_WRBLK	equ	26h
_RDBLK	equ 27h
_TERM0	equ 00h

FCB_RECSIZ	equ 0Eh
FCB_FSIZE	equ 10h
FCB_RECNUM	equ	21h

	org	#0100

	;Open PALET.BIN, skip 7 bytes, then read 32 bytes into 8000h

	ld	de,#8000
	ld	c,_SETDTA
	call	bdos

	ld	de,fcb_pal
	ld	c,_FOPEN
	call	bdos
	ld	hl,7
	ld	(fcb_pal+FCB_RECNUM),hl
	ld	hl,0
	ld	(fcb_pal+FCB_RECNUM+2),hl
	inc	hl
	ld	(fcb_pal+FCB_RECSIZ),hl

	ld	de,fcb_pal
	ld	hl,32
	ld	c,_RDBLK
	call	bdos
	ld	de,fcb_pal
	ld	c,_FCLOSE
	call	bdos

	;Open CTNG.COP, skip 4 bytes, then read 12019 bytes into 8020h

	ld	de,#8020
	ld	c,_SETDTA
	call	bdos

	ld	de,fcb_pic
	ld	c,_FOPEN
	call	bdos

	ld	hl,4
	ld	(fcb_pic+FCB_RECNUM),hl
	ld	hl,0
	ld	(fcb_pic+FCB_RECNUM+2),hl
	inc	hl
	ld	(fcb_pic+FCB_RECSIZ),hl

	ld	de,fcb_pic
	ld	hl,12019
	ld	c,_RDBLK
	call	bdos

	ld	de,fcb_pic
	ld	c,_FCLOSE
	call	bdos

	;Open COMPASS.COM, append the 32+12019 bytes we read previously
	;to the end of it

	ld	de,fcb_com
	ld	c,_FOPEN
	call	bdos
	ld	hl,(fcb_com+FCB_FSIZE)
	ld	(fcb_com+FCB_RECNUM),hl
	ld	hl,0
	ld	(fcb_com+FCB_RECNUM+2),hl
	inc	hl
	ld	(fcb_com+FCB_RECSIZ),hl

	ld	de,#8000
	ld	c,_SETDTA
	call	bdos

	ld	de,fcb_com
	ld	hl,12019+32
	ld	c,_WRBLK
	call	bdos
	ld	de,fcb_com
	ld	c,_FCLOSE
	call	bdos
	ld	c,_TERM0
	jp	bdos


fcb_com	db	0,"COMPASS COM"
	ds	25,0
fcb_pal	db	0,"PALET   BIN"
	ds	25,0
fcb_pic	db	0,"CTNG    COP"
	ds	25,0
