;Compass #1.2 - Debugger

	.label	15

matrix	equ	#fbe5
comline	equ	12
temp2	equ	1
select	equ	24
return	equ	13
escape	equ	27
right	equ	28
left	equ	29
up	equ	30
down	equ	31
stop	equ	250	; specially patched by getkey

startcursorad	equ	#0000
startmonadres	equ	#c000
startpcadres	equ	#0010

SLTTBL	equ	#fcc5
CURSORONOFF	equ	#fca9
CURSORY_X	equ	#f3dc
kbuf	equ	#f41f
PUTTORAM	EQU	#B3
PRINTTEKST	EQU	#92
GETFROMRAM	EQU	#B0
SETBALK	equ	#A4
KIESOPTIE	equ	#C8
GETKEY	equ	#fb
SETVRAMWRITE	EQU	#80
MEMVIEW	EQU	#D4
CALCULATOR	EQU	#D7
MEMORY	EQU	#DA
FILLVRAM	EQU	#89
GODISKDRIVE	EQU	#B6
INPUTTEXT	equ	#bf
PRINTMENU	equ	#c5
WISOUDMENU	equ	#cb
MAINCONFIG	equ	#116
GETPAGES	equ	#119
BEREKENGETAL	equ	#D1
PRINTHEXADEC	equ	#9E
STARTPROGRAM	equ	#E0
PRINTINI	equ	#107
GETREGISTERS	equ	#110
LINETOASSEMB	equ	#10D
SAVECONFIG	equ	#11f
PRINTBLOKKLE	equ	#dd
TEXTTOBLOK	equ	#bc
SETPAGE2	equ	#131
RAMTOVRAM	equ	#86
VRAMTORAM	equ	#e3
SLOT	equ	#f8
WISBALK	equ	#A7
WAITFORKEY	equ	#10a

	org	#4000

STARTDEBUGGER	jp	init
WISBREAK	jp	wisbreak
INSERTBREAK	jp	insertbreak
MAININSTPROG	jp	mainconfig
SETDEBPARS	jp	loadconfig
SETGETPATH	jp	filenames
SETGETADRES	jp	setgetadres
ABOUTPROG jp doabout
REDEFCHARS jp doredefchars
SETNAMEBUFFERS jp change_current_source_buffer

wisbreak	ld	hl,breakbuf
	ld	(breakbufpoint),hl
	ret

saveconfig:
	ld	a,(msxrst)
	ld	(kbuf+261),a
	ld	a,(rstonscreen)
	ld	(kbuf+282),a
	ld	a,(monlinkyesno)
	ld	(kbuf+262),a
	ld	hl,verbodenouts
	ld	de,kbuf+263
	ld	bc,maxvbouts+1
	ldir
	ret
loadconfig:
	ld	a,(kbuf+261)
	ld	(msxrst),a
	ld	a,(kbuf+282)
	ld	(rstonscreen),a
	ld	a,(kbuf+262)
	ld	(monlinkyesno),a
	ld	hl,kbuf+263
	ld	de,verbodenouts
	ld	bc,maxvbouts+1
	ldir
	ret

filenames	push	de
	push	hl
	ld	hl,filbuf-(64+11)
	ld	de,64+11
_filenames1	add	hl,de
	djnz	_filenames1
	ld	bc,64
	or	a
	jr	z,_filenames2
	pop	de
	ldir
	pop	de
_filenames3	ld	bc,11
	ldir
	ret
_filenames2	ex	de,hl
	pop	hl
	ldir
	pop	hl
	jr	_filenames3
filbuf	ds	4*(64+11),0

realfkeys	ds	10

setgetadres	add	a,a
	ld	e,a
	ex	af,af'
	ld	d,0
	ld	hl,monadres-2
	add	hl,de
	ex	af,af'
	jr	c,setgetwrite
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ret
setgetwrite	ld	(hl),c
	inc	hl
	ld	(hl),b
	cp	6
	ret	nz
	inc	hl
	ld	(hl),c	;also put on disoptabpc
	inc	hl
	ld	(hl),b
	ld	a,1
	ld	(aanduiddisam),a
	ret

init	ld	(intreesp),sp
	ld	(bufferhoofdpr),ix
	ld	a,l
	ld	(welkismetsub),a
	ex	de,hl
	ld	bc,4*(33+13)
	add	hl,bc
	ld	de,labbufsegs
	ld	bc,9
	ldir
	ld	hl,eerstekeer
	ld	a,(hl)
	or	a
	jr	nz,nospload
	ld	(hl),1
	call	GETREGISTERS
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	ld	(reg_sp),hl
	ld	(reg_sp_init),hl

	ld	hl,(SLTTBL)
	ld	(subslotregs),hl
	ld	hl,(SLTTBL+2)
	ld	(subslotregs+2),hl
nospload	call	updatesubslot
	ld	hl,realfkeys
	ld	de,#f87f	; address where function keys storage begins
	ld	bc,5*256	; c just before adjust route
