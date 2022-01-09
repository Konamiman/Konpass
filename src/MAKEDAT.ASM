;program to create konpass.dat #1.3.xx
;for dos 1 and 2

	;input
	;main.dat:#3ec0:must contain the main program (bios,etc)
	;editor.dat:#4000
	;asmrout.dat:#3000:assemblerroutine
	;monitor.dat:#1000:monitor
	;debugger.dat:#4000

bdos	equ	#0005
headln	equ	128	;length of header

	org	#0100
	ld	de,txt_info
	ld	c,9
	call	bdos
	ld	a,(#0080)
	or	a
	jr	nz,nouitleg
	ld	de,txt_uitleg
	ld	c,9
	call	bdos
	ld	c,0
	jp	bdos

nouitleg	ld	hl,(#0082)
	ld	(versie),hl

	ld	de,fcb_datfile
	ld	c,22	;create
	call	bdos
	ld	hl,0
	ld	(fcb_datfile+33),hl
	ld	(fcb_datfile+35),hl
	inc	hl
	ld	(fcb_datfile+14),hl
	ld	de,#8000
	ld	c,26
	call	bdos
	ld	hl,header
	ld	de,#8000
	ld	bc,headln
	ldir
	ld	de,fcb_datfile	;write header
	ld	hl,headln
	ld	c,38
	call	bdos
	OR	A
	jr	nz,error

	ld	hl,#4000-#140
	ld	(lengte),hl
	ld	hl,n_main
	call	voegtoe
	jr	c,error

	ld	hl,#4000
	ld	(lengte),hl
	ld	hl,n_editor
	call	voegtoe
	jr	c,error

	ld	hl,#3000
	ld	(lengte),hl
	ld	hl,n_asmrout
	call	voegtoe
	jr	c,error

	ld	hl,#1000
	ld	(lengte),hl
	ld	hl,n_monitor
	call	voegtoe
	jr	c,error

	ld	hl,#4000
	ld	(lengte),hl
	ld	hl,n_debugger
	call	voegtoe
	jr	c,error

	ld	de,fcb_datfile
	ld	c,16
	call	bdos

	ld	c,0
	jp	bdos

error	ld	de,txt_error
	ld	c,9
	call	bdos
	ld	c,0
	jp	bdos

voegtoe	push	hl
	ld	de,fcb+1
	ld	bc,11
	ldir
	pop	hl
	ld	de,showname
	ld	bc,11
	ldir
	ld	de,txt_add
	ld	c,9
	call	bdos

	ld	de,txt_opening
	ld	c,9
	call	bdos

	ld	de,fcb
	ld	c,15
	call	bdos
	OR	A
	scf
	ret	nz

	ld	hl,0
	ld	(fcb+33),hl
	ld	(fcb+35),hl
	inc	hl
	ld	(fcb+14),hl

	ld	de,txt_reading
	ld	c,9
	call	bdos

	ld	hl,(lengte)
	ld	de,fcb
	ld	c,39
	call	bdos	;read data block
	OR	A
	scf
	ret	nz

	ld	de,fcb
	ld	c,16
	call	bdos

	ld	de,txt_writing
	ld	c,9
	call	bdos

	ld	de,fcb_datfile
	ld	hl,(lengte)
	ld	c,38
	CALL	bdos	;write
	OR	A
	ret	z
	scf
	RET

lengte	dw	0

txt_add	db	"Writing to KONPASS.DAT: "
showname	ds	11
	db	"$"

fcb	ds	37,0
fcb_datfile	db	0,"KONPASS DAT"
	DS	25,0

n_main	db	"MAIN    DAT"
n_editor	db	"EDITOR  DAT"
n_asmrout	db	"ASMROUT DAT"
n_monitor	db	"MONITOR DAT"
n_debugger	db	"DEBUGGERDAT"

txt_error	DB	"DISKERROR!",13,10,"$"
txt_opening	db	" opening...$"
txt_reading	db	" reading...$"
txt_writing	db	" writing...",13,10,"$"

txt_info	db	"Program to link all Konpassblocks together.",13,10,"$"
txt_uitleg	db	"Usage: makedat xx with xx two characters (subversion#)"
	db	13,10,10,"$"
header	db	13,"Konpass #1.3."
versie	db	"xx"
    db    "2022 by Konamiman",13,10
    db 10
    db    "Based on Compass #1.2.09, (C)1998 by Compjoetania TNG",13,10
    db 10
    db    "http://www.github.com/Konamiman/Konpass",13,10,10,26
	ds	headln,0
