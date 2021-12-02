;Compass v1.2.02 Monitor 08/07/1998

kbuf:	equ	#f41f	;318 byte buffer

setvramwrite:	equ	#80
fillvram:	equ	#89
printtekst:	equ	#92
printhexadec:	equ	#9e
setbalk:	equ	#a4
wisbalk:	equ	#a7
writevram:	equ	#aa
getfromram:	equ	#b0
puttoram:	equ	#b3
godiskdrive:	equ	#b6
printblok:	equ	#b9
texttoblok:	equ	#bc
inputtext:	equ	#bf
printmenu:	equ	#c5
kiesoptie:	equ	#c8
wisoudmenu:	equ	#cb
berekengetal:	equ	#d1	;for calculator (?)
memview:	equ	#d4
calculator:	equ	#d7
memory:	equ	#da
printblokkle:	equ	#dd
getkey:	equ	#fb
wiskeybuffer:	equ	#101
printini:	equ	#107
waitforkey:	equ	#10a
gotodebugger	equ	#113
maininstall:	equ	#116

msxtype:	equ	#2d	;self posted !
Cursoronoff:	equ	#fca9
Matrix:	equ	#fbe5
Escape:	equ	27
Right:	equ	28
Left:	equ	29
Up:	equ	30
Down:	equ	31
Select:	equ	24
Tab:	equ	9
Bs:	equ	8
Ctrl_a:	equ	1+"A"-"A"
Ctrl_c:	equ	1+"C"-"A"
Ctrl_d:	equ	1+"D"-"A"
Ctrl_e:	equ	1+"E"-"A"
Ctrl_f:	equ	1+"F"-"A"
Ctrl_k:	equ	1+"K"-"A"
Ctrl_n:	equ	1+"N"-"A"
Ctrl_o:	equ	1+"O"-"A"
Ctrl_p:	equ	1+"P"-"A"
Ctrl_q:	equ	1+"Q"-"A"
Ctrl_x	equ	1+"X"-"A"
Ctrl_z:	equ	1+"Z"-"A"

SETGETADRES	equ	#4012	;in debugger segment

	org	#7000

	ld	(Bufferpage0),ix
	ld	(Sp_back),sp
	ld	a,(msxtype)
	cp	3
	ld	a,0
	jr	nz,_nietturbor
	inc	a
_nietturbor	ld	(Turbor),a
	call	changefkey
	ld	a,(chaining)
	or	a
	call	nz,newchaining
	jp	monitortek

Turbor	db	0	;0=not ,1=yes
chaining	db	0	;default: unchained

back	push	af
	ld	a,(chaining)
	or	a
	jr	z,_back
	or	128
	ex	af,af'
	call	berramadres
	ld	c,l
	ld	b,h
	ex	af,af'
	call	GOdebsetgetad
_back	call	oldfkey
	pop	af
	ld	sp,(Sp_back)
	ret
Sp_back	defw	0

