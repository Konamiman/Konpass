;Konpass #1.3 - Editor

;compile with 'assemble to disk' (due to doubleusepage)

;stat_memory=2or3 allowed (=memman+dos1/memman+dos2)
;TPA nums adjusted

;Structure of text buffers:
;Sentence, last character has bit 7 high (#80=empty sentence)

;Building addresses:
;Block (1-..), address low, address high (#ff = end of text)

;Header asmfile: #fc,whole textbl.,residuallength,whole databl.,residuallength,endline
;       Lengtes:  1 ,     1      ,       2     ,       1       ,       2    ,    2

;Info: ld a,""" and ld a,"" are not allowed !

	.label	13

Doubleadres:	equ	#3f40	;address double-use data
bdos:	equ	#f37d
kbuf:	equ	#f41f	;318 byte buffer
startbuf	equ	1	;source buffer to start with
tab_tpa	equ	#fa01

setvramwrite:	equ	#80
;setvramread:  equ     #83
ramtovram:	equ	#86
fillvram:	equ	#89
;wisblinktabe: equ     #8c
;cls:          equ     #8f
printtekst:	equ	#92
;setcolor1:    equ     #95
;setcolor2:    equ     #98
printdecimaa:	equ	#9b
printhexadec:	equ	#9e
;printbinair:  equ     #a1
setbalk:	equ	#a4
wisbalk:	equ	#a7
writevram:	equ	#aa
readvram:	equ	#ad
;getfromram:   equ     #b0
;puttoram:     equ     #b3
godiskdrive:	equ	#b6
;printblok:    equ     #b9
texttoblok:	equ	#bc
inputtext:	equ	#bf
closefile:	equ	#c2
printmenu:	equ	#c5
kiesoptie:	equ	#c8
wisoudmenu:	equ	#cb
;bergetalasm:  equ     #ce
berekengetal:	equ	#d1
memview:	equ	#d4
calculator:	equ	#d7
memory:	equ	#da
printblokkle:	equ	#dd
startprogram:	equ	#e0
vramtoram:	equ	#e3
oldscreen:	equ	#e6
screencompas:	equ	#e9
moveprog:	equ	#ec
;;newbinid:    equ     #ef
gotoeditor:	equ	#f2
gotoass:	equ	#f5
slot:	equ	#f8
getkey:	equ	#fb
mouseoffset:	equ	#fe
wiskeybuffer:	equ	#101
pushanykey:	equ	#104
printini:	equ	#107
;waitforkey:   equ     #10a
;linetoassemb: equ     #10d
getregisters:	equ	#110
;gotodebugger: equ     #113
mainconfig:	equ	#116
;getpages:     equ     #119
doinclude:	equ	#11c
;saveconfig:  equ     #11f
about: equ #137

Cursoronoff:	equ	#fca9
Cursorpositi:	equ	#f3dc
Insonoff:	equ	#fcaa
Matrix:	equ	#fbe5
Escape:	equ	27
Right:	equ	28
Left:	equ	29
Up:	equ	30
Down:	equ	31
;Space:        equ     32
Ins:	equ	18
Del:	equ	127
Tab:	equ	9
Return:	equ	13
Bs:	equ	8
Home:	equ	11
Ctrl_a:	equ	1
Ctrl_b:	equ	1+"B"-"A"
Ctrl_c:	equ	1+"C"-"A"
Ctrl_d:	equ	1+"D"-"A"
Ctrl_e:	equ	1+"E"-"A"
Ctrl_g:	equ	1+"G"-"A"
Ctrl_i:	equ	1+"I"-"A"
Ctrl_j:	equ	1+"J"-"A"
Ctrl_k:	equ	1+"K"-"A"
Ctrl_l:	equ	1+"L"-"A"
Ctrl_n:	equ	1+"N"-"A"
Ctrl_p:	equ	1+"P"-"A"
Ctrl_q:	equ	1+"Q"-"A"
;Ctrl_r: ;See ctrl
Ctrl_s:	equ	1+"S"-"A"
Ctrl_t:	equ	1+"T"-"A"
Ctrl_v:	equ	1+"V"-"A"
Ctrl_w:	equ	1+"W"-"A"
Ctrl_y:	equ	1+"Y"-"A"
Ctrl_z:	equ	1+"Z"-"A"

Commline:	equ	12

;entries in the assembly module
assembledisk:	equ	#4000
assembleren:	equ	#4003
;labbufvol:    equ     #4006 ;*********************************
prterrlines:	equ	#4009
;test label: equ #400c  ;***********    ;for calculator/calculation number
geeflabdata:	equ	#400f
relocatable:	equ	#4012
asstsr	equ	#4015

	org	#4000

	jp	startassemb	;#4000
	jp	setnewbuffer	;#4003
	jp	linedebugger	;#4006
	JP	getinst2kbuf	;#4009
	jp	domemory	;#400c
	JP	parseregist	;#400f
	jp	inclfile	;#4012
	RET		;#4015 not used
	RET
	RET
	RET		;#4018 not used
	RET
	RET
	JP	geefalvrij	;#401b

startassemb	LD	(entryA),A
	push	hl
	LD	(entryDE),DE
	ld	hl,Doubleusepg1
	ld	de,Doubleadres
	ld	bc,Doubleuseend-Doubleuse
	ldir		;copy to page 0
	CALL	transbufp02p1
	pop	hl
	ld	(Bufferpage0),ix
	ld	(Sp_back),sp
	ld	de,Idhex
	ld	bc,6
	ldir		;copy idhex and idbin
	ld	a,(Keer)
	or	a
	jr	nz,_niet1ekeer1
	ld	a,startbuf
	call	setbuffonly1
	ld	b,4
_1ekeer_1:
	push	bc
	ld	a,b
	call	setbuffonly
	call	delsource1
	pop	bc
	djnz	_1ekeer_1

_niet1ekeer1:
	call	changefkey
	ld	a,(Textbuffer)
	call	setbuffer
	ld	a,(Keer)
	or	a
	jr	nz,_niet1ekeer
	call	ini_variabel	;no need anymore??? (already in
_niet1ekeer:	call	tekenscherm	;delsource1)************************
	ld	a,1
	ld	(Keer),a
	LD	A,(entryA)
	OR	A
	LD	HL,kbuf
	CALL	NZ,doinclude
	JP	editor
Sp_back:	defw	0
Keer:	defb	0	;0=1st time
entryA	db	0

transbufp02p1	exx
	LD	HL,(entryDE)
	ld	de,Textbuffer1	;on page 1
	ld	bc,(33+13)*4
	ldir
	ld	de,Aantallabelb	;in page 0
	ld	bc,9
	ldir
	exx
	ret
entryDE	dw	0

getinst2kbuf	CALL	putinst
	LD	HL,Inst1
	LD	DE,kbuf+#f4
	LD	A,4
J40AF:	LD	BC,4
	LDIR
	LD	BC,8
	ADD	HL,BC
	DEC	A
	JR	NZ,J40AF
	RET
;----- Line from debugger to sourcebuffer
;----- IN:  HL = address line
;----- OUT: [C] = error (one buffer full)
linedebugger:
	ld	(Sp_debugger),sp
	PUSH	AF
	PUSH	HL
	OR	A
	JR	NZ,J40CB
	CALL	transbufp02p1
	CALL	delsource1

J40CB	pop	hl
	ld	de,Zin
	ld	bc,50	;************************
	ldir
	ld	a,2
	ld	(Bronerrors),a
	xor	a
	ld	(Printret),a
	call	_return_cont
	ld	hl,(Regelnr)
	POP	AF
	CP	#02
	JR	NZ,J40EE
	CALL	inishowlab
	LD	HL,#0000
J40EE	inc	hl
	ld	(Regelnr),hl
	call	putinst
	xor	a
	ld	(Bronerrors),a
	ret

debuggerfout:
	ld	sp,(Sp_debugger)
	xor	a
	ld	(Bronerrors),a
	scf
	ret
Sp_debugger:	defw	0

;----- Change function keys: F1=255, F2=254, F3=253, F4=252, F5=251
changefkey:
	ld	hl,#f87f
	ld	de,16-1
	ld	ix,Oldfkey
	ld	bc,#0500
_changefkey1:
	dec	c
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
Oldfkey:	ds	10

;----- Restore function keys
oldfkey:
	ld	hl,#f87f
	ld	de,16-1
	ld	ix,Oldfkey
	ld	b,5
_oldfkey1:
	ld	a,(ix)
	inc	ix
	ld	(hl),a
	inc	hl
	ld	a,(ix)
	inc	ix
	ld	(hl),a
	add	hl,de
	djnz	_oldfkey1
	ret

;--------------- Menus
menu2tomenu:
	push	bc
	call	wisoudmenu
	pop	bc
startmenu:
	push	bc
	call	edit_ret1
	pop	bc
	ld	b,0
	rlc	c
	ld	hl,Menus-2
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	jp	(hl)
Menus:	defw	menu1,menu2,menu3,menu4,menu5
Lastmenu:	defb	1

;----- Go to disk drive

gotodisk:
	ld	a,(Textbuffer)
	ld	c,a
	ld	a,1
	call	godiskdrive
	push	af
	ld	hl,25*80
	ld	bc,2*80
	xor	a
	call	fillvram
	call	tekenscherm
	pop	af
	ret

;******************* MENU 1

Menu1optie:	defb	1
Menu1blink:	defw	#0204
Plmenu1:	equ	3*80

tomenu1:
	call	wisoudmenu
menu1:
	ld	a,1
	ld	(Lastmenu),a
	ld	hl,Plmenu1
	ld	ix,Menu1
	call	printmenu
_menu1_2:
	ld	ix,Menu1
_menu1_1:	ld	a,(Menu1optie)
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
	jp	z,editor_cont
	cp	1
	jp	z,editor_cont
	cp	Right
	jp	z,menu2
	and	255-32
	jr	nz,menu1
_menu1_space:
	ld	hl,Menu1opties
	jp	menuoptie

Menu1opties:	defw	__mon,__deb,__disk,__mem,__calc,__slot,__shell,__quit,__about

;##### Monitor
__mon:
	ld	a,3
	jr	backtohoofd

;##### Debugger
__deb:
	ld	a,2
	jr	backtohoofd

;##### Disk
__disk:
	ld	b,0
	ld	ix,Pointerdisk
	call	gotodisk
	call	c,inishowlab1	;As formatted => labels gone
	jp	editor_cont

Diskregel:	defw	0
Pointerdisk:
	defw	loadasmfile,saveasmfile	;assembler file
	defw	loadascfile,saveascfile	;asciifile
	defw	loadblock,saveblock	;block file

;##### Memory
__mem:
	call	memory
	ld	de,Textbuffer1	;in page1
	ld	bc,(33+13)*4
	ldir
	ld	de,Aantallabelb	;in page0
	ld	bc,9
	ldir
	ld	a,(Textbuffer)
	call	setbuffer	;4e8d MUST
_mem1:
editscreen:	;LEAVE IT !
	ld	hl,25*80
	ld	bc,2*80
	xor	a
	call	fillvram
	call	tekenscherm
	jp	editor_cont

;##### Calculator
__calc:
	call	calculator
	jp	editor_cont

;##### Slot view
__slot:
	call	memview
	jr	_mem1

__shell	ld	a,4
	jr	backtohoofd

;##### Quit
__quit:
	ld	hl,80*Commline+(80-26)/2
	ld	bc,Quit
	call	txttocomm
	call	areyousure
	jp	c,editor_cont
	xor	a

backtohoofd:
	push	af
	call	oldfkey
	call	putinst
	ld	hl,Doubleadres
	ld	de,Doubleusepg1
	ld	bc,Doubleuseend-Doubleuse
	ldir		;copy back from page 0
	pop	af
	ld	sp,(Sp_back)
	ret		;back to main program

Quit:	defb	"Quit: ",0

;##### About

__about:
	call about
	call	tekenscherm
	jp	editor_cont

Menu1:
	defb	9,15,0	;height, width text, place background
	defb	"Monitor      ST"
	defb	"Debugger     SL"
	defb	"Disk         ^D"
	defb	"Memory         "
	defb	"Calculator   ^C"
	defb	"Slot view      "
	defb	"Shell    SH+ESC"
	defb	"Quit         ^Q"
	defb    "About          "

;************************ MENU 2

Menu2optie:	defb	1
Menu2blink:	defw	#0f04
menu2:
	ld	a,2
	ld	(Lastmenu),a
	ld	hl,3*80+13
	ld	ix,Menu2
	call	printmenu
_menu2_2:
	call	printtextbuf
	call	printr800
	call	printlablng
	call	printretins
	call	printtabs
	call	printupper
_menu2_1:	ld	ix,Menu2
	ld	a,(Menu2optie)
	ld	c,a
	ld	hl,(Menu2blink)
	call	kiesoptie
	ld	b,a
	ld	(Menu2blink),hl
	ld	a,c
	ld	(Menu2optie),a
	ld	hl,3*80+13
	call	testfkey
	jp	nc,menu2tomenu
	ld	a,b
	cp	Escape
	jp	z,to_editor
	cp	1
	jp	z,to_editor
	cp	Right
	jp	z,tomenu3
	cp	Left
	jp	z,tomenu1
	and	255-32
	jr	nz,_menu2_1
_menu2_space:
	ld	a,c
	dec	a
	jp	z,_menu2_opt1
	dec	a
	jp	z,_menu2_opt2
	dec	a
	jp	z,_menu2_opt3
	dec	a
	jr	z,_m2_retins
	dec	a
	jr	z,_m2_tabs
	dec	a
	jr	z,_m2_upper
	dec	a
	jr	z,__mainconfig
	jr	_menu2_1

to_editor:
	call	wisoudmenu
	jp	editor_cont

__mainconfig:
	call	mainconfig
	ld	de,Idhex
	ld	bc,6
	ldir
	call	tekenscherm
	jp	editor_cont

_m2_retins:
	ld	a,(Retins)
	xor	1
	ld	(Retins),a
	jp	_menu2_2
_m2_tabs:
	ld	a,(Tabsonoff)
	xor	1
	ld	(Tabsonoff),a
	jp	_menu2_2
_m2_upper:
	ld	a,(Upperonoff)
	xor	1
	ld	(Upperonoff),a
	ld	(Huidigupper),a
	jp	_menu2_2

_menu2_opt1:
	ld	b,4
	ld	a,(Textbuffer)
_menu2_op1_1:
	push	bc
	and	%11
	inc	a
	push	af
	call	setnewbuffer
	jr	nc,_menu2_op1_2
	pop	af
	pop	bc
	djnz	_menu2_op1_1
	jp	_menu2_1
_menu2_op1_2:
	pop	af
	pop	bc
	call	printscherm
	call	printinfoRnr
	jp	menu2

_menu2_opt3:
	ld	b,4
	ld	hl,29*256+6
	call	setbalk
_menu2_op3_2:	call	getkey
	cp	27
	jp	z,_menu2_2
	cp	1
	jp	z,_menu2_2
	cp	13
	jp	z,_menu2_2
	cp	28
	jr	c,_menu2_op3_2
	cp	32
	jp	z,_menu2_2
	jr	nc,_menu2_op3_2
	and	%1
	jr	nz,lableft
labright:
	ld	a,(Labellengte)
	cp	20	;16
	ld	b,-14	;-10
	jr	z,_menu2_op3_1
	ld	b,1
	jr	_menu2_op3_1
lableft:
	ld	a,(Labellengte)
	cp	6
	ld	b,14
	jr	z,_menu2_op3_1
	ld	b,-1
_menu2_op3_1:	add	a,b
	ld	(Labellengte),a
	ld	(Huidiglablen),a
	add	a,2
	ld	(Tabs),a
	add	a,8
	ld	(Tabs+1),a
	add	a,17
	ld	(Tabs+2),a
	call	printlablng
	jr	_menu2_op3_2
_menu2_opt2:
	ld	a,(Turbor)
	or	a
	jp	z,_menu2_1
	call	getr800
	inc	a
	cp	3
	jp	nz,_menu2_op2_1
	xor	a
_menu2_op2_1:	or	#80
	call	putr800
	call	printr800
	jp	_menu2_1

printr800:
	ld	a,(Turbor)
	or	a
	jr	z,_printr800_1
	call	getr800
_printr800_1:	ld	bc,R800opties
	or	a
	jr	z,_printr800_2
	ld	bc,R800opties+10
	dec	a
	jr	z,_printr800_2
	ld	bc,R800opties+10+9
_printr800_2:
	ld	hl,5*80+21
	jp	printtekst
R800opties:	defb	"Z80      ",0,"R800 rom",0,"R800 dram",0
printtextbuf:
	ld	hl,4*80+30
	ld	a,(Textbuffer)
	add	a,"0"
	jp	writevram
printretins:
	ld	hl,7*80+28
	ld	a,(Retins)
	jp	printonoff
printtabs:
	ld	hl,8*80+28
	ld	a,(Tabsonoff)
	jp	printonoff
printupper:
	ld	hl,9*80+28
	ld	a,(Upperonoff)
	jp	printonoff
printlablng:
	ld	hl,6*80+30
	ld	a,(Labellengte)
	ld	e,a
	ld	d,0
	ld	b,2
	jp	printdecimaa
Menu2:
	defb	7,16,0
	defb	"Sourcebuffer:   "
	defb	"CPU:            "
	defb	"Label length:   "
	defb	"Ret insert:     "
	defb	"Auto align:     "
	defb	"Upper case:     "
	defb	"Main config     "
;************************ MENU 3

Menu3optie:	defb	1
Menu3blink:	defw	#2104
Plmenu3:	equ	3*80+31

tomenu3:
	call	wisoudmenu
menu3:
	ld	a,3
	ld	(Lastmenu),a
	ld	hl,Plmenu3
	ld	ix,Menu3
	call	printmenu
_menu3_2:
	ld	ix,Menu3
_menu3_1:	ld	a,(Menu3optie)
	ld	c,a
	ld	hl,(Menu3blink)
	call	kiesoptie
	ld	b,a
	ld	(Menu3blink),hl
	ld	a,c
	ld	(Menu3optie),a
	ld	hl,Plmenu3
	push	bc
	call	wisoudmenu
	pop	bc
	call	testfkey
	jp	nc,startmenu
	ld	a,b
	cp	Escape
	jp	z,editor_cont
	cp	1
	jp	z,editor_cont
	cp	Right
	jp	z,menu4
	cp	Left
	jp	z,menu2
	and	255-32
	jr	nz,menu3
_menu3_space:
	ld	hl,Menu3opties
	jp	menuoptie

Menu3opties:	defw	__errors,__labels
	defw	__search,__searchnext,__jmpline,__delsource

;##### Search
__search:
	ld	hl,9*80+20
	ld	de,Searchhok
	call	printblokkle

	ld	hl,10*80+24
	ld	bc,Search
	call	printtekst
	ld	a,":"
	out	(#98),a
_search1:
	ld	hl,10*80+33
	ld	bc,25
	xor	a
	call	fillvram	;LEAVE IT !
	ld	bc,Searchtext
	ld	hl,10*80+33
	call	printtekst
	ld	hl,10*80+33
	ld	de,Searchtext
	ld	bc,25*256+"_"
	ld	a,%11001001
	call	inputtext
	jp	c,editor_cont
	xor	a
	ld	(Searchnext),a
	ld	a,(Searchtext)
	or	a
	jr	z,_search1

	ld	hl,11*80+24
	ld	bc,Replace1
	call	printtekst
	ld	a,":"
	out	(#98),a
	ld	bc,Replacetext
	ld	hl,11*80+33
	call	printtekst
	ld	hl,11*80+33
	ld	de,Replacetext
	ld	bc,25*256+"_"
	ld	a,%11001001
	call	inputtext
	jp	c,editor_cont

	ld	iy,Searchreplac
	ld	(iy),0
	ld	a,(Replacetext)
	or	a
	jr	z,_search2
	inc	(iy)
_search2:
	inc	iy
_search2_1:
	ld	hl,13*80+37
	ld	a,(iy)
	or	a
	ld	bc,Forward
	jr	z,_search2_2
	ld	bc,Back
_search2_2:
	call	printtekst
	ld	hl,36*256+13
	ld	b,9
	call	setbalk
	call	searchkey
	jr	nc,_search3
	ld	a,(iy)
	xor	1
	ld	(iy),a
	jr	_search2_1

_search3:
	ld	hl,36*256+13
	ld	b,9
	call	wisbalk
	inc	iy
_search3_1:
	ld	hl,14*80+36
	ld	bc,Upper
	call	printtekst
	ld	hl,14*80+42
	ld	a,(iy)
	or	a
	ld	bc,Off
	jr	z,_search3_2
	ld	bc,On
_search3_2:
	call	printtekst
	ld	hl,35*256+14
	ld	b,11
	call	setbalk
	call	searchkey
	jr	nc,_search4
	ld	a,(iy)
	xor	1
	ld	(iy),a
	jr	_search3_1

_search4:
	ld	hl,35*256+14
	ld	b,11
	call	wisbalk

_searchcont:
	ld	iy,Searchreplac
	ld	a,1
	ld	(Searchnext),a
	call	dosearch
	jr	c,notfound
	PUSH	HL
	LD	DE,(Searchregel)
	CALL	printinfoDE
	POP	HL
	ld	iy,Searchreplac
	push	iy
	call	searchcursor
	CALL	printcol
	pop	iy
	ld	a,(iy)
	or	a
	call	nz,doreplace
	jp	editor_cont

notfound:
	xor	a
	ld	(Searchnext),a
	ld	hl,80*Commline+(80-16)/2
	ld	bc,Notfound
	call	txttocomm
	call	beep
	call	getkey
	call	wiscommline
	jp	editor_cont
Notfound:	defb	"Text not found !",0

searchkey:
	call	getkey
	cp	27
	jr	z,_searchkey2
	cp	1
	jr	z,_searchkey2
	cp	28
	jr	c,_searchkey1
	cp	32
	ret	c
_searchkey1:
	cp	13
	ret	z
	and	%11011111
	ret	z
	jr	searchkey
_searchkey2:
	ld	hl,#1800+10*10
	ld	bc,10*10
	xor	a
	call	fillvram
	jp	editor_cont

Searchhok:	defw	Eh1,Eh2,Eh2,Eh2,Eh2,Eh2,Eh3,0
Search:	defb	"Search",0
Replace1:	defb	"Replace",0
Forward:	defb	"Forward",0
Back:	defb	" Back  ",0
;Conditional: defb    "un","conditional",0  ********************************
Upper:	defb	"Upper",0
On:	defb	"on ",0
Off:	defb	"off",0

;#### LEAVE IN THIS ORDER!!!! ####
Searchlengte:	defb	0
Searchreplac:	defb	0	;0=search, 1=replace
Vooruitachte:	defb	0	;0=forward, 1=backwards
Searchupper:	defb	0	;0=upper off, 1=upper on

Searchtext:	defs	26
Replacetext:	defs	26

;##### Search next
__searchnext:
	ld	a,(Searchnext)
	or	a
	jp	nz,_searchcont
	call	beep
	jp	editor_cont

Searchnext:	defb	0

;##### Jump to line
__jmpline_err:
	call	beep
__jmpline:
	ld	hl,11*80+20
	ld	de,Gohok
	call	printblokkle
	ld	hl,12*80+24
	ld	bc,Jumptoline
	call	printtekst
	ld	hl,12*80+30
	ld	de,kbuf
	ld	b,30
	ld	a,%10100001
	call	inputtext
	jp	c,editor_cont	;escape
	ld	hl,kbuf
	call	berekengetal
	jr	c,__jmpline_err
	ld	h,d
	ld	l,e
	ld	a,h
	or	l
	jr	z,__jmpline_err
	dec	hl
	ld	bc,(Laatsteregel)
	or	a
	sbc	hl,bc
	jr	c,__jmpline_1
	ld	d,b
	ld	e,c
__jmpline_1:	ld	(Regelnr),de
	jp	_home_cont
Jumptoline:	defb	"Line:",0

;##### Delete source
__delsource:
	ld	hl,80*Commline+(80-35)/2
	ld	bc,Deletesource
	call	txttocomm
	call	areyousure
	jr	c,__delsource_1
	call	delsource1
__delsource_1:
	call	wiscommline
	jp	editor_cont
Deletesource:	defb	"Delete source: ",0

delsource1:
	call	wistext	;clear text buffer
	ld	a,(Aantaldatabl)
	ld	b,a
	ld	ix,Databuffers
	call	_wisbuffer1	;clear data buffer
	ld	a,1
	call	zetdatablok
	ld	a,#ff
	ld	(#8000),a	;end of data buffer
	jp	ini_variabel

Menu3:
	defb	6,16,0
	defb	"Show errors   ^R"
	defb	"Show labels   ^B"
	defb	"Search        ^Z"
	defb	"Search next   ^N"
	defb	"Jump to line  ^J"
	defb	"Delete source   "

;********************* MENU 4

Menu4optie:	defb	1
Menu4blink:	defw	#2f04
Plmenu4:	equ	3*80+45

menu4:
	ld	a,4
	ld	(Lastmenu),a
	ld	hl,Plmenu4
	ld	ix,Menu4
	call	printmenu
_menu4_2:
	ld	ix,Menu4
_menu4_1:	ld	a,(Menu4optie)
	ld	c,a
	ld	hl,(Menu4blink)
	call	kiesoptie
	ld	b,a
	ld	(Menu4blink),hl
	ld	a,c
	ld	(Menu4optie),a
	ld	hl,Plmenu4
	push	bc
	call	wisoudmenu
	pop	bc
	call	testfkey
	jp	nc,startmenu
	ld	a,b
	cp	Escape
	jp	z,editor_cont
	cp	1
	jp	z,editor_cont
	cp	Right
	jp	z,menu5
	cp	Left
	jp	z,menu3
	and	255-32
	jr	nz,menu4
_menu4_space:
	ld	hl,Menu4opties
	jp	menuoptie

Menu4opties:	defw	__assemble,__assdisk,__asstsr,__assrel,__reg,__go

;##### Assemble
__assemble:
	call	iniasm
	call	inishowlab
	call	GOassemblere
	jp	editor_cont

;#####         Assemble                 to disk
__assdisk:
	call	iniasm
	call	inishowlab
	ld	ix,Pointerasm
	ld	b,1
	call	gotodisk
	jp	editor_cont
inishowlab:
	ld	a,1
	ld	(Showlab1ek),a
	ld	(Showlabels),a
	ret
inishowlab1:
	call	inishowlab
	xor	a
	ld	(Showlabels),a
	ret
Pointerasm:	defw	GOassembledi,GOasstsr,GOrelocatabl

;##### Assemble TSR
__asstsr:
	call	iniasm
	call	inishowlab
	ld	ix,Pointerasm
	ld	b,2
	call	gotodisk
	jp	editor_cont

;##### Assemble relocatable
__assrel:
	call	iniasm
	call	inishowlab
	ld	ix,Pointerasm
	ld	b,3
	call	gotodisk
	jp	editor_cont

;##### Registers

Regoptie:	db	1,1

__reg:
	call	getregisters
	ld	de,Registers
	ld	bc,Endreg-Registers
	ldir
	ld	hl,9*80+12
	ld	de,Reghok
	call	printblokkle

reg_hoofdprt:
	call	printreg
reg_hoofd:
	ld	iy,Regoptie
	call	zetregbalk
	push	iy
	call	getkey
	pop	iy
	ld c,a
	call CheckRegSortcut	;Does not return if suitable shortcut found
	ld a,c
	cp	Right
	jr	z,reg_right
	cp	Left
	jr	z,reg_left
	cp	Up
	jr	z,reg_up
	cp	Down
	jr	z,reg_down
	cp	27
	jr	z,reg_end
	cp	1
	jr	z,reg_end
	cp	13
	jp	z,reg_space
	and	255-32
	jp	z,reg_space
	jr	reg_hoofd

reg_end:
	call	wisregbalk
	call	getregisters
	ex	de,hl
	ld	hl,Registers
	ld	bc,Endreg-Registers
	ldir
	jp	editor_cont


reg_right:
	ld	a,(iy+1)
	cp	2+1
	ld	b,4
	jr	c,_reg_right1
	dec	b
	cp	3
	jr	z,_reg_right1
	ld	b,7
_reg_right1:
	ld	a,(iy)
	cp	b
	jr	z,reg_hoofd
	call	wisregbalk
	inc	(iy)
	jr	reg_hoofd
reg_left:
	ld	a,(iy)
	dec	a
	jr	z,reg_hoofd
	call	wisregbalk
	dec	(iy)
	jr	reg_hoofd
reg_up:
	ld	a,(iy+1)
	dec	a
	jr	z,reg_hoofd
	call	wisregbalk
	ld	a,(iy+1)
	dec	(iy+1)
	cp	4
	jp	nz,reg_hoofd
	ld	a,(iy)
	cp	3
	jp	c,reg_hoofd
	ld	(iy),3
	jp	reg_hoofd
reg_down:
	ld	a,(iy+1)
	cp	4
	jp	z,reg_hoofd
	call	wisregbalk
	ld	a,(iy+1)
	inc	(iy+1)
	cp	2
	jr	nz,reg_down1
	ld	a,(iy)
	cp	4
	jp	nz,reg_hoofd
	ld	(iy),3
	jp	reg_hoofd
reg_down1:
	cp	3
	jp	nz,reg_hoofd
	ld	a,(iy)
	cp	2
	jp	c,reg_hoofd
	ld	(iy),2
	jp	reg_hoofd

reg_space:
	ld	a,(iy+1)
	cp	4
	jr	z,_reg_space1
	dec	a
	rlca
	rlca
	add	a,(iy)
	dec	a
	ld	l,a
	ld	h,0
	add	hl,hl
	add	hl,hl
	add	hl,hl
	ex	de,hl
	ld	ix,Reg_info
	add	ix,de
	ld	hl,19*80
	ld	de,kbuf+40
	ld	bc,3*80
	call	vramtoram
	ld	hl,19*80+12
	ld	de,Reghok1
	call	printblokkle
	push	ix
	pop	hl
	inc	hl
	inc	hl
	ld	de,20*80+14
	ld	bc,4
	call	ramtovram
_reg_space2:
	push	ix
	ld	hl,20*80+19
	ld	de,kbuf
	ld	b,30
	ld	a,%11000001
	call	inputtext
	pop	ix
	jr	c,reg_space3	;escape
	push	ix
	ld	hl,kbuf
	call	berekengetal
	pop	ix
	jr	c,_reg_space2
	ld	l,(ix+6)
	ld	h,(ix+7)
	ld	(hl),e
	inc	hl
	ld	(hl),d
reg_space3:
	ld	hl,kbuf+40
	ld	de,19*80
	ld	bc,3*80
	call	ramtovram
	jp	reg_hoofdprt
_reg_space1:
	ld	a,(iy)
	dec	a
	jr	nz,_reg_space4
	ld	a,(Reg_di_ei)
	xor	1
	ld	(Reg_di_ei),a
	jp	reg_hoofdprt
_reg_space4:
	ld	b,a
	ld	a,(Reg_af)
	dec	b
	jr	nz,_reg_sp4_1
	xor	#40
_reg_sp4_1:
	dec	b
	jr	nz,_reg_sp4_2
	xor	1
_reg_sp4_2:
	dec	b
	jr	nz,_reg_sp4_3
	xor	2
_reg_sp4_3:
	dec	b
	jr	nz,_reg_sp4_4
	xor	4
_reg_sp4_4:
	dec	b
	jr	nz,_reg_sp4_5
	xor	#10
_reg_sp4_5:
	dec	b
	jr	nz,_reg_sp4_6
	xor	#80
_reg_sp4_6:
	ld	(Reg_af),a
	jp	reg_hoofdprt

printreg:
	ld	hl,Regtxt
	call	texttoblok
	ld	ix,Reg_info
	ld	b,11
_printreg1:
	push	bc
	ld	e,(ix)
	inc	ix
	ld	d,(ix)
	inc	ix
	push	ix
	pop	hl
	ld	bc,4
	call	ramtovram
	ld	de,4
	add	ix,de
	ld	a," "
	out	(#98),a
	ld	l,(ix)
	inc	ix
	ld	h,(ix)
	inc	ix
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	set	7,h
	ld	b,4
	call	printhexadec
	pop	bc
	djnz	_printreg1

	ld	hl,16*80+20
	ld	a,(Reg_di_ei)
	add	a,"D"
	call	writevram
	ld	a,"I"
	out	(#98),a

	ld	a,(Reg_af)
	ld	b,a
	bit	6,b
	ld	hl,16*80+35
	ld	a,0	;LEAVE IT !
	call	nz,writevram
	bit	0,b
	ld	hl,16*80+40
	ld	a,0	;LEAVE IT !
	call	nz,writevram
	bit	1,b
	ld	hl,16*80+46
	ld	a,"1"
	call	nz,writevram
	bit	2,b
	ld	hl,16*80+51
	ld	a,"O"
	call	nz,writevram
	bit	4,b
	ld	hl,16*80+56
	ld	a,"1"
	call	nz,writevram
	bit	7,b
	ld	hl,16*80+60
	ld	a,"M"
	call	nz,writevram
	ret

zetregbalk:
	call	berregbalk
	jp	setbalk
wisregbalk:
	call	berregbalk
	jp	wisbalk
berregbalk:
	ld	a,(iy+1)
	cp	4
	jr	z,_berregbalk2
	ld	a,13-14
	ld	b,(iy)
_berregbalk1:
	add	a,14
	djnz	_berregbalk1
	ld	h,a
	ld	a,(iy+1)
	add	a,11
	ld	l,a
	ld	b,12
	ret
_berregbalk2:
	ld	a,(iy)
	cp	1
	ld	hl,20*256+16
	ld	b,2
	ret	z
	ld	l,16
	ld	b,a
	rlca
	rlca
	add	a,b
	add	a,34-5-5
	ld	h,a
	ld	b,3
	ret


;Check if the key passed in A corresponds to a register/flag shortcut,
;if so select the register/flag and edit/toggle it without returning,
;otherwise just return.

CheckRegSortcut:
	or 32
	ld b,a
	ld a,(Matrix+6)
	rra
	jr c,CheckRegSortcut_NoShift
	set 7,b
CheckRegSortcut_NoShift:
	ld hl,RegShortcuts
CheckRegSortcutLoop:
	ld a,(hl)
	or a
	ret z
	inc hl
	cp b
	jr z,RegShortcutFound
	inc hl
	inc hl
	jr CheckRegSortcutLoop
RegShortcutFound:
	push hl
	ld	iy,Regoptie
	call	wisregbalk
	pop hl
	ld a,(hl)
	ld (iy),a
	inc hl
	ld a,(hl)
	ld (iy+1),a
	pop hl	;Remove return address from stack
	ld a,c
	call printreg
	call	zetregbalk
	jp reg_space

;Register keyboard shortcuts table
;Format: key (+128 for +Shift),X coord,Y coord

RegShortcuts:
	db 'a',1,1
	db 'b',2,1
	db 'd',3,1
	db 'h',4,1
	db 'x',1,3
	db 'y',2,3
	db 's',3,3
	db 'i',1,4
	db 'z',2,4
	db 'c',3,4
	db 'n',4,4
	db 'o',5,4
	db 'g',6,4
	db 'm',7,4
	db 'a'+128,1,2
	db 'b'+128,2,2
	db 'd'+128,3,2
	db 'h'+128,4,2
	db 0

Registers:
Reg_sp:	defw	0
Reg_iy:	defw	0
Reg_ix:	defw	0
Reg_bc_:	defw	0
Reg_de_:	defw	0
Reg_hl_:	defw	0
Reg_af_:	defw	0
Reg_bc:	defw	0
Reg_de:	defw	0
Reg_hl:	defw	0
Reg_af:	defw	0
Reg_di_ei:	defb	0	;0=di, 1=ei
Endreg:

Reg_info:
	defw	12*80+14
	defb	"AF :"
	defw	Reg_af
	defw	12*80+28
	defb	"BC :"
	defw	Reg_bc
	defw	12*80+42
	defb	"DE :"
	defw	Reg_de
	defw	12*80+56
	defb	"HL :"
	defw	Reg_hl
	defw	13*80+14
	defb	"AF':"
	defw	Reg_af_
	defw	13*80+28
	defb	"BC':"
	defw	Reg_bc_
	defw	13*80+42
	defb	"DE':"
	defw	Reg_de_
	defw	13*80+56
	defb	"HL':"
	defw	Reg_hl_
	defw	14*80+14
	defb	"IX :"
	defw	Reg_ix
	defw	14*80+28
	defb	"IY :"
	defw	Reg_iy
	defw	14*80+42
	defb	"SP :"
	defw	Reg_sp


Reghok:	defw	Rh1,Rh2,Rh2,Rh2,Rh2,Rh2,Rh2,Rh2,Rh3,0
Reghok1:	defw	Rh1,Rh2,Rh3,0
Rh1:	defb	1,24,54,23,1,25,0
Rh2:	defb	1,22,54,0,1,22,0
Rh3:	defb	1,26,54,23,1,27,0

Regtxt:
	defw	10*80+35
	defb	"Registers:",0
	defw	16*80+27
	defb	"Flags:  NZ   NC  N:0   PE  H:0   P",0
;                             ^^^  ^^^  ^^^  ^^^  ^^^  ^^^
	defw	0



;##### Go
__go_error:
	call	beep
__go:
	xor	a
	ld	(Aantalerrors),a
	ld	(Showlabels),a
	ld	hl,11*80+20
	ld	de,Gohok
	call	printblokkle
	ld	hl,12*80+24
	ld	bc,Go
	call	printtekst
	ld	hl,12*80+27
	ld	de,Gotxt
	ld	b,30
	ld	a,%11000001
	call	inputtext
	jp	c,editor_cont	;escape
	ld	hl,Gotxt
	ld	de,kbuf
	push	de
	ld	bc,31
	ldir		;AMOUNT MUST BE IN PAGE 0 !!!
	pop	hl
	call	berekengetal
	jr	c,__go_error
	ld	h,d
	ld	l,e	;start address
	ld	(Startadres),hl
	call	oldfkey
	call	oldscreen
	ld	hl,Data
	call	startprogram
	call	screencompas
	call	changefkey
	call	tekenscherm
	ld	hl,(#f3f8)
	ld	(#f3fa),hl	;key getadres = putaddress
	jp	editor_cont
Data:	defb	#cd	;call
Startadres:	defw	0
	defb	0	;4th byte
Gohok:	defw	Eh1,Eh2,Eh3,0
Go:	defb	"Go "
Gotxt:	defs	30+1


Menu4:
	defb	6,19,0
	defb	"Assemble         ^A"
	defb	"Assemble to disk ^Y"
	defb	"Assemble to TSR    "
	defb	"Assemble to REL    "
	defb	"Registers        ^I"
	defb	"Go               ^G"


;************************** MENU 5

Menu5optie:	defb	1
Menu5blink:	defw	#3b04
Plmenu5:	equ	3*80+57

menu5:
	ld	a,5
	ld	(Lastmenu),a
	ld	hl,Plmenu5
	ld	ix,Menu5
	call	printmenu
_menu5_2:
	ld	ix,Menu5
_menu5_1:	ld	a,(Menu5optie)
	ld	c,a
	ld	hl,(Menu5blink)
	call	kiesoptie
	ld	b,a
	ld	(Menu5blink),hl
	ld	a,c
	ld	(Menu5optie),a
	ld	hl,Plmenu5
	ld	a,b
	cp	Right
	jr	z,_menu5_1
	push	bc
	call	wisoudmenu
	pop	bc
	call	testfkey
	jp	nc,startmenu
	ld	a,b
	cp	Escape
	jp	z,editor_cont
	cp	1
	jp	z,editor_cont
	cp	Left
	jp	z,menu4
	and	255-32
	jr	nz,menu5
_menu5_space:
	ld	hl,Menu5opties
	jp	menuoptie

Menu5opties:	defw	zetstartblok,zeteindeblok,wisstarteind,copyblock
	defw	moveblock,delblock,toprinter,copylabel

Menu5:
	defb	8,15,0
	defb	"Start block  ^S"
	defb	"End block    ^E"
	defb	"Remove block ^T"
	defb	"Copy block   ^K"
	defb	"Move block   ^V"
	defb	"Delete block ^W"
	defb	"Print block  ^P"
	defb	"Copy label   ^L"

menuoptie:
	dec	c
	rlc	c
	ld	b,0
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	jp	(hl)

;----- Question: are you sure? OUT: [C]=no

areyousure:
	ld	a,1
	ld	(Cursoronoff),a
	ld	h,#80
	ld	bc,Areyousure
	call	printtekst
	call	getkey
	push	af
	call	wiscommline
	pop	af
	and	%11011111
	cp	"Y"
	ret	z
	or	a
	ret	z
	scf
	ret
Areyousure:	defb	"Are you sure ? (y/n)",0

gobios:	;***************used???***********************************
	push	iy
	ld	iy,(#fcc0)
	call	#1c
	pop	iy
	ret

;########### Enables buffer A and tests if it is OK
;----- IN:  A=buffer
;----- OUT: [C]=error, (Oldbuffer)=old buffer

setnewbuffer:
	call	setbuffer
	ld	a,(Aantaltextbl)
	or	a
	jr	z,_setnewbuf1	;no text blocks
	ld	a,(Aantaldatabl)
	or	a
	jr	z,_setnewbuf1	;no data blocks
	xor	a
	ret
_setnewbuf1:
	ld	a,(Oldbuffer)
	call	setbuffer
	scf
	ret


;##################### toggle current text+data buffer
;----- IN: A=buffer

setbuffer:
	call	setbuffonly
setbuffer1:
	ld	a,(Aantaldatabl)
	or	a
	jr	z,_data_error	;ret z
	ld	a,(Aantaltextbl)
	or	a
	jr	z,_data_error
	ld	a,1
	call	zetdatablok
	ld	de,#8000
	call	getdatbuffer
	cp	#ff
	ret	z
	cp	16+1
	jr	nc,_data_error
	call	getdatbuffer	;possibly simpler since address
	call	getdatbuffer	;8001 or 8002 is *********************
	and	%11000000
	cp	%10000000
	ret	z
_data_error:
	call	wisbuffer
	jp	ini_variabel

setbuffonly:
	push	af	;better****ex af, af'*******?
	ld	a,(Textbuffer)
	ld	(Oldbuffer),a
	call	putinst
	pop	af
setbuffonly1:
	ld	(Textbuffer),a	;LEAVE !!!
	ld	b,a
	ld	hl,Textbuffer1-(Textbuffer2-Textbuffer1)
	ld	de,Textbuffer2-Textbuffer1
_setbuffer1:	add	hl,de
	djnz	_setbuffer1
	ld	b,d
	ld	c,e
	ld	de,Aantaltextbl
	ldir
	call	positie_adre
	ldir
	jp	iniasm1

;store current position/parameters in buffer A
putinst:
	call	positie_adre
	ex	de,hl
	ldir
	ret

positie_adre:
	ld	a,(Textbuffer)
	ld	b,a
	ld	hl,Positie1-(Positie2-Positie1)
	ld	de,Positie2-Positie1
_setbuffer2:	add	hl,de
	djnz	_setbuffer2
	ld	b,d
	ld	c,e
	ld	de,Editor_y
	ret

iniasm:
	ld	hl,(Laatsteregel)
	dec	hl
	ld	a,h
	or	l
	jp	z,editor_cont
iniasm1:
	ld	a,(Labellengte)
	ld	(Huidiglablen),a
	add	a,2
	ld	(Tabs),a
	add	a,8
	ld	(Tabs+1),a
	add	a,17
	ld	(Tabs+2),a
	ld	a,(Upperonoff)
	ld	(Huidigupper),a
	ret

;#################### Clear text buffers

wistext:
	ld	a,(Aantaltextbl)
	ld	b,a
	ld	ix,Textbuffers
	call	_wisbuffer1
	ld	a,(Textbuffer)
	ld	b,a
	ld	a,(Blokbuffer)
	cp	b
	ret	nz
	ld	hl,0
	ld	(Blokstart),hl
	ld	(Blokeinde),hl
	xor	a
	ld	(Blokbuffer),a
	ret

wisbuffer:
	call	wistext
;              ld      a,(Aantaldatabl)  ***********************??????
;              ld      b,a
;              ld      ix,Databuffers
;              call    _wisbuffer1
	ld	a,1
	call	zetdatablok
	ld	a,#ff
	ld	(#8000),a	;end of data buffer
	ld	a,(Doinclude)
	or	a
	ret	nz
	call	inishowlab1
	ld	a,(Aantallabelb)
	ld	b,a
	ld	ix,Labelbuffers

_wisbuffer1:
	ld	a,b
	or	a
	ret	z
_wisbuffer2:
	push	bc
	ld	a,(ix)
	inc	ix
	ld	h,#80
	call	slot
	ld	a,(ix)
	inc	ix
	call	#0131	;fe*******************************
	ld	hl,#8000
	ld	de,#8001
	ld	bc,#3fff
	ld	(hl),0
	ldir
	pop	bc
	djnz	_wisbuffer2
	ret

ini_variabel:
	ld	hl,1
	ld	(Regelnr),hl
	ld	(Laatsteregel),hl
	ld	a,(Labellengte)
	add	a,2
	ld	(Tabs),a
	inc	a
	ld	(Editor_x),a
	add	a,8-1
	ld	(Tabs+1),a
	add	a,17
	ld	(Tabs+2),a
	ld	a,Bovenaantext
	ld	(Editor_y),a
	xor	a
	ld	(Free_bekend),a
	LD	(afb_offset),A
	inc	a
	ld	(Balkerror),a

;              ld      a,(Doinclude)    ;**********************
;              or      a
;              ret     nz
;              ld      (Aantalerrors),a ;=0

	ld	a,(#fcc1)
	ld	hl,#2d
	call	#0c
	cp	3
	ld	a,0
	jr	c,_noturbor
	inc	a
_noturbor:	ld	(Turbor),a
	ret

;########################### Draw screen

tekenscherm:
	ld	hl,Teksten
	call	texttoblok
	ld	hl,#1800+25*10
	ld	bc,2*10
	ld	a,255
	jp	fillvram

Teksten:
	defw	31
	defb	"Assembler",0
	defw	25*80+1
	defb	"Line:      /",0
	dw	25*80+21
	db	"Col:",0
	defw	25*80+32
	defb	"Ins:",0
	defw	25*80+43
	defb	"Block:",0
	defw	25*80+64
	defb	"Sourcebuffer:",0
	defw	2*80
	defb	23,23,23,23," SYSTEM ",23,23,23,23,23
	defb	" CONFIGURATION ",23,23,23,23,23," OPTIONS ",23,23,23,23
	defb	23," ASSEMBLE ",23,23,23,23,23," BLOCK "
	defb	23,23,23,23,23,23,23,0
	defw	0



;########################### Controls in editor

Bovenaantext:	equ	4	;y position on top
Onderaantext:	equ	25	;y position at the bottom
Aantalrgltxt:	equ	22	;number of lines

bufferfout:	;cursor too high !
	call	wisbuffer
	jr	editor_cont

editor:
	ld	(Sp_editor),sp
editor_cont:
	xor	a
	ld	(Veranderd),a
	call	wiscommline
	call	printscherm
editorbestur:
	ld	sp,(Sp_editor)
	ld	hl,(Editor_y)
	ld	a,l
	cp	Bovenaantext
	jr	c,bufferfout	;!!!!! (cursor too high)
	LD	A,(afb_offset)
D5098:	LD	B,A
J5099:	LD	A,H
	SUB	B
	LD	H,A
	ld	(Cursorpositi),hl
	xor	a
	ld	(Bronerrors),a	;editor errors
	ld	(Doinclude),a	;FOR SAFETY
	ld	(Cursoronoff),a	;cursor on
	call	printinfoRnr

	ld	bc,#0101
	call	mouseoffset
	call	#0134	;******************** used to be getkey****
	cp	241
	jr	c,_noctrl1234
	cp	245
	jp	c,ctrl_1234
_noctrl1234:
	ld	b,a
	ld	a,(Matrix+6)
	srl	a
	jp	nc,editor_shift
	srl	a
	jr	nc,editor_ctrl
	srl	a
	jp	nc,edit_graph

editor_norm:
	ld	a,(Lastmenu)
	ld	c,a
	ld	a,b
	dec	a
	jp	z,startmenu
	call	testfkey
	jp	nc,startmenu
	ld	ix,Normcommando
	ld	iy,Normadressen
	ld	c,0
	call	testkey
	ld	a,b
	cp	32
	jp	c,editorbestur
	cp	127
	jp	c,edit_letter
	jp	editorbestur
editor_ctrl:
	ld	a,(Matrix+4)
	rlca
	jp	nc,printerrors1	;ctrl-r = ins, therefore here
	ld	a,(Matrix+6)
	ld	d,1
	rlca
	jr	nc,ctrl_fkey
	inc	d
	rlca
	jr	nc,ctrl_fkey
	inc	d
	rlca
	jr	nc,ctrl_fkey
	ld	a,(Matrix+7)
	inc	d
	rrca
	jr	nc,ctrl_fkey
	inc	d
	rrca
	jr	nc,ctrl_fkey
	ld	ix,Ctrl_no_ret
	ld	iy,Ctrladressen
	ld	c,0
	call	testkey
	ld	ix,Ctrl_met_ret
	ld	iy,Ctrladresret
	ld	c,1
	call	testkey
	jp	editor_norm


ctrl_1234:
	push	af
	call	edit_ret1
	pop	af
	sub	240
	call	setnewbuffer
	jp	editor_cont

ctrl_fkey:
	call	berfkeyadr
	ld	de,(Regelnr)
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	ld	a,(Textbuffer)
	ld	(hl),a
	call	wiskeybuffer
	jp	editorbestur
berfkeyadr:
	ld	a,d
	add	a,a
	add	a,d
	ld	l,a
	ld	h,0
	ld	de,Fkeyregels-3
	add	hl,de
	ret
shift_fkey:
	push	de
	call	edit_ret1
	pop	de
	call	berfkeyadr
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	a,(hl)
	OR	A
	JR	Z,shift_fkey1
	push	de
	call	setnewbuffer
	pop	de
	jr	c,shift_fkey1
	ld	a,d
	or	e
	jr	z,shift_fkey1
	ld	hl,(Laatsteregel)
	or	a
	sbc	hl,de
	jr	c,shift_fkey1
	ld	(Regelnr),de
	call	wiskeybuffer
	jp	_home_cont
shift_fkey1:
	jp	editorbestur

Fkeyregels:	defs	5*3

editor_shift:
	LD	A,(Matrix+7)
	AND	#04
	JP	Z,__shell
	ld	a,(Matrix+6)
	ld	d,1
	rlca
	jr	nc,shift_fkey
	inc	d
	rlca
	jr	nc,shift_fkey
	inc	d
	rlca
	jr	nc,shift_fkey
	ld	a,(Matrix+7)
	inc	d
	rrca
	jr	nc,shift_fkey
	inc	d
	rrca
	jr	nc,shift_fkey

	ld	a,b
	cp	Down
	jp	z,Shiftdown
	cp	Up
	jp	z,Shiftup
	cp	Right
	jp	z,shiftright
	cp	Left
	jp	z,shiftleft
	cp	Ins
	jp	z,ins10line
	cp	Del
	jp	z,delrestline
	jp	editor_norm

Select: equ 24
Normcommando:
	defb	Left,Right,Down,Up,Ins,Tab,Return,Bs,Del,Home,250,Select,0
Normadressen:
	defw	editor_left,editor_right,editor_down,editor_up
	defw	editor_ins,editor_tab,edit_ret,edit_bs,edit_del
	defw	edit_home,__mon,__deb

Ctrl_no_ret:
	defb	Right,Left,Ctrl_l,0
Ctrladressen:
	defw	edit_ctrlrig,edit_ctrllef,copylabel
Ctrl_met_ret:
	defb	Down,Up,Ctrl_s,Ctrl_e,Ctrl_t
	defb	Ins,Del,Ctrl_a,Ctrl_p,Ctrl_w,Ctrl_k,Ctrl_v
	defb	Ctrl_j,Ctrl_g,Ctrl_q,Ctrl_z,Ctrl_n
	defb	Ctrl_d,Ctrl_c,Ctrl_y,Ctrl_i,Ctrl_b,0
Ctrladresret:
	defw	edit_fastdow,edit_fastup,zetstartblok,zeteindeblok
	defw	wisstarteind
	defw	edit_insline,edit_delline,__assemble,toprinter
	defw	delblock,copyblock,moveblock,__jmpline,__go,__quit
	defw	__search,__searchnext
	defw	__disk,__calc,__assdisk,__reg,__labels


;----- Test whether B=function key, if so: C=menu no (1-5) and [NC]

testfkey:
	ld	a,b
	cp	251
	ret	c
	xor	a
	sub	b
	ld	c,a
	xor	a
	ret

;----- Test whether key is pressed+start program IN: B=key+C OFF: [C]=no
;----- Pop't call if correct key

testkey:
	ld	a,(ix)
	inc	ix
	or	a
	scf
	ret	z	;wrong key
	cp	b
	jr	z,_testkey1
	inc	iy
	inc	iy
	jr	testkey
_testkey1:	pop	hl	;remove call !!!
	ld	l,(iy)
	ld	h,(iy+1)
	push	hl
	ld	a,c
	or	a
	call	nz,edit_ret1
	pop	hl
	jp	(hl)	;start address



;######################## Editor commands worked out

;----- Ctrl+g: Go to line

Shiftdown:
	call	edit_ret1
	ld	b,100
	jr	edit_fastdo1
edit_fastdow:
	ld	b,Aantalrgltxt
edit_fastdo1:	push	bc
	call	downschuif
	call	c,downnormal
	pop	bc
	jr	c,edit_fastdo2
	djnz	edit_fastdo1
edit_fastdo2:	call	printscherm
	jp	editorbestur

editor_down:
	call	edit_ret1
editor_djon	call	downnormal
	jp	nc,editorbestur
	call	downschuif
	call	printscherm
	jp	editorbestur

downnormal:
	ld	hl,Editor_y
	ld	a,(hl)
	cp	Onderaantext
	scf
	ret	z
	ld	hl,(Regelnr)
	ld	de,(Laatsteregel)
	call	rst20
	ret	z
	ld	hl,Editor_y
	inc	(hl)
	ld	hl,(Regelnr)
	inc	hl
	ld	(Regelnr),hl
	or	a
	ret

downschuif:
	ld	hl,(Regelnr)
	ld	a,(Editor_y)
	ld	b,a
	ld	a,Onderaantext
	sub	b
	ld	e,a
	ld	d,0
	add	hl,de
	ld	de,(Laatsteregel)
	call	rst20
	ccf
	ret	c
	ld	hl,(Regelnr)
	inc	hl
	ld	(Regelnr),hl
	or	a
	ret

Shiftup:
	call	edit_ret1
	ld	b,100
	jr	edit_fastup1
edit_fastup:
	ld	b,Aantalrgltxt
edit_fastup1:	push	bc
	call	upschuif
	call	c,upnormal
	pop	bc
	jr	c,edit_fastup2
	djnz	edit_fastup1
edit_fastup2:	call	printscherm
	jp	editorbestur

editor_up:
	call	edit_ret1
	call	upnormal
	jp	nc,editorbestur
	call	upschuif
	call	printscherm
	jp	editorbestur

upnormal:
	ld	hl,Editor_y
	ld	a,(hl)
	cp	Bovenaantext
	scf
	ret	z
	dec	(hl)
	ld	hl,(Regelnr)
	dec	hl
	ld	(Regelnr),hl
	or	a
	ret
upschuif:
	ld	hl,(Regelnr)
	ld	a,(Editor_y)
	sub	Bovenaantext
	ld	e,a
	ld	d,0
	scf
	sbc	hl,de
	ld	a,h
	or	l
	scf
	ret	z
	ld	hl,(Regelnr)
	dec	hl
	ld	(Regelnr),hl
	or	a
	ret


editor_left:
	ld	hl,Editor_x
	ld	a,(hl)
	DEC	A
	JP	Z,editorbestur
	DEC	(HL)
	LD	A,(#F3DD)	;********************************
	DEC	A
	JP	NZ,editorbestur
	LD	HL,afb_offset
	DEC	(HL)
	CALL	printscherm
	JP	editorbestur

editor_right:
	ld	hl,Editor_x
	ld	a,(hl)
	cp	160
	jp	z,editorbestur
	inc	(hl)
	LD	A,(#F3DD)	;*********************
	CP	#50
	JP	NZ,editorbestur
	LD	HL,afb_offset
	INC	(HL)
	CALL	printscherm
	jp	editorbestur

editor_ins:
	ld	a,(Insonoff)
	xor	1
	ld	(Insonoff),a
	jp	editorbestur

;org 5381:

;----- Small to large, large to small

edit_graph:
	CALL	C53DC
	CALL	C53EE
	ld	a,(Matrix+8)
	bit	7,a
	ld	d,0
	jr	z,edit_graphok
	bit	4,a
	jp	nz,editorbestur
	DEC	HL
	LD	A,(Editor_x)
	DEC	A
	jp	z,editorbestur
	inc	d
edit_graphok:	push	de
	ld	a,(hl)
	cp	"A"
	jr	c,_nograph
	cp	"Z"+1
	jr	nc,edit_graph1
	or	%100000
	jr	edit_graph2
edit_graph1:	cp	"a"
	jr	c,_nograph
	cp	"z"+1
	jr	nc,_nograph
	and	%11011111
edit_graph2:	ld	(hl),a
_nograph:	call	J53F9
	pop	af
	or	a
	jp	nz,editor_left
	jp	editor_right

;----- letter keyed in

edit_letter:
	call	edit_letter1
	CALL	J53F9
	jp	editor_right
edit_letter1:
	push	af
	CALL	C53DC
	ld	a,(Insonoff)
	or	a
	call	nz,edit_do_ins
	CALL	C53EE
	pop	af
	LD	(HL),A
	ret

C53DC:	LD	HL,Veranderd
	LD	A,(HL)
	OR	A
	RET	NZ
	LD	(HL),1
	LD	HL,Labelbuffer
	LD	DE,(Regelnr)
	JP	J6876	;*************************

C53EE:	LD	HL,Labelbuffer-1
	LD	A,(Editor_x)
	LD	E,A
	LD	D,#00
	ADD	HL,DE
	RET

J53F9:	CALL	bervram
	CALL	setvramwrite
	LD	HL,(afb_offset)
	LD	DE,Labelbuffer
	ADD	HL,DE
	LD	BC,#5098
	OTIR
	RET

	;org 540c
edit_do_ins	CALL	C53DC
	LD	A,(Editor_x)
	LD	B,A
	LD	A,161
	SUB	B
	RET	Z
	CP	1
	RET	Z
	LD	C,A
	LD	B,#00
	LD	HL,Labelbuffer+159
	LD	DE,Labelbuffer+160
	LDDR
	RET
;----- TAB

editor_tab:
	CALL	C53DC
	ld	a,(Editor_x)
	LD	B,A
	dec	a
	ld	c,a	;C = current position 0-79
	ld	iy,Tabs
_edit_tab2:	ld	a,(iy)
	inc	iy
	or	a
	jr	z,_edit_tab1
	cp	c
	jr	c,_edit_tab2
	jr	z,_edit_tab2
	ld	c,a
_edit_tab1:
	ld	a,c
	inc	a
	sub	b	;length
	jr	z,_edit_tab5
	ld	b,a
_edit_tab4:
	push	bc
	ld	a,(Insonoff)
	or	a
	jr	z,_edit_tab3
	call	edit_do_ins
	CALL	C53EE
	LD	(HL),#20
_edit_tab3:
	LD	HL,Editor_x
	INC	(HL)
	pop	bc
	djnz	_edit_tab4
_edit_tab5:
	CALL	J53F9
	LD	HL,afb_offset
	LD	A,(Editor_x)
	SUB	(HL)
	CP	81
	JP	C,editorbestur
	LD	A,(HL)
	ADD	A,40
	CP	80
	LD	(HL),80
	JR	NC,_edit_tab6
	LD	(HL),A
_edit_tab6	CALL	printscherm
	jp	editorbestur

	;org 547c

;----- CTRL+RIGHT
edit_ctrlrig:
	CALL	C53DC
	CALL	C53EE
	LD	A,(Editor_x)
	LD	B,A

edit_ctrlri2:	ld	a,b
	cp	160
	jr	z,edit_ctrlri1
	inc	b
	ld	a,(hl)
	inc	hl
	cp	","
	jr	z,edit_ctrlri5
	cp	":"
	jr	z,edit_ctrlri5
	and	%11011111
	jr	nz,edit_ctrlri2
edit_ctrlri5:
	ld	c,b	;separator found
	dec	c
edit_ctrlri3:	ld	a,b
	cp	161
	ld	a,c
	jr	z,edit_ctrlri4
	inc	b
	ld	a,(hl)
	inc	hl
	and	%11011111
	jr	z,edit_ctrlri3
	dec	b
edit_ctrlri1:	ld	a,b
edit_ctrlri4:
	ld	(Editor_x),a
	LD	B,A
	LD	HL,afb_offset
edit_ctrlri6	LD	A,B
	SUB	(HL)
	CP	79
	JR	C,edit_ctrlri7
	LD	A,(HL)
	ADD	A,40
	CP	80
	LD	(HL),80
	JR	NC,edit_ctrlri7
	LD	(HL),A
	JR	edit_ctrlri6
edit_ctrlri7	CALL	printscherm
	jp	editorbestur

;----- CTRL+LEFT
edit_ctrllef:
	CALL	C53DC
	CALL	C53EE
	LD	A,(Editor_x)
	LD	B,A
edit_ctrlle2:	ld	a,b
	cp	1
	jr	z,edit_ctrlle1
	dec	b
	ld	a,(hl)
	dec	hl
	cp	","
	jr	z,edit_ctrlle3
	cp	":"
	jr	z,edit_ctrlle3
	and	%11011111
	jr	nz,edit_ctrlle2
edit_ctrlle3:	ld	a,b
	cp	1
	jr	z,edit_ctrlle1
	dec	b
	ld	a,(hl)
	dec	hl
	and	%11011111
	jr	z,edit_ctrlle3
	inc	b
edit_ctrlle1:	ld	a,b
	ld	(Editor_x),a
	LD	HL,afb_offset
edit_ctrlle4	LD	A,B
	DEC	A
	CP	(HL)
	CCF
	JR	C,edit_ctrlle5
	LD	A,(HL)
	SUB	40
	LD	(HL),0
	JR	C,edit_ctrlle5
	LD	(HL),A
	JR	edit_ctrlle4
edit_ctrlle5	CALL	printscherm
	jp	editorbestur

;----- SHIFT + LEFT
shiftleft:
	CALL	C53DC
	XOR	A
	LD	(afb_offset),A
	INC	A
	LD	(Editor_x),A
	CALL	printscherm
	jp	editorbestur

;----- SHIFT + RIGHT
shiftright:
	CALL	C53DC
	LD	HL,Labelbuffer+159
	LD	A,(Editor_x)
	LD	C,A
	LD	B,160
_shiftright1:
	ld	a,(hl)
	and	255-32
	jr	nz,_shiftright2
	dec	hl
	djnz	_shiftright1
_shiftright2:
	ld	a,b
	cp	160
	jr	z,_shiftright3
	inc	a
_shiftright3:
	CP	C
	JP	C,editorbestur
	JP	edit_ctrlri4


;----- CTRL+S
zetstartblok:
	ld	hl,(Regelnr)
	ld	de,(Laatsteregel)
	call	rst20
	jp	z,editorbestur

	ld	hl,(Regelnr)
	ld	(Blokstart),hl
	ld	a,(Blokbuffer)
	ld	b,a
	ld	a,(Textbuffer)
	cp	b
	jr	z,_zetstartbl2	;same buffer
	ld	(Blokbuffer),a
	ld	hl,(Laatsteregel)
	dec	hl
	ld	(Blokeinde),hl
	jr	_zetstartbl1
_zetstartbl2:
	ld	de,(Regelnr)
	ld	hl,(Blokeinde)
	call	rst20
	jr	nc,_zetstartbl1
	ld	hl,(Laatsteregel)
	dec	hl
	ld	(Blokeinde),hl
_zetstartbl1:
	call	printscherm
	jp	editorbestur

;----- CTRL+E
zeteindeblok:
	ld	hl,(Regelnr)
	ld	de,(Laatsteregel)
	call	rst20
	jr	nz,_zeteindblk3
	dec	hl
	ld	a,h
	or	l
	jp	z,editorbestur
_zeteindblk3:
	ld	(Blokeinde),hl
	ld	a,(Blokbuffer)
	ld	b,a
	ld	a,(Textbuffer)
	cp	b
	jr	z,_zeteindblk2	;same buffer
	ld	(Blokbuffer),a
	ld	hl,1
	ld	(Blokstart),hl
	jr	_zetstartbl1
_zeteindblk2:
	ex	de,hl
	ld	hl,(Blokstart)
	ld	a,h
	or	l
	jr	z,_zeteindblk1
	call	rst20
	jr	c,_zetstartbl1
	jr	z,_zetstartbl1
_zeteindblk1:
	ld	hl,1
	ld	(Blokstart),hl
	jr	_zetstartbl1

;----- CTRL+T
wisstarteind:
	ld	hl,0
	ld	(Blokstart),hl
	ld	(Blokeinde),hl
	xor	a
	ld	(Blokbuffer),a
	call	printscherm
	jp	editorbestur

;----- CTRL+P
toprinter:
	call	testisblock
	ld	bc,Noblock
	jp	c,_noblock
	ld	ix,#a8
	call	gobios
	ld	bc,Prtnotready
	jp	z,_noblock

	call	printini
	ld	a,(Blokbuffer)
	call	setbuffonly

	ld	hl,80*Commline+21
	ld	bc,Printing
	call	txttocomm
	ld	hl,80*Commline+21+17
	ld	de,(Blokeinde)
	ld	b,5
	call	printdecimaa
	ld	hl,(Blokstart)
	ld	(Printline),hl
_printloop:
	ei
	ld	hl,80*Commline+21+9
	ld	de,(Printline)
	ld	b,5	;with leading spaces
	call	printdecimaa
	ei
	ld	a,(Matrix+7)
	and	%00000100
	jr	z,_printabort
	ld	de,(Printline)
	call	haalzinzin
	jr	c,_printend	;end of text
	ld	hl,Zin
	ld	ix,#a5
	ld	b,a	;length
_printnexttk:	ld	a,(hl)
	or	a
	jr	nz,_printteken1
	ld	a," "
_printteken1:	call	gobios
	inc	hl
	djnz	_printnexttk
	ld	a,#0d
	call	gobios
	ld	a,#0a
	call	gobios
	ld	hl,(Printline)
	inc	hl
	ld	(Printline),hl
	dec	hl
	ld	de,(Blokeinde)
	call	rst20
	jr	nz,_printloop

_printend:
	call	wiscommline
	ld	a,(Oldbuffer)
	ld	(Textbuffer),a
	call	setbuffonly
	jp	editor_cont

_printabort:
	call	wiscommline
_printabor1:
	call	getkey	;eliminate test
	ld	a,(Oldbuffer)
	call	setbuffonly
	ld	hl,Commline*80+(80-18)/2
	ld	bc,Printabort
	jr	_noblockcont

_noblock:
	ld	hl,Commline*80+(80-19)/2
_noblockcont:	call	txttocomm
	call	beep
	call	pushanykey
	call	wiscommline
	jp	editor_cont

cursorinblok:
	call	wiscommline
	ld	hl,Commline*80+(80-22)/2
	ld	bc,Cursorinblok
	jr	_noblockcont
Cursorinblok:	defb	"Destination in block !",0

Printabort:	defb	"Printing aborted !",0
Printline:	defw	0	;current line when printing
Printing:	defb	"Printing       -          Esc = abort",0
Prtnotready:	defb	"Printer not ready !",0
Noblock:	defb	"No block selected !",0

testisblock:
	ld	hl,(Blokstart)
	ld	a,h
	or	l
	scf
	ret	z
	ccf
	ret

;----- OFF: 0=before cursor, 1=cursor in block, 2=after cursor
waarisblock:
	ld	a,(Textbuffer)
	ld	b,a
	ld	a,(Blokbuffer)
	cp	b
	ld	a,0
	ret	nz	;other buffer
	ld	hl,(Blokeinde)
	ld	de,(Regelnr)
	call	rst20
	ld	a,0
	ret	c	;in front of
	ld	hl,(Blokstart)
	inc	hl	;1st line is allowed
	ld	de,(Regelnr)
	call	rst20
	ld	a,1
	ret	c	;in
	ret	z
	inc	a
	ret

;----- HOME => To start/end buffer

edit_home:
	ld	a,(Matrix+8)
	and	%10
	jp	nz,editorbestur	;still not pressed

	call	edit_ret1
	ld	hl,(Regelnr)
	dec	hl
	ld	a,h
	or	l
	jr	z,_edit_home1
	ld	hl,1
	ld	(Regelnr),hl
	ld	a,Bovenaantext
	ld	(Editor_y),a
	JR	_edit_home3

_edit_home1:	ld	hl,(Laatsteregel)
	ld	(Regelnr),hl
_home_cont:
	ld	a,Bovenaantext
	ld	(Editor_y),a
	ld	b,10
_edit_home2:	push	bc
	call	upschuif
	pop	bc
	jr	c,_edit_home3
	push	bc
	call	downnormal
	pop	bc
	djnz	_edit_home2
_edit_home3
	LD	A,(Labellengte)
	ADD	A,3
	LD	(Editor_x),A
	XOR	A
	LD	(afb_offset),A
	CALL	printscherm
	jp	editorbestur


;----- RETURN => Sentence to textbuffer

Edit_ret_sp:	defw	0

edit_ret:
	call	C53DC
	ld	a,(Retins)
	or	a
	jr	z,_editret1
	ld	a,(Insonoff)
	or	a
	jr	z,_editret1	;Insert off

	ld	hl,Editor_x
	ld	c,(hl)
	ld	b,0
	ex	de,hl
	ld	hl,Labelbuffer-1
	add	hl,bc
	ex	de,hl
	dec	(hl)
_editret3:
	inc	(hl)
	ld	a,(hl)
	cp	160
	jr	z,_editret2	;insert after current line
	ld	a,(de)
	inc	de
	and	255-32
	jr	z,_editret3

	call	edit_ret2	;insert before current line
	call	insline1
	ld	hl,nietdown
	ld	(jpinvul+1),hl
	ld	hl,(Regelnr)
	push	hl
	jr	_editretcnt1

_editret2:	;Insert after current line
	call	edit_ret2
	ld	hl,(Regelnr)
	push	hl
	inc	hl
	ld	(Regelnr),hl
	call	insline1
_editretcnt1:
	ld	a,(Editor_y)
	cp	15
	jr	c,_editret4
	call	downschuif
	jr	c,_editret4	;can not
	call	upnormal
_editret4:
	pop	hl
	ld	(Regelnr),hl
	call	printscherm
	jr	_editretback

_editret1:
	call	edit_ret2
_editretback:
	ld	a,(Tabsonoff)
	or	a
	jr	z,_editretbac1
	ld	a,(Tabs)
_editretbac1:
	inc	a
	ld	(Editor_x),a
	XOR	A
	LD	(afb_offset),A
	CALL	printscherm
jpinvul	jp	editor_djon
nietdown	ld	hl,editor_djon
	ld	(jpinvul+1),hl
	jp	editorbestur

edit_ret1:
	ld	a,(Veranderd)
	or	a
	ret	z	;no line change
edit_ret2:	xor	a
	ld	(Veranderd),a
	inc	a
	ld	(Printret),a
	ld	hl,Labelbuffer+159	;start at the back
	ld	b,160
	ld	de,Zin+159
_edit_ret2:	ld	a,(hl)
	and	%11011111
	jr	nz,_edit_ret1	;symbol found
	dec	hl
	dec	de
	djnz	_edit_ret2
	jr	_edit_ret3	;empty line

_edit_ret1:	push	de
_edit_ret4:	ld	a,(hl)
	or	a
	jr	nz,_edit_ret5
	ld	a," "
_edit_ret5:	ld	(de),a
	dec	hl
	dec	de
	djnz	_edit_ret4
	pop	de
_edit_ret3:	inc	de
	xor	a
	ld	(de),a


_return_cont:	;CALLING FROM COPYBLOCK !!!
	ld	(Edit_ret_sp),sp
	xor	a
	ld	(Reteinde),a
	call	makeline	;A=length, sentence on ZIN+128
	ld	(Lengtezin),a

	ld	de,(Regelnr)
	call	geefadrrege1	;DE=address data block, C=block
	push	de
	ld	a,c
	push	af
	ld	de,(Regelnr)
	call	geefadrregel	;DE=address textblock, A=block
	jr	nc,editret_wis0

	ld	a,1	;last line
	ld	(Reteinde),a
	ld	hl,Aantaldatabl
	pop	af
	pop	de
	push	de
	push	af
	cp	(hl)
	jr	nz,editret_end
	ld	a,d
	cp	#bf
	jr	c,editret_end
	ld	a,e
	cp	#fd
	jr	c,editret_end
	ld	a,(Bronerrors)
	cp	2	;does it come from linedebugger2editor?
	call	nz,printscherm
	ld	sp,(Edit_ret_sp)
	jp	error2	;data buffer full
editret_end:	ld	hl,(Laatsteregel)
	inc	hl
	ld	(Laatsteregel),hl
	jr	editret_fill

editret_wis0:	push	de
	push	af
	call	zettextblok
	ld	b,0
editret_wis1:	call	gettxtbuffer
	inc	b
	and	%10000000
	jr	z,editret_wis1
	pop	af
	call	zettextblok
	pop	de
editret_wis2:	xor	a
	call	puttxtbuffer
	djnz	editret_wis2	;delete old line

editret_fill:	ld	a,(Lengtezin)
	ld	b,a
	call	freespace	;[C]=full
	jp	c,_bufvol
	ld	b,a
	pop	af
	call	zetdatablok
	pop	de
	ld	a,b
	call	putdatbuffer
	ld	a,l
	call	putdatbuffer
	ld	a,h
	call	putdatbuffer
	ld	a,(Reteinde)
	or	a
	jr	z,edit_no_end
	ld	a,#ff
	ld	(de),a	;end of data buffer

edit_no_end:	ld	a,b
	call	zettextblok
	ld	a,(Lengtezin)
	ld	b,a
	ex	de,hl
	ld	hl,Zin+161
edit_ret_buf:	ld	a,(hl)
	call	puttxtbuffer
	inc	hl
	djnz	edit_ret_buf

edit_ret_end:
	ld	sp,(Edit_ret_sp)
	ld	a,(Printret)
	or	a
	ret	z
	LD	HL,Labelbuffer
	ld	de,(Regelnr)
	call	haalzinHL
	JP	J53F9

	;org 58f8
Printret:	defb	0	;to print ? 1=yes

_bufvol:
	ld	de,(Regelnr)
	call	geefadrregel
	call	zettextblok
	ld	a,#80
	call	puttxtbuffer
	ld	sp,(Edit_ret_sp)
	jp	error1	;text buffer full

Lengtezin:	defb	0
Reteinde:	defb	0	;0=not end, 1=end


;----- BS

edit_bs:
	ld	a,1
	jr	_edit_del1
;----- DEL

Edit_bs:	defb	0
edit_del:
	xor	a
_edit_del1:	ld	(Edit_bs),a
	CALL	C53DC
	ld	hl,0
	LD	(Labelbuffer+160),HL
	LD	HL,Labelbuffer
	ld	a,(Editor_x)
	ld	c,a
	ld	b,0
	add	hl,bc
	ld	a,(Edit_bs)
	or	a
	jr	z,_edit_del2
	dec	hl
_edit_del2:	ld	d,h
	ld	e,l
	dec	de
	ld	bc,162
	ldir
	CALL	J53F9
	ld	a,(Edit_bs)
	or	a
	jp	z,editorbestur
	jp	editor_left

;----- CTRL+B   Copy label
copylabel:
	call	testisblock
	ld	bc,Noblock
	jp	c,_noblock
	ld	a,(Blokbuffer)
	call	setbuffonly
	ld	de,(Blokstart)
	call	haalzinzin
	ld	a,(Oldbuffer)
	call	setbuffonly
	ld	hl,Zin
	LD	C,#FF
	call	labeluitzin
	jp	c,editorbestur	;no label
	ld	a,(Editor_x)
	add	a,b
	cp	162
	jp	nc,editorbestur	;does not fit in line
	ld	hl,Label
_copylabel1:
	push	bc
	push	hl
	ld	a,(hl)
	call	edit_letter1	;move (Changed)=1
	ld	hl,Editor_x
	inc	(hl)
	pop	hl
	inc	hl
	pop	bc
	djnz	_copylabel1
	LD	HL,afb_offset
	LD	A,(Editor_x)
	CP	161
	JR	NZ,J5999
	DEC	A
	LD	(Editor_x),A
J5999:	SUB	(HL)
	CP	78
	JR	C,J59A8
	LD	A,(HL)
	ADD	A,#28
	CP	80
	LD	(HL),80
	JR	NC,J59A8
	LD	(HL),A
J59A8:	CALL	printscherm
	jp	editorbestur

;----- Extracts label definition from sentence at address HL
;----- IN: HL=start address (terminated with 0)
;----- OUT: Label=label, B=length label, [C]=no label present
labeluitzin:
	ld	de,Label
	ld	b,0
	ld	a,(hl)
	or	a
	scf
	ret	z
	cp	9
	scf
	ret	z
	cp	";"
	scf
	ret	z
_labeluitzi1:
	inc	hl
	inc	b
	AND	C
	ld	(de),a
	inc	de
	xor	a
	ld	(de),a
	ld	a,(hl)
	or	a
	ret	z
	cp	9
	ret	z
	cp	":"
	ret	z
	cp	" "
	ret	z
	cp	";"
	ret	z
	jr	_labeluitzi1

;----- CTRL+V
moveblock:
	ld	a,1
	ld	de,Moving
	jr	_copybl_cont

;----- CTRL+K       Also processes CTRL+V !!!
copyblock:
	xor	a
	ld	de,Copying
_copybl_cont:
	ld	(Soort),a
	call	testisblock
	ld	bc,Noblock
	jp	c,_noblock
	ld	hl,80*Commline+35
	ld	b,d
	ld	c,e
	call	txttocomm
	call	waarisblock	;A: 0=before, 1=at, 2=after cursor
	ld	(Waarblok),a
	cp	1
	jp	z,cursorinblok
	xor	a
	ld	(Free_bekend),a

	ld	hl,(Blokeinde)
	ld	de,(Blokstart)
	dec	de
	or	a
	sbc	hl,de
	ld	b,h
	ld	c,l
	ld	a,(Textbuffer)
	push	bc
	push	af
	push	bc
	ld	a,(Blokbuffer)
	call	setbuffonly
	pop	bc
copycont:
	push	bc
	ld	de,(Blokstart)
	call	haalzinzin
	jr	c,copyeind
	ld	hl,Zin
	ld	b,a
	cp	1
	jr	nz,_copyblock2	;not an empty sentence
	ld	a,(hl)
	or	a
	jr	z,_copyblock3	;empty sentence
_copyblock2:	ld	a,(hl)
	or	a
	jr	nz,_copyblock1
	ld	(hl)," "
_copyblock1:	inc	hl
	djnz	_copyblock2	;clear zeros
	ld	(hl),0
_copyblock3:
	ld	a,(Oldbuffer)
	call	setbuffonly
	call	insline1
	xor	a
	ld	(Printret),a
	call	_return_cont	;to REGELNR
	ld	hl,(Regelnr)
	inc	hl
	ld	(Regelnr),hl
	ld	a,(Blokbuffer)
	call	setbuffonly
	ld	a,(Soort)
	or	a
	jr	nz,_moveextra
_copyextra:
	ld	hl,(Blokstart)
	inc	hl
	ld	(Blokstart),hl
	jr	copyeind
_moveextra:
	ld	hl,(Regelnr)
	push	hl
	ld	hl,(Blokstart)
	ld	(Regelnr),hl
	call	delline1
	pop	hl
	ld	a,(Waarblok)
	or	a
	jr	nz,_moveextra1
	dec	hl
	ld	a,h
	or	l
	jr	nz,_moveextra1
	inc	hl
_moveextra1:	ld	(Regelnr),hl
copyeind:
	ld	a,1
	ld	(Free_bekend),a
	pop	bc
	ld	a,c
	and	%11111
	jr	nz,_copyeind2
	ld	hl,80*Commline+43
	ld	a,(Copybusy)
	xor	%00010000
	ld	(Copybusy),a
	call	writevram
_copyeind2:
	dec	bc
	ld	a,b
	or	c
	jp	nz,copycont

	ld	a,(Soort)
	or	a
	jr	nz,_moveeind

	pop	af
	call	setbuffonly
	pop	bc
	ld	hl,(Blokstart)
	scf
	sbc	hl,bc
	jr	nc,_copyeind1
	inc	hl	;start <> 0
_copyeind1:
	inc	hl
	ld	(Blokstart),hl
	ld	hl,(Regelnr)
	scf
	sbc	hl,bc
	jr	nc,_copyeind3
	inc	hl	;line num <> 0
_copyeind3:
	inc	hl
	ld	(Regelnr),hl
	xor	a
	ld	(Free_bekend),a
	call	wiscommline
	jp	_home_cont	;11 times up + print screen + back

_moveeind:
	ld	a,Bovenaantext
	ld	(Editor_y),a
	ld	b,10
_moveeind3:	push	bc
	call	upschuif
	pop	bc
	jr	c,_moveeind2
	push	bc
	call	downnormal
	pop	bc
	djnz	_moveeind3
_moveeind2:
	pop	af
	ld	(Blokbuffer),a
	call	setbuffonly
	pop	bc
	ld	hl,(Regelnr)
	dec	hl
	ld	(Blokeinde),hl
	inc	hl
	scf
	sbc	hl,bc
	jr	nc,_moveeind1
	inc	hl	;line num <> 0
_moveeind1:
	inc	hl
	ld	(Regelnr),hl
	ld	(Blokstart),hl
	xor	a
	ld	(Free_bekend),a
	call	wiscommline
	jp	_home_cont	;11 times up + print screen + back


Copying:	defb	"Copying "
Copybusy:	defb	"-",0
Moving:	defb	"Moving  -",0
Soort:	defb	0	;0=copy, 1=move
Waarblok:	defb	0	;0=before, 1=between, 2=after cursor


;----- insert 10 lines (shift+ins)

ins10line:
	ld	b,10
_ins10line1:	push	bc
	call	insline1
	pop	bc
	djnz	_ins10line1
	call	printscherm
	jp	editorbestur

;----- insert line (ctrl+ins)

edit_insline:
	call	insline1
	ld	a,(Editor_y)
	cp	15
	jr	c,edit_inscnt
	call	downschuif
	jr	c,edit_inscnt	;can not
	call	upnormal
edit_inscnt:	call	printscherm
	jp	editorbestur
insline1:
	di
	ld	de,(Laatsteregel)
	call	geefadrrege1	;DE=last used data address
	ld	(Laatsteadres),de
	ld	hl,Laatsteblok
	ld	(hl),c
	ld	b,1
	call	freespace	;still free space?
	jp	c,error1	;text buffer full
	ld	(hl),#80	;empty line
	ld	(Inslineadres),hl
	ld	(Inslineblok),a	;fill in later

	ld	de,(Regelnr)
	call	geefadrrege1	;DE=data address, C=data block number (1-..)
	ld	a,c	;block number
	push	af
	push	de
	call	insdat
	pop	de
	pop	af
	call	backinsline
	ret


;-------------------- Insert data into data buffer
;----- IN:  DE=Target address data, A=Target block data

insdat:
	ld	iy,Huidbl
	ld	(iy),a
	ld	a,(Laatsteblok)
	ld	(iy+1),a
	ld	hl,(Laatsteadres)
	inc	hl
	inc	hl
	inc	hl
	bit	6,h
	jr	z,_insd1
	ld	a,(Aantaldatabl)
	cp	(iy+1)
	jp	z,error2
	res	6,h
	inc	(iy+1)

_insd1:
	ld	(Eindad),hl
	ld	a,(iy)
	call	zetdatablok
	ld	a,(iy)
	cp	(iy+1)
	ld	hl,#c000
	jr	nz,_insd2
	ld	hl,(Eindad)
	inc	hl
_insd2:
	ld	(Einde),hl
	xor	a
	ld	(Opslag),a
	call	getbov
	call	movmid
	ld	de,#8000

_insd4:
	ld	a,(iy)
	cp	(iy+1)
	ret	z
	inc	(iy)
	ld	a,(iy)
	call	zetdatablok
	ld	a,(iy)
	cp	(iy+1)
	jr	nz,_insd3
	ld	hl,(Eindad)
	inc	hl
	ld	(Einde),hl
_insd3:
	call	getbov
	call	movmid
	call	putond
	jr	_insd4

Opslag:	defb	0
Einde:	defw	#c000

getbov:
	push	de
	ld	hl,#c000-3
	ld	a,(Opslag)
	xor	1
	ld	(Opslag),a
	ld	de,kbuf
	jr	nz,_getb1
	ld	de,kbuf+128
_getb1:
	ld	bc,3
	ldir
	pop	de
	ret

movmid:
	push	de
	ld	hl,(Einde)
	dec	hl
	dec	hl
	dec	hl
	scf
	sbc	hl,de
	jr	c,_movm1	;length<1
	ld	b,h
	ld	c,l
	inc	bc
	add	hl,de
	ld	de,(Einde)
	dec	de
	lddr
_movm1:
	pop	de
	ret

putond:
	push	de
	ld	de,#8000
	ld	a,(Opslag)
	xor	1
	ld	hl,kbuf
	jr	nz,_puto1
	ld	hl,kbuf+128
_puto1:
	ld	bc,3
	ldir
	pop	de
	ret

Huidbl:	defb	0,0	;current block, end block
Eindad:	defw	#a000
Laatsteadres:	defw	0
Laatsteblok:	defb	0

backinsline:
	call	zetdatablok
	ld	a,(Inslineblok)
	call	putdatbuffer
	ld	hl,(Inslineadres)
	ld	a,l
	call	putdatbuffer
	ld	a,h
	call	putdatbuffer
	ld	hl,(Laatsteregel)
	inc	hl
	ld	(Laatsteregel),hl
	ld	a,(Aantalerrors)
	or	a
	call	nz,inserrorline
	call	insfkeylines

	ld	a,(Blokbuffer)
	ld	b,a
	ld	a,(Textbuffer)
	cp	b
	ret	nz
	ld	de,(Blokstart)
	ld	a,d
	or	e
	ret	z	;no block
	ld	hl,(Regelnr)	;hl=line num, de=start block
	call	rst20
	jr	c,_incstart
	jr	z,_incstart
	ld	de,(Blokeinde)	;de=end block
	call	rst20
	jr	c,_inceinde
	jr	z,_inceinde
	ret
_incstart:	ld	hl,(Blokstart)
	inc	hl
	ld	(Blokstart),hl
_inceinde:	ld	hl,(Blokeinde)
	inc	hl
	ld	(Blokeinde),hl
	ret

Inslineadres:	defw	0
Inslineblok:	defb	0


;----- Increase/decrease all error lines

inserrorline:
	ld	b,a
	ld	hl,#1910+2
inserr1:
	call	getline
	jr	nz,inserr2
	push	hl
	ld	hl,(Regelnr)
	scf
	sbc	hl,de
	pop	hl
	jr	nc,inserr2
	inc	de
inserr2:
	call	putline
	djnz	inserr1
	ret

insfkeylines:
	ld	b,5
	ld	hl,Fkeyregels
_ins_fkey:
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	a,(Textbuffer)
	cp	(hl)
	jr	nz,_ins_fkey1
	ld	a,d
	or	e
	jr	z,_ins_fkey1
	push	hl
	ld	hl,(Regelnr)
	scf
	sbc	hl,de
	pop	hl
	jr	nc,_ins_fkey1
	inc	de
	dec	hl
	ld	(hl),d
	dec	hl
	ld	(hl),e
	inc	hl
	inc	hl
_ins_fkey1:
	inc	hl
	djnz	_ins_fkey
	ret

decerrorline:
	ld	b,a
	ld	hl,#1910+2
decerr1:
	call	getline
	push	hl
	jr	nz,decerr2
	ld	hl,(Regelnr)
	scf
	sbc	hl,de
	jr	nc,decerr2
	inc	hl
	ld	a,h
	or	l
	jr	z,delerrorline
	dec	de
decerr2:
	pop	hl
	call	putline
	djnz	decerr1
	ret

decfkeylines:
	ld	b,5
	ld	hl,Fkeyregels
_dec_fkey:
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	push	hl
	inc	hl
	ld	a,(Textbuffer)
	cp	(hl)
	jr	nz,_dec_fkey1
	ld	a,d
	or	e
	jr	z,_dec_fkey1
	ld	hl,(Regelnr)
	scf
	sbc	hl,de
	jr	nc,_dec_fkey1
	inc	hl
	dec	de
	ld	a,h
	or	l
	jr	nz,_dec_fkey2
	ld	de,0
_dec_fkey2:
	pop	hl
	push	hl
	ld	(hl),d
	dec	hl
	ld	(hl),e
_dec_fkey1:
	pop	hl
	inc	hl
	inc	hl
	djnz	_dec_fkey
	ret

delerrorline:
	pop	hl
	dec	hl
	push	bc
	push	hl
	ld	d,h
	ld	e,l
	dec	de
	dec	de
	inc	hl
	inc	hl
	inc	hl
delerr2:
	push	bc
	ld	b,5
delerr1:
	call	readvram
	inc	hl
	ex	de,hl
	call	writevram
	inc	hl
	ex	de,hl
	djnz	delerr1
	pop	bc
	djnz	delerr2
	ld	hl,Aantalerrors
	dec	(hl)
	call	moveerrbalk
	pop	hl
	pop	bc
	jr	decerr1
putline:
	ld	a,d
	call	writevram
	dec	hl
	ld	a,e
	call	writevram
	ld	de,5
	add	hl,de
	ret
getline:
	call	readvram
	ld	e,a
	inc	hl
	call	readvram
	ld	d,a
	inc	hl
	call	readvram
	dec	hl
	ld	c,a
	ld	a,(Textbuffer)
	cp	c
	ret

moveerrbalk:
	ld	a,(Huidigerror)
	ld	d,a
	ld	a,(Balkerror)
	dec	a
	add	a,d
	dec	a
	ret	z
	dec	d
	ld	a,(Balkerror)
	dec	a
	jr	nz,_moverrbalk
	ld	a,d
	ld	(Huidigerror),a
	ret
_moverrbalk:
	ld	(Balkerror),a
	ret



;----- CTRL+D
delblock:
	ld	hl,(Blokstart)
	ld	a,h
	or	l
	ld	bc,Noblock
	jp	z,_noblock

	call	waarisblock
	ld	(Waarblok),a

	ld	a,(Textbuffer)
	push	af
	ld	a,(Blokbuffer)
	call	setbuffonly

	ld	hl,80*Commline+34
	ld	bc,Deleting
	call	txttocomm
	ld	hl,(Regelnr)
	ld	(Oldline),hl
	ld	hl,(Blokeinde)
	ld	(Regelnr),hl

	ld	hl,(Blokeinde)
	ld	de,(Blokstart)
	or	a
	sbc	hl,de
	inc	hl	;number of lines
	ld	b,h
	ld	c,l

_nextdelbloc:
	push	bc
	call	delline1
	ld	hl,(Regelnr)
	dec	hl
	ld	(Regelnr),hl
	ld	hl,(Oldline)
	ld	a,(Waarblok)
	cp	2
	jr	z,_delblock2
	dec	hl
	ld	a,h
	or	l
	jr	nz,_delblock2
	inc	hl
_delblock2:
	ld	(Oldline),hl
	pop	bc
	ld	a,c
	and	%11111
	jr	nz,_delblock1
	ld	hl,80*Commline+43
	ld	a,(Copybusy)
	xor	%00010000
	ld	(Copybusy),a
	call	writevram
_delblock1:
	dec	bc
	ld	a,b
	or	c
	jr	nz,_nextdelbloc

	ld	a,Bovenaantext
	ld	(Editor_y),a
	ld	hl,0
	ld	(Blokstart),hl
	ld	(Blokeinde),hl	;block erased !
	xor	a
	ld	(Blokbuffer),a

	call	wiscommline
	ld	hl,(Oldline)
	ld	(Regelnr),hl
	pop	af
	call	setbuffonly
	call	printscherm
	jp	editorbestur

Oldline:	defw	0
Deleting:	defb	"Deleting =",0

;----- delete rest of line

delrestline:
	CALL	C53DC
	CALL	C53EE
	LD	D,H
	LD	E,L
	INC	DE
	LD	A,(Editor_x)
	LD	B,A
	LD	A,161
	SUB	B
	LD	C,A
	LD	B,#00
	LD	(HL),B
	LDIR
	CALL	J53F9
	jp	editorbestur

;----------- delete line (CTRL+DEL)

edit_delline:
	call	delline1
	call	printscherm
	jp	editorbestur
delline1:
	di
	call	edit_ret1
	ld	de,(Regelnr)
	call	geefadrregel
	ret	c	;last line
	push	de
	push	af
	call	zettextblok
	ld	b,0
_editdellin1:	call	gettxtbuffer
	inc	b
	and	%10000000
	jr	z,_editdellin1
	pop	af
	call	zettextblok
	pop	de
_editdellin2:	xor	a
	call	puttxtbuffer
	djnz	_editdellin2	;Delete B characters

	ld	de,(Laatsteregel)
	call	geefadrrege1
	ld	(Laatsteadres),de
	ld	a,c
	ld	(Laatsteblok),a
	ld	de,(Regelnr)
	call	geefadrrege1	;DE=data address, C=data block number (1-..)
	ld	a,c	;block number
	call	deldat
	jp	dellineback


;-------------------- Delete data from data buffer
;----- IN: DE=Target address data, A=Target block data, BC=Length data

deldat:
	ld	(Dataad),de
	ld	iy,Huidbl
	ld	(iy+1),a
	ld	a,(Laatsteblok)
	ld	(iy),a
	call	zetdatablok
	ld	hl,(Laatsteadres)
	inc	hl
	ld	(Einde),hl

	ld	a,(iy)	;current block
	cp	(iy+1)	;=1st block ?
	ld	de,#8000
	jr	nz,_deld2
	ld	de,(Dataad)
_deld2:
	xor	a
	ld	(Opslag),a
	call	getond
	call	movmiddel
	ld	hl,#c000
	ld	(Einde),hl

_deld3:
	ld	a,(iy+1)
	cp	(iy)
	ret	z
	dec	(iy)
	ld	a,(iy)
	call	zetdatablok
	ld	a,(iy)	;current block
	cp	(iy+1)	;=1st block ?
	ld	de,#8000
	jr	nz,_deld5
	ld	de,(Dataad)
_deld5:
	call	getond
	call	movmiddel
	call	putbov
	jr	_deld3

Dataad:	defw	0

getond:
	push	de
	ld	hl,#8000
	ld	a,(Opslag)
	xor	1
	ld	(Opslag),a
	ld	de,kbuf
	jr	nz,_geto1
	ld	de,kbuf+128
_geto1:
	ld	bc,3
	ldir
	pop	de
	ret

movmiddel:
	push	de
	ld	bc,3
	ld	hl,(Einde)
	or	a
	sbc	hl,bc
	scf
	sbc	hl,de
	jr	c,_movmdel1	;length<1
	inc	hl
	push	hl
	ld	h,d
	ld	l,e
	add	hl,bc
	pop	bc
	ldir
_movmdel1:
	pop	de
	ret

putbov:
	push	de
	ld	bc,3
	ld	h,d
	ld	l,e
	add	hl,bc
	dec	hl
	bit	6,h
	jr	nz,putbo1
	ld	de,#c000-3
	ld	a,(Opslag)
	xor	1
	ld	hl,kbuf
	jr	nz,_putb1
	ld	hl,kbuf+128
_putb1:
	ldir
	pop	de
	ret

putbo1:
	ld	a,(Opslag)
	xor	1
	ld	hl,kbuf
	jr	nz,_putb2
	ld	hl,kbuf+128
_putb2:
	add	hl,bc
	push	hl
	ld	hl,#c000
	or	a
	sbc	hl,de
	ld	b,h
	ld	c,l
	pop	hl
	or	a
	sbc	hl,bc
	ldir
	pop	de
	ret

dellineback:
	ld	hl,(Laatsteregel)
	dec	hl
	ld	(Laatsteregel),hl
	ld	a,(Aantalerrors)
	or	a
	call	nz,decerrorline
	call	decfkeylines

	xor	a
	ld	(Free_bekend),a	;new free space created

	ld	a,(Blokbuffer)
	ld	b,a
	ld	a,(Textbuffer)
	cp	b
	ret	nz
	ld	de,(Blokstart)
	ld	a,d
	or	e
	ret	z	;no block
	ld	hl,(Regelnr)	;hl=line num, de=start block
	call	rst20
	jr	c,_decstart
	ld	de,(Blokeinde)	;de=end block
	call	rst20
	jr	c,_deceinde
	jr	z,_deceinde
	ret
_decstart:	ld	hl,(Blokstart)
	dec	hl
	ld	(Blokstart),hl
_deceinde:	ld	hl,(Blokeinde)
	dec	hl
	ld	(Blokeinde),hl
	ld	de,(Blokstart)
	call	rst20
	ret	nc
	ld	hl,0
	ld	(Blokstart),hl
	ld	(Blokeinde),hl	;block erased
	ret

Sp_editor:	defw	0



;----- Find free space in textbuffer with length B
;----- OUT: [C] = no space found, HL=address, A=how many blocks
Free_bekend:	defb	0	;Address known? 0=no, 1=yes (CTRL-INS for more often)
Free_blok:	defb	0
Free_adres:	defw	0	;last address + block

freespace:
	ld	a,(Free_bekend)
	or	a
	jr	z,freespace1	;not known
	push	bc
	call	freespace1
	pop	bc
	ret	nc
	xor	a	;start at the front
	ld	(Free_bekend),a

freespace1:
	ld	a,b
	ld	(Aantalfree),a
	ld	a,(Free_bekend)
	or	a
	jr	z,_nietbekend
	ld	a,(Free_blok)
	call	zettextblok
	ld	ix,Textbloknr
	ld	hl,#c000
	ld	de,(Free_adres)
	or	a
	sbc	hl,de
	ld	b,h
	ld	c,l
	ex	de,hl
	jr	_freespace2	;start at end address last time

_nietbekend:	;start at start buffer
	ld	a,1
	call	zettextblok	;start at block number 1
	ld	ix,Textbloknr
_freespace1:
	ld	hl,#8000
	ld	bc,#4000
_freespace2:	xor	a
	cpir
	jr	z,_spacefound
_notspace:	ld	a,(Aantaltextbl)
	cp	(ix)
	scf
	ret	z	;no room found
	ld	a,(ix)
	inc	a
	call	zettextblok
	jr	_freespace1

Aantalfree:	defb	0	;number of zeros to search

_spacefound:
	dec	hl
	ld	(Spaceadress),hl
	ld	a,(Aantalfree)
	ld	d,a
_spacefound1:	ld	a,(hl)
	inc	hl
	or	a
	jr	nz,_freespace2	;shortage
	dec	bc
	ld	a,b
	or	c
	jr	z,_notspace
	dec	d
	jr	nz,_spacefound1
	ld	a,1
	ld	(Free_bekend),a	;for next time
	ld	hl,(Spaceadress)
	ld	a,(ix)
	ld	(Free_adres),hl
	ld	(Free_blok),a
	ret

Spaceadress:	defw	0

;----- calculate address in vram  IN:Editor_y  OUT: HL=vramaddress
;----- Changes: B,DE, HL, AF
bervram:
	LD	A,(Editor_y)	;**********************************
	LD	B,A	;shorter! since Edit_y>=4
	LD	HL,-80
	LD	DE,80
_bervram	ADD	HL,DE
	DJNZ	_bervram
	RET

;----- print info on screen

printinfoRnr	ld	de,(Regelnr)
printinfoDE	ld	hl,25*80+7
	ld	b,5
	call	printdecimaa
	ld	hl,25*80+13
	ld	de,(Laatsteregel)
	ld	b,5
	call	printdecimaa
	CALL	printcol
	ld	hl,25*80+78
	ld	a,(Textbuffer)
	add	a,"0"
	call	writevram
	ld	hl,25*80+37
	ld	a,(Insonoff)
	call	printonoff
	ld	hl,(Blokstart)
	ld	a,h
	or	l
	ld	hl,25*80+50
	jr	z,printonoff
	ld	a,(Blokbuffer)
	add	a,"0"
	ld	(Blockon+1),a
	ld	bc,Blockon
	jp	printtekst

printcol	LD	HL,25*80+26
	LD	A,(Editor_x)
	LD	E,A
	LD	D,#00
	LD	B,#03
	JP	printdecimaa

Blockon:	defb	"[ ]",0

;---------- A=off(0)/on(<>0)
printonoff:
	ld	bc,On
	or	a
	jr	nz,_printonoff1	;***shorter*********jp nz,printtekst
	ld	bc,Off
_printonoff1:	jp	printtekst

Turbor:	defb	0	;is turbo-r ? 1=yes


;########################### Load block file

loadblock:
	ld	hl,(Regelnr)
	ld	(Oldregelblk),hl
	ld	(Used_fcb),de
	xor	a
	ld	(Loadsaveblok),a	;load
	inc	a
	ld	(Blokload),a
	jr	blokloadcont

Loadsaveblok:	defb	0
Oldregelblk:	defw	0

;############################ Load ASCII file
Eindeload:	defb	0
Blokload:	defb	0	;0=normal load, 1=block load

loadascfile:
	ld	(Used_fcb),de
	call	ini_variabel
	call	wisbuffer
	xor	a
	ld	(Blokload),a	;just load
	ld	ix,#8000	;Address target text
	ld	a,1
	call	zetdatablok	;block 1
	ld	iy,#8000	;Address addresses+blocks
	ld	a,1
	call	zettextblok

blokloadcont:
	ld	(Sp_asciiload),sp
	ld	a,1
	ld	(Bronerrors),a	;load errors from ascii
	ld	de,(Bufferpage0)	;load in page 0
	push	de
	push	ix
	push	iy
	call	setdma
	ld	hl,1
	CALL	loaddisk
	pop	iy
	pop	ix
	pop	hl
	ld	a,(hl)
	cp	#f0
	jp	nc,jon_ascii_err
	LD	HL,(Used_fcb)
	LD	DE,33
	ADD	HL,DE
	XOR	A	;*****record number, only 2 bytes? instead of 4
	LD	(HL),A
	INC	HL
	LD	(HL),A
	ld	(Eindeload),a
	ld	de,Zin
;----- DE=target in "Sentence", IX=target in textbuffer, IY=target in databuffer
_volgendblok:
	ld	(Zinadres),de
	ld	a,(Eindeload)
	or	a
	jp	nz,_eindefile
	ld	hl,1024
	ld	de,(Used_fcb)
	ld	c,#27
	push	ix
	push	iy
	call	bdos	;load block
	ld	b,h
	ld	c,l	;BC = actual length
	pop	iy
	pop	ix	;Destination address text buffer
	ld	(Eindeload),a	;<>0 => last time

	ld	de,(Zinadres)
	ld	hl,(Bufferpage0)

_loadnext:	ld	a,(hl)
	and	%01111111
	inc	hl
	cp	#0d
	jr	z,_loadreturn
	cp	#0a
	jr	z,_loadeind
	ld	(de),a
	inc	de
_loadreturn:	dec	bc
	ld	a,b
	or	c
	jr	nz,_loadnext
	jr	_volgendblok

_loadeind:
	push	hl
	push	bc
	ld	a,(Textbloknr)
	ld	(Blokbuff),a	;current block (for data)
	xor	a
	ld	(de),a	;indicate end of sentence

	ld	a,(Blokload)
	or	a
	jp	nz,contblokload	;continue at block load

	ld	(Lastdatadres),iy
	ld	a,(Databloknr)
	ld	(Lastdatblok),a	;for "Datbuf too small" !
	call	makeline	;make sentence with tabs
	call	huidigtxtblk
	push	ix
	pop	de
	ld	(Adresbuffer),de
	ld	hl,Zin+161
_loadeind1:	ld	a,(hl)
	inc	hl
	call	puttxtbuffer
	and	%10000000
	jr	z,_loadeind1	;sentence to buffer
	push	de
	pop	ix

	push	iy	;fill in data block
	pop	de
	call	huidigdatblk
	ld	a,(Blokbuff)
	call	putdatbuffer
	ld	a,(Adresbuffer)
	call	putdatbuffer
	ld	a,(Adresbuffer+1)
	call	putdatbuffer
	push	de
	pop	iy
	ld	hl,(Laatsteregel)
	inc	hl
	ld	(Laatsteregel),hl

contblokld1:
	pop	bc
	pop	hl
	ld	a,(hl)
	cp	#1a
	jr	z,_eindefile
	ld	de,Zin
	jr	_loadreturn

Blokbuff:	defb	0
Adresbuffer:	defw	0

contblokload:
	call	insline1
	xor	a
	ld	(Printret),a	;do not print on return
	call	_return_cont	;to REGELNR
	ld	hl,(Regelnr)
	ld	(Blokeinde),hl
	inc	hl
	ld	(Regelnr),hl
	jr	contblokld1


_eindefile:
	ld	a,(Blokload)
	or	a
	jr	z,_eindefile1
	ld	hl,(Oldregelblk)
	ld	(Regelnr),hl
	ld	(Blokstart),hl
	ld	a,(Textbuffer)
	ld	(Blokbuffer),a
	jp	closefile
_eindefile1:
	call	huidigdatblk
	ld	(iy),#ff	;End addresses
	jp	closefile


Zinadres:	defw	0	;Current address in "Sentence"
Lengte_low:	defw	0
Lengte_high:	defw	0


;#################### Save block

saveblock:
	ld	(Used_fcb),de
	ld	a,1
	ld	(Bloksave),a
	ld	(Loadsaveblok),a	;save
	ld	hl,(Blokstart)
	ld	a,h
	or	l
	ld	bc,Noblock
	jr	z,_noblocksv
	dec	hl
	push	hl
	push	iy
	ld	a,(Blokbuffer)
	call	setbuffonly
	pop	iy
	pop	hl
	jp	contsaveblok
_noblocksv:
	ld	hl,Commline*80+(80-19)/2
	ld	bc,Noblock
	call	printtekst
	call	beep
	jp	closefile

testendblk:
	exx
	ld	hl,(Blokeinde)
	ld	de,(Saveline)
	or	a
	sbc	hl,de
	exx
	ret

;#################### Save ascii file
Saveline:	defw	0
Bloksave:	defb	0	;1=Save block

saveascfile:
	ld	(Used_fcb),de
	xor	a
	ld	(Bloksave),a
	ld	hl,1-1

contsaveblok:
	ld	(Saveline),hl
	ld	(Foutadres),iy
	ld	hl,(Bufferpage0)
	ld	(Savebufadres),hl
	ex	de,hl
	call	setdma	;buffer in page 0

_nextsavereg:	ld	de,(Saveline)
	inc	de
	ld	(Saveline),de
	call	geefadrregel	;a=block number, de=address
	jr	c,endsavefile	;end
	call	zettextblok

	ld	a,(Bloksave)
	or	a
	call	nz,testendblk
	jr	c,endsavefile	;end block

	ld	hl,(Savebufadres)	;hl=address buffer
_nextsavetek:	call	gettxtbuffer
	bit	7,a
	jr	nz,_saveendzin
	call	tosavebuffer
	jr	_nextsavetek
_saveendzin:	and	%01111111
	call	nz,tosavebuffer	;0 do not save
	ld	a,#0d
	call	tosavebuffer
	ld	a,#0a
	call	tosavebuffer
	ld	(Savebufadres),hl
	jr	_nextsavereg

endsavefile:
	ld	hl,(Savebufadres)
	ld	a,#1a	;end of file
	call	tosavebuffer
	ld	bc,(Bufferpage0)
	or	a
	sbc	hl,bc	;length
	ld	a,h
	or	l
	jr	z,_endsave1
	call	savediskasci
_endsave1:
	ld	a,(Bloksave)
	or	a
	jp	z,closefile
	ld	a,(Oldbuffer)
	call	setbuffonly
	jp	closefile


Savebufadres:	defw	0

tosavebuffer:
	ld	(hl),a
	inc	hl
	ld	a,(Bufferpage0)
	cp	l
	ret	nz
	ld	a,(Bufferpage0+1)
	add	a,4
	cp	h
	ret	nz
	push	de
	ld	hl,1024
	call	savediskasci
	pop	de
	ld	hl,(Bufferpage0)
	ret

savedisk:
	push	iy
	push	ix
	ld	de,(Used_fcb)
	ld	c,#26
	call	bdos	;interim save
	pop	ix
	pop	iy
	or	a
	ret	z
	ld	ix,(Foutadres)
	jp	(ix)
savediskasci:
	push	iy
	push	ix
	ld	de,(Used_fcb)
	ld	c,#26
	call	bdos
	pop	ix
	pop	iy
	or	a
	ret	z
	ld	a,(Bloksave)
	or	a
	jr	z,_savediskas1
	ld	a,(Oldbuffer)
	call	setbuffonly
_savediskas1:
	ld	ix,(Foutadres)
	jp	(ix)

loaddisk:
	push	iy
	ld	de,(Used_fcb)
	ld	c,#27
	call	bdos
	pop	iy
	ret

;----- Load assembler file

Doinclude:	defb	0

inclfile:
	ld	a,1
	jr	_loadasm1

loadasmfile:
	xor	a
_loadasm1:
	ld	(Doinclude),a
	ld	(Used_fcb),de
	ld	(Sp_asciiload),sp
	ld	a,1
	ld	(Bronerrors),a
	call	ini_variabel
	call	wisbuffer
	ld	de,(Bufferpage0)
	push	de
	call	setdma
	ld	hl,9
	call	loaddisk
	pop	hl
	ld	de,Headerasm
	ld	bc,9
	ldir
	ld	iy,Headerasm
	ld	a,(iy)
	cp	#fc
	jp	nz,_noasmfile
	inc	iy
	ld	a,(Aantaltextbl)
	inc	(iy)
	cp	(iy)
	jp	c,goerror1	;text buffer too small
	ld	a,(Aantaldatabl)
	inc	(iy+3)	;=iy+4 (because of inc iy)
	cp	(iy+3)
	jp	c,goerror2	;data buffer too small
	ld	de,#8000
	call	setdma

	ld	c,0
_nexttextloa:
	inc	c
	push	bc
	ld	a,c
	ld	(Specialload+1),a
	call	zettextblok
	ld	hl,#f344
	ld	a,(Txtslt)
	cp	(hl)
	ld	hl,zettextblok
	jr	nz,_specialload	;load in another slot
	call	loadblok
	pop	bc
	jr	c,loadcont
	jr	_nexttextloa
_specialload:
	call	loadspecial
	pop	bc
	jr	nc,_nexttextloa

loadcont:
	ld	c,0
	ld	iy,Headerasm+4
_nextdataloa:
	inc	c
	push	bc
	ld	a,c
	ld	(Specialload+1),a
	call	zetdatablok
	ld	hl,#f344
	ld	a,(Datslt)
	cp	(hl)
	ld	hl,zetdatablok
	jr	nz,_specialloa1	;load in another slot
	call	loadblok
	pop	bc
	jr	c,loadcont1
	jr	_nextdataloa
_specialloa1:
	call	loadspecial
	pop	bc
	jr	nc,_nextdataloa

loadcont1:
	ld	hl,(Laatstergl)
	ld	(Laatsteregel),hl
	ld	sp,(Sp_asciiload)
	ld	a,(Doinclude)
	or	a
	jp	z,closefile
	xor	a
	ret

;----- load block in standard ram

loadblok:
	dec	(iy)
	jr	z,_loadlast
	ld	hl,#4000
	call	loaddisk
	xor	a
	ret
_loadlast:
	ld	l,(iy+1)
	ld	h,(iy+2)
	ld	a,h
	or	l
	scf
	ret	z
	call	loaddisk
	scf
	ret

;----- load block in external mapper

loadspecial:
	ld	(Specialload1+1),hl
	xor	a
	ld	(Showlabels),a
	ld	a,(#f344)
	ld	h,#80
	call	slot
	ld	a,(Labelbuffers+1)
	CALL	#0131
	dec	(iy)	;[Z]=special last
	push	af
	ld	hl,#4000
	jr	nz,_load4000
	ld	l,(iy+1)
	ld	h,(iy+2)
	ld	a,h
	or	l
	jr	z,_loadasm_end
_load4000:
	push	hl
	call	loaddisk
	ld	a,(#bfff)
	ld	(Errorspec+1),a
Specialload:	ld	a,0	;FILLED IN !!!
Specialload1:	call	0	;FILLED IN !!!
	pop	bc
	di
	ld	a,(Labelbuffers+1)
	out	(#ff),a
	ld	hl,#c000
	ld	de,#8000
	ldir
Errorspec:	ld	a,0
	ld	(#bfff),a	;#FFFF unreadable !
	xor	a
	out	(#ff),a
_loadasm_end:
	pop	af
	scf
	ret	z	;Last
	ccf
	ret

_noasmfile:
	ld	sp,(Sp_asciiload)
	ld	a,(Doinclude)
	or	a
	scf
	ret	nz
	ld	bc,Noasmfile
_jon_asc_err	ld	hl,15*80+(80-13)/2
	call	printtekst
	call	beep
	jp	closefile
Noasmfile:	defb	"No asm file !",0

jon_ascii_err	LD	SP,(Sp_asciiload)
	LD	BC,Noasciifile
	JR	_jon_asc_err
Noasciifile	db	"No ascii file !",0

goerror1:
	ld	hl,error1
	jr	_goerror2_1
goerror2:
	ld	hl,error2
_goerror2_1:
	ld	sp,(Sp_asciiload)
	ld	a,(Doinclude)
	or	a
	scf
	ret	nz
	jp	(hl)


;----- Save assembler file

saveasmfile:
	ld	(Used_fcb),de
	ld	(Foutadres),iy
	ld	iy,Saveblok
	ld	(iy),1
	ld	de,#8000
	ld	(iy+1),1
	ld	bc,#c000

J64FD:	BIT	6,B
	CALL	NZ,C65E0
	LD	A,(BC)
	INC	BC
	CP	#FF
	JR	Z,J652E
	PUSH	AF
	BIT	6,B
	CALL	NZ,C65E0
J650E:	LD	A,(BC)
	LD	L,A
	INC	BC
	BIT	6,B
	CALL	NZ,C65E0
	LD	A,(BC)
J6517:	LD	H,A
	INC	BC
	POP	AF
	CP	(IY+#01)
	JR	Z,J6527
	JR	C,J64FD
	LD	(IY+#01),A
J6524:	EX	DE,HL
J6525:	JR	J64FD
J6527:	CALL	rst20
	JR	C,J64FD
	JR	J6524
J652E:	LD	A,(IY+#01)
	CALL	zettextblok
J6534:	CALL	gettxtbuffer
	BIT	7,A
	JR	Z,J6534
	BIT	6,D
	JR	Z,J6544
	RES	6,D
	INC	(IY+#01)
J6544:	LD	A,(IY+#01)
	dec	a
	ld	(iy+3),a	;number of whole
	ld	(iy),1
	RES	7,D
	LD	(Lengtelast),DE
	ld	de,(Laatsteregel)
	ld	(Laatstergl),de
	call	geefadrrege1
	ld	a,c
	dec	a
	ld	(Aantalhele1),a
	inc	de
	res	7,d
	ld	(Lengtelast1),de
	ld	de,(Bufferpage0)
	push	de
	call	setdma
	pop	de

	ld	hl,Headerasm
	LD	(HL),#FC
	ld	bc,9
	ldir
	ld	hl,9
	call	savedisk	;save header

	ld	de,#8000
	call	setdma
	ld	ix,Lengtelast
	dec	(iy)
_nextsave:
	inc	(iy)
	ld	a,(iy)
	call	zettextblok
	ld	hl,#f344
	ld	a,(Txtslt)
	cp	(hl)
	jr	nz,_specialsave
	call	saveblok
	jr	nc,_nextsave
	jr	savecont
_specialsave:
	call	savespecial
	jr	nc,_nextsave

savecont:
	ld	a,(Aantalhele1)
	inc	a
	ld	(iy+1),a
	ld	(iy),0
	ld	ix,Lengtelast1
_nextdatsave:
	inc	(iy)
	ld	a,(iy)
	call	zetdatablok
	ld	hl,#f344
	ld	a,(Datslt)
	cp	(hl)
	jr	nz,_specialsav1
	call	saveblok
	jr	nc,_nextdatsave
	jr	savecont1
_specialsav1:
	call	savespecial
	jr	nc,_nextdatsave

savecont1:
	jp	closefile

C65E0:	LD	A,(IY+#00)
	CALL	zetdatablok
	INC	(IY+#00)
	LD	BC,#8000
	RET

;----- save block from standard ram

saveblok:
	ld	a,(iy)
	cp	(iy+1)
	jr	z,_savelast
	ld	hl,#4000
	call	savedisk
	xor	a
	ret
_savelast:
	ld	l,(ix)
	ld	h,(ix+1)
	call	savedisk
	scf
	ret

;----- save block from external mapper

savespecial:
	xor	a
	ld	(Showlabels),a
	ld	a,(iy)
	cp	(iy+1)
	push	af
	ld	hl,#4000
	jr	nz,_save4000
	ld	l,(ix)
	ld	h,(ix+1)
	ld	a,h
	or	l
	jr	z,_saveasm_end
_save4000:
	push	hl
	bit	6,h
	jr	z,_onder4000
	dec	hl
_onder4000:
	di
	ld	a,(Labelbuffers+1)	;holala, daring!!!!***********
	out	(#ff),a
	ld	b,h
	ld	c,l
	ld	hl,#8000
	ld	de,#c000
	ldir
	xor	a
	out	(#ff),a
	ld	a,(#bfff)
	push	af
	ld	a,(#f344)
	ld	h,#80
	call	slot
	ld	a,(Labelbuffers+1)
	CALL	#0131	;same as out fe,a
	pop	af
	ld	(#bfff),a	;#FFFF not to write !!!
	pop	hl
	call	savedisk
_saveasm_end:
	pop	af
	scf
	ret	z	;last
	ccf
	ret

	;would be at 665A**************************************

Saveblok:	defb	0
Lastblok:	defb	0	;iy+1

Headerasm:	defb	#fc
Aantalhele:	defb	0	;iy+2 text Header starts here !
Lengtelast:	defw	0	;iy+3 text
Aantalhele1:	defb	0	;data
Lengtelast1:	defw	0	;data
Laatstergl:	defw	0	;last line num.

;org 6665

;----- Make "Sentence" a sentence with tabs etc. "Sentence" ended with a 0
;----- OUT: A=Length target, Sentence in "Sentence"+161 (Ends with bit 7 high)

makeline:
	push	bc
	push	iy
	xor	a
	ld	(Aanhaling),a	;quotes off
	ld	(Puntkomma),a
	ld	a,#80	;empty Sentence
	ld	(Zin+161),a
	ld	hl,Zin	;length Sentence=160+zero
	ld	de,Zin+161-1
	ld	c,0	;Position 0
_makeline2:
	ld	a,c
	cp	161
	jp	nc,_endofline
	ld	a,(hl)
	inc	hl
	cp	9
	jr	z,_killspace1
	cp	" "
	jr	z,_killspace
	inc	c
	or	a
	jp	z,_endofline
	cp	34	;"
	jp	z,_aanhaling
	cp	"'"
	jr	z,_aanhaling
	cp	";"
	jp	z,_puntkomma
;              cp      "a"
;              jr      c,_natab
;              cp      "z"+1
;              jr      nc,_natab
;              ld      b,a
;              ld      a,(Upperonoff)
;              or      a
;              ld      a,b
;              jr      z,_natab         ;Upper off
;              ld      a,(Aanhaling)
;              or      a
;              ld      a,b
;              jr      nz,_natab
;              ld      a,(Puntkomma)
;              or      a
;              ld      a,b
;              jr      nz,_natab
;              and     %11011111

_natab:	inc	de
	ld	(de),a
	jr	_makeline2	;Next one

_killspace:
	ex	af,af'
	ld	a,(Tabsonoff)
	or	a
	ld	a," "
	jr	z,_natab	;tabs off, so just space
	ld	a,(Aanhaling)
	ld	b,a
	ld	a,(Puntkomma)
	or	b
	ld	a," "
	jr	nz,_natab	;quotes or semicolon
	ex	af,af'
_killspace1:
	ld	b,a
	ld	a,(hl)
	inc	hl
	cp	" "
	jr	nz,_killspace2
	ld	a,9
	jr	_killspace1
_killspace2:	or	a
	jp	z,_endofline
	dec	hl
	ld	a,(Tabs+1)
	cp	c
	ld	a,b
	jr	c,_natab
	jp	_maketab

_aanhaling:
	ld	b,a
	ld	a,(Aanhaling)
	or	a
	jr	z,_aanhali1
	cp	b
	ld	a,b
	jr	nz,_natab
	xor	a
	ld	(Aanhaling),a
	ld	a,b
	jr	_natab
_aanhali1:
	ld	a,b
	cp	"'"
	jr	nz,_aanhali2
	dec	hl
	dec	hl
	dec	hl
	ld	a,(hl)
	and	%11011111
	cp	"A"
	inc	hl
	ld	a,(hl)
	inc	hl
	inc	hl
	jr	nz,_aanhali2
	and	%11011111
	cp	"F"
	ld	a,"'"
	jr	z,_natab	;'belongs to ex af,af'
_aanhali2:
	ld	a,b
	ld	(Aanhaling),a
	jr	_natab
Aanhaling:	defb	0	;Quotation mark: 0=off, " or '=on

_puntkomma:
	ld	a,(Aanhaling)
	ld	b,a
	ld	a,(Puntkomma)
	or	b
	ld	b,a
	ld	a,(Tabsonoff)
	xor	1	;1=off
	or	b
	ld	a,";"
	jr	nz,_natab	;";" or quotes or tabs off
	ld	a,1
	ld	(Puntkomma),a
	inc	c
	ld	a,c
	cp	2
	jr	z,_0keertab	;front sentence
	ld	a,(de)
	cp	" "
	jr	z,_1keertab
	inc	de
	cp	9
	jr	nz,_1keertab
	ld	a,(Tabs+1)
	add	a,2
	cp	c
	jr	z,_1keertab
	dec	de
_0keertab:	dec	c
	ld	a,";"
	jp	_natab

_1keertab:	ld	a,9
	ld	(de),a
	ld	a,(Tabs+2)
	ld	c,a
	ld	a,";"
	jp	_natab
Puntkomma:	defb	0


_maketab:
	ld	iy,Tabs
_maketab2:	ld	a,(iy)
	inc	iy
	or	a
	jr	z,_maketab1
	cp	c
	jr	c,_maketab2
	jr	z,_maketab2
	ld	c,a
	ld	a,9
	jp	_natab
_maketab1:
	ld	c,160
	ld	a,9
	jp	_natab

_endofline:
	ex	de,hl
	set	7,(hl)	;Sentence+160 overwritten on empty line!!!
	ld	de,0-(Zin+161-1)
	add	hl,de
	ld	a,l
	pop	iy
	pop	bc
	ret


;******************************   DISK ROUTINES

setdma:
	push	iy
	ld	c,#1a
	call	bdos
	pop	iy
	ret


;########################### Print lines on screen
printscherm:	LD	HL,3*80
	CALL	setvramwrite
	ld	hl,(Regelnr)
	ld	a,(Editor_y)
	sub	Bovenaantext
	ld	e,a
	ld	d,0
	xor	a
	sbc	hl,de
	ex	de,hl	;DE=line number at the top
	PUSH	DE
	LD	B,22
J679C:	DI
	PUSH	BC
	PUSH	DE
	LD	A,(Veranderd)
	OR	A
	JR	Z,J67CA
	LD	HL,(Regelnr)
	CALL	rst20
	JR	NZ,J67CA
	LD	HL,Labelbuffer
	LD	BC,(afb_offset)
	ADD	HL,BC
	LD	BC,#5098
	OTIR
	LD	HL,(Laatsteregel)
	CALL	rst20
	JR	NZ,J67E0
	POP	DE
	INC	DE
	POP	BC
	DEC	B
	JR	Z,J6815
	JR	J67EA
J67CA:	CALL	haalzinzin
	JP	C,J67E8
	LD	HL,Zin
	LD	A,(afb_offset)
	ADD	A,L
	LD	L,A
	JR	NC,J67DB
	INC	H
J67DB:	LD	BC,#5098
	OTIR
J67E0:	EI
	POP	DE
	INC	DE
	POP	BC
	DJNZ	J679C
	JR	J6815
J67E8:	POP	DE
	POP	BC
J67EA:	LD	C,B
J67EB:	LD	A,(Veranderd)
	OR	A
	JR	Z,J680A
	LD	HL,(Regelnr)
	CALL	rst20
	JR	NZ,J680A
	EXX
	LD	HL,Labelbuffer
	LD	BC,(afb_offset)
	ADD	HL,BC
	LD	BC,#5098
	OTIR
	EXX
	JR	J6811
J680A:	LD	B,80
J680C:	XOR	A
	OUT	(#98),A
	DJNZ	J680C
J6811:	INC	DE
	DEC	C
	JR	NZ,J67EB
J6815:	LD	HL,#181E
	CALL	setvramwrite
	POP	DE
	LD	A,(Textbuffer)
	LD	B,A
	LD	A,(Blokbuffer)
	CP	B
	LD	BC,#1698
	JR	NZ,J6850
J6829:	DI
	LD	HL,(Blokstart)
	INC	DE
	CALL	rst20
	DEC	DE
	LD	HL,v_jon1
	JR	NC,J6845
	LD	HL,(Blokeinde)
	CALL	rst20
	LD	HL,v_jon1
	JR	C,J6845
	LD	HL,v_jon2
J6845:	PUSH	BC
	LD	B,10
	OTIR
	EI
	POP	BC
	INC	DE
	DJNZ	J6829
	RET

J6850:	LD	D,B
J6851:	LD	HL,v_jon1
	LD	B,10
	OTIR
	DEC	D
	JR	NZ,J6851
	EI
	RET

v_jon1	ds	10,0
v_jon2	db	#80,0,0,0,0,0,0,0,0,#01

;the following explanation may not be correct
;######################## Get sentence from buffer  IN: DE=line number
;             OUT: Sentence, [C] is end of text, A=length sentence (with [NC])
;       CHANGES: Everything except IX

_haalzinjon	dw	0

haalzinzin
	LD	HL,Zin
haalzinHL
J6876:	LD	(_haalzinjon),HL
	CALL	geefadrregel
	JR	NC,J688D
	LD	HL,(_haalzinjon)
	LD	D,H
	LD	E,L
	INC	DE
	LD	BC,160-1
	LD	(HL),#00
	LDIR
	SCF
	RET

J688D	call	zettextblok
	LD	HL,(_haalzinjon)
	ld	b,160+1
_printnext:	call	gettxtbuffer
	bit	7,a
	jr	nz,_printeinde
	cp	9
	jr	z,_voertabuit
	ld	(hl),a
	inc	hl
_contnatab:	djnz	_printnext
_contnatab2	ld	a,160
	or	a
	ret
_printeinde:
	and	%01111111
	ld	(hl),a
	PUSH	BC
	PUSH	HL
J68AD:	INC	HL
	LD	(HL),#00
	DJNZ	J68AD
	POP	HL
	POP	BC
	LD	A,160+2
	SUB	B
	OR	A
	RET

_voertabuit:
	ld	a,160+1
	sub	b
	ld	c,a	;C = current position 0-80
	ld	iy,Tabs
_voertabuit2:	ld	a,(iy)
	inc	iy
	or	a
	jr	z,_voertabuit1
	cp	c
	jr	c,_voertabuit2
_voertabuit1:
	EXX
	ld	c,a
	ld	b,0
	ld	hl,(_haalzinjon)
	add	hl,bc	;HL = new position in sentence
	LD	A,L
	EXX
	INC	B
J68D7:	CP	L
	JR	Z,_contnatab
	LD	(HL),#00
	INC	HL
	DEC	B
	JR	NZ,J68D7
	JR	_contnatab2

Tabs:	defb	14,22,39,47,55,63,71,79,87,95
	db	103,111,119,127,135,143,151,159,0


;####################################
;Enter address at line   IN: DE=line
;OUT: [C]=end text, DE=address text, A=quantity. text block
;Changes: HL,DE,AF,BC

geefadrregel:
	call	geefadrrege1
	ld	a,c
	call	zetdatablok
	call	getdatbuffer
	cp	#ff
	scf
	ret	z
	ld	c,a
	call	getdatbuffer
	ld	l,a
	call	getdatbuffer
	ld	d,a
	ld	e,l
	ld	a,c
	or	a
	ret

	;ORG #6910
;IN : DE=line number
;OUT: DE=address data buffer, C=how many blocks of data buffer

geefadrrege1:
	dec	de
	ld	c,1	;1st block
	ld	hl,0	;1st address (actually #8000)
	ld	b,3
_geefadrreg3:	add	hl,de
_geefadrreg2:	ld	a,h
	cp	#40
	jr	c,_geefadrreg1
	sub	#40
	ld	h,a
	inc	c
	jr	_geefadrreg2
_geefadrreg1:	djnz	_geefadrreg3
	set	7,h
	ex	de,hl
	ret

;########################### Small subroutines

;----- Toggles current text block
;----- Changes: AF

huidigtxtblk:
	ld	a,(Textbloknr)
;Textblokreal: defb    0                ;Current textblock (#fe value)

;----- IN: A = Block number of text buffer (1-..)
;----- Changes: AF

zettextblok:
	ld	(Textbloknr),a
	add	a,a
	push	hl
	ld	hl,Textbuffers-1
	add	a,l
	ld	l,a
	jr	nc,_zettextblo1
	inc	h
_zettextblo1:
	ld	a,(hl)
	CALL	#0131	;FE    ***************************
	dec	hl
	ld	a,(hl)
	ld	(Txtslt),a
	jr	_korterjon

Txtslt:	defb	0	;used when loading assembler file

;----- IN: A = Block number of label buffer (1-..)
;----- Changes: AF

zetlabblok:
	ld	(Labbloknr),a
	add	a,a
	push	hl
	ld	hl,Labelbuffers-1
	add	a,l
	ld	l,a
	jr	nc,_zetlabblo1
	inc	h
_zetlabblo1:
	ld	a,(hl)
	call	#0131	;fe*************************
	dec	hl
	ld	a,(hl)
	jr	_korterjon

;Labblokreal:  defb    0                ;Current label block (#fe value)

;----- Switches current data block
;----- Changes: AF

huidigdatblk:
	ld	a,(Databloknr)
;Datablokreal: defb    0                ;Current data block (#fe value)

;----- IN: A = Block number of data buffer (1-..)
;----- Changes: AF

zetdatablok:
	ld	(Databloknr),a
	add	a,a
	push	hl
	ld	hl,Databuffers-1
	add	a,l
	ld	l,a	;is not necessary*****because +-#3f40
	jr	nc,_zetdatablo1
	inc	h
_zetdatablo1:
	ld	a,(hl)
	call	#0131	;fe********************************
	dec	hl
	ld	a,(hl)
	ld	(Datslt),a
_korterjon	ld	h,#80
	call	slot
	pop	hl
	ret

Datslt:	defb	0	;load for assembler file

;----- 1 byte to textbuffer + optionally: increase buffer
;----- IN: DE=address

puttxtbuffer:
	ld	(de),a
	inc	de
	bit	6,d
	ret	z
	push	af
	push	hl
	ld	hl,Textbloknr
	ld	a,(Aantaltextbl)
	cp	(hl)
	jp	z,error1	;text buffer full
	inc	(hl)
	ld	a,(hl)
	call	zettextblok
_korterjon2	pop	hl
	pop	af
	res	6,d
	ret

;----- 1 byte of label buffer + increase buffer block if necessary
;----- IN: DE=address
getlabbuffer:
	ld	a,(de)
	inc	de
	bit	6,d
	ret	z
	push	af
	push	hl
	ld	hl,Labbloknr
	ld	a,(Aantallabelb)
	cp	(hl)
	jr	z,_getlabbuff1	;end of label buffer
	inc	(hl)
	ld	a,(hl)
	call	zetlabblok
_getlabbuff1:	jr	_korterjon2	;*******************************

;----- 1 byte of textbuffer + increase buffer block if necessary
;----- IN: DE=address
gettxtbuffer:
	ld	a,(de)
	inc	de
	bit	6,d
	ret	z
	push	af
	push	hl
	ld	hl,Textbloknr
	ld	a,(Aantaltextbl)
	cp	(hl)
	jr	z,_gettxtbuff1	;text buffer full
	inc	(hl)
	ld	a,(hl)
	call	zettextblok
_gettxtbuff1:	jr	_korterjon2

;----- 1 byte to data buffer + optionally: increase buffer
;----- IN: DE=address

putdatbuffer:
	ld	(de),a
	inc	de
	bit	6,d
	ret	z
	push	af
	push	hl
	ld	hl,Databloknr
	ld	a,(Aantaldatabl)
	cp	(hl)
	jp	z,error2	;data buffer full
	inc	(hl)
	ld	a,(hl)
	call	zetdatablok
	jr	_korterjon2

;----- 1 byte of data buffer + increase buffer block if necessary
;----- IN: DE=address
getdatbuffer:
	ld	a,(de)
	inc	de
	bit	6,d
	ret	z
	push	af
	push	hl
	ld	hl,Databloknr
	ld	a,(Aantaldatabl)
	cp	(hl)
	jr	z,_getdatbuff1	;data buffer full
	inc	(hl)
	ld	a,(hl)
	call	zetdatablok
_getdatbuff1:	jr	_korterjon2	;****************************

;----- Compare HL with DE
rst20:
	ld	a,h
	sub	d
	ret	nz
	ld	a,l
	sub	e
	ret

;********** SUBROUTINES

beep:
	push	af
	push	bc
	push	de
	push	hl
	push	ix
	push	iy
	ld	ix,#c0
	call	gobios
	pop	iy
	pop	ix
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

getr800:	ld	ix,#183
	jp	gobios
putr800:	ld	ix,#180
	jp	gobios


;########################## Error Handling

;-------------------- ASCII LOAD

Bronerrors:	defb	0	;0=editor,1=ascii,2=debuggerline


error1:	;Text buffer full
	ld	bc,Txtbuf_full
_error1_2:
	ld	hl,(80-20)/2+80*Commline
_error1_1:
	ld	a,(Bronerrors)
	dec	a
	jr	z,_errdisk
	dec	a
	jr	z,_error1_3
	call	txttocomm
	call	beep
	call	pushanykey
	call	wiscommline
	jr	_error1_3
_errdisk:
	call	printtekst
	call	getkey
_error1_3:
	ld	a,(Bronerrors)
	or	a
	jr	z,_editorfout1
	dec	a
	jr	z,_loadfout1
	jp	debuggerfout
_loadfout1:
	ld	a,(Blokload)
	or	a
	ld	sp,(Sp_asciiload)
	jp	nz,closefile	;load block
	ld	a,(Lastdatblok)
	call	zetdatablok
	ld	hl,(Lastdatadres)
	ld	(hl),#ff	;end of data block
	jp	closefile
Lastdatblok:	defb	0
Lastdatadres:	defw	0

_editorfout1:	ld	sp,(Sp_editor)
	jp	editor_cont

Sp_asciiload:	defw	0
Txtbuf_full:	defb	"Sourcebuffer too small",0

error2:	;Data buffer full
	ld	bc,Datbuf_full
	jr	_error1_2
Datbuf_full:	defb	"Databuffer too small",0

;------ Show labels on screen

;Aantallabels: defw    0
;Huidiglabel:  defw    1
;Balklabel:    defb    1

Labvramadres:	equ	#1c80	;***********************************
Labpage:	defw	1
Showlab1ek:	defb	1

Orig:	equ	kbuf+100	;*************************
Test:	equ	kbuf+125	;**************************
Oudtest:	equ	kbuf+150	;**************************
Showlabels:	defb	0	;0=off, 1=on (off after GO)

__labels:
showlabels:
	ld	hl,3*80+18
	ld	de,Errorhok
	call	printblokkle
	ld	hl,4*80+(80-6)/2
	ld	bc,Labels
	call	printtekst

	ld	a,(Showlabels)
	or	a
	jp	z,prtnolab
	ld	a,1
	call	zetlabblok
	ld	a,(#8003)
	or	a
	jp	z,prtnolab
	call	GOgeeflabdat
	ld	a,#ff
	ld	(kbuf+27*3+2),a	;end of mark***********************
	ld	a,h
	or	l
	jp	z,prtnolab
	ld	a,1
	ld	(Cursoronoff),a

	ld	a,(Showlab1ek)
	or	a
	call	nz,showlabini

	call	printlabels
	ld	bc,#0103
	call	mouseoffset
showlabhoofd:
	ld	iy,Laboptie
	call	setlabbalk
	call	getkey
	push	af
	call	wislabbalk
	pop	af
	cp	Up
	jp	z,labup
	cp	Down
	jr	z,labdown
	cp	27
	jr	z,showlabesc
	cp	1
	jr	z,showlabesc
	cp	13
	jp	z,showlabspace
	and	255-32
	jp	z,showlabspace
	jr	showlabhoofd

showlabesc:
	ld	bc,#0101
	call	mouseoffset
	jp	editor_cont

labdown:
	ld	a,(Matrix+6)
	and	%10
	jr	z,labdownctrl
	inc	(iy)
	ld	a,(iy)
	cp	19
	jr	z,_labdown1
	ld	b,a
	ld	hl,5*80+24
	ld	de,80
_labdown2:
	add	hl,de
	djnz	_labdown2
	call	readvram
	or	a
	jr	nz,showlabhoofd
	dec	(iy)
	jr	showlabhoofd
_labdown1:
	dec	(iy)
	call	showlabdown
	jr	c,showlabhoofd
	ld	(iy),1
	jr	showlabhoofd
labdownctrl:
	call	showlabdown
	ld	iy,Laboptie
	ld	b,(iy)
	ld	hl,5*80+24
	ld	de,80
_labdownctr1:
	add	hl,de
	djnz	_labdownctr1
_labdownctr2:
	call	readvram
	or	a
	jp	nz,showlabhoofd
	dec	(iy)
	sbc	hl,de
	jr	_labdownctr2

showlabdown:
	ld	hl,23*80+24
	call	readvram
	or	a
	scf
	ret	z
	ld	hl,Oudtest
	ld	de,Orig
	ld	bc,21
	ldir		;last
	ld	a,#ff
	ld	(Oudtest),a
	call	haal1groter
	ret	c
	ld	hl,(Labpage)
	inc	hl
	ld	(Labpage),hl
	call	berlabvram
	ex	de,hl
	ld	hl,Lab_adres
	ld	bc,5
	call	ramtovram
	call	printlabels
	xor	a
	ret
labup:
	ld	a,(Matrix+6)
	and	%10
	jr	z,labupctrl
	ld	hl,(Labpage)
	dec	hl
	dec	(iy)
	jp	nz,showlabhoofd
	inc	(iy)
	ld	a,h
	or	l
	jp	z,showlabhoofd	;1st page at the top
	ld	(iy),18
labupctrl:
	call	showlabup
	jp	showlabhoofd

showlabup:
	ld	hl,(Labpage)
	dec	hl
	ld	a,h
	or	l
	ret	z
	ld	(Labpage),hl
	jp	printlabels


showlabini:	;1st time
	ld	(Laboptie),a	;1
	dec	a	;0
	ld	(Showlab1ek),a
	ld	(Orig),a
	dec	a	;#ff
	ld	(Oudtest),a
	ld	hl,1
	ld	(Labpage),hl
	ld	hl,kbuf
	ld	(Lab_lijst),hl
	call	haal1groter
	ld	hl,Lab_adres
	ld	de,Labvramadres
	ld	bc,5
	jp	ramtovram

showlabspace:
	ld	b,(iy)
	ld	hl,5*80+24
	ld	de,80
_showlabsp1:
	add	hl,de
	djnz	_showlabsp1
	ld	de,Register2
	ld	bc,21
	call	vramtoram
	ld	de,1

_showlabsp3:
	push	de
	call	haalzinzin
	jr	c,_showlabsp2	;not found
	ld	hl,Zin
	LD	A,(Huidigupper)
	OR	A
	LD	C,#FF
	JR	Z,J6C3B
	LD	C,#DF
J6C3B	call	labeluitzin
	jr	c,_showlabsp4	;no label
	ld	hl,Label
	ld	de,Register2
_showlabsp5:
	ld	a,(de)
	inc	de
	cp	(hl)
	inc	hl
	jr	nz,_showlabsp4
	or	a
	jr	nz,_showlabsp5
	pop	de
	ld	(Regelnr),de
	XOR	A
	LD	(afb_offset),A
	jp	_home_cont	;5773************************
_showlabsp4:
	pop	de
	inc	de
	jr	_showlabsp3
_showlabsp2:
	call	beep
	jp	showlabhoofd

printlabels:
	call	berlabvram
	ld	de,Lab_adres
	ld	bc,5
	call	vramtoram
	ld	a,(Lab_blk)
	call	zetlabblok
	ld	de,(Lab_adres)
	call	haallabel
	ld	hl,6*80+24
	call	setvramwrite
	ld	hl,Test
	call	prtlabel
	set	7,h
	ld	de,(Tijd_wrd)
	ld	a,(Tijd_srt)
	call	prtwaarde

	ld	hl,Test
	ld	de,Orig
	ld	bc,21
	ldir
	ld	b,17
	ld	hl,7*80+24
_prtlabloop:
	push	bc
	push	hl
	call	setvramwrite
	ld	a,#ff
	ld	(Oudtest),a
	call	haal1groter
	jr	c,_prtlabend
	ld	hl,Oudtest
	ld	de,Orig
	ld	bc,21
	ldir
	ld	hl,Oudtest
	call	prtlabel
	set	7,h
	ld	de,(Lab_waarde)
	ld	a,(Lab_soort)
	call	prtwaarde
_prtlabcont:
	pop	hl
	ld	de,80
	add	hl,de
	pop	bc
	djnz	_prtlabloop
	ret
_prtlabend:
	ld	hl,Oudtest
	ld	(hl),0
	ld	b,29+6
	call	_prtlabel1
	jr	_prtlabcont

Labelboven:	defs	21
Labels:	defb	"Labels:",0

prtlabel:
	ld	b,28
_prtlabel1:
	ld	a,(hl)
	out	(#98),a
	or	a
	jr	z,_prtlabel2
	inc	hl
_prtlabel2:
	djnz	_prtlabel1
	ret

prtwaarde:
	ld	bc,Labmacro
	or	a
	jp	nz,printtekst
	ld	a," "
	out	(#98),a
	ld	b,4
	call	printhexadec
	ld	a," "
	out	(#98),a
	ret
Labmacro:	defb	"[MACRO]",0

berlabvram:
	ld	hl,(Labpage)
	ld	d,h
	ld	e,l
	add	hl,hl
	add	hl,hl
	add	hl,de	;*5
	ld	de,Labvramadres-5	;*************1c7b***********
	add	hl,de
	ret

Laboptie:	defb	0

wislabbalk:
	call	berbalk
	jp	wisbalk
setlabbalk:
	call	berbalk
	jp	setbalk
berbalk:
	ld	a,(iy)
	add	a,5
	ld	l,a
	ld	h,22
	ld	b,38
	ret


;----- Subroutines show labels

haal1groter:	;Orig = kbuf+100, Test = kbuf+125, Oldtest = kbuf+150************
;              continues until: test > orig & test < oldtest      ************
	ld	ix,(Lab_lijst)
	ld	a,(ix+2)
	cp	#ff
	jr	nz,_haal1gr1
	ld	a,(Oudtest)
	inc	a
	scf
	ret	z	;end of buffer and not found
	xor	a
	ret
_haal1gr1:
	or	a
	jr	z,_haal1gr_nf1
	call	zetlabblok
	ld	e,(ix)
	ld	d,(ix+1)
_haal1gr2:
	call	haallabel
	ld	de,Test
	ld	hl,Orig
	call	testgroter
	jr	c,_haal1gr_nfd	;orig > test    OK
	ld	de,Oudtest
	ld	hl,Test
	call	testgroter
	jr	c,_haal1gr_nfd	;test > old test    OK
_haal1gr_fnd:
	ld	hl,Test
	ld	de,Oudtest
	ld	bc,21
	ldir		;make oldtest = test
	ld	hl,Tijd_srt
	ld	de,Lab_soort
	ld	bc,6
	ldir
_haal1gr_nfd:
	ld	a,(Next+2)
	or	a
	jr	z,_haal1gr_nf1
	call	zetlabblok
	ld	de,(Next)
	jr	_haal1gr2
_haal1gr_nf1:
	ld	a,(Oudtest)
	cp	#ff
	ccf
	ret	nc
	xor	a
	ld	(Orig),a
	inc	ix
	inc	ix
	inc	ix
	ld	(Lab_lijst),ix
	jr	haal1groter

haallabel:
	ld	a,(Labbloknr)
	ld	(Tijd_blk),a
	ld	(Tijd_adr),de
	call	getlabbuffer
	ld	(Next),a
	call	getlabbuffer
	ld	(Next+1),a
	call	getlabbuffer
	ld	(Next+2),a
	ld	hl,Test
_haallabel1:
	call	getlabbuffer
	ld	(hl),a
	res	7,(hl)
	inc	hl
	bit	7,a
	jr	z,_haallabel1
	ld	(hl),0
	call	getlabbuffer
	ld	l,a
	call	getlabbuffer
	ld	h,a
	ld	(Tijd_wrd),hl
	call	getlabbuffer
	and	1
	ld	(Tijd_srt),a
	ret
	;org 6e06
Lab_soort:	defb	0
Lab_waarde:	defw	0
Lab_adres:	defw	0
Lab_blk:	defb	0
Lab_lijst:	defw	0
Next:	defs	3	;address+block next
Tijd_srt:	defb	0
Tijd_wrd:	defw	0
Tijd_adr:	defw	0
Tijd_blk:	defb	0

;--- Test whether de > hl

testgroter:
	ld	a,(de)
	inc	de
	cp	(hl)
	inc	hl
	ret	c	;de<hl
	jr	nz,_testgr_fnd	;de>hl
	or	a
	jr	nz,testgroter	;so far right
	scf		;de=hl
	ret
_testgr_fnd:
	xor	a
	ret

GOgeeflabdat:
	push	hl
	ld	hl,geeflabdata
	jp	gotoass

;------ Print errors on screen


printerrors1:
	call	edit_ret1	;for ctrl-r call
__errors:
printerrors:
	ld	hl,3*80+18
	ld	de,Errorhok
	call	printblokkle
	ld	hl,4*80+(80-6)/2
	ld	bc,Errors
	call	printtekst

	ld	a,(Aantalerrors)
	or	a
	jp	z,prtnoerr
	ld	a,1
	ld	(Cursoronoff),a

_printerrcnt:
	ld	iy,Aantalerrors
	ld	a,(Huidigerror)
	ld	l,a
	ld	h,0
	ld	e,l
	ld	d,h
	add	hl,hl
	add	hl,hl
	add	hl,de
	ld	de,#1910-5
	add	hl,de
	ld	de,(Bufferpage0)
	ld	bc,5*18
	call	vramtoram

	ld	hl,6*80+21
	ld	ix,(Bufferpage0)
	ld	a,(Huidigerror)
	dec	a
	call	GOprterrline

_key_error:
	ld	a,(Balkerror)
	add	a,5
	ld	l,a
	ld	h,20
	ld	b,42
	call	setbalk
	call	getkey
	push	af
	ld	a,(Aantalerrors)
	ld	b,a
	ld	a,(Huidigerror)
	ld	d,a
	ld	a,(Balkerror)
	dec	a
	add	a,d
	ld	c,a
	pop	af
	cp	Escape
	jr	z,_prt_esc
	cp	1
	jr	z,_prt_esc
	cp	Up
	jr	z,_prt_up
	cp	Down
	jr	z,_prt_down
	cp	13
	jr	z,_prt_space
	and	255-32
	jr	nz,_key_error
	jr	_prt_space
_prt_down:
	ld	a,c
	cp	b
	jr	z,_key_error
	inc	d
	ld	a,(Balkerror)
	cp	18
	jr	z,_nobalk1
	inc	a
_balkmove:
	push	af
	call	wiserrbalk
	pop	af
	ld	(Balkerror),a
	jr	_key_error
_prt_up:
	ld	a,c
	cp	1
	jr	z,_key_error
	dec	d
	ld	a,(Balkerror)
	dec	a
	jr	nz,_balkmove
_nobalk1:
	ld	a,d
	ld	(Huidigerror),a
	jp	_printerrcnt
_prt_esc:
	call	wiserrbalk
	jp	editor_cont
_prt_space:
	call	wiserrbalk
	ld	a,(Balkerror)
	ld	b,a
	add	a,a
	add	a,a
	add	a,b
	ld	e,a
	ld	d,0
	ld	hl,(Bufferpage0)
	add	hl,de
	dec	hl
	ld	a,(hl)
	push	hl
	call	setnewbuffer
	pop	hl
	jr	c,_notbuf
	dec	hl
	ld	d,(hl)
	dec	hl
	ld	e,(hl)
	ld	l,e
	ld	h,d
	dec	hl
	ld	bc,(Laatsteregel)
	or	a
	sbc	hl,bc
	jr	c,_prt_space1
_notbuf:
	call	beep
	jp	_key_error
_prt_space1:
	ld	(Regelnr),de
	XOR	A
	LD	(afb_offset),A
	jp	_home_cont

Errors:	defb	"Errors:",0


wiserrbalk:
	ld	a,(Balkerror)
	add	a,5
	ld	l,a
	ld	h,20
	ld	b,42
	jp	wisbalk

Errorhok:	defw	Eh1,Eh2,Eh2,Eh2,Eh2,Eh2,Eh2,Eh2,Eh2,Eh2,Eh2,Eh2,Eh2,Eh2
	defw	Eh2,Eh2,Eh2,Eh2,Eh2,Eh2,Eh2,Eh3,0
Eh1:	defb	1,24,44,23,1,25,0
Eh2:	defb	1,22,44,0,1,22,0
Eh3:	defb	1,26,44,23,1,27,0

	;org 6f75
prtnolab:
	ld	bc,Nolabels
	jr	_prtnoerr1
Nolabels:	defb	"No labels !",0
prtnoerr:
	ld	bc,Noerrors
_prtnoerr1:
	ld	hl,12*80+35
	call	printtekst
	call	getkey
	jp	editor_cont
Noerrors:	defb	"No errors !",0

;---------- Search function

dosearch:
	ld	de,(Regelnr)
	ld	(Searchstart),de	;opening line
	ld	(Searchregel),de
	bit	0,(iy+1)
	jp	z,s_vooruit

;----- Search backwards

s_achteruit:
	push	de
	push	iy
	call	haalzinzin
	pop	iy
	pop	de
	jr	nc,s_achternx3
	dec	de
	ld	a,d
	or	e
	scf
	ret	z	;1st line = end of buffer
	jr	s_achternx2	;end of buffer
s_achternx3:
	ld	(iy-1),a	;length line (1-80)
	ld	a,(Editor_x)
	ld	e,a
	ld	d,0
	ld	hl,Zin-2	;previous character
	add	hl,de
	dec	a
	ld	c,a	;current position (1-80)
	jr	s_achter3

s_achternxt:
	ld	de,(Searchregel)
	dec	de
s_achternx2:
	ld	(Searchregel),de
	ld	a,d
	or	e
	jr	nz,s_achternx1
	ld	de,(Laatsteregel)
	call	testrond
	ret	c
	dec	de
	jr	s_achternx2
s_achternx1:
	call	testrond
	ret	c
	push	iy
	call	haalzinzin
	pop	iy
	ld	(iy-1),a
	ld	c,a
	ld	hl,Zin-1	;LEAVE IT !!!
	ld	e,a
	ld	d,0
	add	hl,de	;last character
s_achter3:
	ld	de,Searchtext
s_achter2:
	ld	a,c
	or	a
	jr	z,s_achternxt	;previous line
	ld	a,(hl)
	dec	hl
	dec	c
	call	_upper
	ld	b,a
	ld	a,(de)
	call	_upper
	cp	b
	jr	nz,s_achter2
	push	hl
	push	bc
	inc	hl
	inc	hl
	inc	c	;not 2 times, because counting starts at 1 !
	call	testrest
	pop	bc
	pop	hl
	inc	hl
	ret	nc
	dec	hl
	jr	s_achter3	;search further in this sentence


;----- Search ahead

s_vooruit:
	push	iy
	call	haalzinzin
	pop	iy
	ld	de,1
	jr	c,s_vooruitnx2	;end of buffer
	ld	(iy-1),a	;length rule (1-80)
	ld	a,(Editor_x)
	ld	e,a
	ld	d,0
	ld	hl,Zin
	add	hl,de	;next character
	ld	c,a	;current position (0-79)
	jr	s_vooruit3

s_vooruitnxt:
	ld	de,(Searchregel)
	inc	de
s_vooruitnx2:
	ld	(Searchregel),de
s_vooruitnx1:
	call	testrond
	ret	c
	push	iy
	call	haalzinzin
	pop	iy
	ld	de,1
	jr	c,s_vooruitnx2
	ld	(iy-1),a
	ld	c,0
	ld	hl,Zin	;LEAVE IT !!!
s_vooruit3:
	ld	de,Searchtext
s_vooruit2:
	ld	a,c
	cp	(iy-1)
	jr	nc,s_vooruitnxt	;next line
	ld	a,(hl)
	inc	hl
	inc	c
	call	_upper
	ld	b,a
	ld	a,(de)
	call	_upper
	cp	b
	jr	nz,s_vooruit2
	push	hl
	push	bc
	call	testrest
	pop	bc
	pop	hl
	dec	hl
	ret	nc
	inc	hl
	jr	s_vooruit3	;search further in this sentence

testrest:
	inc	de
	ld	a,(de)
	or	a
	ret	z
	call	_upper
	ld	b,a
	ld	a,c
	cp	(iy-1)
	ccf
	ret	c
	ld	a,(hl)
	inc	hl
	inc	c
	call	_upper
	cp	b
	scf
	ret	nz
	jr	testrest

_upper:
	bit	0,(iy+2)
	ret	z
	cp	"a"
	ret	c
	cp	"z"+1
	ret	nc
	and	%11011111
	ret

testrond:
	ld	hl,(Searchstart)
	or	a
	sbc	hl,de
	ld	a,h
	or	l
	ret	nz
	scf
	ret

Searchstart:	defw	0
Searchregel:	defw	0

;---------- Place screen and cursor on searchstring

searchcursor:
	ld	(Searchplaats),hl
	ld	de,Zin
	or	a
	sbc	hl,de
	ld	a,l
	inc	a
	ld	(Editor_x),a
	LD	HL,afb_offset
	CP	60	;****check this out
	LD	(HL),0
	JR	C,J70DE
	CP	100
	LD	(HL),40
	JR	C,J70DE
	LD	(HL),80
J70DE	ld	hl,(Searchregel)
	ld	(Regelnr),hl
	ld	a,Bovenaantext
	ld	(Editor_y),a
	bit	0,(iy)
	ld	b,10
	jr	z,_search_cur1
	ld	b,5
_search_cur1:	push	bc
	call	upschuif
	pop	bc
	jr	c,_search_cur2
	push	bc
	call	downnormal
	pop	bc
	djnz	_search_cur1

_search_cur2:
	ld	hl,(Editor_y)
	ld	(Cursorpositi),hl	;f3dc*************************
	LD	A,H
	LD	HL,afb_offset
	SUB	(HL)
	LD	(#F3DD),A	;*********************
	xor	a
	ld	(Cursoronoff),a
	jp	printscherm

;----- Replace text

doreplace:
	ld	hl,80*Commline+(80-15)/2
	ld	bc,Replace
	call	txttocomm
	xor	a
	ld	(Cursoronoff),a
	call	getkey
	push	af
	call	wiscommline
	pop	af
	and	%11011111
	cp	"Y"
	ret	nz
	ld	de,(Searchregel)
	call	haalzinzin
	INC	HL
	LD	(HL),#FF
	ld	hl,(Searchplaats)	;must be 71ab***********************
	ld	de,Zin
	or	a
	sbc	hl,de
	ld	b,l
	ld	hl,Zin
	ld	de,Zin+161
	ld	a,b
	or	a
	jr	z,_doreplace1
_doreplace0:
	call	copydeel
_doreplace1:
	ld	bc,Searchtext+1	;4727***************************
_doreplace2:
	ld	a,(bc)
	inc	bc
	inc	hl
	or	a
	jr	nz,_doreplace2
	push	hl	;rest source

	;ld      iy,Searchreplac********may go*******************
	ld	hl,Replacetext	;4740********************************
_doreplace3:
	ld	a,(hl)
	inc	hl
	or	a
	jr	z,_doreplace4
	ld	(de),a
	inc	de
	jr	_doreplace3

_doreplace4:
	pop	hl
	ld	b,160
	call	copydeel
	xor	a
	ld	(Printret),a
	ld	hl,Zin+161
	ld	de,Zin
	ld	bc,160+1
	ldir
	ld	hl,Zin+161
_doreplace5:
	dec	hl
	ld	a,(hl)
	cp	" "
	jr	z,_doreplace5
	inc	hl
	ld	(hl),0
	jp	_return_cont

copydeel:
	ld	a,(hl)
	CP	#FF
	JR	Z,J7194
	inc	hl
	or	a
	jr	nz,_copydeel1
J7194	ld	a," "
_copydeel1:
	ld	(de),a
	inc	de
	djnz	copydeel
	ret

Replace:	defb	"Replace ? (y/n)",0
Searchplaats:	defw	0

;----- print text on command line

txttocomm:
	push	hl
	push	bc
	ld	hl,#1800+10*Commline+1
	ld	bc,8
	ld	a,255
	call	fillvram
	ld	hl,80*Commline+8
	ld	bc,64
	xor	a
	call	fillvram
	pop	bc
	pop	hl
	jp	printtekst

wiscommline:
	ld	hl,#1800+10*Commline+1
	ld	bc,8
	xor	a
	jp	fillvram

;routines main program ###################################################

;----- Memory

Textbufadres:	defw	0
Slotp0adres:	defw	0
Soortmem:	defb	0	;IN A ROW
Dosversion:	defb	0	;IN A ROW
Page0adres:	defw	0
Compassadres:	defw	0
Sp_memory:	defw	0

Memory_x:	defb	1
Memory_y:	defb	1
Memory_oldy:	defb	1
Memory_chg:	defb	0	;0=normal, 1=Konpass slot

domemory:
	ld	(Sp_memory),sp
	call	putreg

	call	inimem
	call	allocatemem
	call	addusedmem
	call	addblok123

	call	printsourceb
	call	printdatab
	call	printlabb
	call	printcompass
	ld	a,(Soortmem)
	ld	hl,Mt6_1
	ld	bc,6
	or	a
	jr	z,_memory4
	add	hl,bc
	dec	a
	jr	z,_memory4
	add	hl,bc
_memory4:
	ld	de,22*80+42+16
	call	ramtovram

_memory3:
	call	printpages
memory_hoofd:
	ld	iy,Memory_x
	call	zetmembalk
	call	getkey
	ld	iy,Memory_x
	cp	1
	jr	z,memoryback
	cp	27
	jr	z,memoryback
	cp	Right
	jr	z,memory_right
	cp	Left
	jr	z,memory_left
	cp	Up
	jp	z,memory_up
	cp	Down
	jp	z,memory_down
	cp	13
	jp	z,memory_space
	and	255-32
	jp	z,memory_space
	jr	memory_hoofd
memoryback:
	call	wismembalk
	call	freemem
	ld	sp,(Sp_memory)
	ret

memory_right:
	ld	a,(iy)
	cp	8
	jr	z,memory_hoofd
	call	wismembalk
	ld	a,(iy+1)
	cp	6+1
	jr	c,mem_right1
	cp	9+1
	jr	c,mem_right2
	cp	13+1
	jr	c,mem_right3
	ld	a,(iy)
	cp	4
	jr	nz,mem_right1
	ld	(iy+1),13
	jr	mem_right1
mem_right3:
	ld	a,(iy)
	cp	6
	jr	nz,mem_right1
	inc	(iy)
	ld	a,(iy+1)
	cp	13
	jr	nz,mem_right1
	ld	(iy+1),12
	jr	mem_right1
mem_right2:
	ld	a,(iy)
	cp	4
	jr	nz,mem_right1
	ld	(iy+1),6
mem_right1:
	inc	(iy)
	jp	memory_hoofd

memory_left:
	ld	a,(iy)
	dec	a
	jp	z,memory_hoofd
	call	wismembalk
	dec	(iy)
	ld	a,(iy)
	cp	7
	jp	nz,memory_hoofd
	ld	a,(iy+1)
	cp	10
	jp	c,memory_hoofd
	dec	(iy)
	jp	memory_hoofd

memory_up:
	ld	a,(iy+1)
	dec	a
	jp	z,memory_hoofd
	call	wismembalk
	dec	(iy+1)
	ld	a,(iy+1)
	cp	9
	jp	nz,memory_hoofd
	ld	a,(iy)
	cp	5
	jp	c,memory_hoofd
	ld	(iy+1),6
	jp	memory_hoofd

memory_down:
	ld	a,(iy)
	cp	5
	jr	nc,mem_down1
	ld	a,(iy+1)
	cp	16
	jp	z,memory_hoofd
	call	wismembalk
	inc	(iy+1)
	jp	memory_hoofd
mem_down1:
	cp	8
	jr	nz,mem_down2
	ld	a,(iy+1)
	cp	12
	jp	z,memory_hoofd
mem_down2:
	ld	a,(iy+1)
	cp	13
	jp	z,memory_hoofd
	call	wismembalk
	inc	(iy+1)
	ld	a,(iy+1)
	cp	7
	jp	nz,memory_hoofd
	ld	(iy+1),10
	ld	a,(iy)
	cp	7
	jp	nz,memory_hoofd
	ld	(iy),8
	jp	memory_hoofd

memory_space:
	ld	a,(iy+1)
	ld	(iy+2),a
	ld	a,(iy)
	cp	4+1
	ld	hl,(Textbufadres)
	ld	de,Textbuffer2-Textbuffer1
	jr	c,mem_source
	ld	de,Databuffer1-Textbuffer1
	add	hl,de
	ld	a,(iy+1)
	cp	6+1
	ld	de,Databuffer2-Databuffer1
	jr	c,mem_data
	ld	de,Labelbuffer-Databuffer1
	add	hl,de
	ld	a,(iy)
	cp	5
	jr	z,mem_label
	cp	6
	jr	z,mem_compass

	ld	a,(iy+1)
	sub	10
	ld	(Changepage),a
	ld	hl,(Page0adres)
	ld	e,a
	ld	d,0
	add	hl,de
	add	hl,de
	ld	(Chgbuffer),hl
	ld	(iy+3),2	;feature: pages
	jr	changehoofd

mem_label:
	ld	a,(iy+1)
	sub	9
	ld	(iy+1),a	;will be restored later
	jr	_mem_source1
mem_data:
	ld	a,(iy)
	sub	4
mem_source:
	dec	a
	jr	z,_mem_source1
	add	hl,de
	jr	mem_source
_mem_source1:
	ld	(Chgbufstart),hl
	ld	a,(hl)
	inc	a
	cp	(iy+1)
	jp	c,_changeback1
	ld	a,(iy+1)
	cp	(hl)
	ld	a,0
	jr	c,_mem_source2
	inc	a
_mem_source2:
	ld	(Magleeg),a
	ld	e,(iy+1)
	dec	e
	rlc	e
	ld	d,0
	inc	hl
	add	hl,de
	ld	(Chgbuffer),hl
	ld	(iy+3),0	;normal change
	jr	_changehoof1

mem_compass:
	xor	a
	ld	(Magleeg),a
	ld	a,(iy+1)
	sub	10
	rlca
	ld	e,a
	ld	d,0
	ld	hl,(Compassadres)
	add	hl,de
	ld	(Chgbuffer),hl
	ld	(iy+3),1	;Konpass slot
_changehoof1:
	ld	a,(hl)
	ld	(Oldvalue),a
	ld	b,a
	inc	hl
	ld	a,(hl)
	ld	(Oldvalue+1),a
	call	exist
	res	6,(ix)	;also good at the end

changehoofd:
	call	getkey
	ld	ix,(Chgbuffer)
	cp	Right
	jr	z,changeright
	cp	Up
	jr	z,changeright
	cp	Left
	jr	z,changeleft
	cp	Down
	jr	z,changeleft
	cp	27
	jr	z,changeback
	cp	1
	jr	z,changeback
	cp	13
	jr	z,changeback
	and	255-32
	jr	nz,changehoofd
changeback:
	ld	a,(iy+3)
	cp	2
	jr	z,_changeback1
	ld	hl,(Chgbuffer)
	ld	a,(hl)
	or	a
	jr	z,_changeback1
	ld	b,a
	inc	hl
	ld	a,(hl)
	call	exist
	set	6,(ix)	;also good at the end
	ld	a,(iy+3)
	dec	a
	jr	nz,_changeback1
	ld	bc,(Oldvalue)
	ld	hl,(Chgbuffer)
	call	moveprog
_changeback1:
	ld	a,(iy+2)
	ld	(iy+1),a	;recovery of label
	jp	memory_hoofd

changeright:
	xor	a
	jr	_changeleft1
changeleft:
	ld	a,1
_changeleft1:
	call	zoeken
	ld	a,(iy+3)
	or	a
	jr	nz,_changeleft3
	ld	hl,(Chgbuffer)
	ld	a,(hl)
	or	a
	ld	hl,(Chgbufstart)
	jr	z,_changeleft2
	ld	a,(hl)
	cp	(iy+1)
	jr	nc,_changeleft3
	inc	(hl)
	jr	_changeleft3
_changeleft2:
	ld	a,(hl)
	cp	(iy+1)
	jr	nz,_changeleft3
	dec	(hl)
_changeleft3:
	ld	a,(iy)
	cp	4+1
	ld	hl,printsourceb
	jr	c,_changeleft4
	ld	a,(iy+2)
	cp	6+1
	ld	hl,printdatab
	jr	c,_changeleft4
	call	printlabb
	call	printcompass
	call	printpages
	jp	changehoofd
_changeleft4:
	ld	(_changecall+1),hl
_changecall:	call	0
	jp	changehoofd


Chgbufstart:	defw	0
Chgbuffer:	defw	0
Oldvalue:	defw	0

zetmembalk:
	call	bermemadres
	jp	setbalk
wismembalk:
	call	bermemadres
	jp	wisbalk
bermemadres:
	ld	a,(iy)
	rlca
	ld	b,a
	rlca
	rlca
	add	a,b
	sub	10-2
	ld	h,a
	ld	a,(iy+1)
	add	a,7
	ld	l,a
	ld	b,7
	ret

printsourceb:
	ld	hl,8*80+2
	ld	de,(Textbufadres)
	ld	bc,#0410
_prtsourceb1:
	push	bc
	push	hl
	push	de
	ld	b,c
	ld	a,(de)
	ld	c,a
	inc	de
	call	prtmem
	pop	hl
	ld	bc,Textbuffer2-Textbuffer1	;BEATS ! (ALSO HERE)
	add	hl,bc
	ex	de,hl
	pop	hl
	ld	bc,10
	add	hl,bc
	pop	bc
	djnz	_prtsourceb1
	ret

printdatab:
	ld	hl,(Textbufadres)
	ld	de,Databuffer1-Textbuffer1	;BEATS !
	add	hl,de
	ex	de,hl
	ld	hl,8*80+42
	ld	bc,#0406
_prtdatab1:
	push	bc
	push	hl
	push	de
	ld	b,c
	ld	a,(de)
	ld	c,a
	inc	de
	call	prtmem
	pop	hl
	ld	bc,Databuffer2-Databuffer1	;BEATS
	add	hl,bc
	ex	de,hl
	pop	hl
	ld	bc,10
	add	hl,bc
	pop	bc
	djnz	_prtdatab1
	ret

printlabb:
	ld	hl,(Textbufadres)
	ld	de,Labelbuffer-Textbuffer1	;BEATS !
	add	hl,de
	ex	de,hl
	ld	hl,17*80+42
	ld	b,4
	ld	a,(de)
	ld	c,a
	inc	de
	jr	prtmem

printpages:
	ld	hl,17*80+72
	ld	de,(Page0adres)
	ld	bc,#0303
	call	prtmem
	inc	de	;***********************************
	inc	de	;Page 3 is 2 bytes ahead
	ld	bc,#0101
	call	prtmem
	ld	hl,17*80+76
	ld	de,(Page0adres)
	ld	b,3
_printpages1:
	push	bc
	ld	a,3
	sub	b
	ld	b,a
	ld	a,(de)
	call	geefsoortblk
	and	%10
	ld	bc,3
	call	z,fillvram	;clear number of blocks
	inc	de
	inc	de
	ld	bc,80
	add	hl,bc
	pop	bc
	djnz	_printpages1
	ret

printcompass:
	ld	hl,17*80+52
	ld	de,(Compassadres)
	ld	bc,#0404
prtmem:
	ld	a,c
	or	a
	jr	nz,_prtmem2
_prtmem1:
	push	bc
	ld	bc,Prtmem1
	call	printtekst
	inc	de
	jr	_prtmemcnt
_prtmem2:
	dec	c
	push	bc
	call	setvramwrite
	ld	a,(de)
	inc	de
	ld	c,a
	bit	7,c
	jr	z,_prtmem3
	and	3
	add	a,"0"
	out	(#98),a
	nop
	nop
	ld	a,"-"
	out	(#98),a
	ld	a,c
	rrca
	rrca
	and	3
	add	a,"0"
	jr	_prtmemcnt1
_prtmem3:
	xor	a
	out	(#98),a
	nop
	nop
	ld	a,c
	add	a,"0"
	out	(#98),a
	nop
	nop
	ld	a," "
_prtmemcnt1:
	out	(#98),a
	nop
	nop
	ld	a," "
	out	(#98),a
	push	de
	push	hl
	ld	a,(de)
	ld	e,a
	ld	d,0
	ld	b,3
	set	7,h
	call	printdecimaa
	pop	hl
	pop	de
_prtmemcnt:
	ld	bc,80
	add	hl,bc
	inc	de
	pop	bc
	djnz	prtmem
	ret
Prtmem1:	defb	"  ---  ",0

Mt6_1:	defb	"None  "
Mt6_2:	defb	"Dos 2 "
Mt6_3:	defb	"Memman"

;----- Specify type+number of blocks at spec. page+slot
;----- IN:  A=slot, B=page
;----- OUT: A=sort, B=number (0=no mapper)
zoeksoort:
	ld	a,(ix)
	ld	b,d
geefsoortblk:
	push	hl
	ld	h,a
	and	3
	rlca
	rlca
	rlca
	ld	l,a
	ld	a,h
	and	%1100
	srl	a
	add	a,l	;slot*2
	ld	l,a
	ld	a,b
	rlca
	rlca
	rlca
	rlca
	rlca		;page*32
	add	a,l
	ld	hl,(Slotp0adres)
	add	a,l
	ld	l,a
	jr	nc,_geefsoort1
	inc	h
_geefsoort1:	ld	a,(hl)
	inc	hl
	ld	b,(hl)
	pop	hl
	ret

putreg:
	ld	(Textbufadres),ix
	ld	(Slotp0adres),iy
	ld	(Page0adres),hl
	ld	(Compassadres),de
	ld	(Soortmem),bc
	ret

;---------- Memory routines

inimem:
	ld	a,(Soortmem)
	cp	1
	ret	nz
	xor	a
	ld	de,#0402
	call	#ffca
	ld	a,b
	ld	(Primary),a
	ld	(_allocdos2_1+1),hl
	inc	hl
	inc	hl
	inc	hl
	ld	(_freedos2_1+1),hl
	ret

;---------- Allocate all available memory and put in Buffer1024
;---------- (Slot, block, slot, ......., block, 0)

allocatemem:
	ld	a,(Soortmem)
	or	a
	jr	nz,alldos2memm
alldos1:
	ld	hl,(Slotp0adres)
	ld	de,16*2*2+1
	add	hl,de	;page 2
	ex	de,hl
	ld	iy,#fcc1
	ld	ix,(Bufferpage0)
	ld	hl,500	;almost 8 MB
	ld	bc,#1000	;b=number, c=slot
_alldos1_3:
	push	bc
	ld	a,(de)
	or	a
	jr	z,_alldos1_1	;rom or fixed ram
	bit	7,(iy)
	jr	z,_alldos1_4
	set	7,c
_alldos1_4:
	inc	a
_alldos1_7:
	ex	af,af'
	ld	a,h
	or	l
	jr	z,_alldos1_1
	ex	af,af'
	dec	a
	ld	b,a
	ld	a,(tab_tpa+3)
	cp	b
	ld	a,b
	jr	nz,_alldos1_5
	ld	a,(#f344)
	cp	c
	ld	a,b
	jr	z,_alldos1_6
_alldos1_5	dec	hl
	ld	(ix),c
	inc	ix
	ld	(ix),a
	inc	ix
_alldos1_6	or	a
	jr	nz,_alldos1_7
_alldos1_1:
	pop	bc
	inc	de
	inc	de
	ld	a,c
	and	%1100
	cp	%1100
	ld	a,c
	ld	c,4
	jr	nz,_alldos1_2
	inc	iy
	ld	c,-11
_alldos1_2:
	add	a,c
	ld	c,a
	djnz	_alldos1_3
	ld	(ix),0
	ret

;----- Dos 2 & Memman

alldos2memm:
	ld	ix,(Bufferpage0)
	ld	hl,384	;= 6 Mb
_allocateme1:
	push	hl
	call	allocate
	pop	hl
	jr	c,_allocateme2
	ld	(ix),b
	inc	ix
	ld	(ix),a
	inc	ix
	dec	hl
	ld	a,h
	or	l
	jr	nz,_allocateme1
_allocateme2:
	ld	(ix),0
	ret

allocate:
	ld	a,(Soortmem)
	dec	a
	jr	nz,allocmemman
allocdos2:
	ld	a,(Primary)
	or	%00110000	;first other slots, then primary slot
	ld	b,a
	ld	a,1	;system segment  
_allocdos2_1:
	jp	0

allocmemman:
	push	ix
	ld	b,3	;FSEG 
	ld	de,"M"*256+10
	call	#ffca
	pop	ix
	ld	a,h
	or	l
	scf
	ret	z
	ld	b,l
	ld	a,h
	ccf
	ret


;---------- Add used memory
;----- IN:  IX = end address Buffer1024

addusedmem:
	ld	hl,(Compassadres)
	ld	b,4
	call	_addusedmem2

	ld	hl,(Textbufadres)
	ld	de,Textbuffer2-Textbuffer1
	push	hl
	ld	b,4
	call	_addusedmem1
	pop	hl

	push	hl
	ld	de,Databuffer1-Textbuffer1
	add	hl,de
	ld	de,Databuffer2-Databuffer1
	ld	b,4
	call	_addusedmem1
	pop	hl

	ld	de,Labelbuffer-Textbuffer1
	add	hl,de
	ld	b,1
_addusedmem1:
	push	bc
	push	hl
	ld	a,(hl)
	or	a
	jr	z,_addusedm1_1
	ld	b,a
	inc	hl
	call	_addusedmem2
_addusedm1_1:
	pop	hl
	add	hl,de
	pop	bc
	djnz	_addusedmem1
	ret
_addusedmem2:
	ld	a,(Soortmem)
	or	a
	jr	nz,_addusedm2_1
_addusedm2_2:	;CALLING ADDRESS !
	push	bc
	ld	b,(hl)
	inc	hl
	ld	a,(hl)
	inc	hl
	call	exist
	jr	nc,_addusedm2_3
	ld	(ix),b
	ld	(ix+1),c
	ld	(ix+2),0
_addusedm2_3:
	set	6,(ix)
	pop	bc
	djnz	_addusedm2_2
	ret
_addusedm2_1:
	ld	c,(hl)
	inc	hl
	ld	a,(hl)
	inc	hl
	ld	(ix),c
	set	6,(ix)
	inc	ix
	ld	(ix),a
	inc	ix
	djnz	_addusedm2_1
	ld	(ix),0
	ret

;---------- Adds TPA nums from the primary mapper (if absent)

addblok123:
	ld	a,(#f344)
	ld	c,a
	ld	hl,tab_tpa
	ld	b,3
_addblok12_1:
	push	bc
	ld	a,(hl)
	ld	b,c
	call	exist
	set	4,(ix)	;mark as tpa
	jr	nc,_addblok12_2	;already exists
	set	4,b
	ld	(ix),b
	inc	ix
	ld	(ix),c
	inc	ix
	ld	(ix),0
_addblok12_2:
	pop	bc
	inc	hl
	djnz	_addblok12_1
	ret

;---------- Test whether block is present
;----- IN:  B = lock, A = block
;----- OUT: IX = last address, [C] = does not exist

exist:
	ld	c,a
	ld	ix,(Bufferpage0)
	dec	ix
	dec	ix
_exist1:
	inc	ix
	inc	ix
	ld	a,(ix)
	or	a
	scf
	ret	z
	and	%10001111	;mask bit 4 and 6
	cp	b
	jr	nz,_exist1
	ld	a,(ix+1)
	cp	c
	jr	nz,_exist1
	ret		;[NC] is set

;---------- Release other segments again

freemem:
	ld	a,(Soortmem)
	or	a
	ret	z
_freedos2mem:
	ld	ix,(Bufferpage0)
	dec	ix
	dec	ix
_freemem1:
	inc	ix
	inc	ix
	ld	a,(ix)
	or	a
	ret	z
	bit	4,a
	jr	nz,_freemem1
	bit	6,a
	jr	nz,_freemem3
	and	%10001111	;to be sure
	ld	b,a
	ld	c,(ix+1)
	call	free
	jr	_freemem1
_freemem3:
	ld	a,(Soortmem)
	cp	2
	jr	c,_freemem1
	ld	l,(ix)
	res	6,l
	ld	h,(ix+1)
	ld	de,"M"*256+11
	push	ix
	call	#ffca	;reserve segment
	pop	ix
	jr	_freemem1
free:
	ld	a,(Soortmem)
	cp	2
	jr	nc,freememman
	ld	a,c
_freedos2_1	jp	0
freememman:
	ld	l,b
	ld	h,c
	ld	de,"M"*256+20
	push	ix
	call	#ffca
	pop	ix
	ret

;---------- Find next/previous block
;----- IN:  A: 0=forward, 1=backward
;-----      IX: source address

Changepage:	defb	0

zoeken:
	ld	(Zoekrichting),a
	bit	1,(iy+3)	;=2 ?
	jp	z,_zoeken5
	or	a
	ld	a,(Changepage)
	ld	d,a
	jr	z,zoekpgvoor
zoekpgachter:
	call	zoeksoort
	cp	2
	jr	c,_zoekpgacht1
	ld	a,(ix+1)
	or	a
	jr	z,_zoekpgacht1
	dec	(ix+1)
	ret
_zoekpgacht1:
	ld	a,(ix)
	and	%1111
	ld	c,a
	ld	a,%1111
	jr	z,_zoekpgacht4
_zoekpgacht2:
	ld	a,c
	and	%1100
	ld	a,-4
	jr	nz,_zoekpgacht4
	ld	a,11
_zoekpgacht4:
	add	a,c
_zoekpgacht3:	;label redundant??************************************
	call	setsecundair
	call	zoeksoort
	ld	(ix+1),b
	or	a
	jr	z,_zoekpgacht1
	ret

zoekpgvoor:
	call	zoeksoort
	cp	2
	jr	c,_zoekpgvoor1
	ld	a,b
	cp	(ix+1)
	jr	z,_zoekpgvoor1
	inc	(ix+1)
	ret
_zoekpgvoor1:
	ld	a,(ix)
	and	%1111
	ld	c,a
	cp	%1111
	ld	a,-%1111
	jr	z,_zoekpgvoor4
_zoekpgvoor2:
	ld	a,c
	and	%1100
	cp	%1100
	ld	a,4
	jr	nz,_zoekpgvoor4
	ld	a,-11
_zoekpgvoor4:
	add	a,c
_zoekpgvoor3:	;label redundant?*******************************************
	call	setsecundair
	ld	(ix+1),0
	call	zoeksoort
	or	a
	jr	z,_zoekpgvoor1
	ret

setsecundair:
	ld	(ix),a
	and	%11
	push	hl
	ld	hl,#fcc1
	add	a,l
	ld	l,a
	bit	7,(hl)
	pop	hl
	ret	z
	set	7,(ix)
	ret

_zoeken5:
	push	ix
	push	af
	ld	a,(ix)
	ld	b,a
	ld	c,a
	ld	d,a	;0-0 0
	or	a
	jr	z,_zoeken1	;block is empty
	and	%11
	ld	b,a
	ld	a,(ix)
	and	%1100
	ld	c,a
	ld	d,(ix+1)
_zoeken1:
	pop	hl
	bit	0,h
	jr	nz,_zoeken4
	call	vooruit
	jr	_zoeken3
_zoeken4:
	call	achteruit
_zoeken3:
	pop	ix
	ld	(ix),b
	ld	(ix+1),a	;set a new block
	ld	a,b
	or	a
	jr	nz,_zoeken2	;not empty
	ld	a,(Magleeg)
	or	a
	ld	a,(Zoekrichting)
	jr	z,_zoeken5	;cannot be empty

_zoeken2	LD	A,(IY+#02)
	CP	#0B
	JR	NZ,J78FF
	LD	A,(IY+#00)
	CP	#06
	JR	NZ,J78FF
	CALL	C7911
	JR	NZ,_zoeken5
J78FF
	ld	a,(iy+2)
	cp	10
	ret	nz
	ld	a,(iy)
	cp	5
	ret	nz
	CALL	C7911
	jr	nz,_zoeken5	;1st block of labelb. => primary
	ret

C7911	ld	a,(#f344)
	cp	b
	ld	a,(Zoekrichting)
	ret

Zoekrichting:	defb	0
Magleeg:	defb	0

; B.C.D < (IX).(IX+1) < H.L.E

vooruit:
	ld	ix,(Bufferpage0)
	dec	ix
	dec	ix
	ld	h,#ff	;primary slot #ff
_vooruit1:
	inc	ix
	inc	ix
	ld	a,(ix)
	or	a
	jr	z,_vooruit4
	bit	6,a
	jr	nz,_vooruit1
	and	%11
	cp	b
	jr	c,_vooruit1
	jr	nz,_vooruit2
	ld	a,(ix)
	and	%1100
	cp	c
	jr	c,_vooruit1
	jr	nz,_vooruit2
	ld	a,(ix+1)
	cp	d
	jr	c,_vooruit1
	jr	z,_vooruit1
_vooruit2:
	ld	a,(ix)
	and	%11
	cp	h
	jr	c,_vooruit3
	jr	nz,_vooruit1
	ld	a,(ix)
	and	%1100
	cp	l
	jr	c,_vooruit3
	jr	nz,_vooruit1
	ld	a,(ix+1)
	cp	e
	jr	nc,_vooruit1
_vooruit3:
	ld	a,(ix)
	and	%11
	ld	h,a
	ld	a,(ix)
	and	%1100
	ld	l,a
	ld	e,(ix+1)
	ld	(Foundadres),ix	;7a00******************************
	jr	_vooruit1
_vooruit4:
	xor	a
	ld	b,a
	inc	h
	ret	z	;empty
	ld	ix,(Foundadres)
	ld	b,(ix)
	res	4,b
	ld	a,(ix+1)
	ret

; H.L.E < (IX).(IX+1) < B.C.D

achteruit:
	ld	a,b
	or	c
	jr	nz,_achteruit5
	ld	b,#ff	;primary slot #ff
_achteruit5:
	ld	ix,(Bufferpage0)
	dec	ix
	dec	ix
	ld	hl,0	;lock 0-0 (CAN NOT !)
_achteruit1:
	inc	ix
	inc	ix
	ld	a,(ix)
	or	a
	jr	z,_achteruit4
	bit	6,a
	jr	nz,_achteruit1
	and	%11
	cp	b
	jr	c,_achteruit2
	jr	nz,_achteruit1
	ld	a,(ix)
	and	%1100
	cp	c
	jr	c,_achteruit2
	jr	nz,_achteruit1
	ld	a,(ix+1)
	cp	d
	jr	nc,_achteruit1
_achteruit2:
	ld	a,(ix)
	and	%11
	cp	h
	jr	c,_achteruit1
	jr	nz,_achteruit3
	ld	a,(ix)
	and	%1100
	cp	l
	jr	c,_achteruit1
	jr	nz,_achteruit3
	ld	a,(ix+1)
	cp	e
	jr	c,_achteruit1
	jr	z,_achteruit1
_achteruit3:
	ld	a,(ix)
	and	%11
	ld	h,a
	ld	a,(ix)
	and	%1100
	ld	l,a
	ld	e,(ix+1)
	ld	(Foundadres),ix
	jr	_achteruit1
_achteruit4:
	ld	a,h
	or	l
	ld	b,a
	ret	z	;empty
	ld	ix,(Foundadres)
	ld	b,(ix)
	res	4,b
	ld	a,(ix+1)
	ret

Foundadres:	dw	0

Primary:	defb	0

parseregist:
	call	putreg
	exx
	ld	(Bufferpage0),hl
	ld	a,(kbuf)
	or	a
	ret	z	;it's a new compass, keep default
	LD	hl,kbuf+#f4
	LD	de,Inst1
	LD	A,4
_parseregist	LD	BC,4
	LDIR
	ex	de,hl
	LD	BC,Inst2-Inst1-4	;!!
	ADD	HL,BC
	ex	de,hl
	DEC	A
	JR	NZ,_parseregist
	RET

geefalvrij:	CALL	inimem
	CALL	allocatemem
	CALL	addusedmem
	CALL	addblok123
	LD	HL,(Bufferpage0)
J7A35:	LD	A,(HL)
	OR	A
	JP	Z,freemem
	RES	6,(HL)
	INC	HL
	INC	HL
	JR	J7A35

;Variables

Editor_y:	defb	2
Editor_x:	defb	1
Regelnr:	defw	1
Laatsteregel:	defw	1
afb_offset	dw	0
Labellengte:	defb	12
Retins:	defb	0	;0=off, 1=on
Tabsonoff:	defb	1	;0=off, 1=on
Upperonoff:	defb	0	;0=off, 1=on

Positie1:	defb	2,1
	defw	1,1
	dw	0
Inst1:	defb	12,0,1,0

Positie2:	defb	2,1
	defw	1,1
	dw	0
Inst2:	defb	12,0,1,0

Positie3:	defb	2,1
	defw	1,1
	dw	0
Inst3:	defb	12,0,1,0

Positie4:	defb	2,1
	defw	1,1
	dw	0
Inst4:	defb	12,0,1,0

Oldbuffer:	defb	0
Blokstart:	defw	0
Blokeinde:	defw	0
Blokbuffer:	defb	0

Textbuffer1:
	defs	1+32
Databuffer1:
	defs	1+12
Textbuffer2:
	defs	1+32
Databuffer2:
	defs	1+12
Textbuffer3:
	defs	1+32
Databuffer3:
	defs	1+12
Textbuffer4:
	defs	1+32
Databuffer4:
	defs	1+12

Labelbuffer:
	ds	170,0

Zin:
	defs	(256+64+10),0
Label:	equ	Zin+161	;30 characters + 0 ;*******okay
Commando:	equ	Label+31	;10  characters + 0   ;?
Register1:	equ	Commando+11	;146 characters + 0   ;?used nowhere!***
Register2:	equ	Register1+146	;80 characters + 0   ;?

einde2:

;!!!!!!!!!!!!!!!!!!!!!!!!! Duplicate variables/addresses
Doubleusepg1:
	org	Doubleadres

Doubleuse:
Used_fcb:	defw	0
Foutadres:	defw	0
Veranderd:	defb	0	;0=line not changed, 1=yes
GOedit_ret1:
	push	hl
	ld	hl,edit_ret1
	jp	gotoeditor
Aantallabelb:	defb	0
Labelbuffers:	defs	8

GO_wisbuffe1:
	push	hl
	ld	hl,_wisbuffer1
	jp	gotoeditor
Huidigerror:	defb	1
Balkerror:	defb	0
GOpushanykey:
	push	hl
	ld	hl,pushanykey
	jp	gotoeditor
GOwiscommlin:
	push	hl
	ld	hl,wiscommline
	jp	gotoeditor
GOeditor_con:
	push	hl
	ld	hl,editor_cont
	jp	gotoeditor
GOprintscher:
	push	hl
	ld	hl,printscherm
	jp	gotoeditor
GOprinterror:
	push	hl
	ld	hl,printerrors
	jp	gotoeditor
Bufferpage0:	defw	0	;address buffer in page 0
Labbloknr:	defb	0	;(1-..)
Idhex:	defb	"#",0,0	;"# " before (last 1=after)   COPY
Idbin:	defb	"%",0,0	;"% " before (Last 1=after)   COPY
Huidiglablen:	defb	12
Binheader:	defw	0	;address header bin-files
GOtxttocomm:
	push	hl
	ld	hl,txttocomm
	jp	gotoeditor
GObeep:
	push	hl
	ld	hl,beep
	jp	gotoeditor
Aantalerrors:	defb	0
GOassembledi:
	push	hl
	ld	hl,assembledisk	;#4000
	jp	gotoass
GOassemblere:
	push	hl
	ld	hl,assembleren	;#4003
	jp	gotoass
GOeditscreen:
	push	hl
	ld	hl,editscreen
	jp	gotoeditor
Aantaltextbl:	defb	8
Textbuffers:	defb	#83,9,#83,10,#83,11,#83,12	;why already filled in?***
	defb	#83,13,#83,14,#83,15,#83,16
	defb	0,0,0,0,0,0,0,0
	defb	0,0,0,0,0,0,0,0
Aantaldatabl:	defb	2
Databuffers:	defb	#83,5,#83,6,0,0,0,0,0,0,0,0	;idem
Databloknr:	defb	0
Textbloknr:	defb	0	;(1-..)
GOprterrline:
	push	hl
	ld	hl,prterrlines	;#4009
	jp	gotoass
GOrelocatabl:
	push	hl
	ld	hl,relocatable	;#4012
	jp	gotoass
GOasstsr:
	push	hl	;#4015
	ld	hl,asstsr
	jp	gotoass
Huidigupper:	defb	0
GOsetbuf:
	push	hl
	ld	hl,setnewbuffer
	jp	gotoeditor
Textbuffer:	defb	startbuf	;current text buffer
Doubleuseend:

	ds	#8000-Doubleusepg1-($-Doubleadres),0	;fill to the end