_adjustfkey	dec	c
	ld	a,(de)
	ld	(hl),a
	inc	hl
	ld	a,c
	ld	(de),a
	inc	de
	ld	a,(de)
	ld	(hl),a
	inc	hl
	xor	a
	ld	(de),a
	ld	a,e
	add	a,15	; 16 bytes per f-key and already 1 inc de
	ld	e,a
	ld	a,0
	adc	a,d
	ld	d,a
	djnz	_adjustfkey

	ld	a,(#fcc1)
	ld	hl,#2d
	call	#c
	cp	3
	ld	a,0
	jr	c,init1
	inc	a
init1	ld	(turbor),a
	ei

	call	scherminit
	jp	hoofdlus

eerstekeer	db	0	;0=first time
reg_sp_init	dw	0

scherminit	call	stackinit
	call	initdis
	ld	hl,2*80
	ld	bc,hoofdbalk
	call	PRINTTEKST
	ld	hl,26
	ld	bc,titelbalk
	call	PRINTTEKST
	ld	hl,25*80+regviewx
	ld	bc,regend
	call	PRINTTEKST

	ld	hl,11*80+39
	call	SETVRAMWRITE
	ld	a,20
	out	(#98),a

	ld	hl,11*80+73
	call	SETVRAMWRITE
	ld	a,19
	out	(#98),a

	ld	hl,80*(12+aantalmonlijn)+39
	call	SETVRAMWRITE
	ld	a,20
	out	(#98),a
	ld	a,23
	ld	b,33
scherminit1	out	(#98),a
	djnz	scherminit1
	ld	a,19
	out	(#98),a

	call	ispconmon
	call	ispconscr
	ld	a,(aanduidtrace)
	or	a
	ret	z
	jp	setpcbalk

hoofdbalk	db	23,23,23,23,23," SYSTEM ",23,23,23,23
	db	23," CONFIGURATION ",23,23
	db	23,23," OPTIONS ",23
	db	23,23," I/O-LIST ",23,23
	db	23,23," BREAKPOINTS ",23,23,23,23,0

titelbalk	db	"Disassembler/Debugger",0
; function keys produce code ff,fe,fd,fc,fd
hoofdlus	call	regafbeeld
	call	slotmonitor
hoofdlusbis	call	monitor
	call	stackvupdate

	ld	b,2
	call	WAITFORKEY
	jr	c,hoofdlusbis

	ld	b,a
	ld	a,(matrix+6)
	srl	a
	ld	a,b
	jr	c,noshift
	cp	escape
	jp	z,shiftesc
noshift	cp	up
	jr	z,hoofdlus2
	cp	down
	jr	z,hoofdlus2
	cp	'J'
	jr	z,hoofdlus2
	push	af
	ld	a,(aanduidtrace)
	call	respcbalk
	call	wismonbalk
	pop	af
hoofdlus2	call	hoofdlusactie
	call	ispconmon
	ld	a,(aanduidtrace)
	or	a
	jr	z,hoofdlus
	call	setpcbalk
	jr	hoofdlus
intreesp	dw	0

hoofdlusactie	cp	123
	jr	nc,hoofdlusactie2
	cp	97
	jr	c,hoofdlusactie2
	xor	32
hoofdlusactie2	ld	hl,hfdlusactitab-3
	ld	b,a
	ld	a,(matrix+6)
	and	%10
	jr	z,hoofdlusactie3	;[CTRL]
	ld	a,b
	cp	13
	jp	z,gopulldown
	dec	a
	jp	z,gopulldown
hoofdlusactie3	inc	hl
	inc	hl
	inc	hl
	ld	a,(hl)
	or	a
	ret	z
	cp	b
	jr	nz,hoofdlusactie3
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	jp	(hl)

MKLIST	macro	@toets,@routine
	db	@toets
	dw	@routine
	db	@toets-64	;for CTRL
	dw	@routine
	endm

; comment replace " with ' here and we get errors
; GEN80 loses quotes on parameter binding
hfdlusactitab	MKLIST	'A',getdisamadres
	MKLIST	'B',routnewbreak
	MKLIST	'C',CALCULATOR
	MKLIST	'D',diskscherm
	MKLIST	'E',exectillbp
	MKLIST	'H',routhere
	MKLIST	'I',initsp
	MKLIST	'J',routandback
	MKLIST	'L',tomonlink1	;tomonlink
	MKLIST	'M',getmonitoradres
	MKLIST	'P',getslotindeel
	MKLIST	'Q',toquit
	MKLIST	'R',regaanpas
	MKLIST	'S',routstep
	MKLIST	'T',routtrace
	MKLIST	'U',getreturnadres
	MKLIST	'V',viewbreak
	MKLIST	'W',routdelbreak
	MKLIST	'Y',specialtrace
	MKLIST	'G',routgo
	MKLIST	'O',getcalladres

	db	select
	dw	tomonitor

	db	stop
	dw	toassembler

	db	255
	dw	pulldown1
	db	254
	dw	pulldown2
	db	253
	dw	pulldown3
	db	252
	dw	pulldown4
	db	251
	dw	pulldown5
	db	up
	dw	routcursup
	db	down
	dw	routcursdown

	db	0

tomonlink1:
	call	tomonlink2
	jp	scherminit

initsp	ld	hl,(reg_sp_init)
	ld	(reg_sp),hl
	ret
gopulldown
	ld	a,(Pulldown)
	ld	l,a
	ld	h,0
	add	hl,hl
	ld	de,Pulldadr-2
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	jp	(hl)

Pulldadr:	dw	pulldown1,pulldown2,pulldown3,pulldown4,pulldown5
Pulldown:	db	1

puldwn1optie:	db	1
puldwn1blink:	dw	#0204

pulldown1	ld	a,1
	ld	(Pulldown),a
	ld	ix,puldown1menu
	ld	hl,3*80
	call	PRINTMENU
_puldown1	ld	a,(puldwn1optie)
	ld	c,a
	ld	hl,(puldwn1blink)
	ld	ix,puldown1menu
	call	KIESOPTIE
	ld	b,a
	ld	(puldwn1blink),hl
	ld	a,c
	ld	(puldwn1optie),a
	ld	ix,puldown1menu
	ld	hl,3*80
	ld	a,b
	cp	29
	jr	z,_puldown1
	cp	251
	jr	nc,_puldown11
	cp	28
	jr	nz,_puldown12
	ld	a,254
_puldown11	push	af
	call	WISOUDMENU
	pop	af
	jp	hoofdlusactie2
_puldown12	cp	1
	jp	z,WISOUDMENU
	cp	escape
	jr	nz,_puldown13
	JP	WISOUDMENU

_puldown13	and	255-32
	jr	nz,_puldown1
	push	bc
	call	WISOUDMENU
	pop	bc
	dec	c
	jr	z,toassembler
	dec	c
	jr	z,tomonitor
	dec	c
	jp	z,diskscherm
	dec	c
	jr	z,tomemory
	dec	c
	jp	z,CALCULATOR
	dec	c
	jp	z,tomemview
	dec	c
	jr	z,shiftesc
	dec c
	jr z,toquit

toabout
	call doabout
	jp scherminit

toquit	call	zetkader
	ld	bc,txt_quit
	ld	hl,comline*80+27
	call	PRINTTEKST
	call	GETKEY
	and	#df	;difference uppercase/lowercase
	cp	"Y"
	jr	z,toquit6
	jp	buf2screen
shiftesc:	ld	a,4
	jr	restorefkey
toquit6	xor	a
restorefkey	push	af
	ld	de,realfkeys
	ld	hl,#f87f	; address where function keys storage begins
	ld	b,5
restorefkey1	ld	a,(de)
	ld	(hl),a
	inc	hl
	inc	de
	ld	a,(de)
	ld	(hl),a
	inc	de
	push	de
	ld	de,15
	add	hl,de
	pop	de
	djnz	restorefkey1
	pop	af
	ld	sp,(intreesp)
	ret
toassembler	ld	a,1
	jp	restorefkey
tomonitor	ld	a,3
	jp	restorefkey

tomemory	ld	a,32
	ld	hl,3*80
	ld	bc,23*80
	call	FILLVRAM
	call	MEMORY
	call	updatesubslot
	JP	scherminit

txt_quit	db	"Quit: are you sure ? (y/n)",0

tomemview	ld	a,32
	ld	hl,3*80
	ld	bc,23*80
	call	FILLVRAM
	call	MEMVIEW
	jp	scherminit

diskscherm	ld	a,2
	ld	b,0
	call	GODISKDRIVE
	jp	scherminit

puldwn2optie:	db	1
puldwn2blink:	dw	#1204

pulldown2	ld	a,2
	ld	(Pulldown),a
	xor	a
	ld	(rstonscreen),a
	ld	ix,puldown2menu
	ld	hl,3*80+16
	call	PRINTMENU
adjustpulmen2	ld	a,(turbor)
	or	a
	jr	z,adjustpulmen21
	ld	ix,#183
	ld	iy,(#FCC0)
	call	#1c
	inc	a
	ld	b,a
	ld	de,10
	ld	hl,txtr800-10
adjustpulmen20	add	hl,de
	djnz	adjustpulmen20
	ld	b,h
	ld	c,l
	ld	hl,80*4+24
	call	PRINTTEKST

adjustpulmen21	ld	a,(monlinkyesno)
	inc	a
	ld	b,a
	ld	hl,linktekst-19
	ld	de,19
adjustpulmen22	add	hl,de
	djnz	adjustpulmen22
	ld	b,h
	ld	c,l
	ld	hl,80*6+19
	call	PRINTTEKST

	ld	a,(msxrst)
	ld	b,0
	ld	c,a
	ld	hl,txtyesno
	add	hl,bc
	ld	b,h
	ld	c,l
	ld	hl,80*5+28
	call	PRINTTEKST

	ld	bc,configtekst
	ld	hl,80*7+19
	call	PRINTTEKST

_puldown2	ld	a,(puldwn2optie)
	ld	c,a
	ld	hl,(puldwn2blink)
	ld	ix,puldown2menu
	call	KIESOPTIE
	ld	b,a
	ld	(puldwn2blink),hl
	ld	a,c
	ld	(puldwn2optie),a
	ld	ix,puldown2menu
	ld	hl,3*80+16
	ld	a,b
	cp	251
	jr	nc,_puldown21
	cp	right
	jr	nz,_puldown22
	ld	a,253
_puldown21	push	af
	call	pulldwn2exit
	pop	af
	jp	hoofdlusactie2
_puldown22	cp	left
	jr	nz,_puldown23
	ld	a,255
	jr	_puldown21
_puldown23	cp	1
	jp	z,pulldwn2exit
	cp	escape
	jp	z,pulldwn2exit
_puldown24	and	255-32
	jr	nz,_puldown2
	dec	c
	jr	z,tor800
	dec	c
	jr	z,tomsxrst
	dec	c
	jr	z,tomonlink

	call	pulldwn2exit
	call	MAINCONFIG
	jp	scherminit

tomonlink	call	tomonlink2
	jp	adjustpulmen2

tomonlink2	ld	a,(monlinkyesno)
	inc	a
	ld	(monlinkyesno),a
	cp	3
	ret	nz
	xor	a
	ld	(monlinkyesno),a
	ret

tomsxrst	ld	a,(msxrst)
	xor	4
	ld	(msxrst),a
	ld	hl,disbuffer+disopwrmnomic
	ld	de,lglnlngh
	ld	b,disopaantlijn
tomsxrst1	ld	a,(hl)
	cp	"R"
	jr	nz,tomsxrst2
	inc	hl
	ld	a,(hl)
	cp	"S"
	jr	z,tomsxrst3
	dec	hl
tomsxrst2	add	hl,de
	djnz	tomsxrst1
	jp	adjustpulmen2
tomsxrst3	ld	a,1
	ld	(rstonscreen),a
	jp	adjustpulmen2

tor800	ld	a,(turbor)
	or	a
	jp	z,adjustpulmen2
	ld	ix,#183
	ld	iy,(#FCC0)
	call	#1c
	inc	a
	cp	3
	jr	c,tor800r
	xor	a
tor800r	ld	ix,#180
	ld	iy,(#FCC0)
	or	128
	call	#1c
	jp	adjustpulmen2
pulldwn2exit	call	WISOUDMENU
	ld	a,(rstonscreen)
	or	a
	ret	z
	ld	hl,(disoptabpc)
	ld	(reg_pcvdis),hl
	jp	disameenscherm

rstonscreen	db	0

puldwn3optie:	db	1
puldwn3blink:	dw	#2004

pulldown3	ld	a,3
	ld	(Pulldown),a
	ld	ix,puldown3menu
	ld	hl,3*80+30
	call	PRINTMENU
_puldown3	ld	a,(puldwn3optie)
	ld	c,a
	ld	hl,(puldwn3blink)
	ld	ix,puldown3menu
	call	KIESOPTIE
	ld	b,a
	ld	(puldwn3blink),hl
	ld	a,c
	ld	(puldwn3optie),a
	ld	ix,puldown3menu
	ld	hl,3*80+30
	ld	a,b
	cp	251
	jr	nc,_puldown32
	cp	left
	jr	nz,_puldown31
	ld	a,254
	jr	_puldown32
_puldown31	cp	right
	jr	nz,_puldown33
	ld	a,252
_puldown32	push	af
	call	WISOUDMENU
	pop	af
	jp	hoofdlusactie2
_puldown33	cp	1
	jp	z,WISOUDMENU
	cp	27
	jr	nz,_puldown34
	jp	WISOUDMENU

_puldown34	and	255-32
	jr	nz,_puldown3
	push	bc
	call	WISOUDMENU
	pop	bc
	dec	c
	jp	z,getdisamadres
	dec	c
	jp	z,getmonitoradres
	dec	c
	jp	z,routgo
	dec	c
	jp	z,regaanpas
	dec	c
	jp	z,getcalladres
	dec	c
	jp	z,getreturnadres
	dec	c
	jp	z,routprint
	jp	routtotxtbuf

getslotmenu	db	1,17,0
getslotindtxt1	db	"  Memory page X  ",0
getslotindtxt2	db	"   Main slot X ",0
getslotindtxt3	db	"    Sub slot X",0
getslotindtxt4	db	"Mapper Page      ",0
getslotpag	db	0
getslotindeel	ld	ix,getslotmenu
	ld	hl,29+9*80
	ld	a,(getslotpag)
	add	a,"0"
	ld	(getslotindtxt1+14),a
	call	PRINTMENU
	ld	bc,getslotindtxt1
	ld	a,(getslotpag)
	call	getbetween03
	jp	c,getslotend0
	ld	(getslotpag),a
	call	GETPAGES
	ld	d,0
	add	a,a
	ld	e,a
	add	hl,de
	push	hl
	ld	a,(hl)
	and	3
	ld	e,a
	add	a,"0"
	ld	(getslotindtxt2+13),a
	ld	bc,getslotindtxt2
	ld	a,e
	call	getbetween03
	pop	hl
	jp	c,getslotend0
	ld	b,a
	push	hl
	push	bc
	inc	b
	ld	a,(welkismetsub)
getslotindeel1	rrca
	djnz	getslotindeel1
	jr	c,getslotindeel2
	pop	bc
	ld	a,b
	jp	getslotinddeel4	; a save in hl
getslotindeel2	ld	a,(hl)	; request subslot here
	rra
	rra
	and	3
	ld	e,a
	add	a,"0"
	ld	(getslotindtxt3+13),a
	ld	bc,getslotindtxt3
	ld	a,e
	call	getbetween03
	jr	nc,getslotinddeel3
	pop	hl
	jr	getslotend0
getslotinddeel3	pop	bc
	ld	c,a
	add	a,a
	add	a,a
	or	b
	or	128
getslotinddeel4	pop	hl
	ld	(hl),a
; adjust subslot register if necessary
	bit	7,a
	jp	z,getslotsubniet
	push	hl
	ld	hl,subslotregs
	ld	d,0
	and	3
	ld	e,a
	add	hl,de
	ld	a,(getslotpag)
	sub	4
	neg
	add	a,a
	ld	b,a
	ld	a,252
getslotinddeel5	rrca
	rrc	c
	djnz	getslotinddeel5
	and	(hl)
	or	c
	ld	(hl),a
	pop	hl
; still picking up the memmappage
getslotsubniet	inc	hl
	push	hl
	ld	bc,getslotindtxt4
	ld	hl,30+10*80
	call	PRINTTEKST
	ld	hl,30+10*80+12
	ld	de,kbuf
	ld	b,5
	ld	a,128+64
	call	INPUTTEXT
	push	af
	call	getslotend0
	pop	af
	pop	hl
	jr	c,getslotexit
	push	hl
	ld	hl,kbuf
	call	BEREKENGETAL
	pop	hl
	jr	c,getslotexit
	ld	(hl),e
getslotexit	jp	routtotxtend2

getslotend0	ld	ix,getslotmenu
	ld	hl,29+9*80
	jp	WISOUDMENU

getbetween03	ld	e,a
	ld	hl,31+10*80
	call	PRINTTEKST
getbetween030	call	CHRGET
	cp	1
	scf
	ret	z
	cp	escape
	scf
	ret	z
	cp	return
	jr	nz,getbetween032
	ld	a,e
	ret
getbetween032	cp	"0"
	jr	c,getbetween030
	cp	"4"
	jr	nc,getbetween030
	sub	"0"
	ret

printnotready	call	zetkader
	ld	bc,txt_prtnotrdy
	ld	hl,comline*80+30
	call	PRINTTEKST
	call	GETKEY
	jp	buf2screen
txt_prtnotrdy	db	"Printer not ready !",0
txt_print	db	"Print",0

routprint	ld	ix,#a8
	ld	iy,(#FCC0)
	call	#1C
	jr	z,printnotready

	ld	a,(aanduidtrace)
	call	respcbalk
	call	zet_start_end
	ld	hl,11*80+36
	ld	bc,txt_print
	call	PRINTTEKST
	call	input_duo_adr
	jp	c,scherminit
	ld	(printstart),hl
	ld	(printstop),de
	push	hl
	call	scherminit
	pop	hl
	ld	(reg_pcvdis),hl
	call	zetgrootkot

	ld	hl,11*80+28
	ld	bc,txt_nowprt
	call	PRINTTEKST
	ld	hl,13*80+31
	ld	bc,txt_press
	call	PRINTTEKST

	call	PRINTINI

routprint1	ld	hl,(bufferhoofdpr)
	ld	e,l
	ld	d,h
	inc	de
	ld	a,32
	ld	(hl),a
	ld	bc,100	;********************************
	ldir
	ld	hl,(bufferhoofdpr)
	ld	de,5
	add	hl,de
	ld	(waarbuffer),hl

	ld	hl,(reg_pcvdis)
	push	hl
	call	vulbuffer
	call	disassem
	ld	hl,(bufferhoofdpr)
	ld	(waarbuffer),hl
	pop	hl
	call	hltobuffer

	ld	hl,(waarbuffer)
	xor	a
	ld	(hl),a
	ld	bc,(bufferhoofdpr)
	ld	hl,80*11+49
	call	PRINTTEKST
	ld	a,9
	call	ascitobuffer

	ld	hl,(waarbuffer)
	ld	de,20
	add	hl,de
	ld	(waarbuffer),hl
	ld	hl,codebuffer	;the four-byte buffer
	ld	a,(lenghtcode)
	ld	c,a
	ld	b,4
routprint2	ld	a,c
	or	a
	jr	nz,routprint3
	ld	a,32
	call	ascitobuffer
	call	ascitobuffer
	jr	routprint4
routprint3	dec	c
	ld	a,(hl)
	call	atobuffer
	inc	hl
routprint4	djnz	routprint2

	ld	a,9
	call	ascitobuffer
	ld	a,(lenghtcode)
	ld	b,a
	ld	hl,codebuffer
routprint5	ld	a,(hl)
	inc	hl
	cp	32
	jr	nc,routprint6
	ld	a,'.'
routprint6	djnz	routprint5
	ld	a,13
	call	ascitobuffer
	ld	a,10
	call	ascitobuffer
	xor	a
	call	ascitobuffer
	call	printecht
	jr	c,routprintend
	call	escpressed
	jr	z,routprintend
routprint7	ld	de,(printstop)
	ld	hl,(reg_pcvdis)
	call	hlgelijkde
	jp	c,routprint1
	jp	scherminit

escpressed	in	a,(#aa)
	and	#f0
	or	%0111
	out	(#aa),a
	in	a,(#a9)
	and	4
	ret

routprintend	jp	scherminit

txt_nowprt	db	"Now printing address 0000",0
txt_press	db	"press <esc> to stop",0

printstart	dw	0
printstop	dw	0

printecht	ld	hl,(bufferhoofdpr)
printecht1	ld	a,(hl)
	inc	hl
	or	a
	ret	z
	push	hl
	ld	ix,#a5
	ld	iy,(#FCC0)
	call	#1C
	pop	hl
	ret	c
	jr	printecht1

puldwn4optie:	db	1
puldwn4blink:	dw	#3204

pulldown4	ld	a,4
	ld	(Pulldown),a
	ld	a,(verbodenouts)
	or	a
	jr	z,pulldown41
	add	a,3
	ld	c,2
	jr	pulldown42
pulldown41	ld	a,1
	ld	c,a
	ld	hl,#3304
	ld	(puldwn4blink),hl
	ld	(puldwn4optie),a
pulldown42	ld	(puldown4menu),a
	ld	a,c
	ld	(puldown4ch1),a
	ld	ix,puldown4menu
	ld	hl,3*80+48
	call	PRINTMENU
	ld	a,(puldown4menu)
	dec	a
	jr	z,_puldown4
	ld	a,2
	ld	(puldown4ch1),a
	ld	hl,verbodenouts
	ld	de,7*80+51
	ld	b,(hl)
	inc	hl
	ex	de,hl
pulldown43	ld	a,(de)
	inc	de
	push	de
	ld	de,puldown4menu1+2
	ld	(waarbuffer),de
	call	atobuffer
	push	hl
	push	bc
	ld	bc,puldown4menu1
	call	PRINTTEKST
	pop	bc
	pop	hl
	ld	de,80
	add	hl,de
	pop	de
	djnz	pulldown43
_puldown4	ld	a,(puldwn4optie)
	ld	c,a
	ld	hl,(puldwn4blink)
	ld	ix,puldown4ch1
	call	KIESOPTIE
	ld	b,a
	ld	(puldwn4blink),hl
	ld	a,c
	ld	(puldwn4optie),a
	ld	ix,puldown4menu
	ld	hl,3*80+48
	ld	a,b
	cp	251
	jr	nc,_puldown41
	cp	28
	jr	nz,_puldown42
	ld	a,251
_puldown41	push	af
	call	WISOUDMENU
	pop	af
	jp	hoofdlusactie2
_puldown42	cp	left
	jr	nz,_puldown43
	ld	a,253
	jr	_puldown41
_puldown43	cp	1
	jp	z,WISOUDMENU
	cp	escape
	jr	nz,_puldown44
	jp	WISOUDMENU

_puldown44	and	255-32
	jr	nz,_puldown4
	; if c=1 -> add i/o , c=2 -> select + delete
	ld	a,c
	dec	a
	jr	z,puldown4inv
	ld	ix,puldown4ch1
	ld	a,(verbodenouts)
	ld	(puldown4ch1),a
	ld	hl,#3207
	ld	c,1
	call	KIESOPTIE
	cp	1
	jr	z,_puldown4
	cp	escape
	jr	z,_puldown4
	ld	e,c
	ld	d,0
	ld	hl,verbodenouts
	dec	(hl)
	add	hl,de
	ld	d,h
	ld	e,l
	inc	hl
	ld	a,c
	sub	maxvbouts
	neg
	ld	c,a
	ld	b,0
	ldir
	ld	ix,puldown4menu
	ld	hl,3*80+48
	call	WISOUDMENU
	jp	pulldown4

puldown4inv	ld	a,(verbodenouts)
	cp	maxvbouts
	jp	z,_puldown4
	call	WISOUDMENU

	ld	bc,txt_insport
	call	kadermettxtBC
	ld	hl,13*80+22
	ld	bc,txt_port
	call	PRINTTEKST
	ld	hl,13*80+28
	call	input_adres
	jp	c,buf2screen
	ld	c,e
	ld	hl,verbodenouts
	ld	a,(hl)
	or	a
	jr	z,puldown4inv2
	ld	b,a
puldown4inv1	inc	hl
	ld	a,(hl)
	cp	c
	jp	z,_pulldown4
	djnz	puldown4inv1
puldown4inv2	ld	hl,verbodenouts
	ld	d,0
	ld	a,(hl)
	inc	a
	ld	(hl),a
	ld	e,a
	add	hl,de
	ld	(hl),c
pulldown4sort	ld	hl,verbodenouts
	ld	b,(hl)
	inc	hl
	ld	de,0
puldw4sort1	ld	a,(hl)
	cp	e
	jr	nc,puldw4sort2
	inc	d
	ld	(hl),e
	dec	hl
	ld	(hl),a
	inc	hl
puldw4sort2	ld	e,(hl)
	inc	hl
	djnz	puldw4sort1
	ld	a,d
	or	a
	jr	nz,pulldown4sort
_pulldown4	call	buf2screen
	jp	pulldown4

puldown4ch1	db	0,6	; limited info table needed for Select option
puldown4menu	db	3,6,0
	db	"insert"
	db	"delete"
	db	"------"
puldown4menu1	db	" #89  ",0

txt_insport	db	"  Insert port   "
txt_port	db	"Port:",0

puldwn5optie:	db	1
puldwn5blink:	dw	#3704

pulldown5	ld	a,5
	ld	(Pulldown),a
	ld	ix,puldown5menu
	ld	hl,3*80+53
	call	PRINTMENU
_puldown5	ld	a,(puldwn5optie)
	ld	c,a
	ld	hl,(puldwn5blink)
	ld	ix,puldown5menu
	call	KIESOPTIE
	ld	b,a
	ld	(puldwn5blink),hl
	ld	a,c
	ld	(puldwn5optie),a
	ld	ix,puldown5menu
	ld	hl,3*80+53
	ld	a,b
	cp	251
	jr	nc,_puldown52
	cp	right
	jr	z,_puldown5
_puldown51	cp	left
	jr	nz,_puldown53
	ld	a,252
_puldown52	push	af
	call	WISOUDMENU
	pop	af
	jp	hoofdlusactie2

_puldown53	cp	1
	jp	z,WISOUDMENU
	cp	escape
	jr	nz,_puldown54
	JP	WISOUDMENU

_puldown54	and	255-32
	jr	nz,_puldown5
	push	bc
	call	WISOUDMENU
	pop	bc
	dec	c
	jp	z,routnewbreak
	dec	c
	jp	z,routdelbreak
	dec	c
	jp	z,exectillbp
	dec	c
	jp	z,viewbreak
	jp	specialtrace

puldown1menu	db	9,15,0
	db	"Assembler    ST"
	db	"Monitor      SL"
	db	"Disk         ^D"
	db	"Memory         "
	db	"Calculator   ^C"
	db	"Slot view      "
	db	"Shell    SH+ESC"
	db	"Quit         ^Q"
	db  "About          "

puldown2menu	db	4,18,0
	db	"CPU: Z80          "	; off,rom,dram in order
	db	"MSX rst: yes      "
linktekst	db	"Linking off     ^L",0
	db	"Linked: cursor  ^L",0
	db	"Linked: PC reg. ^L",0
configtekst	db	"Main config       ",0

turbor	db	0
monlinkyesno	db	0
txtyesno	db	"no ",0,"yes",0
txtr800	db	"Z80      ",0
	db	"R800 rom ",0
	db	"R800 dram",0

puldown3menu	db	8,19,0
puldown3menu4	db	"Debugger address ^A"
puldown3menu3	db	"Monitor address  ^M"
puldown3menu1	db	"Go               ^G"	; see also: goadres
	db	"Registers        ^R"
puldown3menu2	db	"Temporary        ^O"
	db	"Return           ^U"
	db	"Print              "
	db	"Dis > source       "

puldown5menu	db	5,19,0
puldown3menu5	db	"Set breakpoint   ^B"
puldown3menu6	db	"Reset breakpoint ^W"
	db	"Execute till bp  ^E"
	db	"View breakpoints ^V"
	db	"Special trace    ^Y"

specialtrace	ld	hl,(bufferhoofdpr)
	ld	(waarbuffer),hl
	ld	hl,(reg_pc)
	ld	(reg_pcvdis),hl
	call	vulbuffer1
	call	disassem
	ld	hl,(reg_pcvdis)
	call	mainbreakfulq
	jr	c,specialtrcfout
	push	hl
	call	mainbreaknew
	push	af
	call	exectillbp
	pop	af
	pop	hl
	ret	nc	;!!!!!
	jp	_delbreak2

specialtrcfout	ld	ix,spcstepfoutmenu
	ld	hl,11*80+25
	jp	PUTMENU
spcstepfoutmenu	db	temp2,31,0
	db	" Can't create extra breakpoint "
showcounter	db	0

exectillbp	ld	a,(breakbufpoint)
	cp	((breakbuf) and #ff)
	jr	z,exectillbp2
exectillbp1	ld	a,(showcounter)
	dec	a
	jr	nz,exectillbp3
	call	regafbeeld
	call	stackvupdate
	xor	a
exectillbp3	ld	(showcounter),a
	call	routtrace
	call	escpressed
	ret	z
	ld	hl,(reg_pc)
	call	ishlbreakpoint
	jr	c,exectillbp1
	ret

exectillbp2	call	zetkader
	ld	bc,txt_nodef
	ld	hl,comline*80+28
	jp	_noreturnadres
txt_nodef	db	"No breakpoints defined !",0

routgo	ld	de,bckup_space
	ld	bc,puldown3menu1
	scf
	call	adresinvoer
	jp	c,buf2screen

	ld	(codebuffer+1),de
	ld	a,3
	ld	(lenghtcode),a
	ld	a,#cd
	ld	(codebuffer),a
	call	buf2screen
	jp	executesimpl
bckup_space	ds	29,0

txt_transfer	db	"Transfer",0

routtotxtbuf	call	zet_start_end
	ld	hl,11*80+36
	ld	bc,txt_transfer
	call	PRINTTEKST
	call	input_duo_adr
	jp	c,scherminit
	LD	(printstart),hl
	LD	(printstop),de
	LD	(reg_pcvdis),hl
	ld	a,#c3	; start deflections
	ld	(atobuffer),a
	ld	(hltobuffer),a
	ld	hl,totxthl
	ld	(hltobuffer+1),hl
	ld	hl,totxta
	ld	(atobuffer+1),hl
	ld	hl,0
	ld	(labelcount),hl
	ld	hl,#8000
	ld	(labelpoint),hl
	ld	a,1
	ld	(totxt_labblok),A
;pass 1 for storage labels
; hl storage : 0 no 16bits printed otherwise yes
; labelpoint :BEGIN POINTS TO LAST BYTE PROGRAM TO MAX #8000
;
totxtlabel	call	knipper
	xor	a	; reset byte or 16bit is inserted
	ld	(hlopslag),a
	ld	de,(bufferhoofdpr)
	ld	(waarbuffer),de
	call	escpressed
	jp	z,routtotxt5
	call	vulbuffer
	call	disassem
	ld	a,(hlopslag)
	or	a
	jp	z,totxtlabel9
	ld	hl,(hlopslag+1)
	ld	de,(printstart)
	call	hlgelijkde
	jp	c,totxtlabel9
	ld	de,(printstop)
	call	hlgelijkde
	jr	z,totxtlabel1
	jp	nc,totxtlabel9
totxtlabel1	call	ishllabel
	jp	nc,totxtlabel3
	ld	hl,(labelpoint)

	ld	de,#c000-3
	call	hlgelijkde
	jr	c,totxtlabel2
	ld	a,(totxt_labblok)
	ld	b,a
	ld	a,(labbufsegs)
	cp	b
	jr	z,totxtlabela
totxtlabel2	ld	a,(totxt_labblok)
	call	zetlabbufA
	call	labelid
	ld	de,(labelpoint)
	call	writelabbufDE
	ld	hl,(hlopslag+1)
	ld	a,l
	call	writelabbufDE
	ld	a,h
	call	writelabbufDE
	ld	(labelpoint),de
	ld	a,(labelbufnr)
	ld	(totxt_labblok),a
	ld	hl,(labelcount)
	inc	hl
	ld	(labelcount),hl
	jr	totxtlabel9

totxtlabel3	call	labelid
	ld	c,a
	ld	a,(ix+0)
	cp	"J"
	jp	z,totxtlabel9
	cp	"D"
	jp	z,totxtlabel4
	ld	a,c
	cp	"J"
	jp	nz,totxtlabel9
totxtlabel4	ld	a,(savelabbufnr)
	call	zetlabbufA
	ld	de,(savelabbufad)
	ld	a,c
	ld	(de),a

totxtlabel9	ld	de,(printstop)
	ld	hl,(reg_pcvdis)
	call	hlgelijkde
	jp	c,totxtlabel

totxtlabela	ld	de,(bufferhoofdpr)
	ld	hl,txtorg
	ld	bc,5
	ldir
	ld	(waarbuffer),de
	ld	hl,(printstart)
	ld	(reg_pcvdis),hl
	call	totxthl
	ld	hl,(waarbuffer)
	ld	(hl),0
	xor	a	;init sourcebuffer
	call	transfer
	call	transferempty
	ld	hl,tolabelhl
	ld	(hltobuffer+1),hl

routtotxt1	call	knipper
	ld	de,(bufferhoofdpr)
	ld	(waarbuffer),de
	call	vulbuffer
	ld	hl,(reg_pcvdis)
	call	ishllabel
	jp	c,routtotxt10
	ld	a,(ix)
	cp	"C"
	push	ix
	call	z,transferempty
	pop	ix
	call	plaatslabel
	ld	a,":"
	call	ascitobuffer
routtotxt10	ld	a," "
	call	ascitobuffer
	call	disassem
	ld	hl,(waarbuffer)
	ld	(hl),0
	ld	hl,(bufferhoofdpr)
	inc	hl
	ld	a,(hl)
	cp	'R'
	jr	nz,routtotxt19
	inc	hl
	ld	a,(hl)
	cp	'S'
	jr	nz,routtotxt4
	ld	de,6
	add	hl,de
	ld	a,(hl)
	or	a
	jr	z,routtotxt4
	xor	a
	ld	(hl),a
	push	hl
	call	transferline
	pop	hl
	ld	(hl),32
	push	hl
	ld	de,7
	add	hl,de
	ld	a,(hl)
	or	a
	pop	de
	jr	z,routtotxt18
	ld	(hl),0
	push	hl
	ex	de,hl
	ld	a,1
	call	LINETOASSEMB	; don't check here on carry, comes second
	pop	hl
	dec	hl
	dec	hl
	dec	hl
	push	hl
	ld	(hl)," "
	inc	hl
	ld	(hl),"D"
	inc	hl
	ld	(hl),"W"
	inc	hl
	ld	(hl)," "
	pop	de

routtotxt18	ex	de,hl
	ld	a,1
	call	LINETOASSEMB
	jr	routtotxt41

routtotxt19	ld	a,'>'	; check if there is an arrow to address ;*
	ld	b,40
routtotxt2	inc	hl
	cp	(hl)
	jr	nz,routtotxt3
;        dec hl                                         ;*
	ld	de,-5	;*
	push	hl
	add	hl,de
	ex	de,hl
	pop	hl
	inc	hl	;*
	ld	bc,16	;*
	ldir		;*
;        ld a,";"                                       ;*
;        ld (hl),a                                      ;*
	jr	routtotxt4


routtotxt3	djnz	routtotxt2
routtotxt4	call	transferline
routtotxt41	jr	c,routtotxt6
	ld	a,(codebuffer)
	cp	#c9
	call	z,transferempty
	call	escpressed

	jr	z,routtotxt5
	ld	de,(printstop)
	ld	hl,(reg_pcvdis)
	call	hlgelijkde
	jp	c,routtotxt1
	jr	routtotxtend
routtotxt5	call	CHRGET
routtotxt6	ld	hl,80*9+25
	ld	ix,transferermenu
	call	PUTMENU

; end: fix deflections
routtotxtend	call	transferempty
	ld	de,(bufferhoofdpr)
	ld	hl,txt_end
	ld	bc,5
	ldir
	ld	a,2	;to end
	call	transfer
	ld	hl,0
	ld	(atobuffer),hl
	ld	(atobuffer+1),hl
	ld	(hltobuffer),hl
	ld	(hltobuffer+1),hl
routtotxtend2	ld	hl,(disoptabpc)
	ld	(reg_pcvdis),hl
	call	disameenscherm
	jp	scherminit

transferempty	ld	hl,(bufferhoofdpr)
	ld	(hl),0
	jp	transferline

txtorg	db	" ORG "
txt_end	db	" END",0
transferermenu	db	temp2,34,0
	db	" Error occurred! Transfer stopped "

hlopslag	db	0
	dw	0

knipper	ld	a,(vorigpos)
	ld	b,a
	ld	a,(reg_pcvdis)
	and	#40
	cp	b
	ret	z
	ld	(vorigpos),A
	ld	hl,11*80+45
	call	SETVRAMWRITE
	ld	a,(tekentje)
	xor	#10
	ld	(tekentje),a
	out	(#98),a
	ret

tekentje	db	"-"
vorigpos	db	0

totxthl	ld	(hlopslag+1),hl
	ld	a,1
	ld	(hlopslag),a
	call	idhexvoor
	ld	a,h
	call	atobuffer1
	ld	a,l
	jp	atobuffer1

totxta	push	af
	call	idhexvoor
	pop	af
	jp	atobuffer1

idhexvoor	ld	a,"#"
	jp	ascitobuffer

tolabelhl	push	ix	; deflect to print labels if it has one
	push	de
	call	ishllabel
	pop	de
	jr	c,tolabelhl1
	call	plaatslabel
	pop	ix
	ret
tolabelhl1	pop	ix
	jr	totxthl

plaatslabel	ld	a,(ix+0)
	call	ascitobuffer
	ld	a,(ix+2)
	call	atobuffer1
	ld	a,(ix+1)
	jp	atobuffer1

transferline	ld	a,1
transfer	ld	hl,(bufferhoofdpr)
	jp	LINETOASSEMB

labelpoint	dw	0
totxt_labblok	db	0
labelcount	dw	0
labeldummycnt	dw	0

ishllabel	ld	(ishllabel_hl),hl
	ld	a,1
	call	zetlabbufA
	ld	bc,0
	ld	de,#8000
	ld	ix,ishllab_data
_ishllabel1	ld	hl,(labelcount)
	or	a
	sbc	hl,bc
	ld	a,h
	or	l
	jr	nz,_ishllabel2
	ld	hl,(ishllabel_hl)
	scf
	ret

_ishllabel2	inc	bc
	ld	(labeldummycnt),bc
	ld	a,(labelbufnr)
	ld	(savelabbufnr),a
	ld	(savelabbufad),de
	call	leeslabbufDE
	ld	(ix),a
	call	leeslabbufDE
	ld	l,a
	call	leeslabbufDE
	ld	h,a
	push	de
	ld	de,(ishllabel_hl)
	call	hlgelijkde
	pop	de
	jr	nz,_ishllabel3
	ld	(ix+1),l
	ld	(ix+2),h
	or	a
	ret

_ishllabel3	ld	bc,(labeldummycnt)
	jr	_ishllabel1

ishllab_data	db	0,0,0
ishllabel_hl	dw	0
savelabbufnr	db	0
savelabbufad	dw	0

;returns label id. J,C or D (in order of importance)
; back A contains ascii v/d ID
; changes : af
labelid	ld	a,(codebuffer)
	cp	#c3	; jp
	jp	z,labelidj
	cp	#18	; jr
	jp	z,labelidj
	cp	#10	; djnz
	jp	z,labelidj
	and	%11000111	; jp cc
	cp	%11000010
	jp	z,labelidj
	ld	a,(codebuffer)
	and	%11100111
	cp	%00100000
	jp	nz,labelid1
labelidj	ld	a,"J"
	ret
labelid1	ld	a,(codebuffer)
	cp	#cd
	jp	z,labelidc
	and	%11000111	; call cc
	cp	%11000100
	jp	z,labelidc
	ld	a,"D"
	ret
labelidc	ld	a,"C"
	ret

vramadresmenu	equ	830
callbufpoint	dw	callbuf-1
callbuf	ds	3*9
callbufend	equ	$

getadres	push	ix	; input [c] then hexprinthl
	push	hl
	push	af
	ld	hl,80*5+30
	call	PRINTMENU
	ld	ix,getadresmenu
	ld	hl,12*80+26
	call	PRINTMENU
	pop	af
	pop	de
	jr	nc,getadres0
	ld	b,4
	ld	hl,13*80+39
	call	PRINTHEXADEC
	ld	c,1
	jr	getadres1
getadres0	ld	c,2
getadres1	push	af
	ld	ix,getadresmenu
	ld	hl,12*80+26
	call	WISOUDMENU
	pop	af
	pop	ix
	push	af
	ld	hl,80*5+30
	call	WISOUDMENU
	pop	af
	ret	c

getadres2	ld	hl,kbuf
	call	BEREKENGETAL
	jr	nc,getadres9
	push	af
	push	de
	ccf
	rla
	ld	d,0
	ld	e,a
	ld	hl,foutenmenus
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	de
	pop	ix
	ld	hl,80*7+30
	call	PUTMENU
	pop	de
	pop	af
getadres9	ex	de,hl
	ret

getadresmenu	db	temp2,28,1
	db	"Address :                   "

foutenmenus	dw	foutmenu0
	dw	foutmenu1
	dw	foutmenu0
	dw	foutmenu3
foutmenu0	db	temp2,12,0
	db	"Syntax error"
foutmenu1	db	temp2,12,0
	db	"Bad mnemonic"
foutmenu3	db	temp2,15,0
	db	"Divide by zero "

hlgelijkde	ld	a,h
	cp	d
	ret	nz
	ld	a,l
	cp	e
	ret

getreturnadres	ld	hl,(callbufpoint)
	ld	de,callbuf-1
	call	hlgelijkde
	jp	z,noreturnadres
	dec	hl
	ld	a,(hl)
	ld	(aanduiddisam),a
	dec	hl
	ld	d,(hl)
	dec	hl
	ld	e,(hl)
	ld	(reg_pcvdis),de
	ld	de,callbuf
	call	hlgelijkde
	jr	nz,getreturnadr2
	dec	hl
getreturnadr2	ld	(callbufpoint),hl
aanpasmonlink	call	updcursordis
	ld	a,(monlinkyesno)
	dec	a
	ret	nz
	ld	hl,(disoptabpc)
	ld	(monadres),hl
	ret

noreturnadres	call	zetkader
	ld	bc,txt_noreturn
	ld	hl,comline*80+26
_noreturnadres	call	PRINTTEKST
	call	GETKEY
	jp	buf2screen

txt_noreturn	db	"Call-buffer already empty !",0

getcalladres	ld	hl,(callbufpoint)
	ld	de,callbufend
	call	hlgelijkde
	jr	z,_calladresmax
	ld	de,callbuf-1
	call	hlgelijkde
	jr	nz,_getcalladres
	ld	hl,callbuf
_getcalladres	ld	de,(disoptabpc)
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	ld	a,(aanduiddisam)
	or	a
	jr	nz,_getcalladres1
	inc	a
_getcalladres1	ld	(hl),a
	inc	hl
	ld	(callbufpoint),hl

	xor	a
	ld	bc,puldown3menu2
	call	adresinvoer
	jr	nc,invoerokee
	call	buf2screen
	jp	getreturnadres
invoerokee	ld	(reg_pcvdis),de
	ld	a,1
	ld	(aanduiddisam),a
	call	buf2screen
	jp	aanpasmonlink
_calladresmax	call	zetkader
	ld	bc,txt_filled
	ld	hl,comline*80+26
	jr	_noreturnadres
txt_filled	db	"Call-buffer already filled !",0
txt_adres	db	"Address:",0

getmonitoradres	xor	a
	ld	bc,puldown3menu3
	call	adresinvoer
	jp	c,buf2screen
	ld	(monadres),de
	xor	a
	ld	(monlinkyesno),a
	call	buf2screen
	call	monitor
	jp	ispconmon

getdisamadres	xor	a
	ld	bc,puldown3menu4
	call	adresinvoer
	jp	c,buf2screen
	push	de
	call	buf2screen
	pop	de
	ld	(reg_pcvdis),de
	ld	a,1
	ld	(aanduiddisam),a
	jp	aanpasmonlink

txt_bfull	db	"Breakpoint-memory full !",0
txt_already	db	"Already defined as breakpoint !",0

routnewbreak	call	mainbreakfulq
	jr	nc,_routnewbreak
	call	zetkader
	ld	bc,txt_bfull
	ld	hl,comline*80+28
	jp	_noreturnadres

_routnewbreak	xor	a
	ld	bc,puldown3menu5
	call	kadermettxtBC
	ld	hl,13*80+22
	ld	bc,txt_adres
	call	PRINTTEKST
	call	adresnapijl
	ld	b,4
	ld	hl,13*80+31
	call	PRINTHEXADEC
	ld	hl,13*80+31
	call	input_adres
	push	af
	push	de
	call	buf2screen
	pop	hl
	pop	af
	ret	c
	call	mainbreaknew
	jp	c,bpverandert
	call	zetkader
	ld	bc,txt_already
	ld	hl,comline*80+24
	jp	_noreturnadres

mainbreakfulq	ld	a,(breakbufpoint)
	sub	((breakbufend) and 255)
	or	a
	ret	nz
	scf
	ret

insertbreak	call	mainbreakfulq	;add bkp, in HL
	ret	c

mainbreaknew	call	ishlbreakpoint
	ret	nc
	ex	de,hl
	ld	hl,(breakbufpoint)
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	ld	(breakbufpoint),hl
	scf
	ret

txt_nobdel	db	"No breakpoints to delete !",0
txt_nobadr	db	"   No breakpoint at that address !   ",0

routdelbreak	ld	a,(breakbufpoint)
	cp	((breakbuf) and #ff)
	jr	nz,routdelbreak0
	call	zetkader
	ld	bc,txt_nobdel
	ld	hl,comline*80+27
	jp	_noreturnadres
routdelbreak0	ld	hl,(reg_pc)
	call	ishlbreakpoint

routdelbreak1	push	af
	push	hl
	ld	bc,puldown3menu6
	CALL	kadermettxtBC
	ld	hl,13*80+22
	ld	bc,txt_adres
	call	PRINTTEKST
	pop	de
	pop	af
	jr	c,_routdelbr1
	ld	b,4
	ld	hl,13*80+31
	call	PRINTHEXADEC
_routdelbr1	ld	hl,13*80+31
	call	input_adres
	jp	c,buf2screen
	ex	de,hl
	call	ishlbreakpoint
	jr	nc,_routdelbr2
	call	buf2screen
	call	zetkader
	ld	bc,txt_nobadr
	ld	hl,comline*80+22
	jp	_noreturnadres
_routdelbr2	push	hl
	call	buf2screen
	pop	hl

_delbreak2	ld	de,breakbuf
_delbreak3	ld	a,(de)
	inc	de
	cp	l
	jr	z,_delbreak4
	inc	de
	jr	_delbreak3
_delbreak4	ld	a,(de)
	inc	de
	cp	h
	jr	nz,_delbreak3

	ld	hl,breakbufend
	sbc	hl,de	;Carry is still zero
	ld	b,h
	ld	c,l
	ld	h,d
	ld	l,e
	dec	de
	dec	de
	ldir

	ld	hl,breakbufpoint
	dec	(hl)
	dec	(hl)

bpverandert	ld	ix,disoptabpc
	ld	de,disbuffer+disopwrmnomic-2
	ld	b,disopaantlijn
bpverandert1	ld	l,(ix+0)
	ld	h,(ix+1)
	inc	ix
	inc	ix
	push	de
	call	ishlbreakpoint
	pop	de
	ld	a,32
	jr	c,bpverandert2
	ld	a,"$"
bpverandert2	ld	(de),a
	ld	hl,lglnlngh
	add	hl,de
	ex	de,hl
	djnz	bpverandert1
	jp	distoscr

; IN :HL  OUT:NC=hl no breakpoint Changes:C,DE,AF
ishlbreakpoint	ld	de,breakbuf
	ld	a,(breakbufpoint)
	ld	c,a
_ishlbreak1	ld	a,c
	cp	e
	scf
	ret	z	;end reached
	ld	a,(de)
	inc	de
	cp	l
	jr	z,_ishlbreak2
	inc	de
	jr	_ishlbreak1
_ishlbreak2	ld	a,(de)
	cp	h
	ret	z	;found it!
	inc	de
	jr	_ishlbreak1

viewbreakx	equ	43
viewbreaky	equ	3
viewtekst1	db	18,23,23,23,23,25,0
viewtekst2	db	12,32,32,32,32,22,0
viewtekst3	db	17,23,23,23,23,27,0
viewbrpijl	db	0
viewbrnumber	db	0

viewbreak	ld	a,(breakbufpoint)
	cp	((breakbuf) and #ff)
	jp	z,exectillbp2
	ld	hl,(2+viewbreakx)*256+viewbreaky+1
	ld	(breakvalsbalk),hl
	ld	a,1
	ld	(breakvalsopt),a
	ld	(breakvalsmenu),a
	ld	ix,breakbuf
	ld	hl,breakvalsmenu+3
	ld	(waarbuffer),hl
viewbreak1	ld	h,(ix+1)
	ld	l,(ix+0)
	call	hltobuffer
	inc	ix
	inc	ix
	push	hl
	ld	de,(breakbufpoint)
	push	ix
	pop	hl
	call	hlgelijkde
	pop	hl
	jr	z,viewbreak0
	ld	hl,breakvalsmenu
	inc	(hl)
	jr	viewbreak1
viewbreak0	ld	ix,breakvalsmenu
	ld	hl,80*viewbreaky+viewbreakx
	call	PRINTMENU
viewbreak2	ld	a,(breakvalsopt)
	ld	c,a
	ld	hl,(breakvalsbalk)
	ld	ix,breakvalsmenu
	call	KIESOPTIE
	push	af
	ld	a,c
	ld	(breakvalsopt),a
	ld	(breakvalsbalk),hl
	ld	ix,breakvalsmenu
	ld	hl,80*viewbreaky+viewbreakx
	call	WISOUDMENU
	pop	af
	cp	" "
	ret	nz
viewbreak3	ld	a,(breakvalsopt)
	ld	b,a
	ld	hl,breakbuf-2
viewbreak4	inc	hl
	inc	hl
	djnz	viewbreak4
	ex	de,hl
	ld	a,(de)
	inc	de
	ld	l,a
	ld	a,(de)
	ld	h,a
	xor	a
	jp	routdelbreak1

breakbufpoint	dw	breakbuf	;reference to first FREE entry
breakbuf	ds	2*15
breakbufend	equ	$
breakvalsopt	db	0
breakvalsbalk	dw	0
breakvalsmenu	db	0,4,0
	ds	15*4

stackviewx	equ	73
stackviewy	equ	3
stackaantlijn	equ	19
	; init routine to put frame on screen
stackinit	ld	hl,stackviewy*80+stackviewx	; first structure screen frame
	ld	bc,stackuplijn1
	call	PRINTTEKST	; top line
	ld	hl,stackviewy*80+stackviewx+80
	inc	bc	;=ld bc,stackupline2
	call	PRINTTEKST	; top line
	ld	hl,stackviewy*80+stackviewx+160
	inc	bc	;=ld bc,stackupline3
	call	PRINTTEKST	; top line
	ld	hl,stackviewy*80+stackviewx+240
	ld	de,80
	exx
	ld	b,stackaantlijn

_stackinit1	exx
	ld	bc,stackleeglijn
	call	PRINTTEKST
	add	hl,de
	exx
	djnz	_stackinit1
	exx
	inc	bc	;=ld bc,stackdown line
	jp	PRINTTEKST	; bottom line

stackuplijn1	db	18,23,23,23,23,23,25,0
stackuplijn2	db	22,83,84,65,67,75,22,0
stackuplijn3	db	20,23,23,23,23,23,19,0
stackleeglijn	db	22,32,32,32,32,32,22,0
stackdownlijn	db	17,23,23,23,23,23,27,0

; following routine is needed to keep the frame up to date
stackvupdate	ld	hl,(reg_sp)
	ld	bc,stackaantlijn*2
	call	GETFROMRAM
	ld	de,(bufferhoofdpr)
	ld	b,stackaantlijn
	ld	hl,stacktxtbuffer
	ld	(waarbuffer),hl
_stackvupd1	ld	a,(de)
	inc	de
	ld	l,a
	ld	a,(de)
	inc	de
	ld	h,a
	call	hltobuffer
	ld	hl,(waarbuffer)
	inc	hl
	ld	(waarbuffer),hl
	djnz	_stackvupd1
	ld	hl,80*(3+stackviewy)+stackviewx+2
	ld	bc,stacktxtbuffer
	exx
	ld	b,stackaantlijn
	jp	_toscr

stacktxtbuffer	ds	5*stackaantlijn

regafbeeld	ld	a,i
	ld	h,a
	ld	a,r
	ld	l,a
	ld	(reg_ir),hl
	ld	hl,regscrpoint
	ld	b,13
_regtoscr	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	(waarbuffer),de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	inc	hl
	inc	hl
	ex	de,hl
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	call	hltobuffer	; this is without #
	ex	de,hl
	djnz	_regtoscr

	ld	a,(reg_af)
	ld	e,a

	ld	bc,#4D50	; MP
	ld	hl,regsflag
	sla	e
	call	_regflag

	ld	bc,#204E	; SPACE N
	ld	hl,regzflag
	sla	e
	call	_regflag

	ld	bc,#3130	; 10
	ld	hl,reghflag
	sla	e
	sla	e
	call	_regflag

	ld	bc,#454F	; OE
	ld	hl,regpflag
	sla	e
	sla	e
	call	_regflag

	ld	bc,#3130	; 10
	ld	hl,regnflag
	sla	e
	call	_regflag

	ld	bc,#204E	; SPACE N
	ld	hl,regcflag
	sla	e
	call	_regflag

	ld	a,(eiofdi)
	add	a,68
	ld	(regeiflag),a

regviewx	equ	40
regviewy	equ	3
scrreg	equ	regviewx*16+regviewy

	ld	hl,regviewy*80+regviewx
	ld	bc,regscreen
	exx
	ld	b,9
	jp	_toscr

_regflag	ld	a,c	; NC then reg to c show else b
	jr	nc,_regflag1
	ld	a,b
_regflag1	ld	(hl),a
	ret

regscrpoint	; first where buffer then which register then vram address
	dw	regscraf+5,reg_af,(1+regviewx)*256+regviewy+1
	dw	regscraf+16,reg_bc,(12+regviewx)*256+regviewy+1
	dw	regscraf+28,reg_de,(24+regviewx)*256+regviewy+1

	dw	regscrafac+5,reg_afac,(1+regviewx)*256+regviewy+2
	dw	regscrafac+16,reg_bcac,(12+regviewx)*256+regviewy+2
	dw	regscrafac+28,reg_deac,(24+regviewx)*256+regviewy+2

	dw	regscrhl+5,reg_hl,(1+regviewx)*256+regviewy+3
	dw	regscrhl+16,reg_ix,(12+regviewx)*256+regviewy+3
	dw	regscrhl+28,reg_iy,(24+regviewx)*256+regviewy+3

	dw	regscrhlac+5,reg_hlac,(1+regviewx)*256+regviewy+4
	dw	regscrhlac+16,reg_pc,(12+regviewx)*256+regviewy+4
	dw	regscrhlac+28,reg_sp,(24+regviewx)*256+regviewy+4

	dw	regscrir+5,reg_ir,(1+regviewx)*256+regviewy+5

regscreen	db	23,23,23,23,23,23,23,23,23,23,23,23
	db	23,23,23,23,23,23,23,23,23,23,23,23,23
	db	23,23,23,23,23,23,23,23,0

regscraf	db	" AF :3455   BC :5445    DE :4323 ",0
regscrafac	db	" AF':7866   BC':3434    DE':3434 ",0
regscrhl	db	" HL :2342   IX :3434    IY :     ",0
regscrhlac	db	" HL':4344   PC :        SP :     ",0
regscrir	db	" IR :4534   "
regeiflag	db	"EI                   ",0
	db	"                                 ",0
	db	"   "
regzflag	db	"NZ   "
regcflag	db	"NC  N:"
regnflag	db	"1   P"
regpflag	db	"O  H:"
reghflag	db	"1    "
regsflag	db	"S   ",0
regend	db	23,23,23,23,23,23,23,23,23,23,23,23
	db	23,23,23,23,23,23,23,23,23,23,23,23,23
	db	23,23,23,23,23,23,23,23,0


;Check if the key passed in A corresponds to a register/flag shortcut,
;if so select the register/flag and edit/toggle it without returning,
;otherwise just return.

CheckRegSortcut:
	or 32
	ld b,a
	ld a,(matrix+6)
	rra
	jr c,CheckRegSortcut_NoShift
	set 7,b
CheckRegSortcut_NoShift:
	ld hl,RegShortcuts
	ld c,0
CheckRegSortcutLoop:
	ld a,(hl)
	or a
	ret z
	cp b
	jr z,RegShortcutFound
	inc hl
	inc c
	jr CheckRegSortcutLoop
RegShortcutFound:
	pop hl	;Remove return address from stack
	ld a,c
	cp 14
	jr nc,RegShortcutIsForFlag

RegShortcutIsForReg:
	ld a,0C9h	;RET, so that the "call regaanpas5" actually returns
	ld (regaanpas0),a
	call regaanpas5
	ld a,0CDh	;CALL, to restore the "call	CHRGET"
	ld (regaanpas0),a
	jp regaanpas_space

RegShortcutIsForFlag:
	sub 14
	ld c,a	;Flag indexes start again at 0
	ld a,0C9h	;RET, so that the "call flagaanpas5" actually returns
	ld (flagaanpas0),a
	call flagaanpas5
	ld a,0CDh	;CALL, to restore the "call	CHRGET"
	ld (flagaanpas0),a
	jp flagaanpas8

RegShortcuts:
	db 'a'
	db 'b'
	db 'd'
	db 'a'+128
	db 'b'+128
	db 'd'+128
	db 'h'
	db 'x'
	db 'y'
	db 'h'+128
	db 'p'
	db 's'
	db 'r'
	db 'i'
	db 'z'
	db 'c'
	db 'n'
	db 'o'
	db 'g'
	db 'm'
	db 0


regaanpas	ld	c,1	; c=pointer which reg(max 12, IR+diei=13)
	ld	a,29
	jr	regaanpas1
regaanpas0	call	CHRGET
	ld d,a
	ld e,c
	call CheckRegSortcut
	ld a,d
	ld c,e
	cp	escape
	jp	z,regaanpasex
	cp	1
	jp	z,regaanpasex
	cp	right
	jr	nz,regaanpas1
	inc	c
	jr	regaanpas5
regaanpas1	cp	left
	jr	nz,regaanpas2
	dec	c
	jr	regaanpas5
regaanpas2	cp	up
	jr	nz,regaanpas3
	dec	c
	dec	c
	dec	c
	jr	regaanpas5
regaanpas3	cp	down
	jr	nz,regaanpas4
	inc	c
	inc	c
	inc	c
regaanpas5	call	resregaanpas
	ld	a,c
	cp	13
	jp	z,regaanpaseiblk
	jp	nc,flagaanpas
regaanpas50	ld	hl,regscrpoint-2
	ld	de,6
	ld	b,c
	inc	b
regaanpas51	add	hl,de
	djnz	regaanpas51
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	ld	b,8
regaanpas52	push	bc
	call	SETBALK
	pop	bc
	jr	regaanpas0

regaanpaseiblk	ld	b,2
	ld	hl,(12+regviewx)*256+regviewy+5
	jr	regaanpas52

regaanpas4	cp	32
	jr	nz,regaanpas0
regaanpas_space:	
	ld	a,c
	cp	13
	jr	nz,regaanpas6
	ld	a,(eiofdi)
	xor	1
	ld	(eiofdi),a
	push	bc
	call	regafbeeld
	pop	bc
	jp	regaanpas0

regaanpas6	ld	hl,regviewy+6+256*regviewx
	ld	b,33
	push	bc
	call	SETBALK
	pop	bc
	ld	hl,regscrpoint-6
	ld	de,6
	ld	b,c
	inc	b
regaanpas61	add	hl,de
	djnz	regaanpas61
	ld	a,(hl)
	inc	hl
	push	hl
	ld	h,(hl)
	ld	l,a
	dec	hl
	dec	hl
	dec	hl
	dec	hl
	push	bc
	push	hl
	ld	hl,80*(6+regviewy)+regviewx
	call	SETVRAMWRITE
	pop	hl
	ld	b,4
regaanpas62	ld	a,(hl)
	inc	hl
	out	(#98),a
	djnz	regaanpas62
	ld	b,27
	ld	hl,80*(6+regviewy)+regviewx+4
	ld	de,kbuf
	ld	a,128+64
	call	INPUTTEXT
	push af
	ld	hl,regviewy+6+256*regviewx
	ld	b,33
	call	WISBALK
	pop af
	pop	bc
	pop	hl
	jr	c,regaanpas63
	push	bc
	push	hl
	call	resregaanpas
	call	getadres2
	ex	de,hl
	pop	hl
	pop	bc
	jr	c,regaanpas63
	ex	de,hl
	inc	de
	push	hl
	ld	a,(de)
	ld	l,a
	inc	de
	ld	a,(de)
	ld	h,a
	pop	de
	ld	(hl),e
	inc	hl
	ld	(hl),d
	ld	a,(reg_ir+1)
	ld	i,a
regaanpas63	ld	hl,80*(6+regviewy)+regviewx
	push	bc
	ld	bc,33
	ld	a,32
	call	FILLVRAM
	call	regafbeeld
	pop	bc
	jp	regaanpas50

flagaanpas	ld	c,0
	jr	flagaanpas5
flagaanpas0	call	CHRGET
	ld d,a
	ld e,c
	call CheckRegSortcut
	ld a,d
	ld c,e
	cp	up
	jr	nz,flagaanpas1
	ld	c,12
	jp	regaanpas5
flagaanpas1	cp	down
	jr	nz,flagaanpas2
	ld	c,0
	jp	regaanpas5
flagaanpas2	cp	right
	jr	nz,flagaanpas3
	inc	c
	jr	flagaanpas5
flagaanpas3	cp	left
	jr	nz,flagaanpas4
	dec	c
	jr	flagaanpas5
flagaanpas4	cp	escape
	jr	z,regaanpasex
	cp	1
	jr	z,regaanpasex
	cp	32
	jr	nz,flagaanpas0
	jr	flagaanpas8
flagaanpas5	ld	a,c
	cp	255
	jr	nz,flagaanpas6
	ld	a,5
	jr	flagaanpas7
flagaanpas6	cp	6
	jr	nz,flagaanpas7
	ld	a,0
flagaanpas7	ld	c,a
	call	resregaanpas
	ld	a,c
	add	a,a
	add	a,a
	add	a,c
	ld	l,regviewx+2
	add	a,l
	ld	h,a
	ld	l,10
	ld	b,3
	push	bc
	call	SETBALK
	pop	bc
	jr	flagaanpas0

flagaanpas8	ld	b,0
	ld	hl,flagtab
	add	hl,bc
	ld	a,(reg_af)
	xor	(hl)
	ld	(reg_af),a
	push	bc
	call	regafbeeld
	pop	bc
	jp	flagaanpas0

flagtab	db	%01000000	; zero
	db	%00000001	; carry
	db	%00000010	; n
	db	%00000100	; po
	db	%00010000	; h
	db	%10000000	; s
; order of flag tab in same order as display on screen

resregaanpas	push	bc
	ld	b,7
resregaanpas1	ld	a,3
	add	a,b
	push	bc
	ld	b,34
	ld	l,a
	ld	h,regviewx
	call	WISBALK
	pop	bc
	djnz	resregaanpas1
	pop	bc
	ret

regaanpasex	call	resregaanpas
	call	ispconscr
	CALL	ispconmon
	ld	a,(monlinkyesno)
	cp	2
	ret	nz
	ld	hl,(reg_pc)
	ld	(monadres),hl

ispconmon	ld	b,0
	ld	de,(monadres)
	ld	hl,(reg_pc)
	call	hlgelijkde
	rl	b	; if monadres<=reg_pc then b=0 else b=1
	ld	hl,(aantalmonlijn-1)*8
; ADD HL,DE IS SPLIT TO NOTICE WALK AROUND
	ld	a,l
	add	a,e
	ld	e,a
	ld	a,d
	adc	a,h
	ld	d,a
	push	af
	ld	hl,(reg_pc)
	call	hlgelijkde
	ccf
	rl	b
	pop	af
	ld	a,b
	jr	nc,ispconmon0
	cp	%11
	jp	z,wismonbalk
	jr	ispconmon3
ispconmon0	or	a	; will zero as pc within limits
	jp	nz,wismonbalk

ispconmon3	call	wismonbalk
	ld	hl,(reg_pc)
	ld	de,(monadres)
	or	a
	sbc	hl,de
	ld	a,l	;l=%yyyyyxxx y-line x'th character
	rrca
	rrca
	rrca
	and	15
	add	a,12+1
	ld	(monybalk),a
	ld	a,l
	and	7
	push	af
	ld	b,a
	add	a,a
	add	a,B
	add	a,40
	ld	b,3
	call	ispconmon1
	pop	af
	add	a,40+25
	ld	b,1
ispconmon1	ld	h,a
	ld	a,(monybalk)
	ld	l,a
	jp	SETBALK

wismonbalk	ld	a,(monybalk)
	ld	l,a
	ld	h,40	; clears bar on monitor
	ld	b,33
	jp	WISBALK


monitor	ld	a,(monlinkyesno)
	cp	1
	jr	c,monitor7
	jr	nz,monitor0
	ld	a,(aanduiddisam)
	or	a
	jr	z,monitor7	; at zero no arrow visible
	call	adresnapijl
	jr	monitor1
monitor0	ld	a,(aanduidtrace)
	or	a
	jr	z,monitor7	; at zero no bar visible
	ld	de,(reg_pc)
monitor1	ld	hl,7
	call	hlgelijkde
	jr	c,monitor2
	jr	monitor4
monitor2	ld	hl,#fff7
	call	hlgelijkde
	jr	nc,monitor5
monitor4	ld	hl,0
	ld	(monadres),hl
	jr	monitor65
monitor5	ld	hl,(monadres)
	ld	bc,8
	add	hl,bc
	call	hlgelijkde
	jr	c,monitor6	; C=> monaddress+8<disoptabpc
	ld	hl,(monadres)
	ld	a,h
	or	l
	jr	z,monitor65
	ld	bc,-7
	dec	hl
	call	hlgelijkde	; C=> monaddress-1<disop
	jr	c,monitor65
	add	hl,bc
monitor6	ld	(monadres),hl
	jr	monitor

monitor65	call	ispconmon
monitor7	ld	hl,monitorbuf+27
	ld	(waarbuffer),hl
	ld	hl,(monadres)
	call	hltobuffer
	ld	bc,8*(aantalmonlijn-1)
	call	GETFROMRAM
	ld	hl,monitorbuf+34
	ld	de,(bufferhoofdpr)
	ld	b,aantalmonlijn-1
monitor8	ld	c,b
	push	de
	ld	b,8
monitor9	ld	(waarbuffer),hl
	ld	a,(de)
	call	atobuffer
	inc	hl
	inc	hl
	inc	hl
	inc	de
	djnz	monitor9
	pop	de
	inc	hl
	ld	b,8
monitora	ld	a,(de)
	or	a
	jr	nz,monitorb
	ld	a,32
monitorb	ld	(hl),a
	inc	de
	inc	hl
	djnz	monitora

	inc	hl
	ld	b,c
	djnz	monitor8

	ld	hl,80*12+40
	ld	bc,monitorbuf
	exx
	ld	b,aantalmonlijn
	jp	_toscr

slot0	db	%10000111
	db	54
	db	%00000111
	db	105
	db	%00001100
	db	58
	db	%10001001
	db	254

slotmonitor	call	GETPAGES
	push	hl
	ld	de,slotkader+43
	ld	b,4
slotmonitor1	ld	a,(hl)
	and	3
	add	a,"0"
	ld	(de),a
	inc	de
	inc	de
	ld	a,(hl)
	rlca
	jr	nc,slotmonitor2
	rrca
	rrca
	rrca
	and	3
	add	a,"0"
	jr	slotmonitor3
slotmonitor2	ld	a,"X"
slotmonitor3	ld	(de),a
	inc	de
	inc	de
	inc	hl
	inc	hl
	djnz	slotmonitor1
	pop	de
	ld	hl,slotkader+43+35
	ld	(waarbuffer),hl
	inc	de
	ld	b,4
slotmonitor4	ld	a,(de)
	inc	de
	inc	de
	call	atobuffer
	ld	a,32
	call	ascitobuffer
	call	ascitobuffer
	djnz	slotmonitor4
	ld	hl,slotkadergeg+6	;place subslot regs
	ld	de,subslotregs+3
	ld	a,8
slotmonitor5	ld	b,a
	ex	af,af'
	ld	a,(welkismetsub)
	and	b
	jr	z,slotmonitor6
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	dec	hl
	ld	(waarbuffer),bc
	ld	a,(de)
	call	atobuffer
slotmonitor6	dec	hl
	dec	hl
	dec	de
	ex	af,af'
	rrca
	jr	nc,slotmonitor5

	ld	hl,80*(13+aantalmonlijn)+40
	ld	bc,slotkader
	exx
	ld	b,3
	jp	_toscr

slotkader	db	" PAGE     0   1   2   3          ",0
	db	" SLOT     -   -   -   -    ",28,29,"  ",28,29,0
	db	" MAPPER                    ",28,29,"  ",28,29,0

slotkadergeg	dw	slotkader+1*34+27
	dw	slotkader+1*34+31
	dw	slotkader+2*34+27
	dw	slotkader+2*34+31

disopaantlijn	equ	21
disopwradres	equ	1
disopwrmnomic	equ	9
disopwrhex	equ	29

uplijn	db	24,23,23,23,23,23,23,18,23,23,23,23,23,23,23,23,23
	db	23,23,23,23,23,23,23,23,23,23,23,18,23,23,23,23,23
	db	23,23,23,23,23,18,0

	db	22
leeglijndb	db	"      ",22,"                    ",22
	db	"         "
leeglijnend2	db	" "
leeglijnend	db	22,0
lglnlngh	equ	leeglijnend-leeglijndb

downlijn	db	26,23,23,23,23,23,23,17,23,23,23,23,23,23,23,23,23
	db	23,23,23,23,23,23,23,23,23,23,23,17,23,23,23,23,23
	db	23,23,23,23,23,17,0

bufferhoofdpr	dw	0	;because of GETFROMRAM

reg_pcvdis	dw	0	; pc register for next instr

;disoppoint      db 0 ;GIVES MANY POINTER OF DISOPTAB not used?*********

monitorbuf	db	"   Minimonitor-address :   ADAD  ",0
	db	"                                 ",0
	db	"                                 ",0
	db	"                                 ",0
	db	"                                 ",0
	db	"                                 ",0
	db	"                                 ",0
	db	"                                 ",0
	db	"                                 ",0
	db	"                                 ",0
monybalk	db	7	; not to zero otherwise damage main bar
	;on first call erase bar in main loop
aantalmonlijn	equ	9
monadres	dw	startmonadres
reg_pc	dw	startpcadres
cursoradres	dw	startcursorad
disoptabpc	dw	startcursorad
	ds	(disopaantlijn*2)-2	; corresponding address per line
disbuffer	ds	disopaantlijn*lglnlngh	;LINES END=0
;
; Init takes care of overall initialization data+building the
; frames on the screen
initdis	ld	hl,3*80	; first construction screen frame disam
	ld	bc,uplijn
	call	PRINTTEKST	; top line
	ld	a," "
	ld	(leeglijnend2),a
	ld	hl,4*80
	ld	de,80
	exx
	ld	b,disopaantlijn
_initdis1	exx
	ld	bc,leeglijndb-1
	call	PRINTTEKST	; each time an empty line with stripes
	add	hl,de
	exx
	djnz	_initdis1
	exx
	inc	bc	;=ld bc,downline
	call	PRINTTEKST	; bottom line
	xor	a
	ld	(leeglijnend2),a
	ld	a,disopaantlijn
	ld	de,disbuffer
_initdis2	ld	bc,lglnlngh	; fill buffer with empty lines
	ld	hl,leeglijndb
	ldir
	dec	a
	jp	nz,_initdis2	;quick jump

	ld	hl,disoptabpc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	(reg_pcvdis),de

disameenscherm	ld	b,disopaantlijn	;creates a screen
	ld	hl,disbuffer
	ld	(waarbuffer),hl
	ld	hl,disoptabpc
_disam1scherm1	push	bc
	ld	de,(reg_pcvdis)
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	push	hl
	ld	hl,(waarbuffer)
	push	hl
	call	disameenlijn
	pop	hl
	ld	bc,lglnlngh
	add	hl,bc
	ld	(waarbuffer),hl
	pop	hl
	pop	bc
	djnz	_disam1scherm1
	ld	a,(aanduiddisam)
	or	a
	jr	z,_disam1scherm3
	ld	b,a
	ld	hl,disopwrmnomic-1+disbuffer-lglnlngh
	ld	de,lglnlngh
_disam1scherm2	add	hl,de
	djnz	_disam1scherm2
	ld	a,">"
	ld	(hl),a

_disam1scherm3	ld	a,(aanduidtrace)
	call	respcbalk
	call	ispconscr
;
; the routine puts all the lines on the screen
distoscr	ld	hl,80*4+1
	ld	bc,disbuffer
	exx
	ld	b,disopaantlijn
_toscr	exx
	ld	de,80
	exx
_toscrloop	exx
	call	PRINTTEKST
	inc	bc
	add	hl,de
	exx
	djnz	_toscrloop
	ret

ispconscr	xor	a
	ld	(aanduidtrace),a
	ld	de,(reg_pc)
	ld	hl,disoptabpc
	ld	b,disopaantlijn

ispconscr1	ld	a,(hl)
	inc	hl
	cp	e
	jr	z,ispconscr3	;jr not usually performed w: 7cks
	inc	hl	;(is the fastest)
	djnz	ispconscr1
	ret
ispconscr3	ld	a,(hl)
	inc	hl
	cp	d
	jr	z,ispconscr2
	djnz	ispconscr1
	ret
ispconscr2	ld	a,disopaantlijn+1
	sub	b
	ld	(aanduidtrace),a
	ret

aanduiddisam	db	1
aanduidtrace	db	1

shiftpushed	in	a,(#aa)
	and	#f0
	or	%0110
	out	(#aa),a
	in	a,(#a9)
	rra
	ret

ctrlpushed	call	shiftpushed
	rra
	ret

bigupdwn	ld	hl,(disoptabpc)
	add	hl,de
	ld	(reg_pcvdis),hl
	ld	b,5
bigupdwn1	ld	hl,(bufferhoofdpr)
	ld	(waarbuffer),hl
	push	bc
	call	vulbuffer
	call	disassem
	pop	bc
	djnz	bigupdwn1

updcursordis	call	disameenscherm
updcursoradr	ld	a,(aanduiddisam)
	or	a
	ret	z
getadrnapijl	add	a,a
	ld	c,a
	ld	b,0
	ld	hl,disoptabpc-2
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	(cursoradres),de
	ret

routcursup	call	shiftpushed
	jr	c,routcursup0
	ld	de,-220
	jr	bigupdwn
routcursup0
	call	ctrlpushed
	jr	c,routcursup1
	ld	hl,(disoptabpc)
	dec	hl
	ld	(reg_pcvdis),hl
	jr	updcursordis

routcursup1	ld	a,(aanduiddisam)
	or	a
	jp	z,pijlonscrback
	dec	a
	jr	z,eenlijnup
	ld	(aanduiddisam),a
	ld	b,a
	ld	hl,disopwrmnomic-1+disbuffer-lglnlngh
	ld	de,lglnlngh
routcursup2	add	hl,de
	djnz	routcursup2
	ld	a,">"
	ld	(hl),a
	add	hl,de
	ld	a,32
	ld	(hl),a
	call	distoscr
	jr	updcursoradr

eenlijnup	ld	hl,(disoptabpc)
	ld	de,20
	call	hlgelijkde
	ld	de,-20
	jr	c,eenlijnup2
	add	hl,de
	ld	(reg_pcvdis),hl
eenlijnup1	ld	(eenlijnuptmp),hl
	call	eenlijnup0	; hl=hl+ lengthcode on (hl)
	ld	de,(disoptabpc)
	call	hlgelijkde
	jr	c,eenlijnup1
eenlijnup4	ld	hl,(eenlijnuptmp)
	ld	(reg_pcvdis),hl
	jr	updcursordis

eenlijnup2	add	hl,de
	ld	(reg_pcvdis),hl
eenlijnup3	ld	(eenlijnuptmp),hl
	call	eenlijnup0
	ld	de,400
	call	hlgelijkde
	jr	nc,eenlijnup3
	ld	de,(disoptabpc)
	call	hlgelijkde
	jr	c,eenlijnup3
	jr	eenlijnup4

eenlijnuptmp	dw	0
eenlijnup0	call	vulbuffer
	ld	hl,(bufferhoofdpr)
	ld	(waarbuffer),hl
	call	disassem
	ld	hl,(reg_pcvdis)
	ret

routcursdown	call	shiftpushed
	jr	c,routcursdown0
	ld	de,180
	jp	bigupdwn
routcursdown0
	call	ctrlpushed
	jr	c,routcursdown1
	ld	hl,(disoptabpc)
	inc	hl
	ld	(reg_pcvdis),hl
	jp	updcursordis

routcursdown1	ld	a,(aanduiddisam)
	or	a
	jp	z,pijlonscrback
	inc	a
	cp	disopaantlijn+1
	jr	z,eenlijndown
	ld	(aanduiddisam),a
	dec	a
	ld	b,a
	ld	hl,disopwrmnomic-1+disbuffer-lglnlngh
	ld	de,lglnlngh
routcursdown2	add	hl,de
	djnz	routcursdown2
	ld	a,32
	ld	(hl),a
	add	hl,de
	ld	a,">"
	ld	(hl),a
	call	distoscr
	jp	updcursoradr

; ALLOW SCREEN TO GO AHEAD ONE INSTRUCTION
eenlijndown	ld	hl,disbuffer+lglnlngh
	ld	de,disbuffer
	ld	bc,(disopaantlijn-1)*lglnlngh
	ldir
	ld	hl,disoptabpc+2
	ld	de,disoptabpc
	ld	bc,disopaantlijn*2-2
	ldir
	ld	hl,(reg_pcvdis)
	ld	(disoptabpc+disopaantlijn*2-2),hl
	ld	hl,disbuffer+(disopaantlijn-2)*lglnlngh+disopwrmnomic-1
	ld	a," "
	ld	(hl),a
	ld	hl,disbuffer+(disopaantlijn-1)*lglnlngh
	ld	(waarbuffer),hl
	call	disameenlijn
	ld	hl,disbuffer+(disopaantlijn-1)*lglnlngh+disopwrmnomic-1
	ld	a,">"
	ld	(hl),a

	ld	a,(aanduidtrace)
	or	a
	jr	z,eenlijndown1
	call	respcbalk
	ld	a,(aanduidtrace)
	dec	a
	ld	(aanduidtrace),a
	jr	eenlijndown5

eenlijndown1	ld	hl,(reg_pc)
	ld	de,(disoptabpc+disopaantlijn*2-2)
	call	hlgelijkde
	jr	nz,eenlijndown5
	ld	a,disopaantlijn
	ld	(aanduidtrace),a
eenlijndown5	call	distoscr
	jp	updcursoradr

routhere	ld	a,(aanduiddisam)
	or	a
	call	z,pijlonscrback
	call	adresnapijl
	ld	(reg_pc),de
	call	ispconscr
	jp	ispconmon

routandback	ld	a,(aanduidtrace)
	or	a
	jr	nz,routandback5
	ld	a,1
	ld	(aanduiddisam),a
	ld	hl,(reg_pc)
	ld	(reg_pcvdis),hl
	jp	disameenscherm

routandback5	ld	a,(aanduiddisam)
	ld	b,a
	ld	hl,disopwrmnomic-1+disbuffer-lglnlngh
	ld	de,lglnlngh
routandback6	add	hl,de
	djnz	routandback6
	ld	a," "
	ld	(hl),a
	ld	a,(aanduidtrace)
	ld	(aanduiddisam),a
	ld	b,a
	ld	hl,disopwrmnomic-1+disbuffer-lglnlngh
	ld	de,lglnlngh
routandback7	add	hl,de
	djnz	routandback7
	ld	a,">"
	ld	(hl),a
	jp	distoscr

setpcbalk	add	a,3	; in: a contains y-coordinate for bar
	ld	l,a
	push	hl
	ld	h,disopwradres
	ld	b,6
	call	SETBALK
	pop	hl
	push	hl
	ld	h,disopwrmnomic-1
	ld	b,20
	call	SETBALK
	pop	hl
	ld	h,disopwrhex
	ld	b,10
	jp	SETBALK

respcbalk	add	a,3
	ld	l,a
	ld	h,0
	ld	b,39
	jp	WISBALK

; create a line in the disassembler frames
; waarbuffer must point to the beginning of the line
; adjusting the address tab must be done outside this route.
disameenlijn	call	vulbuffer	;provides places 4 bytes
	ld	de,(waarbuffer)
	ld	hl,leeglijndb
	ld	bc,lglnlngh-1	; number of characters per empty line
	ldir
	ld	hl,(waarbuffer)	;faster than push/pop
	push	hl
	;add hl,disopwraddress
	inc	hl

	ld	(waarbuffer),hl
	ld	hl,(reg_pcvdis)
	call	hltobuffer
	call	ishlbreakpoint
	ld	a,32
	jr	c,_eenlijn1
	ld	a,"$"

_eenlijn1	pop	hl
	push	hl
	ld	de,disopwrmnomic-2
	add	hl,de
	ld	(hl),a
	inc	hl
	inc	hl
	ld	(waarbuffer),hl
	call	disassem
	pop	hl
	ld	de,disopwrhex
	add	hl,de
	ld	(waarbuffer),hl
	ld	hl,codebuffer	;the four-byte buffer
	ld	a,(lenghtcode)
	ld	b,a
_eenlijn2	ld	a,(hl)
	call	atobuffer
	inc	hl
	djnz	_eenlijn2
	ret

vulbuffer	ld	hl,(reg_pcvdis)
vulbuffer1	ld	bc,4
	call	GETFROMRAM
	ld	hl,(bufferhoofdpr)
	ld	de,codebuffer
	ldi
	ldi
	ldi
	ldi
	ret
; this is the real routine
disassem	LD	HL,codebuffer
	LD	(waarbufcode),HL
	LD	HL,(waarbuffer)
	LD	(orgwaarbuf),HL
	XOR	A
	LD	(reedsixydebc),A
	LD	(hlixiy),A
	LD	(usedix),A
	INC	A
	LD	(lenghtcode),A
	CALL	disassem1
	LD	A,(lenghtcode)
	ld	d,0
	ld	e,a
	ld	hl,(reg_pcvdis)
	add	hl,de
	ld	(reg_pcvdis),hl
	ret

disassem1	call	leescodebyte
	bit	7,a
	jp	nz,disassemb71
	and	%01000000
	jp	z,disassemb7060
	ld	hl,txtuitz7061	;disassemb7061
	call	uitzondering
	ld	hl,txtldnormaal
	jp	codtxttobuf

txtldnormaal	DB	"LD ",9,",",1+128

disassemb7060	LD	HL,txtuitz7060
	CALL	uitzondering
	LD	HL,tabel7060
tabelcontrol	CALL	leescodebyte
	AND	#F
tabelcontrol1	ADD	A,A
tabelcontrol2	LD	B,0
	LD	C,A
	ADD	HL,BC
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	JP	codtxttobuf

disassemb71	CP	#CB
	JP	Z,disassemCB
	CP	#ED
	JP	Z,disassemED
	CP	#DD
	JP	Z,disassemIX
	CP	#FD
	JP	Z,disassemIY
	AND	%01000000
	JR	Z,disassemb7160
	LD	HL,txtuitz7161	;disassemb7161
	CALL	uitzondering
	LD	HL,tabel7161
	JP	tabelcontrol

disassemb7160	LD	HL,txtadd
	JP	codtxttobuf

txtadd	DB	5,1+128

alixiy	LD	A,(hlixiy)
	OR	A
	RET	Z
	POP	HL
notexist	LD	DE,(orgwaarbuf)
	LD	A,1
	LD	(lenghtcode),A
	LD	HL,txtdb
	LD	BC,18
	LDIR
	; code needed for txttobuffer
	xor	a	; reset byte or 16bit is inserted
	ld	(hlopslag),a

	LD	HL,(orgwaarbuf)
	LD	DE,3
	ADD	HL,DE
	LD	(waarbuffer),HL
	LD	A,(codebuffer)
	JP	atobuffer

txtdb	DB	"DB                "

disassemCB	LD	A,(hlixiy)
	OR	A
	JR	Z,disassemCB0
	LD	HL,(waarbufcode)
	INC	HL
	LD	(waarbufcode),HL
disassemCB0	CALL	verhoogenlees
disassemcb2	AND	%11000000
	JR	NZ,disassemcb3
	LD	HL,txtrlc
	JR	disassemcb6
disassemcb3	CP	%01000000
	JR	NZ,disassemcb4
	LD	HL,txtbit
	JR	disassemcb6
disassemcb4	CP	%10000000
	JR	NZ,disassemcb5
	LD	HL,txtres
	JR	disassemcb6
disassemcb5	LD	HL,txtset
disassemcb6	JP	codtxttobuf


txtrlc	db	10," ",1+128
txtbit	db	"BIT ",11,",",1+128
txtres	db	"RES ",11,",",1+128
txtset	db	"SET ",11,",",1+128


disassemED	CALL	alixiy
	CALL	verhoogenlees
	LD	HL,txtuitzED
	CALL	uitzondering
	CALL	leescodebyte
	AND	%11000000
	CP	%01000000
	JR	Z,disassemED01
	CALL	leescodebyte
	AND	%11100100
	CP	%10100000
	JR	Z,disassemED10
	JP	notexist

disassemED01	LD	HL,tabel7061
	JP	tabelcontrol

disassemED10	LD	HL,txtin
	JP	codtxttobuf

txtin	DB	19,20+128

disassemIX	CALL	alixiy
	LD	A,4
disassemIX1	LD	(hlixiy),A
	CALL	verhoogleesbyte
	JP	disassem1
disassemIY	CALL	alixiy
	LD	A,6
	JR	disassemIX1

; from hl text to buffer
codtxttobuf	LD	A,(HL)
	AND	127
	CP	32
	JR	NC,stcdtxttobuf1
	LD	(bewaarhl),HL
	CALL	stuurcode
	LD	HL,(bewaarhl)
	JR	stcdtxttobuf2
stcdtxttobuf1	CALL	ascitobuffer
stcdtxttobuf2	LD	A,(HL)
	BIT	7,A
	JP	NZ,all_ok_met_IXIY
	INC	HL
	JR	codtxttobuf
bewaarhl	dw	0

all_ok_met_IXIY	LD	A,(hlixiy)
	OR	A
	RET	Z
	LD	A,(usedix)
	OR	A
	RET	NZ
	JP	notexist

; input a=control code
stuurcode	LD	HL,stuurcodtab-2
stuurcode1	ADD	A,A
	LD	E,A
	LD	D,0
	ADD	HL,DE
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	PUSH	BC
	JP	leescodebyte


stuurcodtab	DW	rs1bit02ixpv	;CONTROL CODE 1
	DW	rsbit35	;CONTROL CODE 2
	DW	rp1bit45af	;CONTROL CODE 3
	DW	rp1bit45	;CONTROL CODE 4
	DW	addbit35	;
	DW	ntobuffer	;6
	DW	jradres
	DW	jpadres	;8
	DW	rs1bit35ixpv
	DW	rlcrout	;10
	DW	bit35nr
	DW	codeonbestaand	;12
	DW	bcdeofadres
	DW	aofhlixiy	;14
	DW	hlixiyadd
	DW	condibit35	;16
	DW	addaen
	DW	ldspixy	;18
	DW	ldcpinout
	DW	idirdr	;20
	DW	rstrout

; set single register name determined by bit 3-5 in A to buffer
; ALSO BEWARE FOR IX
rsbit35	LD	E,A
	AND	%00111000
	CP	%00110000
	JR	Z,rsbit35ixpv1
	LD	A,E
	RRA
	RRA
	JR	rsbit02v

;set single register name determined by bit 0-2 in A to buffer
;AND CONVERT H,L TO IXH,IYL ETC.
rsbit02	SLA	A
rsbit02v	AND	%00001110
	LD	D,0
	LD	E,A
	LD	HL,rstxt
	ADD	HL,DE
	LD	A,(hlixiy)
	OR	A
	JP	Z,regtobuffer
	LD	A,E
	CP	%00001000
	JR	Z,rsbit02ixh
	CP	%00001010
	JR	Z,rsbit02ixh
	JP	regtobuffer
rsbit02ixh	PUSH	HL
	LD	A,%100
	CALL	rp1bit351
	POP	HL
	JP	regtobuffer

; set register bit 0-2 in A to buffer with (HL) -> (IX/Y+d)
rs1bit02ixpv	LD	E,A
	AND	%00000111
	CP	%00000110
	LD	A,E
	JR	NZ,rsbit02
rsbit35ixpv1	LD	A,"("
	CALL	ascitobuffer
	LD	A,%00100000
	CALL	rp1bit45
	LD	A,(hlixiy)
	OR	A
	JR	Z,rsbit35ixpv2

	PUSH	BC
	LD	A,(derdebyte)
	BIT	7,A
	LD	B,#2B
	JR	Z,J678C
	LD	B,#2D
	NEG
J678C:	LD	C,A
	LD	A,B
	CALL	ascitobuffer
	LD	A,(lenghtcode)
	INC	A
	LD	(lenghtcode),A
	LD	A,C
	CALL	atobuffer
	POP	BC
	LD	HL,(bewaarhl)
	INC	HL
	INC	HL
	LD	A,(HL)
	CP	#86
	JR	NZ,rsbit35ixpv2
	CALL	verhoogleesbyte
	LD	HL,lenghtcode
	DEC	(HL)

rsbit35ixpv2	LD	A,")"
	JP	ascitobuffer

; set register bit 3-5 in A to buffer with (HL) -> (IX/Y+d)
rs1bit35ixpv	LD	E,A
	AND	%00111000
	CP	%00110000
	LD	A,E
	jp	nz,rsbit35
	JR	rsbit35ixpv1

ldspixy	LD	A,4
	JR	rp1bit351

rp1bit45af	LD	E,A
	AND	%00110000
	CP	%00110000
	LD	A,E
	JR	NZ,rp1bit45
	LD	HL,rp1txtaf
	JR	regtobuffer
; set register pair case1 name determined by bit 4-5 in A to buffer
rp1bit45	RRA
	RRA
	RRA
rp1bit351	AND	%00000110
	LD	D,0
	CP	%100
	LD	E,A
	JR	NZ,rp1bit352
	LD	A,(hlixiy)
	LD	(usedix),A
	ADD	A,E
	LD	E,A
rp1bit352	LD	HL,rp1txt
	ADD	HL,DE
regtobuffer	LD	A,(HL)
	INC	HL
	CALL	ascitobuffer
	LD	A,(HL)
	CP	0
	RET	Z

ascitobuffer	exx
	ld	hl,(waarbuffer)
	ld	(hl),a
	inc	hl
	ld	(waarbuffer),hl
	exx
	ret

hltobuffer	nop
	nop
	nop
hltobuffer1	ld	a,h
	call	atobuffer1
	ld	a,l
	jr	atobuffer1
atobuffer	nop
	nop
	nop
atobuffer1	exx
	ld	c,a
	rrca
	rrca
	rrca
	rrca
	call	atobuasci
	ld	hl,(waarbuffer)
	ld	(hl),a
	inc	hl
	ld	a,c
	call	atobuasci
	ld	(hl),a
	inc	hl
	ld	(waarbuffer),hl
	exx
	ret
atobuasci	and	#0f
	add	a,"0"
	cp	"9"+1
	ret	c
	add	a,"A"-"9"-1
	ret

addbit35	RRA
	RRA
	RRA
	AND	%00000111
	INC	A
	LD	B,A
	LD	HL,adbitstxt
addbit351	LD	A,(HL)
	OR	A
	INC	HL
	JR	NZ,addbit351
	DJNZ	addbit351
addbit352	LD	A,(HL)
	INC	HL
	OR	A
	RET	Z
	CALL	ascitobuffer
	JR	addbit352

ntobuffer	CALL	verhoogenlees
	JP	atobuffer

jradres	CALL	ntobuffer
	LD	HL,txtpijl
	CALL	codtxttobuf
	CALL	leescodebyte
	LD	HL,(reg_pcvdis)
	INC	HL
	INC	HL
	LD	E,A
	OR	A
	LD	D,0
	JP	P,jradres1
	DEC	D
jradres1	ADD	HL,DE
	JP	hltobuffer
txtpijl	DB	" -",'>'+128

jpadres	LD	HL,lenghtcode
	INC	(HL)
	INC	(HL)
	LD	HL,(waarbufcode)
	INC	HL
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	JP	hltobuffer

rlcrout	LD	HL,rlctxt
	CALL	leescodebyte
	RRA
	RRA
	RRA
	AND	%00000111
	LD	E,A
	LD	D,0
	ADD	HL,DE
	ADD	HL,DE
	ADD	HL,DE
	LD	B,3
rlcrout1	LD	A,(HL)
	OR	A
	RET	Z
	INC	HL
	CALL	ascitobuffer
	DJNZ	rlcrout1
	RET

bit35nr	RRA
	RRA
	RRA
	AND	7
	CALL	atobuasci
	JP	ascitobuffer

codeonbestaand	POP	HL	; not sure of
	JP	notexist

bcdeofadres	LD	E,A
	AND	%00110000
	CP	%00100000
	JR	NC,bcdeofadres1
	LD	A,E
	JP	rp1bit45
bcdeofadres1	JP	jpadres

aofhlixiy	LD	E,A
	AND	%00110000
	CP	%00100000
	JR	NZ,aofhlixiy1
	LD	A,E
	JP	rp1bit45
aofhlixiy1	LD	A,"A"
	JP	ascitobuffer

hlixiyadd	LD	A,%00100000
	JP	rp1bit45

condibit35	LD	HL,condititxt
	RRA
	RRA
	AND	%00001110
	LD	D,0
	LD	E,A
	ADD	HL,DE
	JP	regtobuffer

addaen	LD	HL,tabeladdaen
	RRA
	RRA
	AND	%00001110
	JP	tabelcontrol2

calladres	CALL	verhoogenlees
	LD	L,A
	CALL	verhoogenlees
	LD	H,A
	JP	hltobuffer

ldcpinout	AND	3
	LD	HL,tabelldcpinout
	JP	tabelcontrol1

tabelldcpinout	DW	txtld1
	DW	txtld2
	DW	txtld3
	DW	txtld4

txtld1	DB	"L",'D'+128
txtld2	DB	"C",'P'+128
txtld3	DB	"I",'N'+128
txtld4	DB	"OU",'T'+128

idirdr	RRA
	RRA
	RRA
	AND	3
	LD	HL,tabelidirdr
	JP	tabelcontrol1

tabelidirdr	DW	txti1
	DW	txti2
	DW	txti3
	DW	txti4

txti1	DB	'I'+128
txti2	DB	'D'+128
txti3	DB	"I",'R'+128
txti4	DB	"D",'R'+128

rstrout	AND	%00111000
	PUSH	AF
	CALL	atobuffer
	LD	A,(msxrst)
	OR	A
	JR	NZ,rstrout2
	POP	AF
	RET
rstrout2	POP	AF
	CP	%00001000
	JR	Z,rstrout3
	CP	%00110000
	RET	NZ
	CALL	rstrout3
	LD	A,";"
	CALL	ascitobuffer
	JP	jpadres
rstrout3	LD	HL,rstroutDBtxt
	CALL	codtxttobuf
	JP	ntobuffer
rstroutDBtxt	DB	" DB",' '+128

uitzondering	CALL	leescodebyte
	LD	E,A
uitzondering1	LD	A,(HL)
	CP	E
	JR	Z,uitzondering2
	CP	#DD
	RET	Z
	INC	HL
	INC	HL
	INC	HL
	JR	uitzondering1
uitzondering2	POP	DE
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,E
	JP	codtxttobuf

leescodebyte	exx
	ld	hl,(waarbufcode)
	ld	a,(hl)
	exx
	ret
verhoogleesbyte	exx
	ld	hl,(waarbufcode)
	inc	hl
	ld	(waarbufcode),hl
	ex	af,af'
	ld	a,(lenghtcode)
	inc	a
	ld	(lenghtcode),a
	ex	af,af'
	exx
	ret
verhoogenlees	exx
	ld	hl,(waarbufcode)
	inc	hl
	ld	(waarbufcode),hl
	ld	a,(lenghtcode)
	inc	a
	ld	(lenghtcode),a
	ld	a,(hl)
	exx
	ret

rstxt	DB	"B",0
	DB	"C",0
	DB	"D",0
	DB	"E",0
	DB	"H",0
	DB	"L",0
	DB	"HL"
	DB	"A",0

rp1txt	DB	"BC"
	DB	"DE"
	DB	"HL"
	DB	"SP"
	DB	"IX"
	DB	"IY"
rp1txtaf	DB	"AF"

adbitstxt	DB	0,"ADD A,",0
	DB	"ADC A,",0
	DB	"SUB ",0
	DB	"SBC A,",0
	DB	"AND ",0
	DB	"XOR ",0
	DB	"OR ",0
	DB	"CP ",0

condititxt	DB	"NZ"
	DB	"Z",0
	DB	"NC"
	DB	"C",0
	DB	"PO"
	DB	"PE"
	DB	"P",0
	DB	"M",0

rlctxt	DB	"RLC"
	DB	"RRC"
	DB	"RL",0
	DB	"RR",0
	DB	"SLA"
	DB	"SRA"
	DB	"SLL"
	DB	"SRL"

tabeladdaen	DW	txtaddaen0
	DW	txtaddaen1
	DW	txtaddaen2
	DW	txtaddaen3
	DW	txtaddaen4
	DW	txtaddaen5
	DW	txtaddaen6
	DW	txtaddaen7

txtaddaen0	DB	"ADD A",','+128
txtaddaen1	DB	"ADC A",','+128
txtaddaen2	DB	"SUB",' '+128
txtaddaen3	DB	"SBC A",','+128
txtaddaen4	DB	"AND",' '+128
txtaddaen5	DB	"XOR",' '+128
txtaddaen6	DB	"OR",' '+128
txtaddaen7	DB	"CP",' '+128

tabel7060	DW	tnotexist
	DW	txttabel0001
	DW	txttabel0002
	DW	txttabel0003
	DW	txttabel0004
	DW	txttabel0005
	DW	txttabel0006
	DW	tnotexist
	DW	tnotexist
	DW	txttabel0009
	DW	txttabel000A
	DW	txttabel000B
	DW	txttabel0004
	DW	txttabel0005
	DW	txttabel0006
	DW	tnotexist

tabel7161	DW	txttabel1100
	DW	txttabel1101
	DW	txttabel1102
	DW	tnotexist
	DW	txttabel1104
	DW	txttabel1105
	DW	txttabel1106
	DW	txttabel1107
	DW	txttabel1100
	DW	tnotexist
	DW	txttabel1102
	DW	tnotexist
	DW	txttabel1104
	DW	txttabel110D
	DW	txttabel1106
	DW	txttabel1107

tabel7061	DW	txttabel0100
	DW	txttabel0101
	DW	txttabel0102
	DW	txttabel0103
	DW	tnotexist
	DW	tnotexist
	DW	tnotexist
	DW	tnotexist
	DW	txttabel0100
	DW	txttabel0101
	DW	txttabel010A
	DW	txttabel010B
	DW	tnotexist
	DW	tnotexist
	DW	tnotexist
	DW	tnotexist

txttabel0001	DB	"LD ",4,",",8+128
txttabel0002	DB	"LD (",13,"),",14+128
txttabel0003	DB	"INC ",4+128
txttabel0004	DB	"INC ",2+128
txttabel0005	DB	"DEC ",2+128
txttabel0006	DB	"LD ",2,",",6+128
txttabel0009	DB	"ADD ",15,",",4+128
txttabel000A	DB	"LD ",14,",","(",13,')'+128
txttabel000B	DB	"DEC ",4+128

txttabel1100	DB	"RET ",16+128
txttabel1101	DB	"POP ",3+128
txttabel1102	DB	"JP ",16,",",8+128
txttabel1104	DB	"CALL ",16,",",8+128
txttabel1105	DB	"PUSH ",3+128
txttabel1106	DB	17,6+128
txttabel1107	DB	"RST ",21+128
txttabel110D	DB	"CALL ",8+128

txttabel0100	DB	"IN ",2,",(C",')'+128
txttabel0101	DB	"OUT (C),",2+128
txttabel0102	DB	"SBC HL,",4+128
txttabel0103	DB	"LD (",8,"),",4+128
txttabel010A	DB	"ADC HL,",4+128
txttabel010B	DB	"LD ",4,",(",8,')'+128

txtuitz7061	DB	#76
	DW	txthalt
	DB	#66
	DW	txtldhhl
	DB	#6E
	DW	txtldlhl
	DB	#74
	DW	txtldhlh
	DB	#75
	DW	txtldhll
	DB	#DD
txthalt	DB	"HAL",'T'+128
txtldhhl	DB	"LD H,",1+128
txtldlhl	DB	"LD L,",1+128
txtldhlh	DB	"LD ",2,",",'H'+128
txtldhll	DB	"LD ",2,",",'L'+128


txtuitz7060	DB	#00
	DW	txtnop
	DB	#07
	DW	txtrlca
	DB	#08
	DW	txtexafaf
	DB	#0F
	DW	txtrrca
	DB	#10
	DW	txtdjnz
	DB	#17
	DW	txtrla
	DB	#18
	DW	txtjr
	DB	#1F
	DW	txtrra
	DB	#20
	DW	txtjrnz
	DB	#27
	DW	txtdaa
	DB	#28
	DW	txtjrz
	DB	#2F
	DW	txtcpl
	DB	#30
	DW	txtjrnc
	DB	#37
	DW	txtscf
	DB	#38
	DW	txtjrc
	DB	#3F
	DW	txtccf
	DB	#DD
txtnop	DB	"NO",'P'+128
txtrlca	DB	"RLC",'A'+128
txtexafaf	DB	"EX AF,AF",39+128
txtrrca	DB	"RRC",'A'+128
txtdjnz	DB	"DJNZ"," ",7+128
txtrla	DB	"RL",'A'+128
txtjr	DB	"JR ",7+128
txtrra	DB	"RR",'A'+128
txtjrnz	DB	"JR NZ,",7+128
txtdaa	DB	"DA",'A'+128
txtjrz	DB	"JR Z,",7+128
txtcpl	DB	"CP",'L'+128
txtjrnc	DB	"JR NC,",7+128
txtscf	DB	"SC",'F'+128
txtjrc	DB	"JR C,",7+128
txtccf	DB	"CC",'F'+128

txtuitz7161	DB	#C3
	DW	txtjp
	DB	#C9
	DW	txtret
	DB	#D3
	DW	txtout
	DB	#D9
	DW	txtexx
	DB	#DB
	DW	txtina
	DB	#E3
	DW	txtexsphl
	DB	#E9
	DW	txtjphl
	DB	#EB
	DW	txtexdehl
	DB	#F3
	DW	txtdi
	DB	#F9
	DW	txtldsphl
	DB	#FB
	DW	txtei
	DB	#DD

txtjp	DB	"JP ",8+128
txtret	DB	"RE",'T'+128
txtout	DB	"OUT (",6,"),",'A'+128
txtexx	DB	"EX",'X'+128
txtina	DB	"IN A,(",6,')'+128
txtexsphl	DB	"EX (SP),",4+128
txtjphl	DB	"JP (",4,')'+128
txtexdehl	DB	"EX DE,",4+128
txtdi	DB	"D",'I'+128
txtldsphl	DB	"LD SP,",18+128
txtei	DB	"E",'I'+128

txtuitzED	DB	#4C
	DW	tnotexist
	DB	#4E
	DW	tnotexist
	DB	#54
	DW	tnotexist
	DB	#55
	DW	tnotexist
	DB	#5C
	DW	tnotexist
	DB	#5D
	DW	tnotexist
	DB	#63
	DW	tnotexist
	DB	#64
	DW	tnotexist
	DB	#65
	DW	tnotexist
	DB	#66
	DW	tnotexist
	DB	#6B
	DW	tnotexist
	DB	#6C
	DW	tnotexist
	DB	#6D
	DW	tnotexist
	DB	#6E
	DW	tnotexist
	DB	#70
	DW	TINFC
	DB	#71
	DW	tnotexist
	DB	#72
	DW	TSBCHLSP
	DB	#73
	DW	TLDNNSP
	DB	#74
	DW	tnotexist
	DB	#75
	DW	tnotexist
	DB	#76
	DW	tnotexist
	DB	#77
	DW	tnotexist
	DB	#7A
	DW	TADCHLSP
	DB	#7B
	DW	TLDSPNN
	DB	#7C
	DW	tnotexist
	DB	#7D
	DW	tnotexist
	DB	#7E
	DW	tnotexist
	DB	#7F
	DW	tnotexist
	DB	#47
	DW	TLDIA
	DB	#4F
	DW	TLDRA
	DB	#57
	DW	TLDAI
	DB	#5F
	DW	TLDAR
	DB	#67
	DW	TRRD
	DB	#6F
	DW	TRLD
	DB	#44
	DW	TNEG
	DB	#45
	DW	TRETN
	DB	#46
	DW	TIM0
	DB	#4D
	DW	TRETI
	DB	#56
	DW	TIM1
	DB	#5E
	DW	TIM2
	DB	#C1
	DW	TMULAB
	DB	#C9
	DW	TMULAC
	DB	#D1
	DW	TMULAD
	DB	#D9
	DW	TMULAE
	DB	#C3
	DW	TMULHLBC
	DB	#F3
	DW	TMULHLSP
	DB	#B3
	DW	TOTIR
	DB	#BB
	DW	TOTDR
	DB	#DD

tnotexist	DB	#12+128
TINFC	DB	"IN F,(C",')'+128
TSBCHLSP	DB	"SBC HL,S",'P'+128
TLDNNSP	DB	"LD (",8,"),S",'P'+128
TADCHLSP	DB	"ADC HL,S",'P'+128
TLDSPNN	DB	"LD S","P,(",8,')'+128
TLDIA	DB	"LD I,",'A'+128
TLDRA	DB	"LD R,",'A'+128
TLDAI	DB	"LD A,",'I'+128
TLDAR	DB	"LD A,",'R'+128
TRRD	DB	"RR",'D'+128
TRLD	DB	"RL",'D'+128
TNEG	DB	"NE",'G'+128
TRETN	DB	"RET",'N'+128
TIM0	DB	"IM ",'0'+128
TRETI	DB	"RET",'I'+128
TIM1	DB	"IM ",'1'+128
TIM2	DB	"IM ",'2'+128
TMULAB	DB	"MULUB A,",'B'+128
TMULAC	DB	"MULUB A,",'C'+128
TMULAD	DB	"MULUB A,",'D'+128
TMULAE	DB	"MULUB A,",'E'+128
TMULHLBC	DB	"MULUW HL,B",'C'+128
TMULHLSP	DB	"MULUW HL,S",'P'+128
TOTIR	DB	"OTI",'R'+128
TOTDR	DB	"OTD",'R'+128

orgwaarbuf	DW	0
reedsixydebc	DB	0
hlixiy	DB	0
usedix	DB	0
waarbufcode	DW	0
lenghtcode	DB	0
msxrst	DB	4
codebuffer	DB	0
	DB	0
derdebyte	DB	0
	DB	0
waarbuffer	DW	buffer
buffer	DS	30

routtrace	ld	hl,(reg_pc)
	call	vulbuffer1
	ld	a,(codebuffer)
	or	a
	jp	z,regpcen1
tracecallcc	cp	#cd
	jr	z,tracecall
	ld	c,a
	and	%11000111
	cp	%11000100
	ld	a,c
	jp	nz,tracerest
	call	conditvoldaan
	jp	nz,regpcen3
tracecall	ld	de,(reg_pc)
	inc	de
	inc	de
	inc	de
	call	_push
	jp	tracejp
tracerest	and	%11000111
	cp	%11000111
	ld	a,c
	jp	nz,routstep1
	and	%00111000
	ld	h,0
	ld	l,a
	ld	de,(reg_pc)
	ld	(reg_pc),hl
	inc	de
	call	_push
	jp	regpcen0

routstep	ld	hl,(reg_pc)
	call	vulbuffer1
	ld	a,(codebuffer)
	or	a
	jp	z,regpcen1

routstep1	ld	hl,codebuffer
	ld	(waarbufcode),hl
	ld	hl,(bufferhoofdpr)
	ld	(waarbuffer),hl
	ld	(orgwaarbuf),hl
	xor	a
	ld	(reedsixydebc),a
	ld	(hlixiy),a
	ld	(usedix),a
	inc	a
	ld	(lenghtcode),a
	call	disassem1	; only serves to adjust lenght code

	ld	a,(codebuffer)
	cp	#ED
	jp	z,traceedrout
	cp	#DD
	jp	z,traceddrout
	cp	#FD
	jp	z,tracefdrout

	cp	#fb	; check for ei
	jr	nz,_tracedi
	ld	a,1
	jr	_tracedi1
_tracedi	cp	#f3	; check for di
	jr	nz,_tracehalt
	xor	a
_tracedi1	ld	(eiofdi),a
	jp	regpcen1

_tracehalt	cp	#76
	jp	nz,_tracenog
	ld	a,(eiofdi)
	or	a
	jp	nz,regpcen1
	ld	hl,80*7+20
	ld	ix,dihalttxt
	call	PUTMENU
	jp	regpcen1

dihalttxt	db	5,20,0
	db	" ",24,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,25,"  "
	db	" ",22,"  CRASH ALERT  ",22,"  "
	db	" ",26,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,27,"  "
	db	"  HALT during DI    "
	db	"                    "

_tracenog	cp	#DB
	jp	z,traceinan
	cp	#D3
	jp	z,traceoutna
	cp	#10
	jp	z,tracedjnz
	cp	#18
	jp	z,tracejr
	cp	#C3
	jp	z,tracejp
	cp	#C9
	jp	z,traceret
	ld	c,a
	and	%11000111
	cp	#C0
	ld	a,c
	jp	z,traceretcc
	and	%11100111
	cp	#20
	ld	a,c
	jp	z,tracejrcc
	and	%11000111
	cp	#C2
	ld	a,c
	jp	z,tracejpcc
	cp	#E9	; AND HERE ON JP (HL)
	jp	z,tracejphl
	and	%11001111
	cp	#C5
	jp	z,tracepush
	cp	#C1
	jp	z,tracepop
steprst	and	%11000111
	cp	%11000111
	ld	a,c
	jp	z,specialtrace

; Here deflect subslot registers
; only deflected are ld (hl),r;ld r,(hl);
;      ld (hl),n;ld a,(#ffff);ld (#ffff),a
tracesubslot	cp	#3A
	jr	z,tracesubslot1
	cp	#32
	jr	z,tracesubslot2
	cp	#36
	jr	z,tracesubslot4
	and	%11111000
	cp	%01110000
	ld	a,c
	jr	z,tracesubslot5
	and	%11000111
	cp	%01000110
	ld	a,c
	jp	nz,traceexecute

	call	hlwelffff	;LD r,(HL)
	ld	b,c
	call	get8bit
	ld	b,1
	jr	ldwffff

tracesubslot2	ld	b,1	;LD (#FFFF),A
tracesubslot3	ld	hl,codebuffer+1
	ld	a,(hl)
	inc	hl
	and	(hl)
	inc	a
	ld	a,c
	jp	nz,traceexecute
	ld	a,%1110
	call	get8bit1
	dec	b
	ld	b,3
	jr	z,ldffffw
	jr	ldwffff
tracesubslot1	ld	b,0	;LD A,(#FFFF)
	jr	tracesubslot3
tracesubslot4	call	hlwelffff	;LD (HL),n
	ld	a,(codebuffer+1)
	ld	b,2
	jr	ldffffw
tracesubslot5	call	hlwelffff	;LD (HL),r
	rla
	call	get8bit0
	ld	b,1

ldffffw	push	af	; input a contains value
	call	bepaalsubslreg
	jr	nc,writeffffram	; regular ram (not expanded)
	pop	af
	ld	(hl),a
	rlca
	rlca
	ld	e,a
	call	GETPAGES
	ld	b,4
_ldffffw	ld	a,(hl)
	and	#3
	cp	c	; C loaded by determinesubslreg :)
	jr	nz,_ldffffw2
	ld	a,e
	and	#0c
	ld	d,a
	ld	a,(hl)
	and	#f3
	or	d
	ld	(hl),a
_ldffffw2	rrc	e
	rrc	e
	inc	hl
	inc	hl
	djnz	_ldffffw
	jp	_outa8g

writeffffram	;for the time being********************************************
	;possibly work via traceexecute!
	pop	af
	ld	(hl),a	;should go to real ram (#ffff)
	jp	verzetpcblk

ldwffff	call	bepaalsubslreg	; input de=pointer to register
	jr	nc,leesffffram	;just ram on ffff (not expanded)
	ld	a,(hl)
	cpl
	ld	(de),a
	jp	verzetpcblk
leesffffram	;for the time being********************************************
	;work via traceexecute!
	ld	a,(hl)	;should come from ram (#ffff)
	ld	(de),a
	jp	verzetpcblk

bepaalsubslreg	ld	a,b	; b contains length code
	ld	(lenghtcode),a
	call	GETPAGES
	ld	bc,6
	add	hl,bc
	ld	a,(hl)
	and	3
	ld	c,a
	ld	hl,subslotregs
	add	hl,bc
	inc	a
	ld	b,a
	ld	a,(welkismetsub)
_bepaalsubsl	rrca
	djnz	_bepaalsubsl
	ret		;whether or not to carry

hlwelffff	ld	hl,(reg_hl)	; routine may only
	ld	a,h	; return if hl=#ffff
	and	l	; otherwise routine jumps
	inc	a	; to traceexecute
	ld	a,c	; with care a=instruction byte
	ret	z	; after stack recovery
	pop	hl
	jp	traceexecute

traceedrout	ld	a,(codebuffer+1)
	cp	#4D
	jp	z,traceret
	cp	#45
	jp	z,traceret
	cp	#57	; LD A,I
	jp	nz,traceedrout1
	ld	a,i
	ld	(reg_af+1),a
	jr	traceedrout2
traceedrout1	cp	#5F	; LD A,R
	jp	nz,traceedrout3
	ld	a,r
	ld	(reg_af+1),a
traceedrout2	push	af
	pop	hl
	ld	a,%11101001
	and	l
	ld	l,a
	ld	a,(eiofdi)
	add	a,a
	add	a,a
	or	l
	ld	l,a
	ld	a,(reg_af)
	and	1
	or	l
	ld	(reg_af),a
	jp	verzetpcblk
traceedrout3	cp	#47	; LD I,A
	jr	nz,traceedrout4
	ld	a,(reg_af+1)
	ld	i,a
	jp	verzetpcblk
traceedrout4	cp	#4F	; LD R,A
	jr	nz,traceedrout5
	jp	verzetpcblk

traceedrout5	cp	#46	; IM 0
	jp	z,verzetpcblk
	cp	#56	; IM 1
	jp	z,verzetpcblk
	cp	#5E	; IM 2
	jp	z,verzetpcblk
	cp	#BB
	jp	z,routotdr
	cp	#B3
	jp	z,routotir
	cp	#AB
	jp	z,routoutd
	cp	#A3
	jp	z,routouti
	ld	b,a
	and	%11000111
	cp	%01000000
	jp	z,traceinrc
	cp	%01000001
	jp	z,traceoutrc
	jp	traceexecute

routotir	ld	a,#A3
	ld	(codebuffer+1),a
routotir1	call	_outi
	ld	a,(reg_af)
	and	64
	jr	z,routotir1
	jr	routoutd2

routotdr	ld	a,#AB
	ld	(codebuffer+1),a
routotdr1	call	_outd
	ld	a,(reg_af)
	and	64
	jr	z,routotdr1
	jr	routoutd2

routouti	call	_outi
	jr	routoutd2
routoutd	call	_outd
routoutd2	jp	verzetpcblk

_outi	ld	a,(reg_bc)
	call	verbodouttest
	jp	nc,executesimpl
	ld	hl,(reg_hl)
	inc	hl
	jr	_outd2
_outd	ld	a,(reg_bc)
	call	verbodouttest
	jp	nc,executesimpl
	ld	hl,(reg_hl)
	dec	hl
_outd2	ld	(reg_hl),hl
	ld	a,(reg_bc+1)
	dec	a
	ld	(reg_bc+1),a
	push	af
	pop	hl
	ld	a,%01000001
	and	l
	or	2
	ld	(reg_af),a
	ret

traceinrca8	call	_ina8
traceinrcfl	or	a	;very good approximation flags!!
	push	af	;H-flag always shines at 0 at IN
	pop	hl	;to come
	ld	a,(reg_af)	;other flags are good
	and	1	;mix old carry flag over it
	or	l
	ld	l,a
	push	hl
	pop	af
	pop	bc	;b refresh
	push	bc
	jr	_continrc
traceinrcfc	call	_inmapper
	jr	traceinrcfl
traceinrc	push	bc
	ld	a,(reg_bc)
	cp	#a8
	jr	z,traceinrca8
	cp	#fc
	jr	nc,traceinrcfc
	ld	c,a
	ld	hl,(reg_af)
	push	hl
	pop	af	; keep trick c-flag
	in	a,(c)
_continrc	push	af
	call	get8bit	;in b from a,de
	pop	hl
	pop	bc
	ld	a,l
	ld	(reg_af),a
	ld	a,b
	and	%00111000	;check for IN F,(C)
	CP	%00110000	;this is indeed necessary!
	JP	Z,verzetpcblk
	ld	a,h
	ld	(de),a
	jp	verzetpcblk

traceoutrc	call	get8bit
	ld	b,a
	ld	a,(reg_bc)
	jp	_outrout

;IN  :   B CONTAINS %??XXX??? WITH XXX IS REGISTER NUMBER
;OUT :   DE= POINT TO ADDRESS OF REGISTER
;        A = CONTENTS OF THIS REGISTER
;CHANGES HL
get8bit	ld	a,b
	rra
	rra
get8bit0	and	%1110
get8bit1	ld	hl,reg8point
	ld	d,0
	ld	e,a
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	a,(de)
	ret

reg8point	dw	reg_bc+1
	dw	reg_bc
	dw	reg_de+1
	dw	reg_de
	dw	reg_hl+1
	dw	reg_hl
	dw	reg_af
	dw	reg_af+1

tracefdrout	ld	ix,reg_iy
	jr	traceddfd
traceddrout	ld	ix,reg_ix
traceddfd	ld	a,(codebuffer+1)
	cp	#E9
	jr	nz,traceddfdrout1
	ld	e,(ix+0)
	ld	d,(ix+1)
	ld	(reg_pc),de
	jp	regpcen0
traceddfdrout1	cp	#E5
	jr	nz,traceddfdrout2
	ld	e,(ix+0)
	ld	d,(ix+1)
	call	_push
	jp	verzetpcblk
traceddfdrout2	cp	#E1
	jr	nz,traceddfdrout3
	call	_pop
	ld	(ix+0),e
	ld	(ix+1),d
	jp	verzetpcblk
traceddfdrout3	jp	traceexecute

regpcen4	ld	a,4
	jr	regpcen
regpcen3	ld	a,3
	jr	regpcen
regpcen2	ld	a,2
	jr	regpcen
regpcen1	ld	a,1
	jr	regpcen
regpcen0	xor	a
regpcen	ld	(lenghtcode),a
	jp	verzetpcblk

traceinan	ld	a,(codebuffer+1)
	call	_inrout
	ld	(reg_af+1),a
	jp	verzetpcblk

traceoutna	ld	a,(reg_af+1)
	ld	b,a
	ld	a,(codebuffer+1)
	JP	_outrout

; in: a contains port number
; out: a contains port value
_inrout	cp	#a8
	jr	z,_ina8
	cp	#FC
	jr	nc,_inmapper
	ld	c,a
	in	a,(c)
	ret
_ina8	call	GETPAGES
	ld	b,4
_ina8bug	ld	a,(hl)
	rra
	rr	c
	rra
	rr	c
	inc	hl
	inc	hl
	djnz	_ina8bug
	ld	a,c
	ret
_inmapper	add	a,4
	add	a,a
	ld	d,0
	ld	e,a
	call	GETPAGES
	inc	hl
	add	hl,de
	in	a,(#ff)	;mix in highest bits
	or	(hl)
	ret

; in b contains value , a contains port
_outrout	cp	#A8
	jp	z,_outa8
	cp	#FC
	jp	nc,_outmapper
	call	verbodouttest
	jp	c,verzetpcblk
	out	(c),e
	jp	verzetpcblk

; test for banned out list
; carry if prohibited
; in a contains port to test (goes to c), b the value (goes to e)
verbodouttest	ld	c,a
	ld	e,b
	ld	hl,verbodenouts
	ld	b,(hl)
	ld	a,b
	or	a
	ret	z
verbodouttest1	inc	hl
	ld	a,(hl)
	cp	c
	jr	nz,verbodouttest2
	scf
	ret
verbodouttest2	djnz	verbodouttest1
	or	a
	ret

_outa8	ld	d,b
	call	GETPAGES
	ld	b,4

_outa81	push	bc
	ld	a,(welkismetsub)
	ld	e,a
	rr	d
	rra
	rr	d
	rla
	rla
	and	3
	ld	b,a	;a still contains prim.slot num
	inc	b
_outa82	rr	e
	djnz	_outa82
	jr	nc,_outa8f
	pop	bc	;bug fix : reload B !!
	push	bc	;bug fix
	push	de
	push	hl
	ld	d,0
	ld	e,a
	ld	hl,subslotregs
	add	hl,de
	ld	a,7
	sub	b
	rlca
	ld	b,a
	ld	a,(hl)
_outa83	rrca
	djnz	_outa83
	and	%00001100
	or	128
	or	e
	pop	hl
	pop	de
_outa8f	pop	bc
	ld	(hl),a
	inc	hl
	inc	hl
	djnz	_outa81
_outa8g	call	verzetpcblk
	ld	hl,(disoptabpc)
	ld	(reg_pcvdis),hl
	jp	disameenscherm

welkismetsub	db	0	; BIT X FOR SLOT X
subslotregs	db	0,0,0,0	;filled in at first start debugger

_outmapper	add	a,4
	add	a,a
	ld	d,0
	ld	e,a
	call	GETPAGES
	inc	hl
	add	hl,de
	ld	(hl),b
	jp	_outa8g

maxvbouts	equ	17
verbodenouts	db	7	; first byte is number of ports defined
	db	#98,#99
	db	#A9,#AA,#AB
	db	#E4,#E5
	ds	maxvbouts-7

tracepush	ld	a,c
	call	self
	call	_push
	jp	verzetpcblk

; in :the data
_push	ld	hl,(bufferhoofdpr)
	ld	(hl),e
	inc	hl
	ld	(hl),d
	ld	hl,(reg_sp)
	dec	hl
	dec	hl
	ld	(reg_sp),hl
	ex	de,hl	;target address in DE
	ld	bc,2
	jp	PUTTORAM

tracepop	ld	a,c
	push	af
	call	_pop
	pop	af
	push	de
	call	self
	pop	de
	ld	(hl),e
	inc	hl
	ld	(hl),d
	jp	verzetpcblk

; out: DE=popped value
_pop	ld	hl,(reg_sp)
	ld	bc,2
	call	GETFROMRAM
	ld	hl,(reg_sp)
	inc	hl
	inc	hl
	ld	(reg_sp),hl
	ld	hl,(bufferhoofdpr)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ret

;*********************************************is not being used !
;traceexsphl      ld      hl,(reg_hl)
;                 call    _exsphl
;                 ld      (reg_hl),hl
;                 jp      verzetpcblk
;
;; in hl contains data to be exchanged
;; out hl contains change
;_exsphl          push    hl
;                 call    _pop
;                 pop     hl
;                 ex      de,hl
;                 push    hl
;                 call    _push
;                 pop     hl
;                 ret

tracedjnz	ld	a,(reg_bc+1)
	dec	a
	ld	(reg_bc+1),a
	jr	nz,tracejr
	jp	regpcen2

tracejrcc	ld	a,(codebuffer)
	and	%00011000
	call	conditvoldaan
	jp	nz,regpcen2
tracejr	ld	a,(codebuffer+1)
	ld	hl,(reg_pc)
	ld	d,0
	bit	7,a
	jr	z,_tracejr
	dec	d
_tracejr	ld	e,a
	add	hl,de
	inc	hl
	inc	hl
	jr	tracejp1

tracejpcc	ld	a,(codebuffer)
	call	conditvoldaan
	jp	nz,regpcen3
tracejp	ld	hl,(codebuffer+1)
	jr	tracejp1

tracejphl	ld	hl,(reg_hl)

tracejp1	ld	(reg_pc),hl
	ld	a,(monlinkyesno)
	cp	2
	jr	nz,tracejp2
	ld	(monadres),hl
tracejp2	jp	regpcen0

traceretcc	ld	a,(codebuffer)
	call	conditvoldaan
	jp	nz,regpcen1
traceret	call	_pop
	ld	hl,reg_pc
	ld	(hl),e
	inc	hl
	ld	(hl),d
	jp	regpcen0
;
; Routine that should check if a
; condition is met. If so then will
; Z-flag =0 else nz
; in: a contains bit 3,4,5
; (SIMPLE WITH AND #38)
;
conditvoldaan	ld	hl,condittab
	rra
	rra
	and	#0e
	ld	d,0
	ld	e,a
	add	hl,de
	ld	a,(reg_af)
	and	(hl)
	inc	hl
	xor	(hl)
	ret
condittab	db	%01000000,%00000000	;NZ
	db	%01000000,%01000000	;Z
	db	%00000001,%00000000	;NC
	db	%00000001,%00000001	;C
	db	%00000100,%00000000	;PO
	db	%00000100,%00000100	;PE
	db	%10000000,%00000000	;P
	db	%10000000,%10000000	;M

traceexecute	call	executesimpl
verzetpcblk	ld	a,(lenghtcode)
	ld	b,0
	ld	c,a
	ld	hl,(reg_pc)
	add	hl,bc
	ld	(reg_pc),hl
	call	ispconscr
	call	ispconmon
	ld	a,(aanduidtrace)
	or	a
	ret	nz
	ld	hl,(reg_pc)
	ld	(reg_pcvdis),hl
	ld	a,(aanduiddisam)
	or	a
	jr	z,verzetpcblk2
	call	adresnapijl
	xor	a
	ld	(aanduiddisam),a
verzetpcblk2	call	disameenscherm
	ld	b,disopaantlijn
	ld	de,(verzetpc3)
	ld	ix,disoptabpc
verzetpcblk3	ld	l,(ix+0)
	ld	h,(ix+1)
	inc	ix
	inc	ix
	call	hlgelijkde
	jr	z,verzetpcblk5
	djnz	verzetpcblk3
	ret
verzetpcblk5	ld	a,disopaantlijn+1
	sub	b
	ld	(aanduiddisam),a
	ld	b,a
	ld	hl,disopwrmnomic-1+disbuffer-lglnlngh
	ld	de,lglnlngh
verzetpcblk6	add	hl,de
	djnz	verzetpcblk6
	ld	a,">"
	ld	(hl),a
	jp	distoscr

pijlonscrback	ld	hl,(verzetpc2)
	ld	(reg_pcvdis),hl
	ld	a,(verzetpc1)
	ld	(aanduiddisam),a
	jp	disameenscherm

; DE contains address behind arrow, it must be on screen
adresnapijl	ld	a,(aanduiddisam)
	call	getadrnapijl
	ld	a,(aanduiddisam)
	ld	(verzetpc1),a
	ld	hl,(disoptabpc)
	ld	(verzetpc2),hl
	ld	(verzetpc3),de
	ret

verzetpc1	db	0
verzetpc2	dw	0	; start address of screen
verzetpc3	dw	0	; address behind arrow

reg_ir	dw	0	;lowbyte=r highbyte=i

reg_sp	dw	0	;is filled in at init
reg_iy	dw	0
reg_ix	dw	0
reg_bcac	dw	#4947
reg_deac	dw	#2046
reg_hlac	dw	0
reg_afac	dw	#2042
reg_bc	dw	#5820
reg_de	dw	#4953
reg_hl	dw	#554E
reg_af	dw	#4D53
eiofdi	db	0

; routine that performs non-address-bound
; instructions with the exception of certain ones such as halt,ei,di
; ensures correct setting of af;bc;de;hl+alternate registers
; +ix,iy+sp
uitvoeradres	DB	0,0,0,0
executesimpl	ld	hl,0
	ld	(uitvoeradres),hl
	ld	(uitvoeradres+2),hl
	ld	a,(lenghtcode)
	ld	b,0
	ld	c,a
	ld	de,uitvoeradres
	ld	hl,codebuffer
	ldir
	call	GETREGISTERS
	ex	de,hl
	ld	hl,reg_sp
	ld	bc,eiofdi-reg_sp+1
	ldir
	ld	hl,uitvoeradres
	call	STARTPROGRAM
	ld	de,reg_sp
	ld	bc,eiofdi-reg_sp+1
	ldir
	ret
; in a data recognition in bit 4-5
; out : de contains data reg_??, hl contains place reg_??
; change hl,de,c,af
self	rra
	rra
	rra
	and	6
	ld	d,0
	ld	e,a
	ld	hl,reg16point
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)	; de contains address in regpair
	dec	hl
	ret
reg16point	dw	reg_bc
	dw	reg_de
	dw	reg_hl
	dw	reg_af

CHRGET	ld	a,1
	ld	(CURSORONOFF),a
	ld	a,27
	ld	(CURSORY_X),a
	push	bc
	push	de
	push	hl
	push	ix
	call	GETKEY
	pop	ix
	pop	hl
	pop	de
	pop	bc
	ret

labelbufnr	db	0

zetlabbufA	ld	(labelbufnr),a
	add	a,a
	push	hl
	ld	hl,labbufsegs
	add	a,l
	ld	l,a
	jr	nc,_zetlabbufA
	inc	h
_zetlabbufA	ld	a,(hl)
	call	SETPAGE2
	dec	hl
	ld	a,(hl)
	ld	h,#80
	call	SLOT
	pop	hl
	ret

writelabbufDE	ld	(de),a
	inc	de
	bit	6,d
	ret	z
	push	af
	push	hl
	ld	hl,labelbufnr
	ld	a,(labbufsegs)
	cp	(hl)
	jr	z,_writelabbuf
	inc	(hl)
	ld	a,(hl)
	call	zetlabbufA
_writelabbuf	pop	hl
	pop	af
	res	6,d
	ret

leeslabbufDE	ld	a,(de)
	inc	de
	bit	6,d
	ret	z
	push	af
	push	hl
	ld	hl,labelbufnr
	ld	a,(labbufsegs)
	cp	(hl)
	jr	z,_leeslabbuf
	inc	(hl)
	ld	a,(hl)
	call	zetlabbufA
_leeslabbuf	pop	hl
	pop	af
	res	6,d
	ret

labbufsegs	ds	9

zet_start_end	call	zetgrootkot
	ld	hl,13*80+21
	ld	bc,txt_start
	call	PRINTTEKST
	ld	hl,14*80+21
	ld	bc,txt_eind
	jp	PRINTTEKST

zetgrootkot	ld	hl,10*80+19
	ld	de,grootkotdata
	jp	PRINTBLOKKLE

zetkader	ld	hl,11*80+19
	push	hl
	LD	BC,3*80-2*19
	CALL	screen2buf
	pop	hl
	ld	de,kaderdata
	jp	PRINTBLOKKLE

kadermettxtBC	push	bc
	ld	hl,10*80+19
	push	hl
	ld	bc,5*80-2*19
	CALL	screen2buf
	pop	hl
	ld	de,mediumkotdata
	call	PRINTBLOKKLE
	pop	hl
	ld	de,11*80+32
	ld	bc,16
	jp	RAMTOVRAM

txt_start	db	"Start:",0
txt_eind	db	"End:",0

input_duo_adr	ld	hl,13*80+28
	call	input_adres
	ret	c
_input_duo	push	de
	ld	hl,14*80+28
	call	input_adres
	pop	hl
	ret	c
	call	hlgelijkde
	ccf
	ret	nc
	ex	de,hl
	jr	_input_duo

input_adres	ld	de,kbuf
input_adresDE	ld	(saveramadres),DE
	ld	(savevramadres),HL
_inputadres	ld	hl,(savevramadres)
	ld	de,(saveramadres)
	ld	b,28
	push	de
	ld	a,#c1
	call	INPUTTEXT
	pop	hl
	ret	c
	call	BEREKENGETAL
	jr	c,_inputadres
	ret

adresinvoer	push	af
	push	de
	call	kadermettxtBC
	ld	hl,13*80+22
	ld	bc,txt_adres
	call	PRINTTEKST
	ld	hl,13*80+31
	pop	bc
	pop	af
	jr	nc,input_adres
	push	hl
	push	bc
	call	PRINTTEKST
	pop	de
	pop	hl
	jr	input_adresDE

saveramadres	dw	0
savevramadres	dw	0

grootkotdata	dw	frame1,frame2,frame2,frame2,frame2,frame3,0
mediumkotdata	dw	frame1,frame2,frame2,frame2,frame3,0
kaderdata	dw	frame1,frame2,frame3,0
frame1	db	1,24,40,23,1,25,0
frame2	db	1,22,40,0,1,22,0
frame3	db	1,26,40,23,1,27,0

screen2buf	ld	(screen2bufad),hl
	ld	(screen2bufln),bc
	ld	de,(bufferhoofdpr)
	jp	VRAMTORAM
screen2bufad	dw	0
screen2bufln	dw	0
buf2screen	ld	de,(screen2bufad)
	ld	hl,(bufferhoofdpr)
	ld	bc,(screen2bufln)
	jp	RAMTOVRAM

PUTMENU	push	hl
	push	ix
	call	PRINTMENU
	call	CHRGET
	pop	ix
	pop	hl
	push	af
	call	WISOUDMENU
	pop	af
	ret

updatesubslot	call	GETPAGES
	ld	b,4
adjustsubslot	ld	a,(hl)
	inc	hl
	inc	hl
	bit	7,a
	jr	z,noadjust
	push	hl
	push	bc
	ld	hl,subslotregs
	ld	c,a
	and	#3
	ld	e,a
	ld	d,0
	add	hl,de
	res	2,b
	inc	b
	ld	d,%11110011
	ld	a,c
	and	%1100
_adjustsub	rrc	d
	rrc	d
	rrca
	rrca
	djnz	_adjustsub
	ld	b,a
	ld	a,(hl)
	and	d
	or	b
	ld	(hl),a
	pop	bc
	pop	hl
noadjust	djnz	adjustsubslot
	ret

Main_y:	equ	7
Main_y_colors: equ Main_y+10
Mainoptie:	defb	1
ConfigLinesCount: equ 12

mainconfig	ld	(Coloradres),de
	ld	de,M_config
	ld	bc,M_configend-M_config
	ldir
	ld	hl,3*80
	ld	bc,23*80
	xor	a
	call	FILLVRAM
	ld	hl,3*10+#1800
	ld	bc,24*10	;LEAVE IT !
	xor	a
	call	FILLVRAM
	ld	hl,Main_y*80+24
	ld	de,Mainhok
	call	PRINTBLOKKLE
	ld	hl,Maintxt
	call	TEXTTOBLOK
_main_hoofd1:
	call	printmain
_main_hoofd:
	ld	iy,Mainoptie
	call	mainberbalk
	ld	b,30
	push	iy
	push	hl
	call	SETBALK
	call	GETKEY
	pop	hl
	pop	iy
	cp	escape
	jr	z,maininstback
	cp	1
	jr	z,maininstback
	cp	up
	jr	z,_main_up
	cp	down
	jr	z,_main_down
	cp	return
	jr	z,_main_space
	and	255-32
	jr	nz,_main_hoofd
	jr	_main_space
maininstback:
	call	mainberbalk
	ld	b,30
	call	WISBALK
	xor	a
	ld	hl,M_Idhex
	ret
_main_up:
	dec	(iy)
	jr	nz,_main_up1
	ld	(iy),ConfigLinesCount
_main_up1:
	ld	b,30
	call	WISBALK
	jr	_main_hoofd
_main_down:
	ld	a,(iy)
	cp	ConfigLinesCount
	jr	c,_main_down1
	ld	(iy),0
_main_down1:
	inc	(iy)
	jr	_main_up1
_main_space:
	ld	a,(iy)
	dec	a
	jr	nz,_mainsp2
	ld	hl,(Main_y+3)*80+41
	ld	iy,M_Idhex
_mainsp1_1:
	call	newid
	jp	_main_hoofd1
_mainsp2:
	dec	a
	jr	nz,_mainsp3
	ld	hl,(Main_y+4)*80+41
	ld	iy,M_Idbin
	jr	_mainsp1_1
_mainsp3:
	dec	a
	jr	nz,_mainsp4
	ld	hl,(Main_y+5)*80+39
	ld	de,M_Printerlin
	ld	b,15
	ld	a,%10000001
	call	INPUTTEXT
	jp	_main_hoofd1
_mainsp4:
	dec	a
	jr	nz,_mainsp5
	ld	hl,M_Flags
	ld a,(hl)
	xor 100b
	ld (hl),a
	jp	_main_hoofd1
_mainsp5:
	dec	a
	jr	nz,_mainsp6
	ld	hl,M_Flags
	ld a,(hl)
	xor 1000b
	ld (hl),a
	jp	_main_hoofd1
_mainsp6:
	dec	a
	jr	nz,_mainsp6_1
	ld	hl,M_Flags
	ld	a,(hl)
	xor	10b
	ld	(hl),a
	call doredefchars
	jp	_main_hoofd1
_mainsp6_1:
	dec	a
	jr	nz,_mainsp7
	ld hl,M_Flags
	ld a,(hl)
	xor 1
	ld (hl),a
	jp	_main_hoofd1
_mainsp7:
	cp	11-6
	jp	z,_mainsp11
	ld	b,a
	ld	e,0*2
	dec	a
	jr	z,_mainsp7_1
	ld	e,15*2
	dec	a
	jr	z,_mainsp7_1
	ld	e,3*2
	dec	a
	jr	z,_mainsp7_1
	ld	e,2*2
_mainsp7_1:
	ld	d,0
	ld	iy,(Coloradres)
	add	iy,de	;IY = address colors (#RB, #0G)
	ld	a,b
	add	a,Main_y_colors
	ld	l,a
	ld	h,43
	ld	(CURSORY_X),hl
	xor	a
	ld	(CURSORONOFF),a

	call	_mainsp7_3
	jr	c,_mainsp7_4
	cp	8
	jr	nc,_mainsp7_6
	ld	a,(iy)
	and	%00000111
	rlc	b
	rlc	b
	rlc	b
	rlc	b
	or	b
	ld	(iy),a
	call	_printmain1
	call	setcolor
_mainsp7_4:
	call	_mainsp7_3
	jr	c,_mainsp7_5
	cp	8
	jr	nc,_mainsp7_6
	ld	(iy+1),b
	call	_printmain1
	call	setcolor
_mainsp7_5:
	call	_mainsp7_3
	jr	c,_mainsp7_6
	cp	8
	jr	nc,_mainsp7_6
	ld	a,(iy)
	and	%01110000
	or	b
	ld	(iy),a
	call	setcolor
_mainsp7_6:
	ld	a,1
	ld	(CURSORONOFF),a
	jp	_main_hoofd1
_mainsp7_3:
	call	GETKEY
	cp	escape
	jr	z,_mainsp7_7
	cp	1
	jr	z,_mainsp7_7
	ld	hl,CURSORY_X+1
	inc	(hl)
	inc	(hl)
	sub	"0"
	ld	b,a
	ret	c
	cp	7+1
	ccf
	ret
_mainsp7_7:
	ld	a,8
	or	a
	ret
_mainsp11:
	ld hl,MainSavingTxt
	call TEXTTOBLOK
	ld	a,1
	ld	(CURSORONOFF),a
	ld	hl,M_config
	ld	de,kbuf+211
	ld	bc,M_configend-M_config
	ldir
	call	saveconfig	;already put debuggerpars in kbuf
	call	SAVECONFIG
	ld hl,MainSaveTxt
	call TEXTTOBLOK
	jp	_main_hoofd
mainberbalk:
	ld	a,(iy)
	add	a,Main_y+2
	ld	l,a
	ld	h,25
	ret
printmain:
	ld	hl,"  "
	ld	(Newidhex),hl
	ld	(Newidhex+4),hl
	ld	(Newidbin),hl
	ld	(Newidbin+4),hl

	ld	de,Newidhex
	ld	hl,(Main_y+3)*80+41
	ld	ix,M_Idhex
	call	printmainid
	ld	de,Newidbin
	ld	hl,(Main_y+4)*80+41
	ld	ix,M_Idbin
	call	printmainid
	ld	hl,(Main_y+5)*80+39
	ld	bc,M_Printerlin
	call	PRINTTEKST
	ld	hl,(Main_y+6)*80+42
	ld	a,(M_Flags)
	and 100b
	call	printonoff
	ld	hl,(Main_y+7)*80+45
	ld	a,(M_Flags)
	and 1000b	;Cursor blink on/off
	call	printonoff
	ld	hl,(Main_y+8)*80+47
	ld	a,(M_Flags)
	and 10b	;Mouse on/off
	xor 10b
	call	printonoff
	ld	hl,(Main_y+9)*80+47
	ld a,(M_Flags)
	and 1	;Initially Asm or Ascii
	call printAsmAscii
_printmain1:
	ld	ix,(Coloradres)
	ld	hl,(Main_y_colors)*80+42
	call	printcolor	;color 1 = color num 0
	ld	de,15*2
	add	ix,de
	ld	hl,(Main_y_colors+1)*80+42
	call	printcolor	;color 2 = color num 15
	ld	ix,(Coloradres)
	ld	de,3*2
	add	ix,de
	ld	hl,(Main_y_colors+2)*80+42
	call	printcolor	;color 3 = color num 3
	dec	ix
	dec	ix
	ld	hl,(Main_y_colors+3)*80+42
	jp	printcolor	;color 4 = color num 2
printmainid:
	ld	b,d
	ld	c,e
	ld	a,(ix+2)
	or	a
	jr	z,_printmaini1
	inc	de
	inc	de
	inc	de
	inc	de
_printmaini1:
	ld	a,(ix)
	ld	(de),a
	inc	de
	ld	a,(ix+1)
	or	a
	jr	z,_printmaini2
	ld	(de),a
_printmaini2:
	jp	PRINTTEKST
printcolor:
	call	SETVRAMWRITE
	ld	a,(ix)
	and	%01110000
	rrca
	rrca
	rrca
	rrca
	call	_printcolor1
	ld	a,(ix+1)
	and	7
	call	_printcolor1
	ld	a,(ix)
	and	7
_printcolor1:
	add	"0"
	out	(#98),a
	nop
	nop
	ld	a," "
	out	(#98),a
	ret
setcolor:
	ld	hl,(Coloradres)
	xor	a
	call	_setcolor1
	inc	hl
	inc	hl
	ld	a,2
	call	_setcolor1
	ld	a,3
	call	_setcolor1
	ld	de,11*2
	add	hl,de
	ld	a,15
_setcolor1:
	di
	out	(#99),a
	ld	a,16+128
	out	(#99),a
	ld	a,(hl)
	inc	hl
	out	(#9a),a
	ld	a,(hl)
	inc	hl
	out	(#9a),a
	ret
newid:
	push	iy
	push	hl
	call	printmain
	call	GETKEY
	pop	hl
	pop	iy
	cp	27
	ret	z
	cp	1
	ret	z
	cp	right
	jr	z,_newidright
	cp	left
	jr	z,_newidleft
	cp	return
	jr	z,_newidtext
	and	255-32
	jr	z,_newidtext
	jr	newid
_newidleft:
	ld	(iy+2),0
	jr	newid
_newidright:
	ld	(iy+2),1
	jr	newid
_newidtext:
	push	hl
	ld	de,(bufferhoofdpr)
	ld	b,2
	ld	a,%11000000
	push	de
	push	iy
	call	INPUTTEXT
	pop	iy
	pop	de
	pop	hl
	ret	c
	ld	a,(de)
	ld	b,a
	call	testoke
	jr	c,_newidtext
	inc	de
	ld	a,(de)
	or	a
	jr	z,_newidgoed
	call	testoke
	jr	c,_newidtext
_newidgoed:
	ld	(iy+1),a
	ld	(iy),b
	ret
testoke:
	cp	" "+1
	ret	c
	cp	34
	scf
	ret	z
	cp	"'"
	ccf
	ret	nc
	cp	"?"
	ret	c
	cp	"@"
	scf
	ret	z
	cp	"^"
	scf
	ret	z
	ccf
	ret

printonoff:
	ld	bc,txt_on
	;or	a   ;Assume flags already set at input
	jp	nz,PRINTTEKST
	ld	bc,txt_off
	jp	PRINTTEKST
txt_on	db	"on ",0
txt_off	db	"off",0

printAsmAscii:
	ld bc,AsmStr
	;and 1	;Assume flags already set at input
	jp z,PRINTTEKST
	ld bc,AsciiStr
	jp PRINTTEKST
AsmStr: db "Asm  ",0
AsciiStr: db "Ascii",0

Newidhex:	defb	"  FF  ",0
Newidbin:	defb	"  11  ",0
Coloradres:	defw	0

M_config:
M_Idhex:	defs	3
M_Idbin:	defs	3
M_Printerlin:	defs	16

; Flags:
; Bit 0: initial file type, 0=Asm, 1=Ascii
; Bit 1: rounded corners, 0=rounded, 1=square
; Bit 2: mouse, 0=off, 1=on
; Bit 3: cursor blink, 0=off, 1=on
M_Flags: db 1000b

	defb 0 ;Two unused bytes, were "mouse" and "cursor blink"
	defb 0

M_configend:

Maintxt:
	defw	(Main_y+1)*80+31
	defb	"Main configuration",0
	defw	(Main_y+3)*80+33
	defb	"Hex id:",0
	defw	(Main_y+4)*80+33
	defb	"Bin id:",0
	defw	(Main_y+5)*80+26
	defb	"Printerline:",0
	defw	(Main_y+6)*80+35
	defb	"Mouse:",0
	defw	(Main_y+7)*80+31
	defb	"Cursor blink:",0
	defw	(Main_y+8)*80+30
	defb	"Rounded corners:",0
	defw	(Main_y+9)*80+28
	defb	"Initial file type:",0
	defw	(Main_y_colors)*80+33
	defb	"Color 1:",0
	defw	(Main_y_colors+1)*80+33
	defb	"Color 2:",0
	defw	(Main_y_colors+2)*80+33
	defb	"Color 3:",0
	defw	(Main_y_colors+3)*80+33
	defb	"Color 4:",0
MainSaveTxt:
	defw	(Main_y_colors+4)*80+31
	defb	"Save configuration",0
	defw	0
MainSavingTxt:
	defw	(Main_y_colors+4)*80+31
	defb	"    Saving...     ",0
	defw	0


Mainhok:	defw	Mh1,Mh2,Mh3,Mh2,Mh2,Mh2,Mh2,Mh2
	defw	Mh2,Mh2,Mh2,Mh2,Mh2,Mh2,Mh2,Mh4,0
Mh1:	defb	1,24,30,23,1,25,0	;--------
Mh2:	defb	1,22,30,0,1,22,0	;|      |
Mh3:	defb	1,20,30,23,1,19,0	;|------|
Mh4:	defb	1,26,30,23,1,27,0	;--------

doabout:
	ld	hl,3*80
	ld	bc,23*80
	xor	a
	call	FILLVRAM
	ld	hl,3*10+#1800
	ld	bc,24*10	;LEAVE IT !
	xor	a
	call	FILLVRAM

	ld	hl,Main_y*80+18
	ld	de,aboutlines
	call	PRINTBLOKKLE
	ld	hl,abouttxt
	call	TEXTTOBLOK

	call GETKEY
	jp maininstback

abouttxt:
	defw	(Main_y+1)*80+33
	defb	"About Compass",0
	defw	(Main_y+4)*80+32
	defb	"Compass #1.2.10",0
	defw	(Main_y+6)*80+31
	defb	"2022 by Konamiman",0
	defw	(Main_y+8)*80+28
	defb	"Based on Compass #1.2.09",0
	defw	(Main_y+9)*80+26
	defb	"(C) 1998 by Compjoetania TNG",0
	defw	(Main_y+11)*80+22
	defb	"https://github.com/Konamiman/Compass",0
	defw	0

aboutlines:	defw	Ah1,Ah2,Ah3,Ah2,Ah2,Ah2,Ah2,Ah2
	defw	Ah2,Ah2,Ah2,Ah2,Ah2,Ah4,0
Ah1:	defb	1,24,42,23,1,25,0	;--------
Ah2:	defb	1,22,42,0,1,22,0	;|      |
Ah3:	defb	1,20,42,23,1,19,0	;|------|
Ah4:	defb	1,26,42,23,1,27,0	;--------

; Input: A:1=0 for rounded corners, <>0 for square corners
doredefchars:
	and 10b
	ld hl,vormen
	jr z,redefchars2
	LD	HL,vormen_sq	;change character 17-29
redefchars2:
	LD	DE,#1000+17*8
	LD	BC,13*8
	JP	RAMTOVRAM

vormen	db	#10,#10,#6c,#80,#00,#00,#00,#00	;17
	db	#00,#00,#00,#80,#6c,#10,#10,#10	;18
	db	#10,#10,#60,#80,#60,#10,#10,#10	;19
	db	#10,#10,#0c,#00,#0c,#10,#10,#10	;20
	db	#10,#28,#44,#80,#44,#28,#10,#10	;21
	db	#10,#10,#10,#10,#10,#10,#10,#10	;22
	db	#00,#00,#00,#fc,#00,#00,#00,#00	;23
	db	#00,#00,#00,#00,#0c,#10,#10,#10	;24
	db	#00,#00,#00,#80,#60,#10,#10,#10	;25
	db	#10,#10,#0c,#00,#00,#00,#00,#00	;26
	db	#10,#10,#60,#80,#00,#00,#00,#00	;27
	db	#00,#0f,#1f,#1f,#1f,#1f,#0f,#00	;28
	db	#00,#c0,#e0,#e0,#e0,#e0,#c0,#00	;29

vormen_sq	db	#10,#10,#10,#ff,#00,#00,#00,#00	;17
	db	#00,#00,#00,#ff,#10,#10,#10,#10	;18
	db	#10,#10,#10,#f0,#10,#10,#10,#10	;19
	db	#10,#10,#10,#1f,#10,#10,#10,#10	;20
	db	#10,#10,#10,#ff,#10,#10,#10,#10	;21
	db	#10,#10,#10,#10,#10,#10,#10,#10	;22
	db	#00,#00,#00,#ff,#00,#00,#00,#00	;23
	db	#00,#00,#00,#1f,#10,#10,#10,#10	;24
	db	#00,#00,#00,#f0,#10,#10,#10,#10	;25
	db	#10,#10,#10,#1f,#00,#00,#00,#00	;26
	db	#10,#10,#10,#f0,#00,#00,#00,#00	;27
	db	#00,#0f,#1f,#1f,#1f,#1f,#0f,#00	;28
	db	#00,#c0,#e0,#e0,#e0,#e0,#c0,#00	;29


; Adjust ASM and ASCII file names in the disk menu
; when changing the current source buffer
; (moved here due to exhaustion of space in main buffer)
;
; Input: E = Old source buffer number
;        D = New source buffer number
;        IX = Address of name_asm
;        IY = Address of names_asm_for_buffers-11

change_current_source_buffer:
	ld a,e
	or a
	ret z	;Nothing to do if no old buffer number
	cp d
	ret z	;Nothing to do if not actually changing the buffer number

	push de

	;First backup the current name_asm and name_asc
	;into the appropriate entries in names_asm_for_buffers
	;and names_asc_for_buffers for the old buffer.
	
	call get_buffer_name_asm_address
	push hl
	ex de,hl
	push ix
	pop hl
	ld bc,11
	ldir	;HL points now to name_asc
	ex de,hl
	pop hl
	ld bc,4*11
	add hl,bc	;Entry in asc buffer = entry in asm buffer + 11*4
	ex de,hl
	ld bc,11
	ldir

	;Now set the name from the asm and asc buffers into
	;the appropriate entries in names_asm_for_buffers
	;and names_asc_for_buffers for the new buffer.

	pop af

	call get_buffer_name_asm_address
	push hl
	push ix
	pop de
	ld bc,11
	ldir	;DE points now to name_asc
	pop hl
	ld bc,4*11
	add hl,bc	;Entry in asc buffer = entry in asm buffer + 11*4
	ld bc,11
	ldir
	ret

;Input:  A = Buffer num, 1-4
;Output: HL = Address in names_asm_for_buffers
get_buffer_name_asm_address:
	push iy
	pop hl
	ld b,a
	ld de,11
_get_buf_name_asm_address_loop:
	add hl,de
	djnz _get_buf_name_asm_address_loop
	ret

	ds	#8000-$,0