gobios	push	iy
	ld	iy,(#fcc0)
	call	#1c
	pop	iy
	ret

GOdebsetgetad	push	hl
	ld	hl,SETGETADRES
	jp	gotodebugger

;----- Change function keys: F1=255, F2=254, F3=253, F4=252, F5=251
changefkey	ld	hl,#f87f
	ld	de,16-1
	ld	ix,Oldfkey
	ld	bc,#0500
_changefkey1	dec	c
	ld	a,(hl)
	ld	(ix),a
	inc	ix
	ld	(hl),c
	inc	hl
	ld	a,(hl)
	ld	(ix),a
	inc	ix
	ld	(hl),0
	add	hl,de
	djnz	_changefkey1
	ret
Oldfkey	ds	10
;----- Restore function Keys
oldfkey	ld	hl,#f87f
	ld	de,16-1
	ld	ix,Oldfkey
	ld	b,5
_oldfkey1	ld	a,(ix)
	inc	ix
	ld	(hl),a
	inc	hl
	ld	a,(ix)
	inc	ix
	ld	(hl),a
	add	hl,de
	djnz	_oldfkey1
	ret
;----- Test whether B=function key, if so: C=menu num (1-5) and [NC]
testfkey	ld	a,b
	cp	251
	ret	c
	xor	a
	sub	b
	ld	c,a
	xor	a
	ret
;--------------- Menus
lastmenu	ld	a,(Lastmenu)
	ld	c,a
	jr	startmenu
menu2tomenu	push	bc
	call	wisoudmenu
	pop	bc
startmenu	push	bc
	call	wiscursor
	pop	bc
	ld	a,1
	ld	(Cursoronoff),a
	ld	b,0
	rlc	c
	ld	hl,Menus-2
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	jp	(hl)
Menus:	dw	menu1,menu2,menu3,menu4,menu5
Lastmenu:	db	1

;******************* MENU 1
Menu1optie:	defb	1
Menu1blink:	defw	#0104
Plmenu1	equ	3*80

tomenu1	call	wisoudmenu
menu1	ld	a,1
	ld	(Lastmenu),a
	ld	hl,Plmenu1
	ld	ix,Menu1
	call	printmenu
_menu1_2	ld	ix,Menu1
_menu1_1	ld	a,(Menu1optie)
	ld	c,a
	ld	hl,(Menu1blink)
	call	kiesoptie
	ld	b,a
	ld	(Menu1blink),hl
	ld	a,c
	ld	(Menu1optie),a
	ld	a,b
	cp	Left
	jr	z,_menu1_1
	ld	hl,Plmenu1
	push	bc
	call	wisoudmenu
	pop	bc
	call	testfkey
	jp	nc,startmenu
	ld	a,b
	cp	Escape
	jp	z,monitor
	cp	1
	jp	z,monitor
	cp	Right
	jp	z,menu2
	and	255-32
	jr	nz,menu1
	ld	hl,Menu1opties
	jp	menuoptie
Menu1opties	dw	!asm,!deb,!disk,!mem,!calc,!slot,!shell,!quit

!asm	ld	a,1
	jp	back
!deb	ld	a,2
	jp	back
!disk	ld	b,0
	ld	a,3
	call	godiskdrive
	jp	monitortek
!mem	call	memory
	jp	monitortek
!calc	call	calculator
	jp	monitor
!slot	call	memview
	jp	monitortek
!shell	ld	a,4
	jp	back
!quit	ld	hl,80*12+(80-26)/2
	ld	bc,Quit
	call	txttocomm
	ld	hl,12*80+(80-26)/2+6
	call	areyousure
	ld	a,0
	jp	nc,back
	call	wiscommline
	jp	monitor
Quit	db	"Quit: ",0

areyousure	ld	bc,Areyousure
	call	printtekst
	call	getkey
	or	a
	ret	z
	and	%11011111
	cp	"Y"
	ret	z
	scf
	ret
Areyousure:	db	"Are you sure ? (y/n)",0

Menu1	db	8,13,0	;height, width text, place background
	db	"Assembler    "
	db	"Debugger     "
	db	"Disk       ^D"
	db	"Memory       "
	db	"Calculator ^C"
	db	"Slot view    "
	db	"Shell        "
	db	"Quit       ^Q"

;************************ MENU 2
Menu2optie	defb	1
Menu2blink	defw	#1004
Menu2plaats	equ	3*80+14

menu2	ld	a,2
	ld	(Lastmenu),a
	ld	a,(chaining)
	ld	(oldchaining),a
	ld	hl,Menu2plaats
	ld	ix,Menu2
	call	printmenu
	call	printr800
	call	printchaining
_menu2_1	ld	ix,Menu2
	ld	a,(Menu2optie)
	ld	c,a
	ld	hl,(Menu2blink)
	call	kiesoptie
	ld	b,a
	ld	(Menu2blink),hl
	ld	a,c
	ld	(Menu2optie),a
	ld	hl,3*80+14
	call	testfkey
	jp	nc,menu2tomenu
	ld	a,b
	cp	Escape
	jr	z,to_mon
	cp	1
	jr	z,to_mon
	cp	Right
	jp	z,tomenu3
	cp	Left
	jp	z,tomenu1
	and	255-32
	jr	nz,_menu2_1
	ld	hl,Menu2opties
	jp	menuoptie
Menu2opties	dw	!address,!cpu,!chaining,!maininstall
to_mon	call	wisoudmenu
	ld	a,(chaining)
	or	a
	jp	z,monitor
	ld	hl,oldchaining
	cp	(hl)
	call	nz,newchaining
	jp	monitor

!address	ld	hl,Menu2plaats
	ld	ix,Menu2
	call	wisoudmenu
_addressstrt	ld	hl,11*80+20
	ld	de,Hokaddr
	call	printblokkle
	ld	hl,12*80+24
	ld	bc,Addresstxt
	call	printtekst
	ld	hl,12*80+33
	call	inputbin
	call	zetadres
	jp	monitor

zetadres:	;set address and monitor cursor (IN: DE=address)
	ld	h,d
	ld	a,e
	and	%00001111
	ld	(Mon_x),a
	ld	a,8
	ld	(Mon_y),a
	ld	a,e
	and	%11110000
	ld	l,a
	ld	bc,#80
	sbc	hl,bc	;is set to [NC]
	ld	(Beginadres),hl
	ret
Hokaddr	dw	H1,H2,H3,0
H1	db	1,24,40,23,1,25,0
H2	db	1,22,40,0,1,22,0
H3	db	1,26,40,23,1,27,0
Addresstxt	db	"Address:",0

!cpu	ld	a,(Turbor)
	or	a
	jp	z,_menu2_1
	ld	ix,#183
	call	gobios
	inc	a
	cp	3
	jp	nz,_cpu1
	xor	a
_cpu1	or	#80
	ld	ix,#180
	call	gobios
	call	printr800
	jp	_menu2_1

!chaining	call	changechain
	call	printchaining
	jp	_menu2_1

!changechain	call	changechain
	call	nz,newchaining
	jp	monitor
changechain	ld	a,(chaining)
	inc	a
	ld	(chaining),a
	cp	4
	ret	nz
	xor	a
	ld	(chaining),a
	ret
newchaining	call	GOdebsetgetad
	ld	e,c
	ld	d,b
	jp	zetadres

!maininstall	ld	hl,Menu2plaats
	ld	ix,Menu2
	call	wisoudmenu
	call	maininstall
	jp	monitortek

printr800	ld	a,(Turbor)
	or	a
	jr	z,_printr800_1
	ld	ix,#183
	call	gobios
_printr800_1	ld	bc,R800opties
	or	a
	jr	z,_printr800_2
	ld	bc,R800opties+10
	dec	a
	jr	z,_printr800_2
	ld	bc,R800opties+10+9
_printr800_2	ld	hl,5*80+21
	jp	printtekst
R800opties:	db	"Z80      ",0,"R800 rom",0,"R800 dram",0

printchaining	ld	a,(chaining)
	inc	a
	ld	b,a
	ld	hl,chaintekst-11
	ld	de,11
_printchain	add	hl,de
	djnz	_printchain
	ld	b,h
	ld	c,l
	ld	hl,6*80+22
	jp	printtekst

oldchaining	db	0

chaintekst	db	"ing off   ",0
	db	"ed:minimon",0
	db	"ed:PC reg.",0
	db	"ed:cursor ",0

Menu2	db	4,18,0
	db	"Address         ^A"
	db	"CPU:              "
	db	"Chain           ^X"
	db	"Main install      "

;***************** MENU 3
Menu3optie	db	1
Menu3blink	dw	#2304
Plmenu3	equ	3*80+33

tomenu3	call	wisoudmenu
menu4
menu5
menu3	ld	a,3
	ld	(Lastmenu),a
	ld	hl,Plmenu3
	ld	ix,Menu3
	call	printmenu
_menu3_2	ld	ix,Menu3
	ld	a,(Menu3optie)
	ld	c,a
	ld	hl,(Menu3blink)
	call	kiesoptie
	ld	b,a
	ld	(Menu3blink),hl
	ld	a,c
	ld	(Menu3optie),a
	ld	a,b
	cp	Right
	jr	z,_menu3_2
	ld	hl,Plmenu3
	push	bc
	call	wisoudmenu
	pop	bc
	call	testfkey
	jp	nc,startmenu
	ld	a,b
	cp	Escape
	jp	z,monitor
	cp	1
	jp	z,monitor
	cp	Left
	jp	z,menu2
;              cp      Right
;              jp      z,menu4
	and	255-32
	jr	nz,menu3
	ld	hl,Menu3opties
	jp	menuoptie
Menu3opties	dw	!search,!searchnext,!fill,!copy,!compare
	dw	!poke,!peek,!print

zethoksearch	ld	hl,9*80+20
	ld	de,Hoksearch
	jp	printblokkle
!search	call	zethoksearch
	ld	hl,Searchtext
	call	texttoblok
	ld	hl,12*80+32
	call	inputbin
	ld	(Startsearch),de
	xor	a
	ld	(Searchnext),a	;LEAVE !
_search2	ld	hl,13*80+32
	call	inputbin
	ld	(Stopsearch),de
	ex	de,hl
	ld	de,(Startsearch)
	sbc	hl,de	;[NC] is set
	jr	c,_search2	;Stop < Start
	xor	a
	ld	(kbuf),a
_search1	ld	hl,14*80+32
	ld	bc,25
	xor	a
	call	fillvram	;LEAVE IT !
	ld	hl,14*80+32
	ld	bc,kbuf
	call	printtekst
	ld	hl,14*80+32
	ld	de,kbuf
	ld	bc,24*256+"_"
	ld	a,%11001001
	call	inputtext
	jp	c,monitor
	call	teststring
	jr	c,_search1
	push	ix
	pop	hl
	ld	de,Searchstring
	sbc	hl,de	;[NC] is set
	ld	(Lengthstring),hl
	ld	a,1
	ld	(Searchnext),a
_searchnext	ld	hl,(Stopsearch)	;Get next block from Ram
	ld	de,(Startsearch)
	ld	a,d
	or	e
	jr	z,_searchnext1
	inc	hl
_searchnext1	or	a
	sbc	hl,de
	ld	a,h
	or	l
	jr	z,_searchready
	ld	(Restlengte),hl
	push	hl
	ld	hl,(Startsearch)
	ld	bc,512+30	;512 + extra
	call	getfromram
	pop	bc
	ld	a,b
	cp	2	;< 512 ?
	jr	c,_searchl1
	ld	bc,512
_searchl1	ld	(Huidiglengte),bc
	ld	hl,(Bufferpage0)
_searchcont	ld	a,b	;Find next 1st element
	or	c
	jr	z,_searchnfnd	;For CONT !
	ld	a,(Searchstring)
	cpir
	jr	z,_searchfnd
	;1st element not found => next block ram
_searchnfnd	ld	hl,(Startsearch)
	ld	bc,(Huidiglengte)
	add	hl,bc
	ld	(Startsearch),hl
	jr	c,_searchready
	jr	_searchnext
	;1st element found => test rest
_searchfnd	ld	(Cpiradres),hl
	ld	(Cpirlengte),bc
	ex	de,hl
	ld	hl,(Restlengte)
	ld	bc,(Lengthstring)
	dec	bc
	or	a
	sbc	hl,bc
	jr	c,_searchready	;rest too small for string
	ex	de,hl
	ld	b,c
	ld	a,b
	or	a
	jr	z,_stringfound
_searchrest	ld	de,Searchstring+1
_searchrest2	ld	a,(de)
	inc	de
	cp	(hl)
	inc	hl
	jr	nz,_searchrest1
	djnz	_searchrest2
	jr	_stringfound
_searchrest1	ld	hl,(Cpiradres)	;Rest of the string is incorrect
	ld	bc,(Cpirlengte)
	jr	_searchcont
_searchready	xor	a	;String not found
	ld	(Searchnext),a
	ld	hl,12*80+(80-18)/2
	ld	bc,Stringnfound
	call	txttocomm
	call	beep
	call	getkey
	call	wiscommline
	jp	monitor
beep	ld	ix,#c0
	jp	gobios
_stringfound	ld	hl,(Cpiradres)
	ld	de,(Bufferpage0)
	or	a
	sbc	hl,de
	ld	de,(Startsearch)
	add	hl,de
	ld	(Startsearch),hl	;for Search next !
	ex	de,hl
	dec	de
	call	zetadres
	jp	monitor
Stringnfound	db	"String not found !",0
Cpiradres	dw	0
Cpirlengte	dw	0
Huidiglengte	dw	0	;<= 512
Restlengte	dw	0

Startsearch	dw	0
Stopsearch	dw	0
Searchstring	ds	25
Lengthstring	dw	0

Hoksearch	dw	H1,H2,H2,H2,H2,H2,H3,0
Searchtext	dw	10*80+37
	db	"Search",0
	dw	14*80+24
	db	"Search:",0
Searchtext1	dw	12*80+24
	db	"Start:",0
	dw	13*80+24
	db	"End:",0
	dw	0

!searchnext	ld	a,(Searchnext)
	or	a
	jp	nz,_searchnext
	call	beep
	jp	monitor
Searchnext	db	0	;possible ? => 0=no, 1=yes

!fill	ld	hl,9*80+20
	ld	de,Hokfill
	call	printblokkle
	ld	hl,Filltext
	call	texttoblok
	ld	hl,Searchtext1
	call	texttoblok
	call	inputblok
	ld	hl,14*80+31
	call	inputbin
	ld	(Fillwaarde),de
	ld	a,(Fillwaarde+1)
	or	a
	ld	bc,Filltype16
	ld	a,1
	jr	nz,_filltype1
	ld	hl,30*256+15
	ld	b,6
	call	setbalk
	ld	bc,Filltype8
	ld	a,0
_filltype1	push	af
	ld	hl,15*80+31
	call	printtekst
	pop	af
	or	a
	ld	hl,(Bufferpage0)
	jr	nz,_fill16bit
	ld	hl,15*80+31
	call	inputtype
	push	af
	ld	hl,30*256+15
	ld	b,6
	call	wisbalk
	pop	af
	or	a
	ld	hl,(Bufferpage0)
	jr	nz,_fill16bit
	ld	a,(Fillwaarde)
_fill8bit	ld	d,h
	ld	e,l
	inc	de
	ld	bc,1023
	ld	(hl),a
	ldir
	jr	_fillcont
_fill16bit	ld	bc,(Fillwaarde)
	ld	de,512
_fill16bit1	ld	(hl),c
	inc	hl
	ld	(hl),b
	inc	hl
	dec	de
	ld	a,d
	or	e
	jr	nz,_fill16bit1
_fillcont	ld	de,(Startblok)
_fillloop1	ld	hl,(Stopblok)
	ld	a,d
	or	e
	jr	z,_fillloop2
	inc	hl
_fillloop2	or	a
	sbc	hl,de
	ld	a,h
	or	l
	jp	z,monitor
	ld	a,h
	cp	4
	ld	b,h
	ld	c,l
	jr	c,_filldo1
	ld	bc,1024
_filldo1	push	de
	push	bc
	call	puttoram
	pop	bc
	pop	hl
	add	hl,bc
	ex	de,hl
	jp	c,monitor
	jr	_fillloop1

inputblok	ld	hl,12*80+31
	call	inputbin
	ld	(Startblok),de
_inputblok1	ld	hl,13*80+31
	call	inputbin
	ld	(Stopblok),de
	ex	de,hl
	ld	de,(Startblok)
	sbc	hl,de	;[NC] is set
	jr	c,_inputblok1	;Stop < Start
	ret
Startblok	defw	0
Stopblok	defw	0

inputtype	push	hl
	push	af
	or	a
	ld	bc,Filltype8
	jr	z,_inputtype1
	ld	bc,Filltype16
_inputtype1	call	printtekst
_inputtype2	call	getkey
	or	a
	jr	z,_inputtype3
	cp	" "
	jr	z,_inputtype3
	cp	13
	jr	z,_inputtype3
	cp	27
	jp	z,monitor
	cp	1
	jp	z,monitor
	cp	28
	jr	c,_inputtype2
	cp	32
	jr	nc,_inputtype2
	pop	af
	xor	1
	pop	hl
	jr	inputtype
_inputtype3	pop	af
	pop	hl
	ret

Hokfill	dw	H1,H2,H2,H2,H2,H2,H2,H3,0
Fillwaarde	dw	0
Filltype8	db	"Byte",0
Filltype16	db	"Word",0

Filltext	dw	10*80+38
	db	"Fill",0
	dw	14*80+24
	db	"Fill:",0
	dw	15*80+24
	db	"Type:",0
	dw	0

!copy	call	zethoksearch
	ld	hl,Copytext
	call	texttoblok
	ld	hl,Searchtext1
	call	texttoblok
	call	inputblok
	ld	hl,14*80+31
	call	inputbin
	ld	(Copydoel),de
	ld	de,(Startblok)
_copyloop	ld	hl,(Stopblok)
	ld	a,d
	or	e
	jr	z,_copyloop1
	inc	hl
_copyloop1	or	a
	sbc	hl,de
	ld	a,h
	or	l
	jp	z,monitor
	ld	a,h
	cp	4
	ld	b,h
	ld	c,l
	jr	c,_copy1
	ld	bc,1024
_copy1	push	de
	push	bc
	ex	de,hl
	call	getfromram
	pop	bc
	push	bc
	ld	de,(Copydoel)
	push	de
	call	puttoram
	pop	hl
	pop	bc
	add	hl,bc
	ld	(Copydoel),hl
	pop	hl
	add	hl,bc
	ex	de,hl
	jp	c,monitor
	jr	_copyloop
Copydoel	dw	0

Copytext	defw	10*80+38
	defb	"Copy",0
	defw	14*80+24
	defb	"To:",0
	defw	0

!compare	call	zethoksearch
	ld	hl,Comptext
	call	texttoblok
	ld	hl,Searchtext1
	call	texttoblok
	call	inputblok
	ld	hl,14*80+31
	call	inputbin
	ld	(Compdoel),de
	ld	de,(Startblok)
_comploop	ld	hl,(Stopblok)
	ld	a,d
	or	e
	jr	z,_comploop1
	inc	hl
_comploop1	or	a
	sbc	hl,de
	ld	a,h
	or	l
	jp	z,monitor
	ld	a,h
	cp	2
	ld	b,h
	ld	c,l
	jr	c,_comp1
	ld	bc,512
_comp1	push	de
	push	bc
	ex	de,hl
	call	getfromram
	ld	hl,(Bufferpage0)
	ld	d,h
	ld	e,l
	ld	bc,512
	add	hl,bc
	ex	de,hl
	ldir		;(Bufferpage0) to (Bufferpage0)+512
	pop	bc
	push	bc
	ld	hl,(Compdoel)
	call	getfromram
	ld	hl,(Bufferpage0)
	ld	d,h
	ld	e,l
	ld	bc,512
	add	hl,bc
	pop	bc
	push	bc
_compnext	ld	a,(de)
	inc	de
	cp	(hl)
	inc	hl
	jr	nz,_comparefout
	dec	bc
	ld	a,b
	or	c
	jr	nz,_compnext
	pop	bc
	ld	hl,(Compdoel)
	add	hl,bc
	ld	(Compdoel),hl
	pop	hl
	add	hl,bc
	ex	de,hl
	jp	c,monitor
	jr	_comploop
_comparefout	push	de
	ld	hl,12*80+(80-11)/2
	ld	bc,Comparefout
	call	txttocomm
	call	beep
	call	getkey
	call	wiscommline
	pop	hl
	dec	hl
	ld	de,(Bufferpage0)
	or	a
	sbc	hl,de
	pop	bc
	pop	de
	add	hl,de
	ex	de,hl
	call	zetadres
	jp	monitor
Comparefout	db	"Not equal !",0
Compdoel	dw	0
Comptext	defw	10*80+37
	defb	"Compare",0
	defw	14*80+24
	defb	"With:",0
	defw	0

!poke	call	zethoksearch
	ld	hl,Poketxt
	call	texttoblok
_pokenext	ld	hl,12*80+33
	call	inputbin
	ld	(Pokeadres),de
	ld	hl,13*80+33
	call	inputbin
	ld	hl,(Bufferpage0)
	ld	(hl),e
	inc	hl
	ld	(hl),d
	ld	a,d
	or	a
	jr	nz,_poke16bit
	ld	hl,32*256+14
	ld	b,6
	call	setbalk
	ld	hl,14*80+33
	xor	a
	call	inputtype
	push	af
	ld	hl,32*256+14
	ld	b,6
	call	wisbalk
	pop	af
	or	a
	jr	nz,_poke16bit
_poke8bit	ld	bc,1
	jr	_poke16bit_1
_poke16bit	ld	bc,2
_poke16bit_1	ld	de,(Pokeadres)
	call	puttoram
	call	printmon
	jp	!poke
Pokeadres	dw	0
Poketxt	defw	10*80+38
	defb	"Poke",0
	defw	13*80+24
	defb	"Poke:",0
	defw	14*80+24
	defb	"Type:",0
	defw	12*80+24
	defb	"Address:",0
	defw	0

!peek	ld	hl,9*80+20
	ld	de,Hokfill
	call	printblokkle
	ld	hl,Peektxt
	call	texttoblok
_peeknext	ld	hl,12*80+33
	call	inputbin
	ex	de,hl
	ld	bc,2
	call	getfromram
	ld	hl,(Bufferpage0)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	de
	ld	hl,14*80+33
	ld	b,2
	ld	d,0
	call	printhexadec	;8-bits
	pop	de
	ld	b,4
	ld	hl,15*80+33
	call	printhexadec
	jp	_peeknext
Peektxt	defw	10*80+38
	defb	"Peek",0
	defw	12*80+24
	defb	"Address:",0
	defw	14*80+24
	defb	"8-bits:",0
	defw	15*80+24
	defb	"16-bits:",0
	defw	0

!print	call	zethoksearch
	ld	hl,Printtext
	call	texttoblok
	ld	hl,Searchtext1
	call	texttoblok
	call	inputblok
	ld	ix,#a8
	call	gobios
	jr	nz,_print1
	ld	bc,Prtnotready
_printabort	ld	hl,14*80+31
	call	printtekst
	call	beep
	call	wiskeybuffer
	call	getkey
	jp	monitor
_print1	ld	hl,14*80+35
	ld	bc,Printingtxt
	call	printtekst
	call	printini
	ld	hl,(Startblok)
	ld	bc,16
	push	hl
	call	getfromram
	pop	hl
	ld	a,l
	and	%11110000
	ld	l,a
	call	adresprinter
	ld	a,(Startblok)	;Low-byte
	and	%00001111
	push	af
	ld	b,a
	call	nz,printleeg
	pop	bc
	ld	a,b
	ld	(Leegascii+1),a
	ld	a,16
	sub	b	;A = quantity yet to be printed
	ld	b,a
	ld	hl,(Stopblok)
	inc	hl
	ld	de,(Startblok)
	or	a
	sbc	hl,de
	ld	a,h
	or	a
	jr	nz,_print4	;residual length long enough
	ld	a,l
	cp	b
	jr	nc,_print4
	ld	b,l
_print4	push	bc
	call	doprthex
Leegascii:	ld	b,0	;filled in !!!
	ld	a,b
	or	a
	jr	z,_noleegasc
_leegascii1	ld	a," "
	call	goprint
	djnz	_leegascii1
_noleegasc	pop	bc
	push	bc
	call	doprtascii
	call	doprtend
	pop	bc
	ld	hl,(Startblok)
	ld	c,b
	ld	b,0
	add	hl,bc
	ex	de,hl
_printloop	ei
	ld	a,(Matrix+7)
	and	%00000100
	ld	bc,Printabort
	jp	z,_printabort
	ld	hl,(Stopblok)
	inc	hl
	or	a
	sbc	hl,de
	ld	a,h
	or	l
	jp	z,monitor
	ld	bc,16
	ld	a,h
	or	a
	jr	nz,_print5
	ld	a,l
	cp	16
	jr	nc,_print5
	ld	b,h
	ld	c,l
_print5	push	de
	push	bc
	push	de
	ex	de,hl
	call	getfromram
	pop	hl
	call	adresprinter
	pop	bc
	push	bc
	ld	b,c
	push	bc
	call	doprthex
	pop	bc
	ld	a,16
	sub	b
	ld	b,a
	call	nz,printleeg
	ld	b,c
	call	doprtascii
	call	doprtend
	pop	bc
	pop	hl
	add	hl,bc
	ex	de,hl
	jr	_printloop
printleeg	ld	a," "
	call	goprint
	ld	a," "
	call	goprint
	ld	a," "
	call	goprint
	djnz	printleeg
	ret

doprthex	ld	hl,(Bufferpage0)
_doprthex1	ld	a,(hl)
	inc	hl
	call	hexprinter
	ld	a," "
	call	goprint
	djnz	_doprthex1
	ret

doprtascii	ld	a," "
	call	goprint
	ld	a," "
	call	goprint
	ld	hl,(Bufferpage0)
_doprtascii1	ld	a,(hl)
	inc	hl
	cp	32
	ld	c,"."
	jr	c,_doprtascii2
	cp	128
	jr	nc,_doprtascii2
	ld	c,a
_doprtascii2	ld	a,c
	call	goprint
	djnz	_doprtascii1
	ret
doprtend	ld	a,#0d
	call	goprint
	ld	a,#0a
goprint	push	hl
	push	bc
	ld	ix,#a5
	call	gobios
	pop	bc
	pop	hl
	ret
hexprinter	ld	c,a
	and	%11110000
	rlca
	rlca
	rlca
	rlca
	call	_hexprinter2
	ld	a,c
	and	%1111
_hexprinter2	cp	10
	jr	c,_hexprinter1
	add	a,7
_hexprinter1:	add	a,"0"
	jr	goprint

adresprinter	ld	a,"#"
	call	goprint
	ld	a,h
	call	hexprinter
	ld	a,l
	call	hexprinter
	ld	a," "
	call	goprint
	ld	a," "
	jp	goprint

Printingtxt	db	"Printing...",0
Prtnotready	db	"Printer not ready !",0
Printabort	db	"Printing aborted !",0
Printtext	dw	10*80+38
	db	"Print",0
	dw	0

Menu3	db	8,14,0	;height, width text, place background
	db	"Search      ^Z"
	db	"Search next ^N"
	db	"Fill        ^F"
	db	"Copy        ^K"
	db	"Compare       "
	db	"Poke        ^O"
	db	"Peek        ^E"
	db	"Print       ^P"

menuoptie	dec	c
	rlc	c
	ld	b,0
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	jp	(hl)

inputbin	push	hl
	ld	de,kbuf
	ld	b,20
	ld	a,%11000001
	call	inputtext
	jp	c,monitor
	ld	hl,kbuf
	call	berekengetal
	pop	hl
	jr	c,inputbin
	ret

txttocomm	push	hl
	push	bc
	ld	hl,#1800+10*12+1
	ld	bc,8
	ld	a,255
	call	fillvram
	ld	hl,80*12+8
	ld	bc,64
	xor	a
	call	fillvram
	pop	bc
	pop	hl
	jp	printtekst
wiscommline	ld	hl,#1800+10*12+1
	ld	bc,8
	xor	a
	jp	fillvram

tekenscherm	ld	hl,3*80
	ld	de,Monitorblok
	call	printblok
	ld	hl,Teksten
	jp	texttoblok

Teksten	dw	32
	db	"Monitor",0
	dw	21*80+2
	db	"Address:",0
	dw	2*80
	db	23,23,23,23," SYSTEM ",23,23,23,23,23
	db	" INSTALLATIONS ",23,23,23,23,23," OPTIONS ",23,23,23,23
	db	23,23,23,23,23,23,23,23,23,23,23,23,23,23,23
	db	23,23,23,23,23,23,23,23
	db	23,23,23,23,23,23,23,0
	dw	0
Monitorblok	dw	M1,M2,M2,M2,M2,M2,M2,M2,M2,M2,M2
	dw	M2,M2,M2,M2,M2,M2,M3,M2,M4,M5,M5,M5,0
M1	db	1,24,78,23,1,25,0
M2	db	1,22,78,0,1,22,0
M3	db	1,20,78,23,1,19,0
M4	db	1,26,78,23,1,27,0
M5	db	80,0,0

;---------- MAIN PROGRAM MONITOR
Mon_x	defb	0
Mon_y	defb	8
Hex_ascii	defb	0	;0=hex, 1=ascii part

monitortek	call	tekenscherm
monitor	ld	sp,(Sp_back)
monloop	call	setcursor
	ei		;wait for possible keys
	halt
	ld	b,0
	call	waitforkey	;wait 0 interrupts for keys
	jr	nc,montesttoets
	call	printmon
	jr	monloop
montesttoets	ld	b,a
	ld	a,(#fbeb)
	srl	a
	jr	nc,shifttoets
	srl	a
	jr	nc,montestctrl
_shift	ld	hl,Zonderctrl
	call	testtoets
	ld	b,a
	call	testfkey
	jp	nc,startmenu
	ld	a,(Hex_ascii)
	or	a
	ld	a,b
	jr	z,testhexkey
testasciikey	cp	8
	jp	z,ascii_bs
	cp	32
	jr	c,monitor
	cp	128
	jr	nc,monitor
	jp	vulascii
testhexkey	call	testhex
	jr	c,monitor
	jp	vulhex
montestctrl	ld	hl,Metctrl
	call	testtoets
	jr	monitor
shifttoets	LD	A,(Matrix+7)
	AND	#04
	JR	NZ,_shift
	JP	!shell
mon_down	ld	hl,Mon_y
	ld	a,(hl)
	cp	15
	jr	nc,_mon_down1
	inc	(hl)
	call	wiscursor
	jr	monitor
_mon_down1	ld	de,16
_mon_new	ld	hl,(Beginadres)
	add	hl,de
	ld	(Beginadres),hl
	call	wiscursor
	jr	monitor
mon_down_f	ld	de,256
	jr	_mon_new
mon_up	ld	hl,Mon_y
	ld	de,-16
	ld	a,(hl)
	or	a
	jr	z,_mon_new
	dec	(hl)
	call	wiscursor
	jp	monitor
mon_up_f	ld	de,-256
	jr	_mon_new
mon_left	call	wiscursor
	ld	hl,Mon_x
	ld	a,(hl)
	or	a
	jr	z,_mon_left1
	dec	(hl)
	jp	monitor
_mon_left1	ld	(hl),15
	jp	mon_up
mon_right	call	wiscursor
	ld	hl,Mon_x
	ld	a,(hl)
	cp	15
	jr	nc,_mon_right1
	inc	(hl)
	jp	monitor
_mon_right1	ld	(hl),0
	jp	mon_down
mon_tab	ld	a,(Hex_ascii)
	xor	1
	ld	(Hex_ascii),a
	call	wiscursor
	jp	monitor

Zonderctrl	db	Up
	dw	mon_up
	db	Down
	dw	mon_down
	db	Right
	dw	mon_right
	db	Left
	dw	mon_left
	db	Tab
	dw	mon_tab
	db	Select
	dw	!deb
	db	250	;=[STOP]
	dw	!deb
	db	1
	dw	lastmenu
	db	0

Metctrl	db	Up
	dw	mon_up_f
	db	Down
	dw	mon_down_f
	db	Ctrl_d
	dw	!disk
	db	Ctrl_a
	dw	_addressstrt
	db	Ctrl_z
	dw	!search
	db	Ctrl_n
	dw	!searchnext
	db	Ctrl_f
	dw	!fill
	db	Ctrl_k
	dw	!copy
	db	Ctrl_o
	dw	!poke
	db	Ctrl_e
	dw	!peek
	db	Ctrl_c
	dw	!calc
	db	Ctrl_p
	dw	!print
	db	Ctrl_x
	dw	!changechain
	db	Ctrl_q
	dw	!quit
	db	0

testtoets	ld	a,(hl)
	or	a
	ld	a,b
	ret	z
	cp	(hl)
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	jr	nz,testtoets
	ex	de,hl
	pop	de	;get rid of CALL
	ld	a,1
	ld	(Cursoronoff),a
	push	hl
	call	wiscursor
	pop	hl
	jp	(hl)
setcursor	call	bercursor
	jp	setbalk
wiscursor	call	bercursor
	jp	wisbalk
bercursor	ld	a,(Mon_y)
	add	a,4
	ld	l,a
	ld	a,(Hex_ascii)
	or	a
	ld	a,(Mon_x)
	jr	nz,ber_x_ascii
ber_x_hex	ld	b,a
	add	a,a
	add	a,b
	add	a,9
	ld	h,a
	ld	b,4
	ret
ber_x_ascii	add	a,61
	ld	h,a
	ld	b,1
	ret
vulascii	ld	hl,(Bufferpage0)
	ld	(hl),a
	call	berramadres
	ex	de,hl
	ld	bc,1
	call	puttoram
	jp	mon_right
ascii_bs	ld	hl,(Bufferpage0)
	ld	(hl),0
	call	berramadres
	dec	hl
	ex	de,hl
	ld	bc,1
	call	puttoram
	jp	mon_left
vulhex	push	af
	cp	"A"
	jr	c,_vulhex1
	sub	"A"-"0"-10
_vulhex1	sub	"0"
	rlca
	rlca
	rlca
	rlca
	push	af
	call	berramadres
	ld	bc,1
	call	getfromram
	ld	hl,(Bufferpage0)
	ld	a,(hl)
	and	%00001111
	pop	bc
	or	b
	ld	(Vulbyte),a
	call	bervramadres
	pop	af
	call	writevram
	ld	a,1
	ld	(Cursoronoff),a
_vulhexloop	call	getkey
	cp	Escape
	jp	z,monitor
	cp	1
	jp	z,monitor
	cp	Right
	jr	c,_vulhexloop
	cp	Down+1
	jr	c,_vulhexcurs
	call	testhex
	jr	c,_vulhexloop
	cp	"A"
	jr	c,_vulhex2
	sub	"A"-"0"-10
_vulhex2:	sub	"0"
	ld	b,a
	ld	a,(Vulbyte)
	and	%11110000
	or	b
	ld	(Vulbyte),a
	call	dovulhex
	jp	mon_right
_vulhexcurs	push	af
	call	dovulhex
	pop	af
	jp	montesttoets
dovulhex	ld	hl,(Bufferpage0)
	ld	a,(Vulbyte)
	ld	(hl),a
	call	berramadres
	ex	de,hl
	ld	bc,1
	jp	puttoram
Vulbyte	db	0
testhex	cp	"0"
	ret	c
	cp	"9"+1
	ccf
	ret	nc
	and	%11011111
	cp	"A"
	ret	c
	cp	"F"+1
	ccf
	ret

printmon	call	berramadres
	ex	de,hl
	ld	hl,21*80+11
	ld	b,4
	call	printhexadec
	ld	hl,(Beginadres)
	ld	bc,16*16
	call	getfromram
	ld	hl,(Bufferpage0)
	ld	de,(Beginadres)
	exx
	ld	hl,4*80+3
	ld	de,80	;a a constant
	ld	b,16
_printmon1	call	setvramwrite
	exx
	ld	a,d
	call	printhex
	ld	a,e
	call	printhex
	ld	b,3
_tussen1	ld	a," "
	out	(#98),a
	nop		;!for TR
	nop
	djnz	_tussen1
	push	hl
	ld	b,16
_printmon3	ld	a,(hl)
	inc	hl
	call	printhex
	ld	a," "
	out	(#98),a
	djnz	_printmon3
	pop	hl
	ld	b,3
_tussen2	ld	a," "
	out	(#98),a
	nop		;!for TR
	nop
	djnz	_tussen2
	ld	bc,#1098
_printmon4	outi
	inc	de
	nop		;!for Turbo-R
	jr	nz,_printmon4
	exx
	add	hl,de
	djnz	_printmon1
	ret
printhex	ld	c,a
	and	%11110000
	rlca
	rlca
	rlca
	rlca
	call	_printhex2
	ld	a,c
	and	%1111
_printhex2:	cp	10
	jr	c,_printhex1
	add	a,7
_printhex1:	add	a,"0"
	out	(#98),a
	ret
Beginadres	dw	#bf80	;Start address ! (always on top)

berramadres	ld	de,(Mon_x)	;E=x, D=y
	ld	l,d
	ld	h,0
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl	;*16
	ld	d,0
	add	hl,de
	ld	de,(Beginadres)
	add	hl,de
	ret
bervramadres	ld	de,(Mon_x)	;E=x, D=y
	ld	l,d
	ld	h,0
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl	;*16
	ld	b,h
	ld	c,l
	add	hl,hl
	add	hl,hl
	add	hl,bc
	ld	d,0
	add	hl,de
	add	hl,de
	add	hl,de
	ld	bc,4*80+10
	add	hl,bc
	ret

teststring	ld	hl,kbuf
	ld	ix,Searchstring
_defb1	call	testdefb
	ret	c
	ld	a,(hl)
	inc	hl
	or	a
	ret	z
	cp	","
	jr	z,_defb1
	scf
	ret
testdefb	call	_defb_tekst
	ret	nc
	push	ix
	call	getal8bit
	pop	ix
	ret	c
	ld	(ix),a
	inc	ix
	or	a
	ret
_defb_tekst	push	ix
	push	hl
	ld	a,(hl)
	inc	hl
	cp	34	;"
	jr	z,_weltekst
	cp	"'"
	jr	nz,_notekst
_weltekst	ld	b,a	;" or '
	cp	(hl)
	ld	a,0
	jr	z,_2quotes	;"" or '' = 0
_defb_tekst1	ld	a,(hl)
	inc	hl
	cp	b
	jr	z,_endtekst
	or	a
	jr	z,_endtekst1
_2quotes	ld	(ix),a
	inc	ix
	jr	_defb_tekst1
_endtekst	ld	a,(hl)
	cp	","
	jr	z,_endtekst1
	or	a
	jr	nz,_notekst
_endtekst1	pop	bc
	pop	bc
	or	a
	ret
_notekst	pop	hl
	pop	ix
	scf
	ret
getal8bit	call	berekengetal
	ret	c
	ld	a,d
	dec	a
	cp	#fe
	ret	c
	ld	a,e
	or	a
	ret

Bufferpage0	defw	0	;address buffer in page 0


	ds	#7FF0-$,0

;PATCH FOR ASSEMBLERCORE 1.2.09 IS LOCATED HERE AT #7FF0
	ld	hl,(#0686)
	ld	(#2c2a),hl
	jp	#00c2

	ds	#8000-$,0
