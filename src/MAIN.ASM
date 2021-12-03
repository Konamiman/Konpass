;MAIN PROGRAM COMPASS #1.2
;#1.2.09: DOINCLUDE SEPARATE FCB

	.label	13
bdos	equ	#f37d	;!!!
cursory_x	equ	#f3dc
trgflg	equ	#f3e8
msxtype	equ	#002d
stopvlag	equ	#fc9b
cursoronoff	equ	#fca9	;0=don't show
insonoff	equ	#fcaa	;1=inscursor
kbuf	equ	#f41f
queuebc	equ	#f9f5	;256 bytes of space in sound queue b and c
hookadres	equ	queuebc
matrix	equ	#fbe5
ctngcode	equ	#ff79

videoramfree	equ	#1a00	;from here videoram is free to use
Dskerrline	equ	14
Testlabeladr	equ	#400c	;in ass/monitor segment
MAININSTPROG	equ	#4009	;in debugger segment
SETDEBPARS	equ	#400c	;in debugger segment
;--------------------------------------------
	ORG	#0140

	JR	shellentry
	JP	#8000+set_slot_p0
	db	1,2	;version code (Spain:2,2)
	dw	0	;was codename
	JP	#8000+startcompass
shellentry	DI
	LD	(sp_back_2_dos),SP
	ld	hl,ctngcode
	res	0,(hl)
	IN	A,(#A8)	;do we come from basic or from dos?
	AND	#0C	;basic: page1 is then in slot 0
	ld	c,a	;further check on slot 0.1/2/3
	ld	a,(#fcc1)
	rlca
	ld	a,c
	jr	nc,not_expanded
	ld	a,(#fcc5)
	and	#0c
	or	c
not_expanded	LD	(dosbasic),A	;save result: 0=basic not0=dos

	LD	HL,#FFFF	;on all pages: really switch the slot
	LD	(oudslot),HL
	LD	(oudslot+2),HL

	LD	A,(stat_ins)
	LD	(insonoff),A
	LD	A,(keer1e)
	OR	A
	JR	Z,noteerstekeer
	call	fill_inst
	CALL	sethooks
	CALL	data_2_editor

noteerstekeer	CALL	clearhooks
	CALL	inidos
	LD	A,(keer1e)
	OR	A
	CALL	NZ,fill_NAMEASM	;put NAME.ASM in 4 sbuffers
	XOR	A
	LD	(keer1e),A
	CALL	SCREENCOMPASS
	LD	A,(oldprog)
	OR	A
	JR	NZ,_gotonextprog
	LD	HL,videoramfree	;extract asmname from vram and put in kbuf
	LD	DE,kbuf
	LD	A,(comline_nr)
	INC	A
	LD	C,A
	LD	B,#00
	CALL	VRAMTORAM
startassembl	LD	BC,(sloteditor)
	LD	HL,#4000
	LD	A,#01
_startprogr	LD	DE,idhex
_startprogr1	LD	(oldprog),A
	LD	(calladdress),HL
	LD	(slotsubroutin),BC
	LD	HL,#FFFF
	LD	(oudslot),HL
	LD	(oudslot+2),HL
	PUSH	DE
	CALL	zetslot
	LD	BC,#0101
	CALL	OFFSET	;about mouse
	LD	IX,buffer1024
	POP	HL
	LD	DE,tab_memtabel
	LD	A,(comline_nr)
	db	#cd	;call
calladdress	dw	0
	PUSH	AF
	XOR	A
	LD	(comline_nr),A
	CALL	setscreen1	;clear screen+txt_menu
	POP	AF
	CP	#04
	JP	Z,goshell
	OR	A
	JR	Z,quitcompass
_gotonextprog	DEC	A
	JR	Z,startassembl	;1
	DEC	A
	JR	Z,startdebugger	;2
	JR	startmonitor
oldprog	db	0	;must be zero: start assembler 1st time

startdebugger	db	#1e	;better: ld e,n
debuggerreg	db	0	;special info for debugger
	LD	HL,#4000
	LD	BC,(slotdebugger)
	LD	A,#02
	jr	_startprogr1
startmonitor	LD	HL,#7000
	LD	BC,(slotmonitor)
	LD	A,#03
	jr	_startprogr
setscreen1	LD	HL,#181E	;blink off line 3-26, 0,1,2not
	LD	BC,24*10
	XOR	A
	CALL	FILLVRAM
	LD	HL,#0000	;empty screen (full, also top menu)
	LD	BC,27*80
	XOR	A
	CALL	FILLVRAM
	LD	HL,txt_bovenaan
	JP	TEXTTOBLOK
quitvlag	db	0
quitcompass	LD	BC,(sloteditor)
	CALL	zetslot
	CALL	#401B	;release memory
	ld	hl,(#f349)
	db	#11	;LD DE,nn
newf349	dw	0	;under dos2 this remains 0
	ld	a,h
	cp	d
	jr	nz,alleslaten
	ld	a,l
	cp	e
	jr	nz,alleslaten
	db	#21	;LD HL,nn
oldf349	dw	0
	ld	(#f349),hl
alleslaten	XOR	A	;clear compassID
	LD	(queuebc+4),A
	LD	A,(dosversion)	;delete envitem compass under dos2
	CP	#02
	JR	C,nietdos2
	XOR	A	;replace space with period
	LD	(compasscom+7),A
	LD	HL,compasscom	;name
	LD	DE,queuebc+4	;value =0
	LD	C,#6C	;set envitem, now remove
	CALL	bdos
nietdos2	LD	A,#01
	LD	(quitvlag),A
goshell	LD	A,(insonoff)
	LD	(stat_ins),A
	XOR	A
	LD	(cursoronoff),A
	LD	(stopvlag),A	;clear the "STOPkey buffer"
	LD	(insonoff),A	;block cursor
	LD	IX,#005F	;screen 0
	CALL	gobios
	LD	A,(#F343)
	LD	H,#80
	CALL	SLOT
	LD	A,(tab_tpa+2)
	call	SETPAGE2_DOS2
	ld	a,(tab_tpa+1)
	call	SETPAGE1_DOS2
	LD	A,(quitvlag)
	OR	A
	JR	Z,shell
	LD	A,#C9
	LD	(disable_feda-hook+hookadres),a
	JR	terminate
shell	CALL	sethooks
terminate	LD	A,(dosbasic)
	OR	A
	JR	Z,uitbasic
	LD	HL,(#F3F8)
	LD	DE,dostekst
	LD	B,8
dosviabasic	LD	A,(DE)
	INC	DE
	CALL	putkeybuf
	DJNZ	dosviabasic
	LD	(#F3F8),HL
uitbasic	LD	SP,(sp_back_2_dos)
	ld	hl,ctngcode
	set	0,(hl)
	JP	hook_back-hook+hookadres
dostekst	db	"_SYSTEM",13
stat_ins	db	1	;insstatus 0=block cursor 1=stripe cursor
sp_back_2_dos	dw	0	;backup dos stack pointer
keer1e	db	1	;after loading C is set to 1 (test on filename)
dosbasic	db	0	;flag to see if you are from basic

sethooks	CALL	gethookadres
	LDIR
	EXX
	LDIR
	LD	A,#C3
	LD	(#FDC2),A
	LD	(#FE0D),A
	LD	HL,hookadres	;chgethook
	LD	(#FDC3),HL
	LD	HL,hookadres+cmd-hook	;cmdhook
	LD	(#FE0E),HL
	RET
gethookadres	DI
	LD	HL,#FDC2
	LD	DE,orighookchget-hook+hookadres
	LD	BC,5
	EXX
	LD	HL,#FE0D
	LD	DE,orighookcmd-hook+hookadres
	LD	BC,5
	RET
clearhooks	CALL	gethookadres
	EX	DE,HL
	LDIR
	EXX
	EX	DE,HL
	LDIR
	RET
data_2_editor	CALL	getreg
	EXX
	LD	HL,buffer1024	;work area for unpacking codename
	EXX
	PUSH	HL
	LD	HL,#400F	;parse registers to editor(at 1st time)
	JP	GOTOEDITOR
fill_NAMEASM	LD	HL,pathnamebuf	;use max. 64 bytes from the
	LD	DE,pathname	;pathnamebuffer
	LD	BC,64
	LDIR
	LD	B,#04
nxt_name_deb	PUSH	BC
	XOR	A	;load 4 filenames+path in debugger
	CALL	parse_nam_deb	;this routine happens to be in the
	POP	BC	;debugger segment
	DJNZ	nxt_name_deb
	RET

chk_comline	LD	A,(#0080)	;is there anything else on the command line?
	OR	A
	RET	Z	;new
	LD	(comline_nr),A
	LD	HL,videoramfree
	CALL	SETVRAMWRITE
	LD	HL,#0081
_chk_comline	LD	A,(HL)
	INC	HL
	CP	#20
	JR	Z,_chk_comline	;spaces are ignored
	OUT	(#98),A	;the rest goes to the vram, including
	OR	A	;the zero byte
	RET	Z
	JR	_chk_comline
comline_nr	db	0	;MUST be zero

SCREENCOMPASS	LD	A,80	;width 80
	LD	(#F3AE),A
	LD	HL,#0000	;color 15,0,0
	LD	(#F3EA),HL
	LD	A,#0F
	LD	(#F3E9),A
	LD	IX,#0062
	CALL	gobios
	XOR	A	;screen 0
	LD	IX,#005F
	CALL	gobios
	LD	A,(#F3DE)	;get key on/off status
	LD	(oldfunkkey),A
	LD	IX,#00CC	;key off
	CALL	gobios
	CALL	setcolors
	XOR	A	;key click off
	LD	(#F3DB),A
	INC	A	;cursor not visible
	LD	(#FCA9),A
	CALL	WISBLINKTABEL
	CALL	SETCOLOR1
	DI
	LD	A,(#F3E2)	;save vdp3
	LD	(oldblink),A
	LD	A,%01100111	;blink table at #1800
	LD	(#F3E2),A
	OUT	(#99),A
	LD	A,#83
	OUT	(#99),A
	LD	A,(#FFE8)	;212 lines
	OR	#80
	LD	(#FFE8),A
	OUT	(#99),A
	LD	A,#89
	OUT	(#99),A
	LD	A,#10	;1/5sec on and 0sec off:=constantly on
	OUT	(#99),A
	LD	A,#8D
	OUT	(#99),A
	CALL	CLS
	LD	HL,#1800	;3 top lines colored
	LD	BC,3*10
	LD	A,#FF
	CALL	FILLVRAM
	LD	HL,txt_bovenaan
	CALL	TEXTTOBLOK
	LD	HL,vormen	;change character 17-29
	LD	DE,#1000+17*8
	LD	BC,13*8
	JP	RAMTOVRAM
setcolors	DI
	XOR	A
	OUT	(#99),A
	LD	A,#90
	OUT	(#99),A
	LD	HL,color
	LD	BC,#209A
	OTIR
	RET
txt_bovenaan	dw	1	;vramaddress
	db	"Compass #1.2",0
	dw	62
	db	"2022 by Konamiman",0
	dw	0
txt_menu	dw	2*80+4
	db	" SYSTEM ",0
	dw	0
color	db	#00,0,#00,0,#77,7,#04,0,#17,1,#27,3,#51,1,#27,6
	db	#71,1,#73,3,#61,6,#63,6,#11,4,#65,2,#55,5,#77,7

OLDSCREEN	CALL	WISBLINKTABEL
	CALL	CLS
	LD	A,#01
	LD	(cursoronoff),A	;cursor off
	DI
	LD	A,(oldblink)	;restore vdp 3
	LD	(#F3E2),A
	OUT	(#99),A
	LD	A,#83
	OUT	(#99),A
	LD	A,(#FFE8)	;192lines
	AND	#7F
	LD	(#FFE8),A
	OUT	(#99),A
	LD	A,#89
	OUT	(#99),A
	XOR	A	;blink period 00
	OUT	(#99),A
	LD	A,#8D
	OUT	(#99),A
	LD	A,(oldfunkkey)	;restore any function keys
	LD	(#F3DE),A
	LD	IX,#00C9
	CALL	gobios
	XOR	A	;screen zero
	LD	IX,#005F
	JP	gobios

oldblink	db	0
oldfunkkey	db	0


inidos	LD	C,#18	;get login vector: get connected drives
	CALL	bdos
	LD	A,L
	LD	(drives),A
	LD	A,#03	;start on 'DIR'
	LD	(Diskmenu),A

	LD	(diskhook_sp),SP
	LD	HL,clrdiskhooks
	LD	(diskhook_jp),HL
	CALL	setdiskhooks
	CALL	haalpath
clrdiskhooks	LD	HL,(olderroradres)
	LD	(#F323),HL
	LD	A,#C9	;insert disk for drive...
	LD	(#F24F),A	;back to normal
	RET
setdiskhooks	LD	HL,(#F323)
	LD	(olderroradres),HL
	LD	HL,diskhook1
	LD	(#F323),HL
	LD	HL,#C9F1	;pop af,ret
	LD	(#F24F),HL	;to replace: insert disk...
	RET
diskhook1	dw	dodiskhook
dodiskhook	db	#31	;ld sp,nn
diskhook_sp	dw	0
	LD	HL,#FFFF
	LD	(oudslot),HL
	LD	(oudslot+2),HL
	LD	BC,(slotsubroutin)
	CALL	zetslot
	SCF
	db	#c3	;jp nn
diskhook_jp	dw	0
haalpath	LD	C,#19	;get default drive
	CALL	bdos
	LD	(huidigedrive),A
	ADD	A,"A"
	LD	HL,pathnamebuf
	LD	(HL),A
	INC	HL
	LD	(HL),":"
	INC	HL
	LD	(HL),"\"
	INC	HL
	LD	(HL),0
	LD	A,(dosversion)
	DEC	A
	RET	Z
	LD	BC,#0059	;only do for dos2
	LD	DE,pathnamebuf+3
	PUSH	DE
	CALL	bdos
	POP	HL
	LD	A,(HL)	;root directory?
	OR	A	;yes, pathname is already good
	RET	Z
	LD	HL,pathnamebuf
	LD	BC,64
	XOR	A
	CPIR
	LD	(HL),0
	DEC	HL
	LD	(HL),"\"
	INC	HL
	RET
dosversion	db	0	;dos 1 or 2
drives	db	0	;login vector
huidigedrive	db	0	;default drive
pathname	db	" :\"	;current default directory
	ds	61,0
pathnamebuf	ds	93,0

names
name_asm	db	"NAME    ASM"
name_bin	db	"NAME    BIN"
name_asc	db	"NAME    ASC"
name_blk	db	"NAME    BLK"
name_com1	db	"NAME    COM"	;probably for that and ass.to disk
name_com2	db	"NAME    COM"
name_tsr	db	"NAME    TSR"
name_rel	db	"NAME    REL"

stat_mem	db	0
tab_ROMRAM	ds	#60,0	;ROMRAMtable, 3*16*2=#60 bytes
tab_memory
page0	db	0,0
page1	db	0,0
page2	db	0,0
page3deb	db	0,0	;i.e. debugger, leave it
page3	db	0,0
tab_compass	ds	8,0	;compass blocks, 8 bytes
sloteditor	equ	tab_compass+0	;ok
slothoofdp	equ	tab_compass+2	;ok
slotass	equ	tab_compass+4	;ok
slotmonitor	equ	tab_compass+4	;ok
slotdebugger	equ	tab_compass+6	;ok
slotsubroutin	db	0,2

slotregister	PUSH	BC
	PUSH	DE
	PUSH	HL
	CALL	SLOT
	POP	HL
	POP	DE
	POP	BC
	RET

;own routine (in page 2) that turns on slot A on page 0
;unchanged: IX,IY,mirror registers
;this replaces the slotpage2 routine
set_slot_p0	push	af
	ld	a,#ff
	ld	(#8000+oudslot),a
	pop	af
	ld	b,a
	bit	7,a
	jr	nz,set_exp	;expanded slot?
	IN	A,(#A8)	;no, just put it
	AND	#fc
	OR	B	;note: bits 2-6 are 0 for notexp.slot
	OUT	(#A8),A
	RET
set_exp	rrca
	rrca
	ld	l,a
	and	#c0
	ld	h,a
	in	a,(#a8)
	ld	e,a	;save old a8 status in e
	and	#3f
	or	h
	out	(#a8),a
	ld	a,l
	and	#03
	ld	l,a
	ld	a,(#ffff)
	cpl
	and	#fc
	or	l
	ld	(#ffff),a
	ld	d,a	;new ffff stand in d
	ld	a,e
	out	(#a8),a	;page 3 restore
	ld	hl,#fcc5
	ld	a,b
	and	#03
	ld	c,a
	ld	b,0
	add	hl,bc
	ld	(hl),d
	ld	a,c
	jr	set_slot_p0

gobios	PUSH	IY
	LD	IY,(#FCC0)
	CALL	#001C
	POP	IY
	RET
prtidhexvoor	ld	a,"#"
	out	(#98),a
	ret
prtidbinvoor	ld	a,"%"
	out	(#98),a
	ret
beep	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	PUSH	IX
	LD	IX,#00C0
	CALL	gobios
	POP	IX
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RET

SETVRAMWRITE	LD	A,#40
setrwmain	LD	(invul_or),A
	DI
	BIT	7,H
	RET	NZ
	LD	A,H
	AND	#40
	ADD	A,A
	RLCA
	OUT	(#99),A
	LD	A,#8E
	OUT	(#99),A
	NOP
	LD	A,L
	OUT	(#99),A
	LD	A,H
	AND	#3F
	db	#f6	;OR n
invul_or	db	0
	OUT	(#99),A
	RET
SETVRAMREAD	XOR	A
	JR	setrwmain
RAMTOVRAM	EX	DE,HL
	CALL	SETVRAMWRITE
	LD	A,B
	OR	A
	JR	Z,_ramtovram1	;faster 8 bit counter
_ramtovram3	LD	A,(DE)
	INC	DE
	OUT	(#98),A
	DEC	BC
	LD	A,B
	OR	C
	jp	NZ,_ramtovram3	;fast jmp
	RET
_ramtovram1	LD	B,C
_ramtovram2	LD	A,(DE)
	INC	DE
	OUT	(#98),A
	DJNZ	_ramtovram2
	RET
FILLVRAM	ex	af,af'
	CALL	SETVRAMWRITE
	LD	A,B
	OR	A
	JR	Z,_fillvram1
	ld	a,h
	ex	af,af'
	ld	h,a
_fillvram3	LD	A,H
	OUT	(#98),A
	DEC	BC
	LD	A,B
	OR	C
	jp	nz,_fillvram3	;quick jump
	ex	af,af'
	ld	h,a
	RET
_fillvram1	LD	B,C
	ex	af,af'
_fillvram2	OUT	(#98),A
	DJNZ	_fillvram2
	RET
WISBLINKTABEL	LD	HL,#1800
	LD	BC,27*10
	XOR	A
	JR	FILLVRAM
CLS	LD	HL,#0000
	LD	BC,27*80
	XOR	A
	JR	FILLVRAM
PRINTTEKST	CALL	SETVRAMWRITE
_printtekst	LD	A,(BC)
	OR	A
	RET	Z
	OUT	(#98),A
	INC	BC
	JR	_printtekst
SETCOLOR2
SETCOLOR1	LD	A,(kleur1)
	DI
	OUT	(#99),A
	LD	A,#8C
	OUT	(#99),A
	RET
kleur1	db	#23
	;kleur2 db #45

;----- Print decimal number  IN: HL=vramaddress, DE=number, B=number of characters
;----- Note: HL: bit15=1 => no vram address, B:bit7=1:no leading zeros
;----- Changes: AF, BC, DE, HL
PRINTDECIMAAL	call	SETVRAMWRITE
	push	bc
	ld	hl,0
	ld	(Decimaal),hl
	ld	(Decimaal+2),hl
	ld	(Decimaal+3),hl
	ex	de,hl	;hl=number
	ld	de,Decimaal+5
	ld	c,#f6
getdig:	xor	a
	ld	b,16
divide:	adc	hl,hl
	adc	a,a
	add	a,c
	jr	c,oksub
	sub	c
oksub:	djnz	divide
	adc	hl,hl
	add	a,"0"
	dec	de
	ld	(de),a
	ld	a,h
	or	l
	jr	nz,getdig
	ld	hl,Decimaal+5
	pop	bc
	bit	7,b
	res	7,b
	ld	c,1
	jr	z,_dec_cont
	dec	c
_dec_cont	ld	e,b
	ld	d,0
	or	a
	sbc	hl,de
_nextdec:	ld	a,(hl)
	or	c
	jr	z,_nextdec1	;no number + no leading zeros
	ld	a,(hl)
	out	(#98),a
_nextdec1:	inc	hl
	djnz	_nextdec
	ret
Decimaal:	defb	0,0,0,0,0

;----- Print hexadecimal number  IN: HL=vramaddress, DE=number, B=number of characters
;----- Note: HL:bit15=1 => no vram address, B:bit7=1 => no id
;----- Changes: AF, BC, DE, HL
PRINTHEXADECI	call	SETVRAMWRITE
	ld	hl,0
	ld	(Decimaal),hl
	ld	(Decimaal+2),hl
	ex	de,hl	;hl=number
	ld	de,Decimaal

	bit	7,b
;      push  af
	call	z,prtidhexvoor
	res	7,b
	push	bc
	ld	a,h
	call	_printhexad1
	ld	a,l
	call	_printhexad1
	pop	bc
	ld	hl,Decimaal+4
	ld	e,b
	ld	d,0
	or	a
	sbc	hl,de
_nexthex:	ld	a,(hl)
	inc	hl
	out	(#98),a
	djnz	_nexthex
;      pop   af
;      call  z,prtidhexna
	ret
_printhexad1:
	push	af
	and	%11110000
	rlca
	rlca
	rlca
	rlca
	call	_printhexad2
	pop	af
	and	%00001111
_printhexad2:
	add	a,"0"
	cp	"9"+1
	jr	c,_printhexad3
	add	a,"A"-"0"-10
_printhexad3:	ld	(de),a
	inc	de
	ret
;----- Print binary number  IN: HL=vramaddress, DE=number, B=number of characters
;----- Note: HL:bit15=1 => no vram address, B:bit7=1 => no id
;----- Changes: AF, BC, DE, HL
PRINTBINAIR:	call	SETVRAMWRITE
	ex	de,hl	;hl=number
	bit	7,b
;      push  af
	call	z,prtidbinvoor
	res	7,b
	ld	e,b
	ld	b,16
	ld	c,b
_printbinai2:	ld	d,0
	sla	l
	rl	h
	rl	d	;d contains the bit to be printed (0 or 1)
	ld	a,e
	cp	c	;can it be printed already?
	jr	c,_printbinai1
	ld	a,"0"
	add	a,d
_printbinai3:	out	(#98),a
_printbinai1:	dec	c
	djnz	_printbinai2
;      pop   af
;      call  z,prtidbinna
	ret

;bar routines
setbalk1:	ex	de,hl
	ld	c,b
	ld	hl,#1800-10
	ld	a,d
	ld	b,e
	inc	b
	ld	de,10
setbalk2:	add	hl,de
	djnz	setbalk2
	ld	b,a
	and	%11111000
	rrca
	rrca
	rrca
	ld	e,a
	add	hl,de
	ld	a,b
	and	%00000111
	ld	b,a
	inc	b
	ld	a,%00000001
setbalk3:	rrca
	djnz	setbalk3
	ld	d,a
	ld	b,c
READVRAM	call	SETVRAMREAD
	in	a,(#98)
	ret
setbalk4:
	call	WRITEVRAM
	inc	hl
	call	READVRAM
	jr	setbalk6
wisbalk4:
	call	WRITEVRAM
	inc	hl
	call	READVRAM
	jr	wisbalk6

;----- put bar on screen: IN: b=length, (h,l)=target
SETBALK	call	setbalk1	;calculate offset
setbalk5:	or	d
	rrc	d
	jr	c,setbalk4
setbalk6:	djnz	setbalk5
	jr	WRITEVRAM

;----- clear bar from screen: IN: b=length, (h,l)=target
WISBALK	call	setbalk1	;calculate offset
	ex	af,af'
	ld	a,d
	cpl
	ld	d,a
	ex	af,af'
wisbalk5:	and	d
	rrc	d
	jr	nc,wisbalk4
wisbalk6:	djnz	wisbalk5

WRITEVRAM	ex	af,af'
	call	SETVRAMWRITE
	ex	af,af'
	out	(#98),a
	ret

; Copy: from Buffer-->bep. lock+block
; ----- IN: DE=Target address (page 0-3), BC=Length
PUTTORAM	ex	de,hl
	ld	a,1	;nasty
	jr	_getfromram1

Broncopy:	defw	0
Doelcopy:	defw	0
Lengtecopy:	defw	0
Command:	defb	0	;0=from memory, 1=to memory
; Copy: from bep. slot+block-->Buffer
; ----- IN: HL=Source address (page 0-3), BC=Length
GETFROMRAM:	xor	a
_getfromram1	ld	de,buffer1024
	di
	ld	(Command),a
	ld	(Broncopy),hl
	ld	(Doelcopy),de
	ld	(Lengtecopy),bc
	ld	a,h
	cp	#40
	jr	c,_getfrompg0
	cp	#80
	jr	c,_getfrompg1
	cp	#c0
	jr	c,_getfrompg2
	jr	_getfrompg3
_getfrompg0:	push	hl
	add	hl,bc
	dec	hl	;HL=Last address
	ld	a,h
	pop	hl
	cp	#40
	jp	c,_haalpage0	;Everything in page 0
	ld	ix,#4000
	ld	(Bron2),ix
	ld	ix,_haalpage0
	ld	iy,_haalpage1
	jp	twopages
_getfrompg1:	push	hl
	add	hl,bc
	dec	hl	;HL=Last address
	ld	a,h
	pop	hl
	cp	#80
	jp	c,_haalpage1	;Everything in page 1
	ld	ix,#8000
	ld	(Bron2),ix
	ld	ix,_haalpage1
	ld	iy,_haalpage2
	jp	twopages
_getfrompg2:	push	hl
	add	hl,bc
	dec	hl	;HL=Last address
	ld	a,h
	pop	hl
	cp	#c0
	jp	c,_haalpage2	;Everything in page 2
	ld	ix,#c000
	ld	(Bron2),ix
	ld	ix,_haalpage2
	ld	iy,_haalpage3
	jp	twopages
_getfrompg3:	push	hl
	add	hl,bc
	dec	hl	;HL=Last address
	ld	a,h
	pop	hl
	cp	#40
	jp	nc,_haalpage3	;Everything in page 3
	ld	ix,#0000
	ld	(Bron2),ix
	ld	ix,_haalpage3
	ld	iy,_haalpage0
twopages	ld	(_call1+1),ix
	ld	(_call2+1),iy	;2 call addresses
	ex	de,hl	;de=source
	ld	hl,(Bron2)
	or	a
	sbc	hl,de	;hl=length in 1st page
	ld	b,h
	ld	c,l	;bc=length
	ex	de,hl	;hl=source
	ld	de,(Doelcopy)
	push	bc
	push	de
_call1:	call	0	;copy 1st part
	pop	hl
	pop	bc
	add	hl,bc
	ex	de,hl	;de=address target
	ld	hl,(Lengtecopy)
	or	a
	sbc	hl,bc
	ld	b,h
	ld	c,l	;bc=2nd length
	ld	hl,(Bron2)
_call2:	jp	0	;copy 2nd part
Bron2:	defw	0
_haalpage1	push	hl
	ld	a,(page1)
	ld	h,#40
	call	slotregister
	ld	a,(page1+1)
	call	SETPAGE1_DOS2
	pop	hl
	ld	a,(Command)
	or	a
	jr	z,_haalpage1_1
	ex	de,hl
_haalpage1_1:	ldir
	ld	a,(slotsubroutin)
	ld	h,#40
	call	SLOT
	ld	a,(slotsubroutin+1)
	jp	SETPAGE1_DOS2
_haalpage2	push	hl
	ld	a,(page2)
	ld	h,#80
	call	slotregister
	ld	a,(page2+1)
	call	SETPAGE2_DOS2
	pop	hl
	ld	a,(Command)
	or	a
	jr	z,_haalpage2_1
	ex	de,hl
_haalpage2_1:	ldir
	ld	a,(#f343)
	ld	h,#80
	jp	SLOT
_haalpage3:	ld	a,(Command)
	or	a
	jr	z,_haalpage3_1
	ex	de,hl
_haalpage3_1:	ldir
	ret
_haalpage0	push	hl
	push	de
	push	bc
	ld	a,(slothoofdp)
	ld	h,#80
	call	SLOT
	ld	a,(slothoofdp+1)
	call	SETPAGE2_DOS2	;Main program on page 2
	jp	_haalpage0_1+#8000
_haalpage0_1:	ld	a,(page0+#8000)
	call	set_slot_p0+#8000
	ld	a,(page0+1+#8000)
	out	(#fc),a	;source page on page 0
	pop	bc	;don't adjust f2c7 or anything, switch
	pop	de	;from page0 is only provisional
	pop	hl
	set	7,d	;now on page 2
	ld	a,(Command+#8000)
	or	a
	jr	z,_haalpage0_2
	ex	de,hl
_haalpage0_2:	ldir
	ld	a,(slothoofdp+#8000)
	call	set_slot_p0+#8000
	ld	a,(slothoofdp+1+#8000)
	out	(#fc),a	;this program back on page 0
	ld	a,(#f343)
	ld	h,#80
	jp	SLOT	;automatically return to page 0

DOINCLUDE	LD	(diskhook_sp),SP
	PUSH	HL
	LD	HL,(slotsubroutin)
	LD	(sub),HL
	LD	HL,_incl_error
	LD	(diskhook_jp),HL
	CALL	setdiskhooks
	LD	A,#01
	LD	(doinclude),A
	ld	hl,fcb_work	;backup fcb_work
	ld	de,fcb_inclbkup
	ld	bc,37
	ldir
	POP	HL
	LD	DE,pathnamebuf
	LD	BC,64
	LDIR
	CALL	testpath
	JR	C,_incl_error
	CALL	setdirectory
	OR	A
	SCF
	JR	NZ,_incl_error
	CALL	vulfcbin
	CALL	fcb_open
	OR	A
	SCF
	JR	NZ,_incl_error
	LD	BC,(sloteditor)
	CALL	zetslot
	LD	DE,fcb_work
	CALL	#4012	;load
	PUSH	AF
	CALL	CLOSEFILE
	POP	AF
_incl_error	PUSH	AF
	CALL	clrdiskhooks
	ld	hl,fcb_inclbkup	;restore fcb_work
	ld	de,fcb_work
	ld	bc,37
	ldir
	ld	de,buffer1024	;restore DTA
	call	set_DTA
	LD	BC,(sub)
	LD	(slotsubroutin),BC
	CALL	zetslot
	POP	AF
	LD	SP,(diskhook_sp)
	RET

; Diskdrive: IN: A: 1 = assembler
;                   2 = debugger
;                   3 = monitor
;                B = special option: 1 = Asm disk, 2=TSR, 3=rel
;                C = source buffer, only with Assembler
;                IX = pointer to jp list (Assembler only)
;             OOUT: [C] = it has been formatted (Important for Assembler only)
Soort:	defb	1	;1=asm, 2=asc, 3=bin, 4=dat, 5=blk, 6=sect
Diskasm:	defb	0	;something to assemble?0no,1disk,2TSR,3rel
Bronprog:	defb	0
Buffer:	defb	0
Backuponoff:	defb	0	;0=off
Oldsubrouti:	defw	0
Pointer:	defw	0
Diskmenu:	defb	3	;start on 'dir'
Driveletter:	defb	0
Aantalfiles:	defb	0
Asmbusy:	defb	0
adrsfilepath	dw	0	;start address filename in path
fcb_work	db	0,"???????????"
	ds	25
	NOP		;0C7A
	NOP		;0C7B
	NOP		;0C7C
	NOP		;0C7D
	NOP		;0C7E
fcb_inclbkup	ds	37

GODISKDRIVE	di
	ld	(Bronprog),a
	ld	a,c
	ld	(Buffer),a
	ld	(Pointer),ix
	ld	(Sp_disk),sp
	ld	hl,(slotsubroutin)
	ld	(Oldsubrouti),hl
	ld	a,b
	ld	(Diskasm),a
	xor	a
	ld	(Formatdone),a
	ld	(doinclude),a
	ld	hl,(#f323)
	ld	(olderroradres),hl
	ld	hl,Specialerror
	ld	(#f323),hl
	ld	hl,#c9f1	;pop af, ret
	ld	(#f24f),hl	;override "Insert disk ..."
	ld	bc,#0503
	call	OFFSET
	ld	hl,#1800+3*10
	ld	bc,24*10	;ERRORLIST(#1910...) bug fix!! (it was 25*10)
	xor	a
	call	FILLVRAM	;clear blink table (lines 3-27)
	ld	hl,3*80
	ld	de,Disklines
	call	PRINTBLOK
	ld	hl,Disktext
	call	TEXTTOBLOK
	ld	a,(Diskasm)
	or	a
	jr	nz,_diskasm
	call	setsoort
	jr	_nodiskasm
_diskasm	ld	hl,23*80+7
	ld	a,23
	call	WRITEVRAM
	ld	hl,25*80+7
	ld	a,23
	call	WRITEVRAM
	ld	hl,24*80+2
	ld	bc,Disktextasm
	call	PRINTTEKST
	ld	a,(Diskmenu)
	cp	1
	ld	b,2
	jr	z,_diskasm1
	cp	4
	ld	b,3
	jr	z,_diskasm1
	ld	b,a
_diskasm1	ld	a,b
	ld	(Diskmenu),a
_nodiskasm	xor	a
	ld	(Aantalfiles),a
	inc	a
	ld	(cursoronoff),a
diskerrcont	call	WISKEYBUFFER
	call	jon1
diskhoofdprt	call	prtdskinfo
diskhoofd	ld	sp,(Sp_disk)
	xor	a
	ld	(Asmbusy),a
	call	WISKEYBUFFER
	call	zetdiskbalk
	call	GETKEY
	cp	27
	jr	z,_diskback
	cp	1
	jr	z,_diskback
	cp	28
	jp	z,_diskright
	cp	29
	jp	z,_diskleft
	or	a
	jp	z,_diskspace
	cp	" "
	jp	z,_diskspace
	cp	13
	jp	z,_diskspace
	cp	2
	jp	z,_diskbackup
	cp	"T"-"A"+1
	jp	z,_disktype
	ld	d,a	;ALWAYS LEAVE !!!
	ld	a,(matrix+6)
	and	%00000010
	jr	nz,_disk_noctrl
	ld	a,(matrix)
	ld	bc,#0401
	rrca
_disk_no1234	rrca
	jp	nc,_ctrl1234
	inc	c
	djnz	_disk_no1234
_disk_noctrl	ld	a,d
	cp	" "
	jr	c,diskhoofd
	jp	inputname
_diskback	call	wisdiskbalk
	ld	hl,(olderroradres)
	ld	(#f323),hl
	ld	a,#c9
	ld	(#f24f),a
	ld	bc,(Oldsubrouti)
	ld	(slotsubroutin),bc
	call	zetslot
	ld	bc,#0101
	call	OFFSET
	ld	sp,(Sp_disk)
	ld	a,(Formatdone)
	or	a
	ret	z
	scf
	ret
_diskright	ld	hl,Diskmenu
	ld	a,(hl)
	cp	7
	jp	z,diskhoofd
	push	hl
	call	wisdiskbalk
	pop	hl
	inc	(hl)
	ld	a,(Diskasm)
	or	a
	jr	z,_diskright1
	ld	a,(hl)
	cp	4
	jr	nz,_diskright1
	inc	(hl)
_diskright1	ld	a,(dosversion)
	dec	a
	jr	nz,_diskright2
	ld	a,(hl)
	cp	5
	jr	nz,_diskright2
	inc	(hl)
_diskright2	call	zetdiskbalk
	jp	diskhoofd
_diskleft	ld	hl,Diskmenu
	ld	a,(hl)
	dec	a
	jp	z,diskhoofd
	push	hl
	call	wisdiskbalk
	pop	hl
	dec	(hl)
	ld	a,(dosversion)
	dec	a
	jr	nz,_diskleft3
	ld	a,(hl)
	cp	5
	jr	nz,_diskleft3
	dec	(hl)
_diskleft3	ld	a,(Diskasm)
	or	a
	jr	z,_diskleft1
	ld	a,(hl)
	cp	4
	jr	nz,_diskleft2
	dec	(hl)
	jr	_diskleft1
_diskleft2:	cp	1
	jr	nz,_diskleft1
	inc	(hl)
_diskleft1	call	zetdiskbalk
	jp	diskhoofd
_diskspace	ld	a,(Diskmenu)
	dec	a
	jp	z,_disksave
	dec	a
	jp	z,_diskload
	dec	a
	jp	z,_diskdir
	dec	a
	jp	z,_disktype
	dec	a
	jp	z,_diskmkdir
	dec	a
	jp	z,_diskkill
	dec	a
	jp	z,_diskformat
	jp	diskhoofd
_ctrl1234	call	WISKEYBUFFER
	ld	a,(Bronprog)
	dec	a
	ld	b,a	;this is different in v1.1 compared to v1.0
	ld	a,(Diskasm)	;
	or	b	;
	jp	nz,diskhoofd
	ld	a,c
	push	af
	call	_ctrl1234_1
	pop	bc
	jp	c,diskhoofd
	ld	a,b
	ld	(Buffer),a
	call	jon1
	jp	diskhoofdprt
_ctrl1234_1	push	hl
	ld	hl,#4003
	jp	GOTOEDITOR
zetdiskbalk	call	balkadres
	jp	SETBALK
wisdiskbalk	call	balkadres
	jp	WISBALK
balkadres	ld	l,24
	ld	a,(Diskmenu)
	ld	b,a
	cp	2
	jr	nz,_balknorm
	ld	a,(Diskasm)
	or	a
	jr	z,_balknorm
	ld	h,1
	ld	b,13
	ret
_balknorm	ld	a,1-7
_balkadres1:	add	a,7
	djnz	_balkadres1
	ld	h,a
	ld	b,6
	ret
;--type
_disktype	call	beradrname
	jr	c,_type_sect
	ld	hl,fcb_work+1
	ld	bc,11
	ldir
_type_sect	call	soortmenu
	call	jon1
	jp	diskhoofdprt
;--Dir
_diskdir	call	inputpath
	call	printdir
	ld	a,(Aantalfiles)
	or	a
	call	nz,filemenu
	jp	diskhoofd
;--Mkdir (only comes here in dos2)
_diskmkdir	ld	hl,pathnamebuf
	ld	de,kbuf
	ld	bc,64
	ldir
	ld	hl,(adrsfilepath)
	ld	de,pathnamebuf
	or	a
	sbc	hl,de
	ld	de,kbuf
	add	hl,de	;Target directory name
	ex	de,hl
	ld	hl,fcb_work+1
	ld	b,8
	call	_mkdir_vul
	ld	a,(hl)
	cp	" "
	jr	z,_diskmkdir1
	ld	a,"."
	ld	(de),a
	inc	de
	ld	b,3
	call	_mkdir_vul
_diskmkdir1	xor	a
	ld	(de),a
	ld	b,%10010000
	xor	a
	ld	c,#44
	ld	de,kbuf
	call	bdos	;Create file handle
	cp	#cb
	jp	nz,diskhoofd
_mkdirerr	call	inidir
	ld	hl,Dskerrline*80+(80-19)/2
	ld	bc,Mkdirerr
	jr	_diskkill2
Mkdirerr:	defb	"Name already exists",0

_mkdir_vul	ld	a,(hl)
	inc	hl
	cp	" "
	jr	z,_mkdir_vul1
	ld	(de),a
	inc	de
_mkdir_vul1	djnz	_mkdir_vul
	ret
;--Backup on/asm/asc
_diskbackup	ld	hl,Backuponoff
	inc	(hl)
	ld	a,(hl)
	cp	3
	jp	c,diskhoofdprt
	ld	(hl),0
	jp	diskhoofdprt
;--Kill
_diskkill	call	inidir
	ld	hl,Dskerrline*80+(80-20)/2
	ld	bc,Areyousure
	call	PRINTTEKST
	call	GETKEY
	push	af
	call	inidir
	pop	af
	or	a
	jr	z,_diskkill3
	and	%11011111
	cp	"Y"
	jp	nz,diskhoofdprt
_diskkill3	call	setdirectory
	ld	de,fcb_work
	ld	c,#13
	call	bdos
	or	a
	jr	nz,_diskkill1
	jp	diskhoofd
_diskkill1	ld	hl,Dskerrline*80+(80-14)/2
	ld	bc,Filenotfound
_diskkill2	call	PRINTTEKST
	call	beep
	jp	diskhoofd
Areyousure:	defb	"Are you sure ? (y/n)",0
;--Format
Formatdone:	defb	0
_diskformat	ld	a,1
	ld	(Formatdone),a
	call	inidir
	ld	a,(#f344)
	ld	h,#80
	call	SLOT
	ld	a,(labelbuffer+2)
	call	SETPAGE2_DOS2
	ld	a,(dosversion)
	dec	a
	jr	z,_formdos1
_formdos2	ld	bc,#0067
	xor	a
	call	bdos
	push	hl
	ld	a,b
	ld	h,#40
	call	SLOT
	pop	hl
	call	formoptie
	jr	c,_formdos2cnt
	call	_form_print
	ld	bc,#0067
	ld	hl,#8100
	ld	de,#3e00
	call	bdos
_formdos2cnt	ld	hl,#8000
	ld	de,#8001
	ld	bc,#3fff
	ld	(hl),0
	ldir
	call	inidir
	ld	bc,(slotsubroutin)
	call	zetslot
	jp	diskhoofd
_formdos1	ld	hl,#fb21-2
	ld	a,(#f1c4)	;current physical drive
_formjon	inc	hl
	inc	hl
	sub	(hl)
	jr	nc,_formjon
	add	(hl)
	push	af
	inc	hl
	ld	a,(hl)
	ld	h,#40
	call	SLOT
	call	#4019	;get choice address
	ld	a,h
	or	l
	call	nz,formoptie
	pop	de
	jr	c,_formdos2cnt
	call	_form_print
	ld	hl,#8100
	ld	bc,#3e00
	call	#401c
	jr	_formdos2cnt
Formtxt:	defb	"Format options:",0
formoptie	push	hl
	ld	hl,9*80+2
	ld	bc,Formtxt
	call	PRINTTEKST
	pop	de
	ld	hl,10*80+2
_formloop1	push	hl
_formloop	ld	a,(de)
	inc	de
	or	a
	jr	z,_formoptie1
	cp	#0d
	jr	z,_formoptie2
	call	WRITEVRAM
	inc	hl
	jr	_formloop
_formoptie2	inc	de
	pop	hl
	ld	bc,80
	add	hl,bc
	jr	_formloop1
_formoptie1	pop	hl
_formloop2	call	GETKEY
	cp	27
	jr	z,_foptieesc
	cp	1
	jr	z,_foptieesc
	cp	"1"
	jr	c,_formloop2
	cp	"9"+1
	jr	nc,_formloop2
	sub	"0"
	or	a
	ret
_form_print	push	af
	push	de
	ld	hl,14*80+(80-13)/2
	ld	bc,Form_txt
	call	PRINTTEKST
	pop	de
	pop	af
	ret
Form_txt:	defb	"Formatting...",0
_foptieesc	scf
	ret

;--Load
printload	ld	hl,14*80+(80-10)/2
	ld	bc,Loading
	jp	PRINTTEKST
Loading:	defb	"Loading...",0
_diskload	call	inidir
	ld	de,buffer1024
	call	set_DTA
	ld	a,(Diskasm)
	or	a
	jp	nz,_disk_asm
	call	printload
	call	setdirectory
	ld	a,(Soort)
	cp	6
	jr	z,_diskload1
	call	fcb_open
	or	a
	jr	z,_diskload1
	ld	hl,Dskerrline*80+(80-14)/2
	ld	bc,Filenotfound
	call	PRINTTEKST
	jp	diskhoofdprt
_diskload1	ld	a,(Soort)
	add	a,a
	ld	e,a
	ld	d,0
	ld	hl,Jp_loads-2
_diskloadcnt	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	ld	de,fcb_work
	ld	ix,(Pointer)
	ld	iy,writeerror	;LEAVE IT !!!
	jp	(hl)
Jp_loads:	defw	_load_asm,_load_asc,_load_bin,_load_data
	defw	_load_blk,_load_sect
_disk_asm	ld	a,1
	ld	(Asmbusy),a
	call	setdirectory
	call	fcb_create
	or	a
	jp	nz,writeerror
	ld	de,fcb_work
	ld	ix,(Pointer)
	ld	iy,writeerror	;LEAVE IT !!!
	ld	a,(Diskasm)
	dec	a
	jr	nz,_noasmdisk
	ld	l,(ix)
	ld	h,(ix+1)
	jp	(hl)
_noasmdisk	dec	a
	jr	nz,_noasmtsr
	ld	l,(ix+2)
	ld	h,(ix+3)
	jp	(hl)
_noasmtsr	ld	l,(ix+4)
	ld	h,(ix+5)
	jp	(hl)
_load_asm	ld	l,(ix)
	ld	h,(ix+1)
	jp	(hl)
_load_asc	ld	l,(ix+4)
	ld	h,(ix+5)
	jp	(hl)
_load_blk	ld	l,(ix+8)
	ld	h,(ix+9)
	jp	(hl)
_load_bin	ld	de,Binldheader	;LOAD BINARY FILE
	call	set_DTA
	ld	hl,7
	call	fcb_read
	ld	a,(Binldheader)
	cp	#fe
	jr	nz,_nobinfile
	call	printbin
loadbincont:	;Load call from data file
	ld	de,buffer1024
	call	set_DTA
	ld	hl,(Startldadr)
	push	hl
_loadbin_cnt	ld	hl,(Eindldadr)
	inc	hl
	ld	de,(Startldadr)
	or	a
	sbc	hl,de
	ld	a,h
	or	l
	jr	z,_endloadbin
	ld	de,1025
	sbc	hl,de
	ex	af,af'
	add	hl,de
	ex	af,af'
	jr	c,_loadbin_1	;<=1024
	ld	hl,1024
_loadbin_1:	call	fcb_read
	ld	a,h
	or	l
	jr	z,_endloadbin
	push	hl
	ld	de,(Startldadr)
	push	de
	ld	b,h
	ld	c,l
	call	PUTTORAM
	pop	de
	pop	hl
	add	hl,de
	ld	(Startldadr),hl	;next address
	jr	_loadbin_cnt
_endloadbin	pop	hl
	ld	(Startldadr),hl
	jp	CLOSEFILE
_nobinfile	ld	bc,Nobinfile
	ld	hl,15*80+(80-19)/2
	call	PRINTTEKST
	call	beep
	jp	CLOSEFILE
Nobinfile:	defb	" No binary file !",0
printbin	ld	hl,Bintext
	call	TEXTTOBLOK
	ld	de,(Startldadr)
	ld	b,4
	ld	hl,17*80+17
	call	PRINTHEXADECI
	ld	de,(Eindldadr)
	ld	b,4
	ld	hl,18*80+17
	call	PRINTHEXADECI
	ld	de,(Execldadr)
	ld	b,4
	ld	hl,19*80+17
	jp	PRINTHEXADECI
Bintext	defw	19*80+10
	defb	"Exec:",0
Bintext1:	defw	17*80+10
	defb	"Start:",0
	defw	18*80+10
	defb	"End:",0
	defw	0
Binldheader:	defb	0
Startldadr:	defw	0
Eindldadr:	defw	0
Execldadr:	defw	0
_load_data	call	wissaveload
	ld	hl,fcb_work+16
	ld	e,(hl)
	inc	hl
	ld	d,(hl)	;file length
	ld	(Lengthfile),de
	dec	de
	ld	b,4
	ld	hl,18*80+17
	call	PRINTHEXADECI
	ld	hl,17*80+17
	ld	de,0
	ld	b,4
	call	PRINTHEXADECI
	ld	hl,Bintext1
	call	TEXTTOBLOK
	ld	hl,Starttxt
	ld	de,buffer1024
	ld	bc,21*3
	ldir
	xor	a
	ld	(Starttxt),a
	ld	(Endtxt),a
	ld	(Exectxt),a
_dat_again1	call	bininput1
	ld	hl,(Startsvadr)
	ld	de,(Lengthfile)
	add	hl,de
	dec	hl
	ex	de,hl
	ld	hl,18*80+17
	ld	b,4
	call	PRINTHEXADECI
	call	bininput2
	ld	hl,buffer1024
	ld	de,Starttxt
	ld	bc,21*3
	ldir
	ld	hl,(Startsvadr)
	ld	(Startldadr),hl
	ld	hl,(Endsvadr)
	ld	(Eindldadr),hl
	jp	loadbincont
Lengthfile:	defw	0
_load_sect	call	wissaveload
	ld	hl,Secttxt
	call	TEXTTOBLOK
	call	printinpsect
	ld	bc,(Lengthsect)
	ld	de,(Startsect)
	ld	hl,(Sectadr)
_load_sect1	push	bc
	push	de
	push	hl
	ld	c,#2f
	ld	a,(huidigedrive)
	ld	l,a
	ld	h,1
	call	bdos
	pop	hl
	ld	d,h
	ld	e,l
	ld	bc,(Sectsize)
	add	hl,bc
	push	hl
	call	PUTTORAM
	pop	hl
	pop	de
	inc	de
	pop	bc
	dec	bc
	ld	a,b
	or	c
	jr	nz,_load_sect1
	call	wissaveload
	jp	diskhoofdprt
Secttxt:	defw	17*80+10
	defb	"Address:",0
	defw	18*80+10
	defb	"Start:",0
	defw	19*80+10
	defb	"Length:",0
	defw	0
Sectadr:	defw	0
Startsect:	defw	14
Lengthsect:	defw	1
Sectsize:	defw	0
printinpsect	ld	bc,#001b
	call	bdos
	ld	(Sectsize),bc
	ld	hl,17*80+19
	ld	de,(Sectadr)
	ld	b,4
	call	PRINTHEXADECI
	ld	hl,18*80+19
	ld	de,(Startsect)
	ld	b,5+128
	call	PRINTDECIMAAL
	ld	hl,19*80+19
	ld	de,(Lengthsect)
	ld	b,5+128
	call	PRINTDECIMAAL
	ld	hl,17*80+19
	call	inputsect
	ld	(Sectadr),de
	ld	hl,18*80+19
	call	inputsect
	ld	(Startsect),de
	ld	hl,19*80+19
	call	inputsect
	ld	(Lengthsect),de
	ret
inputsect	push	hl
	ld	de,buffer1024
	call	inputbin
	jp	c,CLOSEFILE
	call	BEREKENGETAL
	pop	hl
	jr	c,inputsect
	ret
;--Disk save
Saving:	defb	"Saving...",0
printsave	ld	hl,14*80+(80-10)/2
	ld	bc,Saving
	jp	PRINTTEKST
wissaveload	ld	hl,14*80+(80-10)/2
	ld	bc,10
	xor	a
	jp	FILLVRAM
_disksave	ld	de,buffer1024
	call	set_DTA
	call	inidir
	call	printsave
	call	setdirectory
	ld	a,(Soort)
	cp	3
	jr	c,_disksave1	;not at asm/asc due to backup
	cp	6
	jr	z,_disksave1
	call	fcb_create
	or	a
	jp	nz,writeerror
_disksave1	ld	a,(Soort)
	add	a,a
	ld	e,a
	ld	d,0
	ld	hl,Jp_Saves-2
	jp	_diskloadcnt
Jp_Saves:	defw	_save_asm,_save_asc,_save_bin,_save_data
	defw	_save_blk,_save_sect
_save_asm	push	ix
	push	iy
	push	de
	ld	a,(Backuponoff)
	dec	a
	call	z,makebackup
	call	fcb_create
	or	a
	jp	nz,writeerror
	pop	de
	pop	iy
	pop	ix
	ld	l,(ix+2)
	ld	h,(ix+3)
	jp	(hl)
_save_asc	push	ix
	push	iy
	push	de
	ld	a,(Backuponoff)
	cp	2
	call	z,makebackup
	call	fcb_create
	or	a
	jp	nz,writeerror
	pop	de
	pop	iy
	pop	ix
	ld	l,(ix+6)
	ld	h,(ix+7)
	jp	(hl)
_save_blk	ld	l,(ix+10)
	ld	h,(ix+11)
	jp	(hl)
_save_bin	ld	de,Binsvheader
	call	set_DTA
	call	wissaveload
	ld	hl,Bintext
	call	TEXTTOBLOK
	ld	hl,17*80+17
	ld	bc,Starttxt
	call	PRINTTEKST
	ld	hl,18*80+17
	ld	bc,Endtxt
	call	PRINTTEKST
	ld	hl,19*80+17
	ld	bc,Exectxt
	call	PRINTTEKST
	call	bininput1
	call	bininput2
_bin_again3	ld	hl,19*80+17
	ld	de,Exectxt
	call	inputbin
	jp	c,CLOSEFILE
	call	BEREKENGETAL
	jr	c,_bin_again3
	ld	(Execsvadr),de
	call	printsave
	ld	hl,7
	call	savefile
binsavecont:	;save call from data
	ld	de,buffer1024
	call	set_DTA
	ld	hl,(Startsvadr)
	push	hl
_binsave_cnt	ld	hl,(Endsvadr)
	inc	hl
	ld	de,(Startsvadr)
	or	a
	sbc	hl,de
	ld	a,h
	or	l
	jr	z,_endsavebin
	ld	de,1025
	sbc	hl,de
	ex	af,af'
	add	hl,de
	ex	af,af'
	jr	c,_savebin_1	;<=1024
	ld	hl,1024
_savebin_1:	push	hl
	ld	b,h
	ld	c,l
	ld	hl,(Startsvadr)
	push	hl
	add	hl,bc
	ld	(Startsvadr),hl
	pop	hl
	call	GETFROMRAM
	pop	hl
	call	savefile
	jr	_binsave_cnt
_endsavebin	pop	hl
	ld	(Startsvadr),hl
	jp	CLOSEFILE
inputbin	push	de
	ld	b,20
	ld	a,%11000001
	call	INPUTTEXT
	pop	hl
	ret
bininput1	ld	hl,17*80+17
	ld	de,Starttxt
	call	inputbin
	jp	c,CLOSEFILE
	call	BEREKENGETAL
	jr	c,bininput1
	ld	(Startsvadr),de
	ret
bininput2	ld	hl,18*80+17
	ld	de,Endtxt
	call	inputbin
	jp	c,CLOSEFILE
	call	BEREKENGETAL
	jr	c,bininput2
	ld	(Endsvadr),de
	ex	de,hl
	ld	de,(Startsvadr)
	sbc	hl,de	;is set to [NC]
	jr	c,bininput2	;end address < start address
	ret
Binsvheader:	db	#fe
Startsvadr:	dw	0
Endsvadr:	dw	0
Execsvadr:	dw	0
Starttxt:	ds	21
Endtxt:	ds	21
Exectxt:	ds	21
_save_data	ld	hl,Bintext1
	call	TEXTTOBLOK
	ld	hl,17*80+17
	ld	bc,Starttxt
	call	PRINTTEKST
	ld	hl,18*80+17
	ld	bc,Endtxt
	call	PRINTTEKST
	call	bininput1
	call	bininput2
	call	printsave
	jp	binsavecont
_save_sect	call	wissaveload
	call	testharddisk
	ld	hl,Secttxt
	call	TEXTTOBLOK
	call	printinpsect
	ld	bc,(Lengthsect)
	ld	de,(Startsect)
	ld	hl,(Sectadr)
_save_sect1	push	bc
	push	de
	ld	bc,(Sectsize)
	add	hl,bc
	push	hl
	or	a
	sbc	hl,bc
	call	GETFROMRAM
	pop	hl
	pop	de
	push	de
	push	hl
	ld	c,#30
	ld	a,(huidigedrive)
	ld	l,a
	ld	h,1
	call	bdos
	pop	hl
	pop	de
	inc	de
	pop	bc
	dec	bc
	ld	a,b
	or	c
	jr	nz,_save_sect1
	call	wissaveload
	jp	diskhoofdprt
testharddisk	ld	a,(dosversion)
	dec	a
	ret	z
	ld	c,#31
	ld	de,buffer1024
	ld	l,0
	call	bdos
	ld	a,(buffer1024+11)
	cp	#f8
	ret	nc
	ld	hl,15*80+(80-14)/2
	ld	bc,Noflop
	call	PRINTTEKST
	jp	diskhoofdprt
Noflop:	defb	"No diskdrive !",0

jon1	LD	A,(Diskasm)
	OR	A
	JR	NZ,_jon12
	LD	A,(Soort)
	CP	1
	JR	Z,_jon11
	LD	HL,pathname
	LD	DE,pathnamebuf
	LD	BC,64
	LDIR
	RET
_jon11	LD	A,(Buffer)
	LD	B,A
parse_nam_deb	LD	HL,pathnamebuf
	LD	DE,name_asm
	PUSH	HL
	LD	HL,#400F
	JP	GOTODEBUGGER
_jon12	PUSH	AF
	CALL	_jon11
	POP	BC
	LD	HL,name_com1
	LD	DE,11
_jon13	ADD	HL,DE
	DJNZ	_jon13
	EX	DE,HL
	LD	HL,name_asm
	LD	BC,8
	LDIR
	RET
jon2	LD	A,(Soort)
	CP	1
	JR	Z,_jon21
	LD	HL,pathnamebuf
	LD	DE,pathname
	LD	BC,64
	LDIR
	RET
_jon21	LD	A,(Buffer)
	LD	B,A
	XOR	A
	JR	parse_nam_deb
;--input pathname
inputpath	ld	hl,pathnamebuf
	ld	de,kbuf
	ld	bc,64
	ldir
	ld	hl,pathnamebuf
	ld	de,pathnamebuf+1
	ld	bc,63
	ld	(hl),0
	ldir		;delete old path
_inputagain	ld	hl,333+2*80
	ld	de,pathnamebuf
	ld	b,63
	ld	a,%10000001	;[ESC] and start at end
	call	INPUTTEXT
	jr	nc,_inputpath1
	ld	hl,kbuf	;[ESC] pressed
	ld	de,pathnamebuf
	ld	bc,64
	ldir
	jp	diskhoofdprt
_inputpath1	call	testpath
	jr	c,_inputagain	;BAD PATH
	ld	a,(dosversion)
	dec	a
	jr	z,_inputpath2
	ld	hl,(adrsfilepath)
	ld	de,kbuf
	ld	bc,20
	ldir
	call	setdirectory
	call	haalpath
	ex	de,hl
	ld	hl,kbuf
	ld	bc,20
	ldir		;Copy name back
	call	printpath
_inputpath2	jp	jon2
;--print directory on screen (including directories with < >)
printdir	call	inidir
	call	printpath
	ret	c
	call	doprintdir
	ld	a,(Aantalfiles)
	or	a
	ret	nz
	ld	hl,Dskerrline*80+(80-14)/2
	ld	bc,Filenotfound
	jp	PRINTTEKST
Filenotfound:	defb	"File not found",0
inidir	xor	a
	ld	(Aantalfiles),a
	inc	a
	ld	(X_file),a
	ld	hl,8*80+3-15
	ld	(Vramnaam),hl
	ld	hl,8*80
	ld	b,15
inidircont	call	SETVRAMWRITE
_inidir2:	push	bc
	ld	a,22
	out	(#98),a
	ld	b,78
_inidir1:	ld	a,0
	out	(#98),a
	djnz	_inidir1
	ld	a,22
	out	(#98),a
	pop	bc
	djnz	_inidir2
	ret
Vramnaam:	defw	0
;--print directory on screen
doprintdir	ld	a,(dosversion)
	dec	a
	jr	z,_dir_dos1
_dir_dos2	ld	a,(huidigedrive)
	ld	e,a
	call	prtfreedisk
	call	dos2firstent
	or	a
	ret	nz
	call	printfile
_nextdos2dir	call	dos2nextentr
	or	a
	ret	nz
	call	printfile
	ld	a,(Aantalfiles)
	cp	14*5
	jr	c,_nextdos2dir
	call	prtcontinue
	ret	c
	call	inidir
	jr	_nextdos2dir
dos2firstent	ld	de,pathnamebuf
	ld	hl,(adrsfilepath)
	ld	b,%00010111
	ld	ix,buffer1024
	ld	c,#40
	jp	bdos
dos2nextentr	ld	ix,buffer1024
	ld	c,#41
	jp	bdos
_dir_dos1	ld	a,(huidigedrive)
	ld	e,a
	call	prtfreedisk
	ld	de,buffer1024
	call	set_DTA
	ld	hl,fcb_work+1
	ld	de,Oldfcb
	ld	bc,11
	ldir
	call	vulfcbin
	call	dos1firstent
	or	a
	jr	nz,_enddos1dir
	call	printfile
_nextdos1dir	call	dos1nextentr
	or	a
	jr	nz,_enddos1dir
	call	printfile
	ld	a,(Aantalfiles)
	cp	14*5
	jr	c,_nextdos1dir
	call	prtcontinue
	jr	c,_enddos1dir
	call	inidir
	jr	_nextdos1dir
_enddos1dir	ld	hl,Oldfcb
	ld	de,fcb_work+1
	ld	bc,11
	ldir
	ret
dos1firstent	ld	de,fcb_work
	ld	c,#11
	jp	bdos
dos1nextentr	ld	c,#12
	jp	bdos
Oldfcb:	defs	11
vulfcbin	ld	b,11
	ld	hl,fcb_work+1
_dir_dos1_1	ld	(hl)," "
	inc	hl
	djnz	_dir_dos1_1
	ld	hl,(adrsfilepath)
	ld	de,fcb_work+1
	ld	b,0
_dir_dos1_2	ld	a,b
	cp	11
	jr	z,_dir_dos1_en
	ld	a,(hl)
	inc	hl
	or	a
	jr	z,_dir_dos1_en
	cp	" "
	jr	z,_dir_dos1_3
	cp	"."
	jr	z,_dir_dos1_8
	cp	"*"
	jr	z,_dir_dos1_5
	ld	(de),a
	inc	de
	inc	b
_dir_dos1_3	jr	_dir_dos1_2
_dir_dos1_8	ld	a,b
	cp	9
	jr	nc,_dir_dos1_en
	ld	b,8
	ld	de,fcb_work+9
	jr	_dir_dos1_2
_dir_dos1_5	ld	a,b
	cp	8
	jr	nc,_dir_dos1_4
	ld	a,8
	sub	b
	ld	b,a
	ld	a,"?"
_dir_dos1_6	ld	(de),a
	inc	de
	djnz	_dir_dos1_6
	ld	b,8
	ld	de,fcb_work+9
	jr	_dir_dos1_2
_dir_dos1_4	ld	a,11
	sub	b
	ld	b,a
_dir_dos1_9	ld	a,"?"
_dir_dos1_7	ld	(de),a
	inc	de
	djnz	_dir_dos1_7
	ld	b,11
_dir_dos1_en	ld	a,b
	or	a
	ld	b,11
	jr	z,_dir_dos1_9	;"*.*" 
	ret
;--print continue (y/n)OUT:[C]=no
prtcontinue	ld	hl,1680+33+80
	ld	bc,Continue
	call	PRINTTEKST
	ld	hl,#2016
	ld	b,16
	call	SETBALK
	call	GETKEY
	push	af
	ld	hl,#2016
	ld	b,16
	call	WISBALK
	pop	af
	and	%11011111
	cp	"Y"
	ret	z
	or	a
	ret	z
	ld	hl,1680+33+80
	ld	bc,14
	xor	a
	call	FILLVRAM
	scf
	ret
Continue:	defb	"Continue (y/n)",0
;--print file on screen with < and > for directories
Filename:	defs	14	;<namename.ext>
printfile	ld	ix,Filename
	ld	hl,Filename
	ld	b,14
_printfile3	ld	(hl),0
	inc	hl
	djnz	_printfile3
	ld	de,Filename+1
	ld	hl,buffer1024+1
	ld	a,(dosversion)
	dec	a
	push	af
	call	nz,_dos2printfi
	pop	af
	call	z,_dos1printfi
	ld	a,(ix+1)
	cp	"."
	jr	nz,_printfile2
	ld	a,(ix+2)
	or	a
	ret	z	;"."   
_printfile2:	ld	hl,Aantalfiles
	inc	(hl)
	ld	a,(X_file)
	ld	b,a
	ld	hl,(Vramnaam)
	ld	de,15
_printfile1:	add	hl,de
	djnz	_printfile1
	ex	de,hl
	ld	hl,Filename
	ld	bc,14
	call	RAMTOVRAM
	ld	hl,X_file
	inc	(hl)
	ld	a,(hl)
	cp	6
	ret	c
	ld	(hl),1
	ld	hl,(Vramnaam)
	ld	de,80
	add	hl,de
	ld	(Vramnaam),hl
	ret
_dos2printfi	ld	a,(buffer1024+14)
	and	%00010000
	jr	z,_dos2printf1
	ld	(ix),"["
	ld	(ix+13),"]"
	ld	a,(hl)
	cp	"."
	jr	nz,_dos2printf1
	ld	(ix+1),"."
	ld	a,(buffer1024+2)
	or	a
	ret	z	;"."
	cp	"."
	jr	nz,_dos2printf3
	ld	(ix+2),"."
	ret		;".."   
_dos2printf3:	ld	(ix+1),0
_dos1printfi:
_dos2printf1	ld	b,8
_dos1printf1	ld	a,(hl)
	inc	hl
	or	a
	ret	z
	cp	"."
	jr	z,_dos2printf2
	ld	(de),a
	inc	de
	djnz	_dos1printf1
_dos2printf2	ld	a,(hl)
	or	a
	ret	z
	ld	(ix+9),"."
_dos2printf4	ld	a,(hl)
	inc	hl
	cp	"."
	jr	z,_dos2printf4	;ALSO GOOD WITH DOS 2!
	ld	(ix+10),a
	ld	a,(hl)
	inc	hl
	ld	(ix+11),a
	ld	a,(hl)
	ld	(ix+12),a
	ret
X_file:	defb	0
;--Choose a file
X_file1:	defb	0
Y_file1:	defb	0
Filemenu:	defb	0
filemenu	ld	hl,#0101
	ld	(X_file1),hl
	ld	a,h
	ld	(Filemenu),a
	call	zetfilebalk
filehoofd	call	GETKEY
	cp	27
	jr	z,_fileback
	cp	1
	jr	z,_fileback
	cp	28
	jr	z,_fileright
	cp	29
	jr	z,_fileleft
	cp	30
	jp	z,_fileup
	cp	31
	jp	z,_filedown
	cp	13
	jp	z,_filespace
	and	255-32
	jr	z,_filespace
	jr	filehoofd
_fileback	jp	wisfilebalk
_fileright	ld	a,(Aantalfiles)
	ld	b,a
	ld	a,(Filemenu)
	cp	b
	jr	z,filehoofd
	ld	hl,X_file1
	ld	a,(hl)
	cp	5
	jr	z,filehoofd
	push	hl
	call	wisfilebalk
	pop	hl
	inc	(hl)
	call	zetfilebalk
	ld	hl,Filemenu
	inc	(hl)
	jr	filehoofd
_fileleft	ld	hl,X_file1
	ld	a,(hl)
	cp	1
	jr	z,filehoofd
	push	hl
	call	wisfilebalk
	pop	hl
	dec	(hl)
	call	zetfilebalk
	ld	hl,Filemenu
	dec	(hl)
	jr	filehoofd
_fileup	ld	hl,Y_file1
	ld	a,(hl)
	cp	1
	jp	z,filehoofd
	push	hl
	call	wisfilebalk
	pop	hl
	dec	(hl)
	call	zetfilebalk
	ld	a,(Filemenu)
	sub	5
	ld	(Filemenu),a
	jp	filehoofd
_filedown	ld	a,(Filemenu)
	add	a,5
	ld	b,a
	ld	a,(Aantalfiles)
	cp	b
	jp	c,filehoofd
	call	wisfilebalk
	ld	hl,Y_file1
	inc	(hl)
	call	zetfilebalk
	ld	a,(Filemenu)
	add	a,5
	ld	(Filemenu),a
	jp	filehoofd
_filespace	call	haalfile
	jr	c,_file_subdir
	call	beradrname
	jr	c,_filespace1
	ld	hl,Filename
	ld	bc,11
	ldir
	call	jon2
	call	prtfilenaam
_filespace1	jp	_fileback
;----- remove file from screen   (empty places become spaces, without ".")
;----- OUT: filename in FILENAME+2, [C]=subdirectory
haalfile	ld	hl,7*80-12+1	;not "["
	ld	a,(Y_file1)
	ld	b,a
	ld	de,80
_haalfile1:	add	hl,de
	djnz	_haalfile1
	ld	a,(X_file1)
	ld	b,a
	ld	de,15
_haalfile2:	add	hl,de
	djnz	_haalfile2
	call	SETVRAMREAD
	ld	hl,Filename
	ld	b,8
_haalfile3:	in	a,(#98)
	or	a
	jr	nz,_haalfile3_1
	or	" "
_haalfile3_1:	ld	(hl),a
	inc	hl
	djnz	_haalfile3
	in	a,(#98)
	nop		;changed compared to v1.0 (dos1 dots bug)
	nop
	ld	b,3
_haalfile4:	in	a,(#98)
	or	a
	jr	nz,_haalfile4_1
	or	" "
_haalfile4_1:	ld	(hl),a
	inc	hl
	djnz	_haalfile4
	in	a,(#98)
	or	a
	ret	z
	scf
	ret
_file_subdir	call	wisfilebalk
	ld	hl,(adrsfilepath)
	ld	de,buffer1024
	ld	bc,20
	ldir
	ld	de,(adrsfilepath)
	ld	hl,Filename
	ld	b,8
	call	_mkdir_vul
	ld	a,(hl)
	cp	" "
	jr	z,_file_subdi1
	ld	a,"."
	ld	(de),a
	inc	de
_file_subdi1	ld	b,3
	call	_mkdir_vul
	xor	a
	ld	(de),a
	ld	de,pathnamebuf
	ld	c,#5a
	call	bdos
	call	haalpath
	ex	de,hl
	ld	hl,buffer1024
	ld	bc,20
	ldir		;Copy name back
	call	printpath
	call	printdir
	jp	filemenu
zetfilebalk	call	filebalkadre
	ld	b,14
	jp	SETBALK
wisfilebalk	call	filebalkadre
	ld	b,14
	jp	WISBALK
filebalkadre	ld	a,(X_file1)
	ld	b,a
	ld	a,3-15
_filebalkad1:	add	a,15
	djnz	_filebalkad1
	ld	h,a
	ld	a,(Y_file1)
	add	a,7
	ld	l,a
	ret
;--Menu of types of files
Soortmenvram:	equ	10*80+31
Soortmenopt:	defb	1
soortmenu	ld	a,(Bronprog)
	ld	ix,Asmfiles+1
	dec	a
	jr	z,_soortmenu1
	ld	ix,Debfiles+1	;Debugger and Monitor alike
_soortmenu1	ld	a,(ix-1)
	ld	de,kbuf
	ld	(de),a	;vertical height
	inc	de
	ld	a,11
	ld	(de),a
	inc	de
	xor	a
	ld	(de),a
	inc	de
	ld	a,(ix-1)	;Number
_soortmenu2	ld	l,(ix)
	inc	ix
	ld	h,(ix)
	inc	ix
	ld	bc,11
	ldir
	dec	a
	jr	nz,_soortmenu2
	call	setsoort1
	ld	hl,Soortmenvram
	ld	ix,kbuf
	call	PRINTMENU
_soortmenu4	ld	a,(Soortmenopt)
	ld	c,a
	add	a,10
	ld	l,a	;MUST !!!
	ld	h,#21
	ld	ix,kbuf
	call	KIESOPTIE
	ex	af,af'
	ld	a,c
	ld	(Soortmenopt),a
	ex	af,af'
	cp	27
	jr	z,_soortmenuba
	cp	1
	jr	z,_soortmenuba
	cp	13
	jr	z,_soortmenu3
	cp	" "
	jr	z,_soortmenu3
	or	a
	jr	nz,_soortmenu4
_soortmenu3	ld	hl,Soortmenvram
	ld	ix,kbuf
	call	WISOUDMENU
	call	setsoort2
	jp	prtdskinfo
_soortmenuba	ld	hl,Soortmenvram
	ld	ix,kbuf
	jp	WISOUDMENU
setsoort1	ld	a,(Bronprog)
	dec	a
	ld	a,(Soort)
	ld	b,a
	jr	z,_soortasm	;assembler
_soortdeb	cp	3
	ld	b,1
	jr	z,_soortasm
	inc	b
	cp	4
	jr	z,_soortasm
	inc	b
	cp	6
	jr	z,_soortasm
	ld	b,1
_soortasm	ld	a,b
	ld	(Soortmenopt),a
	ret
setsoort	call	setsoort1
setsoort2	ld	a,(Bronprog)
	dec	a
	ld	a,(Soortmenopt)
	ld	b,a
	jr	z,_soortasm1
_soortdeb1	dec	a
	ld	b,3
	jr	z,_soortasm1
	inc	b
	dec	a
	jr	z,_soortasm1
	ld	b,6
_soortasm1	ld	a,b
	ld	(Soort),a
	ret
Asmfiles:	defb	6
	defw	Asmf,Ascf,Binf,Datf,Blkf,Sect
Debfiles:	defb	3
	defw	Binf,Datf,Sect
Asmf	defb	" Asm file  "
Ascf	defb	" Ascii file"
Binf	defb	"Binary file"
Datf	defb	" Data file "
Blkf	defb	"Block file "
Sect	defb	"  Sector   "
;--Print info from disk on screen
prtdskinfo	call	printtype
	call	printboven
	call	printpath
	call	prtfilenaam
	ret
printtype	ld	a,(Diskasm)
	or	a
	ld	hl,Asmdiskf-11
	jr	nz,_printtype2
	ld	hl,Asmf-11
	ld	a,(Soort)
_printtype2	ld	b,a
	ld	de,11
_printtype1	add	hl,de
	djnz	_printtype1
	ld	de,4*80+8
	ld	bc,11
	call	RAMTOVRAM	;print type
	ret
Asmdiskf:	defb	"Asm to disk"
AsmTSRf:	defb	"Asm to TSR "
Asmrel:	defb	"Asm reloc. "
printboven	ld	hl,4*80+36
	ld	a,(Bronprog)
	dec	a
	ld	a," "
	jr	nz,_printboven1
	ld	a,(Buffer)
	add	a,"0"
_printboven1:	call	WRITEVRAM
	ld	a,(Backuponoff)
	ld	b,a
	add	a,a
	add	a,b
	ld	e,a
	ld	d,0
	ld	hl,Off
	add	hl,de
	ld	de,4*80+48
	ld	bc,3
	jp	RAMTOVRAM
Off:	defb	"off"
Asm:	defb	"Asm"
Asc:	defb	"Asc"
;--print path and drive on screen
printpath	ld	hl,6*80+3+10
	ld	bc,64
	xor	a
	call	FILLVRAM	;delete old path
	ld	bc,pathnamebuf
	ld	hl,6*80+3+10
	call	PRINTTEKST
testpath	LD	A,(dosversion)
	DEC	A
	JR	NZ,_pathdos2
	LD	A,(pathnamebuf+1)
	CP	":"
	JR	NZ,_nodrv
	LD	A,(pathnamebuf)
	AND	#DF	;big letters only
	JR	Z,_nodrv
	SUB	"A"
	JR	C,_badpath
	LD	HL,pathnamebuf+2
jon4	LD	C,A
	INC	C
	LD	A,(HL)
	CP	"\"
	JR	NZ,_contdrv
	INC	HL
	JR	_contdrv
_nodrv	LD	C,#19	;get defaultdrv
	CALL	bdos
	LD	HL,pathnamebuf
	jr	jon4
_pathdos2	LD	DE,pathnamebuf
	LD	BC,#005B
	CALL	bdos
	LD	A,(DE)
	OR	A
	JP	NZ,_badpath
_contdrv	LD	B,C
	LD	A,(drives)	;login vector
schuifdrives	RRCA		;is the drive connected?
	DJNZ	schuifdrives
	JR	NC,_badpath
	LD	A,C
	LD	(adrsfilepath),HL
	CP	#09
	JR	NC,_badpath	;drive >H
	LD	(fcb_work),A
	DEC	A
	LD	(huidigedrive),A
	LD	E,A	;set default drive
	LD	C,14
	CALL	bdos
	OR	A
	RET

_badpath	LD	A,(doinclude)
	OR	A
	SCF
	RET	NZ
	LD	HL,Dskerrline*80+(80-14)/2
	LD	BC,txt_badpath
	CALL	PRINTTEKST
	CALL	beep
	SCF
	RET
txt_badpath	db	"Bad pathname !",0

doinclude	db	0

;--print file name
prtfilenaam	ld	hl,24*80+53+10
	ld	bc,12
	xor	a
	call	FILLVRAM
	call	beradrname
	ret	c
	ex	de,hl
	ld	de,fcb_work+1
	ld	bc,11
	ldir		;filename to FCB
_prtfilenaam:	;LEAVE IT !!!
	ld	hl,24*80+53+10
	call	SETVRAMWRITE
	ld	hl,fcb_work+1
	ld	b,8
_prtfilenaa1:	ld	a,(hl)
	inc	hl
	out	(#98),a
	djnz	_prtfilenaa1
	ld	a,"."
	out	(#98),a
	ld	b,3
_prtfilenaa2:	ld	a,(hl)
	inc	hl
	out	(#98),a
	djnz	_prtfilenaa2
	ret
beradrname	ld	a,(Diskasm)
	or	a
	jr	z,_beradrname1
	ld	hl,Disknames-2
	jr	_beradrname2
_beradrname1	ld	hl,Names-2
	ld	a,(Soort)
	cp	6
	scf
	ret	z
_beradrname2	add	a,a
	ld	e,a
	ld	d,0
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	xor	a
	ret
Names:	dw	name_asm,name_asc,name_bin,name_com1,name_blk
Disknames:	dw	name_com2,name_tsr,name_rel
;--Calculate and print kB free on disk    IN: E=disknr (1-8)
prtfreedisk	ld	c,#1b
	inc	e
	call	bdos
	call	ber_kb
	ld	hl,4*80+70
	ld	b,5
	jp	PRINTDECIMAAL
ber_kb	push	hl
	ld	e,a
	ld	d,0
	call	b16_mu
	ld	b,h	;512=%10, 1024=%100, 2048=%1000
	pop	hl	;hl=number of free clusters
	ld	de,0
_prtfreedis2:	srl	b	;/2
	jr	c,_prtfreedis1
	sla	l
	rl	h
	rl	e
	rl	d	;*2
	jr	_prtfreedis2
_prtfreedis1	ld	b,2
_prtfreedis3:	srl	d
	rr	e
	rr	h
	rr	l
	djnz	_prtfreedis3	;/1024
	ex	de,hl
	ret

setdirectory	LD	A,(dosversion)
	DEC	A
	RET	Z
	LD	HL,(adrsfilepath)
	LD	DE,pathnamebuf
	OR	A
	SBC	HL,DE
	LD	A,H
	OR	L
	RET	Z	;hl equal to de (no directory)
	LD	B,H
	LD	C,L
	EX	DE,HL
	LD	DE,buffer1024
	LDIR
	XOR	A
	LD	(DE),A
	LD	DE,buffer1024
	LD	C,#5A	;set directory
	JP	bdos

set_DTA	ld	c,26
	jp	bdos
fcb_read	ld	de,fcb_work
	ld	c,39
	jp	bdos
fcb_open	LD	C,#0F
fcb_open_cont	LD	DE,fcb_work
	CALL	bdos
	LD	HL,#0000
	LD	(fcb_work+33),HL
	LD	(fcb_work+35),HL
	INC	HL
	LD	(fcb_work+14),HL
	RET
fcb_create	ld	c,22
	jr	fcb_open_cont
savefile	ld	de,fcb_work
	ld	c,#26
	call	bdos
	or	a
	ret	z
writeerror	ld	de,fcb_work
	ld	c,#10
	call	bdos
	ld	de,fcb_work
	ld	c,#13
	call	bdos	;delete file
	ld	hl,14*80+(80-17)/2
	ld	bc,Writeerror
	jp	_diskkill2
;--Back up filename in FCB
makebackup	ld	hl,fcb_work
	ld	de,buffer1024
	ld	bc,1+11+25
	ldir		;keep
	ld	hl,fcb_work+1+8
	ld	(hl),"B"
	inc	hl
	ld	(hl),"A"
	inc	hl
	ld	(hl),"K"
	ld	de,fcb_work
	ld	c,#13
	call	bdos	;delete .bak file
	ld	hl,fcb_work+1
	ld	de,fcb_work+17
	ld	bc,11
	ldir
	ld	hl,buffer1024+1
	ld	de,fcb_work+1
	ld	bc,11
	ldir
	ld	c,#17
	ld	de,fcb_work
	call	bdos	;rename .asm/.asc => .bak
	ld	hl,buffer1024
	ld	de,fcb_work
	ld	bc,1+11+25
	ldir
	ret
Disklines:	defw	Dline1,Dline2,Dline3,Dline4,Dline5,Dline6,Dline6
	defw	Dline6,Dline6,Dline6,Dline6,Dline6,Dline6,Dline6
	defw	Dline6,Dline6,Dline6,Dline6,Dline6,Dline6,Dline7
Disklinesend:	defw	Dline8,Dline9,0
Dline1:	defb	1,24,19,23,1,18,17,23,1,18,13,23,1,18,10,23,1,18,15,23
	defb	1,25,0
Dline2:	defb	1,22,19,0,1,22,17,0,1,22,13,0,1,22,10,0,1,22,15,0
	defb	1,22,0
Dline3:	defb	1,20,19,23,1,17,17,23,1,17,13,23,1,17,10,23,1,17,15,23
	defb	1,19,0
Dline6:
Dline4:	defb	1,22,78,0,1,22,0
Dline5:	defb	1,20,78,23,1,19,0
Dline7:	defb	1,20,6,23,1,18,6,23,1,18,6,23,1,18,6,23,1,18,6,23,1,18
	defb	6,23,1,18,6,23,1,18,29,23,1,19,0
Dline8:	defb	1,22,6,0,1,22,6,0,1,22,6,0,1,22,6,0,1,22,6,0,1,22
	defb	6,0,1,22,6,0,1,22,29,0,1,22,0
Dline9:	defb	1,26,6,23,1,17,6,23,1,17,6,23,1,17,6,23,1,17,6,23,1,17
	defb	6,23,1,17,6,23,1,17,29,23,1,27,0
Disktext:	defw	6*80+3
	defb	"Pathname:",0
	defw	4*80+2
	defb	"Type:",0
	defw	4*80+22
	defb	"Sourcebuffer:",0
	defw	4*80+40
	defb	"Backup:",0
	defw	4*80+65
	defb	"Free:      kB",0

	defw	24*80+2
	defb	"Save",0
	defw	24*80+9
	defb	"Load",0
	defw	24*80+16+1
	defb	"Dir",0
	defw	24*80+23
	defb	"Type",0
	defw	24*80+30
	defb	"Mkdir",0
	defw	24*80+37
	defb	"Kill",0
	defw	24*80+44-1
	defb	"Format",0
	defw	24*80+53
	defb	"Filename:",0
	defw	0
Disktextasm:
	defb	"  Assemble ",0

;in: DE=pointersto text HL=startVRAM
PRINTBLOK	CALL	SETVRAMWRITE
nxtpointer	EX	DE,HL	;get pointer to data
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,D	;ret as 0000
	OR	E
	RET	Z
	EX	DE,HL
nxtduo	LD	A,(HL)	;get number
	INC	HL
	OR	A
	JR	Z,nxtpointer
	LD	B,A
	LD	A,(HL)
	INC	HL
send2vdp	NOP
	NOP
	OUT	(#98),A
	DJNZ	send2vdp
	JR	nxtduo
TEXTTOBLOK	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,D
	OR	E
	RET	Z
	EX	DE,HL
	CALL	SETVRAMWRITE
	EX	DE,HL
_texttoblok	LD	A,(HL)
	INC	HL
	OR	A
	JR	Z,TEXTTOBLOK
	OUT	(#98),A
	JR	_texttoblok

;in:HL=vramaddress DE=ramaddress B=length C=special character
;A: bit0=1:start end of sentence bit7=1:escape bit6=1:also lowercase
;bit5=1:only numbers bit4=1:also up and down bit3=1:special

vramadrestxt	dw	0	;1f19
txtdoel	dw	0	;1f1b
lengtetext	db	0	;1f1d
position	db	0	;1f1e 1-..
	db	0	;1f1f lengte 1-..
kanescape	db	0	;1f20 0=no esc possible
kleinelett	db	0	;1f21 0=no lowercase letters possible
alleencijf	db	0	;1f22 <>0 only numbers possible
updown	db	0	;1f23 <>0 also up and down
specialchar	db	0	;1f24 <>0 =special character

INPUTTEXT	LD	(vramadrestxt),HL
	LD	(txtdoel),DE
	PUSH	BC
	LD	C,A
	AND	#80
	LD	(kanescape),A
	LD	A,C
	AND	#40
	LD	(kleinelett),A
	LD	A,C
	AND	#20
	LD	(alleencijf),A
	LD	A,C
	AND	#10
	LD	(updown),A
	LD	A,C
	AND	#08
	LD	(specialchar),A
	LD	A,B
	LD	(lengtetext),A
	LD	A,C
	AND	#01
	PUSH	AF
	LD	IX,position
	CALL	zoekeindetxt
	LD	(IX+#01),C
	POP	AF
	LD	C,#01
	JR	Z,_startvoor
	LD	C,(IX+#01)
	LD	A,(lengtetext)
	CP	C
	JR	NC,_startvoor
	DEC	C
_startvoor	LD	(IX+#00),C
	POP	BC
	LD	A,(specialchar)
	OR	A
	JR	Z,texthoofd
	LD	A,C
	LD	(specialchar),A
texthoofd	CALL	printspecial
	CALL	bercursor
	LD	(cursory_x),BC
	XOR	A
	ld	(cursoronoff),a
	CALL	GETKEY
	LD	IX,position
	CP	27
	JR	Z,textesc
	CP	1
	JR	Z,textesc
	CP	13
	JR	Z,textback
	OR	A
	JR	Z,textback
	CP	8
	JP	Z,textbs
	CP	127
	JP	Z,text_del
	CP	18
	JP	Z,text_ins
	CP	28
	JP	Z,text_right
	CP	29
	JP	Z,text_left
	CP	30
	JR	Z,text_updown
	CP	31
	JR	Z,text_updown
	CP	32
	JR	C,texthoofd
	CP	128
	JR	C,text_char
	JR	texthoofd
textback	LD	A,#01
	LD	(cursoronoff),A
	LD	HL,(vramadrestxt)
	LD	DE,(txtdoel)
	XOR	A
	LD	(DE),A
	LD	C,(IX+#01)
	DEC	C
	jr	z,jon3	;here was bug
	LD	B,A
	CALL	VRAMTORAM
	XOR	A
	LD	(HL),A
jon3	LD	HL,(vramadrestxt)
	LD	C,(IX+#00)
	LD	B,A
	ADD	HL,BC
	DEC	HL
	RET
textesc	LD	A,(kanescape)
	OR	A
	JR	Z,texthoofd
	LD	A,#01
	LD	(cursoronoff),A
	DEC	A
	SCF
	RET
text_updown	SUB	29
	LD	B,A
	LD	A,(updown)
	OR	A
	JP	Z,texthoofd
	LD	A,#01
	LD	(cursoronoff),A
	LD	A,B
	SCF
	RET
text_char	LD	B,A
	LD	A,(alleencijf)
	OR	A
	JR	Z,_text_alles
	LD	A,B
	CP	"0"
	JP	C,texthoofd
	CP	"9"+1
	JP	NC,texthoofd
	JR	_text_char1
_text_alles	LD	A,(kleinelett)
	OR	A
	LD	A,B
	JR	NZ,_text_char1
	CP	"a"
	JR	C,_text_char1
	CP	"z"+1
	JR	NC,_text_char1
	AND	#DF
_text_char1	LD	B,A
	LD	A,(insonoff)
	OR	A
	LD	A,B
	JR	NZ,_char_ins
	LD	HL,(vramadrestxt)
	LD	C,(IX+#00)
	LD	B,#00
	ADD	HL,BC
	DEC	HL
	CALL	WRITEVRAM
	LD	A,(IX+#00)
	CP	(IX+#01)
	JR	Z,_char_inscnt
text_right	LD	A,(lengtetext)
	CP	(IX+#00)
	JR	Z,_text_right1
	LD	A,(IX+#00)
	CP	(IX+#01)
	JR	Z,_text_right1
	INC	(IX+#00)
_text_right1	JP	texthoofd
_char_ins	PUSH	AF
	LD	HL,(vramadrestxt)
	LD	DE,buffer1024+900
	LD	A,(lengtetext)
	LD	C,A
	LD	B,#00
	POP	AF
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF
	CALL	VRAMTORAM
	LD	HL,buffer1024+900
	LD	C,(IX+#00)
	LD	B,#00
	ADD	HL,BC
	DEC	HL
	PUSH	HL
	LD	BC,81	;maxlen+1
	ADD	HL,BC
	LD	D,H
	LD	E,L
	INC	DE
	INC	BC
	LDDR
	POP	HL
	POP	AF
	LD	(HL),A
	POP	BC
	POP	HL
	POP	DE
	CALL	RAMTOVRAM
_char_inscnt	LD	A,(lengtetext)
	INC	A
	CP	(IX+#01)
	JR	Z,_charins1
	INC	(IX+#01)
_charins1	JP	text_right

text_left	LD	A,(IX+#00)
	CP	#01
	JR	Z,_text_right1
	DEC	(IX+#00)
	JR	_text_right1
text_ins	LD	A,(insonoff)
	XOR	#01
	LD	(insonoff),A
	JR	_text_right1

text_del	LD	A,(IX+#00)
	CP	(IX+#01)
	JP	Z,texthoofd
	XOR	A
	JR	textbs_cont
textbsdel	db	0	;0=del 1=bs
textbs	ld	a,1
textbs_cont	LD	(textbsdel),A
	LD	HL,(vramadrestxt)
	LD	DE,buffer1024+900
	LD	A,(lengtetext)
	LD	C,A
	LD	B,#00
	PUSH	HL
	PUSH	DE
	PUSH	BC
	CALL	VRAMTORAM
	LD	(HL),#00
	INC	HL
	LD	(HL),#00
	LD	HL,buffer1024+900
	LD	C,(IX+#00)
	LD	B,#00
	ADD	HL,BC
	LD	A,(textbsdel)
	OR	A
	JR	Z,_text_del1
	DEC	HL
_text_del1	LD	D,H
	LD	E,L
	DEC	DE
	ld	bc,82	;max length+2
	LDIR
	POP	BC
	POP	HL
	POP	DE
	CALL	RAMTOVRAM
	DEC	(IX+#01)
	JR	NZ,_text_del2
	INC	(IX+#01)
_text_del2	LD	A,(textbsdel)
	OR	A
	JP	Z,texthoofd
	JP	text_left
bercursor	LD	HL,(vramadrestxt)
	LD	E,(IX+#00)
	LD	D,#00
	DEC	E
	ADD	HL,DE
	LD	B,#00
	LD	DE,80
_bercursor1	INC	B
	OR	A
	SBC	HL,DE
	JR	NC,_bercursor1
	ADD	HL,DE
	LD	C,B
	LD	B,L
	INC	B
	RET
zoekeindetxt	LD	HL,(vramadrestxt)
	LD	A,(lengtetext)
	LD	B,A
	LD	E,A
	LD	D,#00
	ADD	HL,DE
_zoekeinde	DEC	HL
	CALL	READVRAM
	OR	A
	JR	NZ,_starteinde
	DJNZ	_zoekeinde
_starteinde	INC	B
	INC	HL
	LD	C,B
	RET
printspecial	LD	A,(specialchar)
	OR	A
	RET	Z
	LD	E,(IX+#01)
	DEC	E
	LD	D,#00
	LD	HL,(vramadrestxt)
	ADD	HL,DE
	LD	A,(lengtetext)
	INC	A
	SUB	(IX+#01)
	RET	Z
	LD	C,A
	LD	B,#00
	LD	A,(specialchar)
	JP	FILLVRAM

CLOSEFILE	LD	DE,fcb_work
	LD	C,16
	CALL	bdos
	LD	A,(doinclude)
	OR	A
	RET	NZ
	CALL	wissaveload
	ld	a,(Diskasm)
	OR	A
	JP	Z,diskhoofdprt
	CALL	GETKEY
	JP	_diskback
;----- IN: HL=vram address, IX=menu info
PRINTMENU	ld	a,1
	ld	(cursoronoff),a
	push	hl
	ld	a,(ix+2)
	or	a
	ld	de,buffer1024	;1st buffer
	jr	z,_printmenu1
	ld	de,buffer1024+256	;2nd buffer
_printmenu1:	ld	a,(ix)
	cp	1
	jr	nz,_not1
	inc	a
_not1:	add	a,2+1	;+edges+shadow
	ld	b,a
	ld	a,(ix+1)
	add	a,4+2+2	;+spaces+borders+shadow
	ld	c,a	;c=width
_printmenu3:	push	bc
	call	SETVRAMREAD
	ld	b,c
_printmenu2:	in	a,(#98)
	ld	(de),a
	inc	de
	djnz	_printmenu2
	ld	bc,80
	add	hl,bc
	pop	bc
	djnz	_printmenu3	;save background in buffer

	pop	hl
	ld	iy,Menuhok
	ld	a,(ix+1)
	add	a,4	;width+4
	ld	(iy+2),a
	ld	(iy+9),a
	ld	(iy+20),a
	ld	(iy+48),a
	sub	2
	ld	(iy+35),a
	call	printhok
	call	WISKEYBUFFER
	ld	bc,Menuspeed
	jp	OFFSET
Menuspeed:	equ	#0902
;----- IN: C=option num, HL=address blink table, IX=info menu
;----- OUT: A=key, C=option no (1-..), HL=address blink table
KIESOPTIE:
kieshoofd:
	call	kiessetbalk
	push	bc
	call	GETKEY
	pop	bc
	cp	31
	jr	z,kies_down
	cp	30
	jr	z,kies_up
	cp	29
	jr	z,kiesback
	cp	28
	jr	z,kiesback
	cp	27
	jr	z,kiesback
	cp	32
	jr	z,kiesback
	cp	13
	jr	z,kiesback
	cp	250
	jr	nc,kiesback
	cp	2
	jr	nc,kieshoofd
kiesback	push	af
	call	kieswisbalk
	pop	af
	cp	13
	ret	nz
	ld	a,32
	ret
kies_up	call	kieswisbalk
	dec	l
	dec	c
	jr	nz,kieshoofd
	ld	c,(ix)
	ld	a,l
	add	a,(ix)
	ld	l,a
	jr	kieshoofd
kies_down	call	kieswisbalk
	inc	l
	inc	c
	ld	a,c
	dec	a
	cp	(ix)
	jr	nz,kieshoofd
	ld	c,1
	ld	a,l
	sub	(ix)
	ld	l,a
	jr	kieshoofd
kieswisbalk	push	hl
	push	bc
	ld	b,(ix+1)
	inc	b
	inc	b
	call	WISBALK
	pop	bc
	pop	hl
	ret
kiessetbalk:	push	hl
	push	bc
	ld	b,(ix+1)
	inc	b
	inc	b
	call	SETBALK
	pop	bc
	pop	hl
	ret
;----- IN: IX=menu info, HL=address vram
WISOUDMENU	ld	a,(ix+2)
	or	a
	ld	de,buffer1024	;1st buffer
	jr	z,_wisoudmenu1
	ld	de,buffer1024+256	;2nd buffer
_wisoudmenu1:	ld	a,(ix)
	cp	1
	jr	nz,_not1_1
	inc	a
_not1_1	add	a,2+1	;+edges+shadow
	ld	b,a
	ld	a,(ix+1)
	add	a,4+2+2	;+spaces+borders+shadow
	ld	c,a	;c=width
_wisoudmenu3:	push	bc
	call	SETVRAMWRITE
	ld	b,c
_wisoudmenu2:	ld	a,(de)
	inc	de
	out	(#98),a
	djnz	_wisoudmenu2
	ld	bc,80
	add	hl,bc
	pop	bc
	djnz	_wisoudmenu3
	ld	bc,#0101
	jp	OFFSET
;Calculate number for assembling
;In:HL=start address text, DE=assemble address IX=test label address
;A=any segment (bit 6-7)
BERGETALASM	ld	(Testlabel),ix
	ld	(Assembladres),de
	ld	(Segment),a
	jr	contbergetal
;In:HL=start address text,end=0 or ",=<>"
;Off: DE=number HL=next address Cf=error,A=error no:
;0=no number 1=bad mnemonic 2=wrong hook close 3=delinndoor0
Assembladres:	defw	0
BEREKENGETAL	ld	bc,(Result)
	ld	(Assembladres),bc	;for $
	ld	bc,Testlabeladr
	ld	(Testlabel),bc
contbergetal	ld	(Sp_reken),sp
	ld	iy,Exist1
	ld	(iy-2),0	;0 brackets open
	ld	(iy-3),0	;had no numbers
	xor	a
	ld	(Fndsegment),a
	dec	sp
	dec	sp
	ld	a,(hl)
	or	a
	jp	z,eindereken
haakstart	exx
	ld	hl,Exist1
	ld	de,Exist1+1
	ld	bc,19-1
	ld	(hl),0
	ldir
	exx
rekenloop	ld	a,(hl)
	inc	hl
	cp	" "
	jr	z,rekenloop
	dec	hl
	cp	"("
	jr	nz,_reken1
	inc	hl
	inc	(iy-2)
	exx
	ld	(Doel_sp1+1),sp
Doel_sp1:	ld	de,0
	ld	hl,Exist1+18
	ld	bc,20
	lddr		;info to stack
	ex	de,hl
	ld	sp,hl	;new SP
	exx
	jp	haakstart
_reken1	call	haalgetal
haaksluit	ld	a,(hl)
	inc	hl
	cp	" "
	jr	z,haaksluit
	dec	hl
	or	a
	jp	z,eindereken
	cp	","
	jp	z,eindereken
	cp	"<"
	jr	c,no_end
	cp	">"+1
	jp	c,eindereken
no_end:	cp	")"
	jr	nz,_reken2
	ld	a,(iy-2)
	or	a
	jp	z,eindereken
	dec	(iy-2)
	inc	hl
finishcount	ld	a,(Exist1+4)
	or	a
	jr	z,readycount
	call	docount
	jr	finishcount
readycount	ld	de,(Exist1+1)
	exx
	ld	(Doel_sp2+1),sp
Doel_sp2:	ld	hl,0
	inc	hl
	ld	de,Exist1-1
	ld	bc,20
	ldir		;info from stack
	ld	sp,hl	;new SP
	dec	sp	;-1
	exx
	call	soortfound	;fill in + calculate if necessary
	jp	haaksluit
_reken2	cp	"^"
	jr	z,operat
	cp	"*"
	jr	z,operat
	cp	"/"
	jr	z,operat
	cp	"+"
	jr	z,operat
	cp	"-"
	jr	z,operat
	and	%11011111
	inc	hl
	cp	"O"
	jr	z,_or
	cp	"A"
	jr	z,_and
	cp	"X"
	jr	z,_xor
	cp	"M"
	dec	hl	;Leave it !!!
	jp	nz,eindereken
	inc	hl
_mod	ld	a,(hl)
	and	%11011111
	cp	"O"
	jp	nz,badmnemonic
	inc	hl
	ld	a,(hl)
	and	%11011111
	cp	"D"
	jp	nz,badmnemonic
	ld	a,"M"
	jp	operat
_xor	ld	a,(hl)
	and	%11011111
	cp	"O"
	jp	nz,badmnemonic
	inc	hl
	ld	a,(hl)
	and	%11011111
	cp	"R"
	jp	nz,badmnemonic
	ld	a,"X"
	jr	operat
_or	ld	a,(hl)
	and	%11011111
	cp	"R"
	jp	nz,badmnemonic
	ld	a,"O"
	jr	operat
_and	ld	a,(hl)
	and	%11011111
	cp	"N"
	jp	nz,badmnemonic
	inc	hl
	ld	a,(hl)
	and	%11011111
	cp	"D"
	jp	nz,badmnemonic
	ld	a,"A"
operat	ld	(de),a
	inc	hl
	jp	rekenloop
haalgetal	ex	af,af'
	xor	a
	ld	(Newsegment),a
	ld	(iy-1),0	;sign positive
	ex	af,af'
_haalget_cnt	cp	"+"
	jp	z,_haalgetal1
	cp	"-"
	jp	z,_haalgetal2
	call	testhex
	jr	nc,soortfound
	call	testbin
	jr	nc,soortfound
	call	testdec
	jr	nc,soortfound
	call	test_
	jr	nc,soortfound
	call	testkarakter
	jr	nc,soortfound
	call	testlabel
	jp	c,badmnemonic
soortfound	inc	(iy-3)	;number found
	ld	a,(iy-1)
	or	a
	jr	z,_positief
	push	hl
	ld	hl,0
	sbc	hl,de	;make negative, set to [NC]
	ex	de,hl
	pop	hl
_positief	push	hl
	ld	hl,Exist1
	ld	bc,4
_findempty:	ld	a,(hl)
	or	a
	jr	z,_empty
	add	hl,bc
	jr	_findempty
_empty	ld	(hl),1	;number exists
	inc	hl
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	ex	de,hl	;de=address operation
	pop	hl
testifcount	ld	a,(Exist1+4)
	or	a
	call	z,segments	;1st number => Set Fndsegment
	ld	a,(Exist1+16)
	or	a
	ret	z	;not yet full
docount	push	hl
	ld	a,"^"
	ld	c,1
	call	testifexist
	jp	nc,domacht
	ld	a,"*"
	ld	c,1
	call	testifexist
	jp	nc,domaal
	ld	a,"M"
	ld	c,"/"
	call	testifexist
	jp	nc,dodeelmod
	ld	a,"+"
	ld	c,"-"
	call	testifexist
	jp	nc,dooptelaftrk
	ld	a,"A"
	ld	c,"O"
	call	testifexist
	jr	nc,doandor
	ld	a,"X"
	ld	c,1
	call	testifexist
	jr	nc,doxor
	pop	hl
	ret		;nothing more to count
doandor	push	hl
	cp	"A"
	push	af
	call	z,b16_and
	pop	af
	call	nz,b16_or
	jr	cont_optel
doxor	push	hl
	call	b16_xor
	jr	cont_optel
dooptelaftrk	push	hl
	cp	"+"
	push	af
	call	z,b16_add
	pop	af
	call	nz,b16_sub
cont_optel:	ex	de,hl
	pop	hl
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	xor	a
	ld	(hl),a	;clear operation next number
	inc	hl
	ld	(hl),a	;delete exist next number
	ld	a,(Exist1+4)
	or	a
	jr	nz,twee_exist
	ld	hl,Exist1+7
	ld	de,Exist1+3
	ld	bc,4*3
	ldir		;3 => 2 and 4 => 3 and 5 => 4
	jr	docount_end
twee_exist	ld	a,(Exist1+8)
	or	a
	jr	nz,drie_exist
	ld	hl,Exist1+11
	ld	de,Exist1+7
	ld	bc,4*2
	ldir		;4 => 3 and 5 => 4
	jr	docount_end
drie_exist	ld	a,(Exist1+12)
	or	a
	jr	nz,docount_end	;4 also exists, so 5 deleted
	ld	hl,(Exist1+15)
	ld	(Exist1+11),hl
	ld	hl,(Exist1+15+2)
	ld	(Exist1+11+2),hl
docount_end	ld	hl,0
	ld	(Exist1+16-1),hl	;delete 5
	ld	hl,Exist1
	ld	bc,4
_findempty1	ld	a,(hl)
	or	a
	jr	z,_empty1
	add	hl,bc
	jr	_findempty1
_empty1	ex	de,hl
	dec	de	;DE=address operation
	pop	hl	;next address
	ret
domaal	push	hl
	call	b16_mu
	jr	cont_optel
domacht	push	hl
	call	b16_mac
	jr	cont_optel
dodeelmod	push	hl
	cp	"/"
	push	af
	call	z,b16_di
	pop	af
	call	nz,b16_mod
	jr	cont_optel
;----- Operation in A or C already found? [C]=no, otherwise: BC and DE are 2
;      numbers, A=operation
testifexist	ld	hl,Exist1+3
	ld	de,4
	ld	b,4
_testifex1	cp	(hl)
	jr	z,_testfound
	ex	af,af'
	ld	a,c
	cp	(hl)
	jr	z,_testfound
	ex	af,af'
	add	hl,de
	djnz	_testifex1
	scf
	ret
_testfound	dec	hl
	ld	b,(hl)
	dec	hl
	ld	c,(hl)
	push	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	pop	hl
	ret
_haalgetal2	ld	a,(iy-1)
	xor	1
	ld	(iy-1),a	;+ becomes - and vice versa
_haalgetal1	inc	hl
	ld	a,(hl)
	jp	_haalget_cnt
eindereken	push	hl
_eindereken1	ld	a,(Exist1+4)
	or	a
	jr	z,_ready
	call	docount
	jr	_eindereken1
_ready	pop	hl
	ld	a,(iy-3)
	or	a
	jp	z,geengetal
	ld	a,(iy-2)
	or	a
	jp	nz,mishaaksluit
	ld	de,(Exist1+1)
	ld	sp,(Sp_reken)
	ld	a,(Fndsegment)
	ret		;[NC] and DE is found number
Sp_reken:	defw	0
Segment:	defb	0	;current segment when assembling
Fndsegment:	defb	0	;calculated segment
Newsegment:	defb	0	;segment, belonging to number
;----- FAULTS
geengetal	xor	a
	jr	foutback
badmnemonic	ld	a,1
	jr	foutback
mishaaksluit	ld	a,2
	jr	foutback
delingdoor0	ld	a,3
foutback	ld	sp,(Sp_reken)
	scf
	ret

Getalgehad:	defb	0	;0=didn't have a number
Haakgeopend:	defb	0	;number of open brackets
Sign:	defb	0
Exist1:	defb	0	;0=does not exist +0
Getal1:	defw	0	;           +1
Oper1_2:	defb	0	;^*/+-            +3
	defb	0	;           +4
	defw	0	;           +5
	defb	0	;^*/+-            +7
	defb	0	;           +8
	defw	0	;           +9
	defb	0	;^*/+-            +11
	defb	0	;           +12
	defw	0	;           +13
	defb	0
	defb	0
	defw	0
;----- Multiply
; Input:    BC, DE
; Output:   HL = BC * DE
; Changes:  AF, BC, HL
b16_mu	ld	hl,0
	ld	a,b
	ld	b,16
b16_m1	add	hl,hl
	sla	c
	adc	a,a
	jr	nc,b16_m2
	add	hl,de
b16_m2	djnz	b16_m1
segments	ld	a,(Newsegment)
	ld	b,a
	ld	a,(Fndsegment)
	or	b
	ld	(Fndsegment),a
	ret
;----- Shared
; Input:    BC, DE
; Output:   HL = BC / DE
;          [C]= division by 0
; Changes:  AF, BC, DE, HL
b16_di	ld	a,d
	or	e
	jp	z,delingdoor0
	ld	hl,0
	ld	a,b
	or	c
	jr	nz,b16_d0
	ld	d,h
	ld	e,l
	jr	segments	;Tlr=0 => res HL=0 and DE=0
b16_d0	ld	a,b
	ld	b,17
b16_d1	scf
	rl	c
	adc	a,a
	dec	b
	jr	nc,b16_d1	;Find 1st high bit
	;Never come here with B < 1 !
b16_d2	adc	hl,hl
	sbc	hl,de
	jr	nc,b16_d3
	add	hl,de
b16_d3	rl	c
	adc	a,a
	djnz	b16_d2
	ex	de,hl	;DE=rest
	cpl
	ld	h,a
	ld	a,c
	cpl
	ld	l,a
	jr	segments
;----- Adding up
; Input:  BC, DE
; Output: HL = BC + DE
b16_add	ld	h,b
	ld	l,c
	add	hl,de
	jr	segments	;it said ret**=calculatorbugv1.0*****
;----- Substract
; Input:  BC, DE
; Output: HL = BC - DE
b16_sub	ld	h,b
	ld	l,c
	or	a
	sbc	hl,de
	push	bc
	ld	a,(Fndsegment)
	ld	b,a
	ld	a,(Newsegment)
	cp	b
	pop	bc
	jr	nz,segments
	xor	a
	ld	(Fndsegment),a	;Segments exception
	ret
; Power Routine 16-bit
; Input:    BC,DE
; Output:   HL(=BC^DE)
; Changes:  AF, BC, DE and HL
b16_mac	ld	h,d
	ld	l,e	;hl=number of times
	ld	a,h
	or	l
	jr	z,_b16m2	;^0
	dec	hl
	ld	a,h
	or	l
	jr	z,_b16m3	;^1
	ld	d,b
	ld	e,c	;de=bc
_b16m1:	push	hl
	push	de
	call	b16_mu	;multiply
	pop	de
	ld	b,h
	ld	c,l
	pop	hl
	dec	hl
	ld	a,h
	or	l
	jr	nz,_b16m1
	ld	h,b
	ld	l,c
	jr	segments
_b16m2:	ld	hl,1	;bc^0
	jr	segments
_b16m3:	ld	h,b	;bc^1
	ld	l,c
	jr	segments
b16_or	ld	a,b
	or	d
	ld	h,a
	ld	a,c
	or	e
	ld	l,a
	jp	segments
b16_and	ld	a,b
	and	d
	ld	h,a
	ld	a,c
	and	e
	ld	l,a
	jp	segments
b16_xor	ld	a,b
	xor	d
	ld	h,a
	ld	a,c
	xor	e
	ld	l,a
	jp	segments
b16_mod	call	b16_di
	ex	de,hl	;Mod, so residual value
	ret		;segments already done

;----- Is hex number ?     [C]=no
testhex:	ld	a,(hl)
	cp	"A"
	ccf
	ret	c	;must start with number
	push	hl
	call	testidhexvoo
	ld	a,0
	jr	c,_testhex1
	inc	a
_testhex1	ld	(Hexidfound),a
	ld	c,0
	ld	de,0
_testhex_3:	ld	a,(hl)
	inc	hl
	cp	"0"
	jr	c,testhex_idna	;<"0"
	cp	"9"+1
	jr	c,testhex_1
	and	%11011111
	cp	"A"
	jr	c,testhex_idna	;<"A"
	cp	"F"+1
	jr	nc,testhex_idna	;>"F"
	sub	"A"-"0"-10
testhex_1:	sub	"0"
	add	a,a
	add	a,a
	add	a,a
	add	a,a
	ld	b,4
_testhex_2:	sla	a
	rl	e
	rl	d
	djnz	_testhex_2
	inc	c
	jr	_testhex_3
testhex_idna	dec	hl
	ld	a,c
	or	a
	jr	z,testhex_back	;no hex number
	ld	a,(Hexidfound)
	or	a	;=[NC]
	call	z,testidhexna	;no id yet
	jr	c,testhex_back
	pop	bc
	ret
testhex_back:	pop	hl
	scf
	ret
Hexidfound	db	0
;----- Is bin number ?     [C]=no
testbin	push	hl
	call	testidbinvoo
	ld	a,0
	jr	c,_testbin1
	inc	a
_testbin1	ld	(Binidfound),a
	ld	de,0
	ld	c,0
_testbin_1:	ld	a,(hl)
	inc	hl
	cp	" "
	jr	z,_testbin_1
	cp	"0"
	jr	c,testbin_idna	;<"0"
	cp	"1"+1
	jr	nc,testbin_idna	;>"1"
	sub	"0"
	srl	a
	rl	e
	rl	d
	inc	c
	jr	_testbin_1
testbin_idna	dec	hl
	ld	a,c
	or	a
	jr	z,testbin_back	;no bin number
	ld	a,(Binidfound)
	or	a	;=[NC]
	call	z,testidbinna	;no id yet
	jr	c,testbin_back
	pop	bc
	ret
testbin_back:	pop	hl
	scf
	ret
Binidfound	db	0
;----- Is dec number ?    [C]=no
testdec	push	hl
	ld	de,0
	exx
	ld	c,0
	exx
_testdec_1:	ld	a,(hl)
	inc	hl
	cp	" "
	jr	z,_testdec_1
	cp	"0"
	jr	c,testdec_na
	cp	"9"+1
	jr	nc,testdec_na
	sub	"0"
	ex	de,hl
	add	hl,hl	;*2
	ld	b,h
	ld	c,l
	add	hl,hl	;*4
	add	hl,hl	;*8
	add	hl,bc	;*10
	ld	c,a
	ld	b,0
	add	hl,bc
	ex	de,hl
	exx
	inc	c
	exx
	jr	_testdec_1
testdec_na	dec	hl
	exx
	ld	a,c
	exx
	or	a
	jr	z,testdec_back	;no dec number
	pop	bc
	ret
testdec_back	pop	hl
	scf
	ret
;----- is $ ?
test_	ld	a,(hl)
	cp	"$"
	scf
	ret	nz
	inc	hl
	ld	de,(Assembladres)
	ld	a,(Segment)
	ld	(Newsegment),a
	or	a
	ret
;----- is "
testkarakter	push	hl
	ld	a,(hl)
	cp	34
	jr	z,_iskar
	cp	"'"
	jr	nz,testkar_back
_iskar	ld	b,a
	inc	hl
	ld	a,(hl)
	cp	b
	ld	de,0
	jr	z,_2quotes	;"" or ''
	ld	e,a
	inc	hl
	ld	a,(hl)
	cp	b
	jr	z,_2quotes	;"?" or '?'
	ld	d,e
	ld	e,a
	inc	hl
	ld	a,(hl)
	cp	b
	jp	nz,geengetal
_2quotes	inc	hl
	pop	bc
	or	a
	ret
testkar_back	pop	hl
	scf
	ret
testlabel	ld	de,(slotsubroutin)
	push	de
	ld	bc,(slotass)
	call	zetslot
Testlabel:	equ	$+1
	call	0
	ld	(Newsegment),a
	pop	bc
	ld	(slotsubroutin),bc
	push	af
	call	zetslot
	pop	af
	ret
;----- test ids binary and hexadecimal
testidbinvoo	ld	ix,idbin
	ld	a,(ix+2)
	or	a
	jr	nz,_testidbin1
	call	testspecid
	ret	nc
_testidbin1	ld	a,(hl)
	inc	hl
	cp	"%"
	ret	z
	cp	"&"
	jr	nz,_testidfout
	ld	a,(hl)
	and	%11011111
	cp	"B"
	jr	nz,_testidfout
	inc	hl
	or	a
	ret
testidhexvoo	ld	ix,idhex
	ld	a,(ix+2)
	or	a
	jr	nz,_testidhex1
	call	testspecid
	ret	nc
_testidhex1	ld	a,(hl)
	inc	hl
	cp	"#"
	ret	z
	cp	"&"
	jr	nz,_testidfout
	ld	a,(hl)
	and	%11011111
	cp	"H"
	jr	nz,_testidfout
	inc	hl
	or	a
	ret
_testidfout	dec	hl
	scf
	ret
testidhexna	ld	ix,idhex
	ld	a,(ix+2)
	or	a
	jr	z,_testidhexn1
	call	testspecid
	ret	nc
_testidhexn1	ld	a,(hl)
	inc	hl
	and	%11011111
	cp	"H"
	ret	z
	jr	_testidfout
testidbinna	ld	ix,idbin
	ld	a,(ix+2)
	or	a
	jr	z,_testidbinn1
	call	testspecid
	ret	nc
_testidbinn1	ld	a,(hl)
	inc	hl
	and	%11011111
	cp	"B"
	ret	z
	jr	_testidfout
testspecid	ld	b,(hl)
	res	5,b
	ld	a,(ix)
	and	%11011111
	cp	b
	scf
	ret	nz	;no id
	inc	hl
	ld	a,(ix+1)
	or	a
	ret	z	;ok
	and	%11011111
	ld	b,a
	ld	a,(hl)
	inc	hl
	and	%11011111
	cp	b
	ret	z	;ok
	dec	hl
	dec	hl
	scf
	ret		;no id

MEMVIEW	LD	HL,#1800+3*10	;blink table except menu bar
	LD	BC,24*10
	XOR	A
	CALL	FILLVRAM
	LD	HL,3*80	;clear screen (last half line
	LD	BC,23*80	;is always empty)
	XOR	A
	CALL	FILLVRAM
	CALL	printmemview
	CALL	vultabelin
	LD	HL,memviewtxt2
	CALL	TEXTTOBLOK
	CALL	vulrestin
_memview	CALL	GETKEY
	CP	27
	RET	Z
	CP	#01
	RET	Z
	CP	#0D
	RET	Z
	AND	255-32
	RET	Z
	JR	_memview
memviewtxt2	dw	5*80+2
	db	"Bios  ",0
	dw	7*80+2
	db	"Basic ",0
	dw	0
;CALCULATOR
Result	dw	0
Poscalc:	defb	10
Calcdoel:	defw	10*80
Calcdoelblin:	defw	#1800+10*10

CALCULATOR	xor	a
_calccontinu	push	af
	ld	hl,(Calcdoel)
	ld	de,buffer1024+420
	ld	bc,5*80
	call	VRAMTORAM
	ld	hl,(Calcdoelblin)
	ld	de,buffer1024+420+5*80
	ld	bc,5*10
	call	VRAMTORAM
	ld	hl,(Calcdoelblin)
	ld	bc,5*10
	xor	a
	call	FILLVRAM	;clear blink
	ld	hl,(Calcdoel)
	ld	de,Calculalines
	call	PRINTBLOK
	ld	hl,(Calcdoel)
	ld	de,80+2
	add	hl,de
	push	hl
	ld	bc,Calctext1
	call	PRINTTEKST
	pop	hl
	ld	de,160
	add	hl,de
	ld	bc,Calctext2
	call	PRINTTEKST
	pop	af
	jr	nc,calchoofd
	call	berekencalc
	ex	de,hl
	call	RAMTOVRAM
	jr	calccont
calchoofd	ld	hl,(Calcdoel)
	ld	de,80+13
	add	hl,de
	ld	bc,80-13-1
	xor	a
	call	FILLVRAM
calccont	ld	hl,(Calcdoel)
	ld	de,3*80+10
	add	hl,de
	push	hl
	ld	bc,69
	xor	a
	call	FILLVRAM
	pop	hl
	inc	hl
	inc	hl
	inc	hl
	ld	de,(Result)
	ld	b,2
	ld	a,d
	or	a
	jr	z,_8bithex
	ld	b,4
_8bithex:	push	bc
	push	de
	call	PRINTHEXADECI
	pop	de
	call	printtussen
	pop	bc
	inc	b
	push	de
	call	PRINTDECIMAAL
	pop	de
	call	printtussen
	ld	b,8
	ld	a,d
	or	a
	jr	z,_8bitbin
	ld	b,16
_8bitbin:	push	de
	call	PRINTBINAIR
	pop	de
	call	printtussen
	ld	b,"'"
	ld	a,d
	cp	34
	jr	z,_char1
	ld	a,e
	cp	34
	jr	z,_char1
	ld	b,34
_char1	ld	a,b
	out	(#98),a
	ld	a,d
	or	e
	jr	z,_charclose
	ld	a,d
	or	a
	jr	nz,_char2
	ld	a,e
_char2	out	(#98),a
	nop
	nop
	ld	a,d
	or	a
	jr	z,_charclose
	ld	a,e
	out	(#98),a
	nop
	nop
_charclose	ld	a,b
	out	(#98),a
_calc_cont	ld	hl,(Calcdoel)
	ld	de,80+13
	add	hl,de
	ld	de,buffer1024
	ld	b,80-13-2
	ld	a,%11010001	;escape, lowercase, up/down, back
	call	INPUTTEXT
	jr	c,_calc_esc
	ld	hl,buffer1024
	call	BEREKENGETAL
	jr	c,_calc_error
	ld	a,(hl)
	or	a
	jr	nz,_calc_error
	ld	(Result),de
	jp	calchoofd
_calc_error:	call	beep
	jp	calccont
_calc_esc	push	af
	call	_calc_back
	pop	af
	or	a
	ret	z	;escape
	dec	a
	ld	hl,(Calcdoel)
	ld	de,(Calcdoelblin)
	ld	bc,80
	ld	a,(Poscalc)
	jr	nz,_calc_down
_calc_up	cp	3
	jr	z,_calc_down2
	dec	a
	sbc	hl,bc
	ex	de,hl
	ld	bc,10
	sbc	hl,bc
	jr	_calc_down1
_calc_down	cp	20
	jr	z,_calc_down2
	inc	a
	add	hl,bc
	ex	de,hl
	ld	bc,10
	add	hl,bc
_calc_down1	ld	(Poscalc),a
	ld	(Calcdoel),de
	ld	(Calcdoelblin),hl
_calc_down2	scf
	jp	_calccontinu
_calc_back	call	berekencalc
	call	VRAMTORAM
	ld	hl,buffer1024+420
	ld	de,(Calcdoel)
	ld	bc,5*80
	call	RAMTOVRAM
	ld	hl,buffer1024+420+5*80
	ld	de,(Calcdoelblin)
	ld	bc,5*10
	jp	RAMTOVRAM
printtussen	ld	a," "
	out	(#98),a
	nop
	nop
	ld	a,"="
	out	(#98),a
	nop
	set	7,h
	ld	a," "
	out	(#98),a
	ret
berekencalc	ld	hl,(Calcdoel)
	ld	bc,80
	add	hl,bc
	ld	de,kbuf
	ret

Calculalines:	defw	Calcline1,Calcline2,Calcline2,Calcline2,Calcline3,0
Calcline1:	defb	1,24,78,23,1,25,0
Calcline2:	defb	1,22,78,0,1,22,0
Calcline3:	defb	1,26,78,23,1,27,0
Calctext1:	defb	"Calculate:",0
Calctext2:	defb	"Result:",0

MEMORY	ld	hl,3*80
	ld	de,Memorylines
	call	PRINTBLOK
	ld	hl,25*80
	ld	bc,80
	xor	a
	call	FILLVRAM
	ld	hl,3*10+#1800
	ld	bc,24*10
	xor	a
	call	FILLVRAM
	ld	ix,memtxtdoel
_memory2	ld	l,(ix)
	ld	h,(ix+1)
	ld	a,h
	or	l
	jr	z,_memory1
	ld	c,(ix+2)
	ld	b,(ix+3)
	call	PRINTTEKST
	ld	de,4
	add	ix,de
	jr	_memory2
_memory1	call	getreg
	call	gotomemory
	ld	hl,textbuffer1
	ret
gotomemory	push	hl
	ld	hl,#400c
	jp	GOTOEDITOR
getreg	LD	IX,tab_memtabel
	LD	IY,tab_ROMRAM
	LD	A,(dosversion)
	LD	B,A
	LD	A,(stat_mem)
	LD	C,A
	LD	HL,tab_memory
	LD	DE,tab_compass
	RET
memtxtdoel	defw	4*80+(80-13)/2,Mt0
	defw	6*80+2,Mt1,6*80+12,Mt1,6*80+22,Mt1,6*80+32,Mt1
	defw	6*80+18,Mt_2,6*80+28,Mt_3,6*80+38,Mt_4
	defw	6*80+43,Mt2,6*80+53,Mt2,6*80+63,Mt2,6*80+73,Mt2
	defw	6*80+57,Mt_2,6*80+67,Mt_3,6*80+77,Mt_4
	defw	15*80+42,Mt3,15*80+67,Mt4
	defw	17*80+62,Mt5,18*80+62,Mt5,19*80+62,Mt5,20*80+62,Mt5
	defw	18*80+67,Mt_1,19*80+67,Mt_2,20*80+67,Mt_3
	defw	22*80+42,Mt6
	defw	0
Mt0:	defb	"Memory layout",0
Mt1:	defb	"Source1",0
Mt2:	defb	"Data1",0
Mt3:	defb	"Labels  ",22," Compass",0
Mt4:	defb	"Memory",0
Mt5:	defb	"Page 0:",0
Mt_1:	defb	"1",0
Mt_2:	defb	"2",0
Mt_3:	defb	"3",0
Mt_4:	defb	"4",0
Mt6:	defb	"Memory manager:",0
	;*****************possibly remove the 1 from source1 and data1
Memorylines:	defw	M1,M2,M3,M4,M5
	defw	M6,M7,M6,M7,M6,M7,M6,M7,M6,M7,M6,M7
	defw	M6,M8,M6,M9,M6,M10,M6,M9,M6,M9,M6,M9,M6,M9,M6,M11
	defw	M6,M12,M6,M12,M13,0

M1:	defb	1,24,78,23,1,25,0
M2:	defb	1,22,78,0,1,22,0
M3:	defb	1,20,9,23,1,18,9,23,1,18,9,23,1,18,9,23,1,18
	defb	9,23,1,18,9,23,1,18,9,23,1,18,8,23,1,19,0
M4:	defb	1,22,9,0,1,22,9,0,1,22,9,0,1,22,9,0
	defb	1,22,9,0,1,22,9,0,1,22,9,0,1,22,8,0,1,22,0
M5:	defb	1,20,9,23,1,21,9,23,1,21,9,23,1,21,9,23,1,21
	defb	9,23,1,21,9,23,1,21,9,23,1,21,8,23,1,19,0
M6:	defb	1,22,9,0,1,22,9,0,1,22,9,0,1,22,9,0,0
M7:	defb	1,22,9,0,1,22,9,0,1,22,9,0,1,22,8,0,1,22,0
M8:	defb	1,20,9,23,1,21,9,23,1,21,9,23,1,17,8,23,1,19,0
M9:	defb	1,22,9,0,1,22,9,0,1,22,18,0,1,22,0
M10:	defb	1,20,9,23,1,21,9,23,1,21,18,23,1,19,0
M11:	defb	1,20,9,23,1,17,9,23,1,17,18,23,1,19,0
M12:	defb	1,22,38,0,1,22,0
M13:	defb	1,26,9,23,1,17,9,23,1,17,9,23,1,17,9,23,1,17,38,23,1,27,0

;print small block on screen: in:HL=vramadres DE=info-adress
_printblokkl	POP	HL
	EX	DE,HL
	LD	BC,80
	ADD	HL,BC
PRINTBLOKKLEI	CALL	SETVRAMWRITE
	EX	DE,HL
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	INC	HL
	LD	A,B
	OR	C
	RET	Z
	PUSH	HL
	LD	H,B
	LD	L,C
_printblokk3	LD	A,(HL)
	INC	HL
	OR	A
	JR	Z,_printblokkl
	LD	B,A
	LD	A,(HL)
	INC	HL
_printblokk2	NOP
	OUT	(#98),A
	DJNZ	_printblokk2
	JR	_printblokk3

;in: HL=address data (4bytes)=instruction to execute out:HL:register table
STARTPROGRAM	LD	DE,data
	LD	BC,4
	LDIR
	LD	A,(#FFFF)
	CPL
	LD	(old_ffff+1),A
	LD	A,(slothoofdp+1)
	LD	(old_blok+1),A
	LD	A,(page0+1)
	LD	(new_blok+1),A
	LD	HL,new_f38c
	LD	DE,kbuf
	LD	BC,end_f38c-new_f38c
	LDIR
	LD	A,(page2)
	LD	H,#80
	CALL	SLOT
	LD	A,(page2+1)
	CALL	SETPAGE2_DOS2
	LD	A,(page1)
	LD	H,#40
	CALL	SLOT
	LD	A,(page1+1)
	CALL	SETPAGE1_DOS2
	DI
	LD	HL,(#F38C)	;save original routine
	LD	(old_f38c+1-new_f38c+kbuf),HL
	LD	HL,(#F38E)
	LD	(old_f38e+1-new_f38c+kbuf),HL
	LD	A,#C3	;deflect 'hook #001c' to kbuf
	LD	(#F38C),A
	LD	HL,kbuf
	LD	(#F38D),HL
	LD	IY,(page0-1)
	LD	IX,#0000	;first clear page 0
	CALL	#001C	;START!!!
	LD	HL,#FFFF
	LD	(oudslot),HL
	LD	(oudslot+2),HL
	LD	BC,(slotsubroutin)
	CALL	zetslot
	LD	A,(#F343)
	LD	H,#80
	CALL	SLOT
GETREGISTERS	LD	HL,registers
	RET
new_f38c	OUT	(#A8),A
new_blok	LD	A,0	;filled in
	call	SETPAGE0_DOS2
old_f38c	LD	HL,0	;filled in: RESTORE F38C
	LD	(#F38C),HL
old_f38e	LD	HL,0	;filled in
	LD	(#F38E),HL
	POP	AF
	LD	(old_a8-new_f38c+kbuf+1),A
	LD	(old_sp-new_f38c+kbuf),SP
	LD	A,(reg_di_ei-new_f38c+kbuf)
	OR	A
	DI
	JR	Z,no_ei
	EI
no_ei	LD	BC,(reg_bc_-new_f38c+kbuf)	;BC'
	LD	DE,(reg_de_-new_f38c+kbuf)	;DE'
	LD	HL,(reg_hl_-new_f38c+kbuf)	;HL'
	EXX
	LD	HL,(reg_af_-new_f38c+kbuf)	;AF'
	PUSH	HL
	POP	AF
	EX	AF,AF'
	LD	HL,(reg_af-new_f38c+kbuf)	;AF
	PUSH	HL
	POP	AF
	LD	BC,(reg_bc-new_f38c+kbuf)
	LD	DE,(reg_de-new_f38c+kbuf)
	LD	HL,(reg_hl-new_f38c+kbuf)
	LD	IX,(reg_ix-new_f38c+kbuf)
	LD	IY,(reg_iy-new_f38c+kbuf)
	LD	SP,(reg_sp-new_f38c+kbuf)
data	ds	4,0	;filled in: execute
	LD	(reg_sp-new_f38c+kbuf),SP
	LD	SP,(old_sp-new_f38c+kbuf)
	PUSH	AF
	LD	A,I	;get interrupt state
	LD	A,#00
	JP	PO,_eidi-new_f38c+kbuf
	INC	A
_eidi	PUSH	AF
	DI
old_a8	LD	A,#00	;filled in
	OUT	(#A8),A
old_ffff	LD	A,#00	;filled in
	LD	(#FFFF),A
old_blok	LD	A,#00	;filled in
	CALL	SETPAGE0_DOS2
	LD	(reg_iy),IY
	LD	(reg_ix),IX
	LD	(reg_hl),HL
	LD	(reg_de),DE
	LD	(reg_bc),BC
	LD	HL,(reg_sp-new_f38c+kbuf)
	LD	(reg_sp),HL
	POP	AF
	LD	(reg_di_ei),A
	POP	HL
	LD	(reg_af),HL
	EXX
	EX	AF,AF'
	LD	(reg_hl_),HL
	LD	(reg_de_),DE
	LD	(reg_bc_),BC
	PUSH	AF
	POP	HL
	LD	(reg_af_),HL
	RET
registers
reg_sp	dw	0	;is filled in by startcompass
reg_iy	dw	0
reg_ix	dw	0
reg_bc_	dw	0
reg_de_	dw	0
reg_hl_	dw	0
reg_af_	dw	0
reg_bc	dw	0
reg_de	dw	0
reg_hl	dw	0
reg_af	dw	0
reg_di_ei	db	0	;0=di 1=ei
old_sp	dw	0
end_f38c

VRAMTORAM	CALL	SETVRAMREAD
	EX	DE,HL
_vramtoram	IN	A,(#98)
	LD	(HL),A
	INC	HL
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,_vramtoram
	RET

GOTOEDITOR	LD	(invul_call1),HL
	PUSH	BC	;B=dosversion C=stat_mem
	LD	BC,(slotsubroutin)
	LD	(sub),BC
	LD	BC,(sloteditor)
goto_cont	LD	(slotsubroutin),BC
	CALL	zetslot
	POP	BC
	POP	HL	;get tab_memory
	db	#cd	;call
invul_call1	dw	0
	PUSH	BC
	LD	BC,(sub)
	LD	(slotsubroutin),BC
	CALL	zetslot
	POP	BC
	RET
sub	dw	0
GOTODEBUGGER	LD	(invul_call1),HL
	PUSH	BC
	LD	BC,(slotsubroutin)
	LD	(sub),BC
	LD	BC,(slotdebugger)
	JR	goto_cont
GOTOASS	LD	(invul_call1),HL
	PUSH	BC
	LD	BC,(slotsubroutin)
	LD	(sub),BC
	LD	BC,(slotass)
	JR	goto_cont
zetslot	PUSH	AF
	PUSH	DE
	PUSH	HL
	LD	A,B
	CALL	SETPAGE1_DOS2
	LD	A,C
	LD	H,#40
	CALL	SLOT
	POP	HL
	POP	DE
	POP	AF
	RET
SLOT	PUSH	HL
	PUSH	AF
	LD	A,H
	LD	HL,oudslot
	RLCA
	JR	NC,_slot1
	INC	HL
	INC	HL
_slot1	RLCA
	JR	NC,_slot2
	INC	HL
_slot2	POP	AF
	CP	(HL)	;was this slot already switched on?
	LD	(HL),A
	POP	HL
	RET	Z
	PUSH	DE
	PUSH	BC
	PUSH	HL
	CALL	#0024
	POP	HL
	POP	BC
	POP	DE
	RET
oudslot	db	#ff,#ff,#ff,#ff
stat_getkey	db	0	;input only possible with Left fire button
GETKEY2	ld	a,1
	ld	(stat_getkey),a
GETKEY	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	A,(cursoronoff)
	OR	A
	JR	Z,not_visible
wait1	LD	B,#00
	CALL	WAITFORKEY	;wait for a key and monitor in the meantime
	JR	C,wait1	;also the ctrl56,R800/Z80
	JP	getkey_back
not_visible	LD	BC,(#F3DC)	;get cursor position C=y(1-80) B=x(1-80)
	CALL	beradresvram
	CALL	READVRAM
	PUSH	AF
	PUSH	HL
	LD	L,A	;char num *8
	LD	H,#00
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	LD	DE,#1000	;pattern table
	ADD	HL,DE
	CALL	SETVRAMREAD
	LD	B,8	;default normal cursor
	LD	HL,blokvorm
	LD	DE,oldvorm
	LD	A,(insonoff)
	OR	A
	JR	Z,no_ins
	LD	B,5
_getkey1	IN	A,(#98)	;at ins top 5 lines unchanged
	LD	(DE),A
	INC	DE
	LD	(HL),A
	INC	HL
	DJNZ	_getkey1
	LD	B,#03
no_ins	IN	A,(#98)	;invert the rest
	LD	(DE),A
	INC	DE
	XOR	#FC
	LD	(HL),A
	INC	HL
	DJNZ	no_ins
	POP	HL	;name table location
	PUSH	HL
	LD	A,#FF	;print character 255
	CALL	WRITEVRAM
_getkey4	LD	HL,blokvorm
	LD	DE,#1000+255*8
	LD	BC,8
	CALL	RAMTOVRAM
_getkey3	LD	B,20
	CALL	WAITFORKEY
	JR	NC,_getkey2
	LD	A,(knipper)
	OR	A
	JR	Z,_getkey3
	LD	HL,oldvorm
	LD	DE,#1000+255*8
	LD	BC,8
	CALL	RAMTOVRAM
	LD	B,10
	CALL	WAITFORKEY
	JR	C,_getkey4
_getkey2	LD	(invul_lda+1),A	;safe code
	POP	HL	;get name table address
	POP	AF	;get old character
	CALL	WRITEVRAM
	LD	HL,#1000+255*8
	LD	BC,8
	LD	A,#FC
	CALL	FILLVRAM
invul_lda	LD	A,#00
getkey_back	PUSH	AF
	XOR	A
	LD	(stat_getkey),A
	POP	AF
	POP	BC
	POP	DE
	POP	HL
	RET
oldvorm	ds	8,0
blokvorm	ds	8,0

WAITFORKEY	PUSH	BC
	CALL	rdmous	;mouse handling
	CALL	janeetoetsen	;Z80/R800
	CALL	hertztoetsen	;ctrl+5/6
	POP	BC
	EI
	LD	A,(matrix+6)
	AND	#02
	JR	NZ,no1234_1
	LD	A,(matrix)
	LD	DE,4*256+241
	RRCA
no1234_0	RRCA
	JR	NC,ctrl1234
	INC	E
	DEC	D
	JR	NZ,no1234_0
no1234_1	LD	HL,(#F3FA)	;pointer first character in buffer
	LD	A,(#F3F8)	;pointer for new character
	CP	L	;equal? (then the buffer is empty)
	JR	NZ,_waitforkey	;new! just pick up sign
	LD	A,(matrix+7)	;pressed STOP?
	AND	#10
	JR	NZ,_waitforkey2	;new
_waitforkey3	LD	A,(matrix+7)	;yes, wait till it's out
	AND	#10
	JR	Z,_waitforkey3
	LD	A,250	;display code 250, carry cleared
	RET
_waitforkey2	LD	A,B	;is up time
	OR	A	;(wait B interrupts)
	SCF
	RET	Z
	HALT
	DJNZ	WAITFORKEY
	SCF
	RET
ctrl1234	ld	a,e
	PUSH	AF
	CALL	WISKEYBUFFER
	POP	AF
	RET		;code in E: 241-244
_waitforkey	ld	a,(hl)
	INC	HL
	PUSH	AF
	LD	A,L
	CP	#18
	JR	NZ,_waitforkey1
	LD	HL,#FBF0
_waitforkey1	LD	(#F3FA),HL
	POP	AF
	OR	A	;clear carry, key in a and buffer smaller
	RET

LINETOASSEMB	PUSH	HL
	LD	HL,#4006
	JP	GOTOEDITOR

;in: b=x(1-80) c=y(1-27) out:hl=vramaddress,changes: B,DE,HL,F
beradresvram	LD	H,#00
	LD	L,B
	DEC	HL
	LD	DE,80
	OR	A
	SBC	HL,DE
	LD	B,C
_beradresvram	ADD	HL,DE
	DJNZ	_beradresvram
	RET
WISKEYBUFFER	LD	HL,(#F3F8)
	LD	(#F3FA),HL
	RET

PUSHANYKEY	LD	HL,#1800+10*24	;in blink table
	LD	BC,10	;80 characters! wide
	LD	A,#FF
	CALL	FILLVRAM	;bar
_pushloop1	CALL	wispushany
	LD	B,10	;wait 10 interrupts
	CALL	WAITFORKEY
	JR	NC,_push_back
	LD	HL,80*24+(80-12)/2
	LD	BC,txt_pushany
	CALL	PRINTTEKST
	LD	B,20	;wait 20 interrupts
	CALL	WAITFORKEY
	JR	C,_pushloop1
_push_back	LD	HL,#1800+10*24
	LD	BC,10
	XOR	A
	CALL	FILLVRAM
wispushany	LD	HL,80*24
	LD	BC,80
	XOR	A
	JP	FILLVRAM
txt_pushany	db	"Push any key",0

PRINTINI	LD	IX,#00A5
	LD	HL,printerline
_printini0	LD	A,(HL)
	INC	HL
	OR	A
	RET	Z
	CP	"^"
	JR	NZ,_printini1
	LD	A,27
_printini1	ld	b,0	;try 256 times
_retrysend	CALL	gobios
	jr	nc,_printini0
	djnz	_retrysend
	JR	_printini0	;try the following characters

MAININSTALL	LD	BC,(slotsubroutin)
	LD	(oldslotsub+1),BC
	LD	BC,(slotdebugger)
	LD	(slotsubroutin),BC
	CALL	zetslot
	LD	HL,tab_inst
	LD	DE,color
	call	MAININSTPROG
	ld	de,tab_inst
	ld	bc,tab_inst_end-tab_inst
	ldir
oldslotsub	LD	BC,#0000
	LD	(slotsubroutin),BC
	CALL	zetslot
	LD	HL,tab_inst
	RET
tab_inst
idhex	db	"#",0,0
idbin	db	"%",0,0
printerline	ds	16,0
mouse	db	0	;1=on, turn off by default
knipper	db	1	;1=on
tab_inst_end

SAVEINSTALL	LD	A,(Backuponoff)	;backup status
	LD	(kbuf+#0104),A
	LD	HL,#0101	;notnew+notsrcem
	LD	(kbuf),HL
	LD	HL,tab_memtabel	;memconfig table
	LD	DE,kbuf+2
	LD	BC,#C1
	LDIR
	ld	hl,tab_compass	;compass blocks
	ld	bc,8
	ldir
	ld	hl,tab_memory	;memory status
	ld	bc,8
	ldir

	LD	HL,(color)	;palettebytes color 0,(0)
	LD	(kbuf+#ec),HL
	LD	HL,(color+30)	;palettebytes color 1,(15)
	LD	(kbuf+#ee),HL
	LD	HL,(color+6)	;palettebytes color 2,(3)
	LD	(kbuf+#f0),HL
	LD	HL,(color+4)	;palettebytes color 3,(2)
	LD	(kbuf+#f2),HL

	LD	BC,(sloteditor)
	CALL	zetslot
	CALL	#4009
	ld	bc,(slotdebugger)
	call	zetslot

	LD	(diskhook_sp),SP
	LD	HL,_saveerror
	LD	(diskhook_jp),HL
	CALL	setdiskhooks

	LD	A,(dosversion)
	CP	#02
	JR	C,openfile_dos1
	XOR	A
	LD	(compasscom+7),A
	LD	HL,compasscom
	LD	DE,buffer1024+750
	LD	BC,#FF6B
	CALL	bdos	;get envitem COMPASS (gives a
	LD	DE,buffer1024+750
	XOR	A	;null string back if not exists)
	LD	C,#43	;open file handle
	CALL	bdos
	JR	skip_opendos1
openfile_dos1	LD	HL,compasscom
	LD	DE,fcb_work+1
	LD	BC,11
	LDIR
	CALL	fcb_open
skip_opendos1	OR	A
	JR	NZ,_saveerror
	LD	A,B
	LD	(handle_nr),A
	db	#21	;ld hl,nn
si_place1	dw	#0300
	LD	(fcb_work+33),HL
	LD	DE,kbuf
	CALL	set_DTA
	db	#21	;ld hl,nn
si_lenght	dw	#011C
	CALL	saven_maar	;save and close
	JR	skip_save_err
_saveerror	LD	HL,22*80+31
	LD	BC,Writeerror
	CALL	PRINTTEKST
	CALL	beep
	CALL	GETKEY
skip_save_err	CALL	clrdiskhooks
	LD	HL,22*80	;ev delete error text?
	LD	BC,80	;clear line 22
	XOR	A
	JP	FILLVRAM

saven_maar	LD	A,(dosversion)
	CP	#02
	JR	C,save_dos1
	PUSH	HL
	LD	A,(handle_nr)
	LD	B,A
	db	#21	;ld hl,nn
si_place2	dw	#0300
	XOR	A
	LD	D,A
	LD	E,A
	LD	C,#4A
	PUSH	BC
	CALL	bdos
	POP	BC
	LD	DE,kbuf
	DEC	C
	POP	HL
	PUSH	BC
	CALL	bdos
	POP	BC
	LD	C,#45
	JP	bdos
handle_nr	db	0
save_dos1	LD	DE,fcb_work
	LD	C,38
	PUSH	DE
	CALL	bdos	;save
	POP	DE
	LD	C,#10	;and close
	JP	bdos
compasscom	db	"COMPASS COM"

GETPAGES	ld	hl,page0	;(2 times ld de,nn)
	ret
;moved compassblock:c=oldslot B=old block (THUS REVERSE),HL=pointer2new
MOVEPROG	LD	DE,#FFFF
	LD	(oudslot+1),DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	HL,(sub)
	CALL	testmove	;change content sub if it's that segm
	LD	(sub),HL	;that is going to be changed
	LD	HL,(slotsubroutin)
	CALL	testmove	;ditto content slot subroutin
	LD	(slotsubroutin),HL
	PUSH	DE	;ED contains the new, BC the old
	LD	A,B	;enable old page on page1
	CALL	SETPAGE1_DOS2
	LD	A,C
	LD	H,#40
	CALL	SLOT
	POP	BC	;enable new ones on page2
	LD	A,B
	CALL	SETPAGE2_DOS2
	LD	A,C
	LD	H,#80
	CALL	SLOT
	LD	HL,#4000
	LD	DE,#8000
	ld	b,h	;1byte gain (LD BC,#4000)
	ld	c,l
	LDIR
	LD	HL,(slotsubroutin)
	LD	A,H
	CALL	SETPAGE1_DOS2
	LD	A,L
	LD	H,#40
	CALL	SLOT
	LD	HL,(slothoofdp)
	PUSH	HL
	LD	A,H
	CALL	SETPAGE2_DOS2
	LD	A,L
	LD	H,#80
	CALL	SLOT
	POP	HL
	JP	#8000+_moveprog
_moveprog	DI
	LD	A,H
	LD	(hook_blok-hook+hookadres),A
	call	SETPAGE0_DOS2
	LD	A,L
	LD	(hook_slot-hook+hookadres),A
	LD	(oudslot+#8000),A
	jp	#8000+set_slot_p0
testmove	ld	a,h
	cp	b
	ret	nz
	ld	a,l
	cp	c
	ret	nz
	ld	h,d
	ld	l,e
	ret

;----- enter name
Nameadres:	defw	0
Posname:	defb	0

inputname	push	af
	ld	hl,fcb_work+1
	ld	de,buffer1024
	ld	b,11
_inputloop1	ld	a,(hl)
	ld	(hl)," "
	inc	hl
	ld	(de),a
	inc	de
	djnz	_inputloop1
	ld	hl,#3e18
	ld	b,14
	call	SETBALK
	xor	a
	ld	(cursoronoff),a
	ld	ix,Posname
	ld	(ix),1
	pop	af
	jr	input_char
inputhoofd	call	_prtfilenaam
	ld	a,(ix)
	cp	9
	jr	c,_inputhoofd1
	inc	a
_inputhoofd1	add	a,#3f
	ld	h,a
	ld	l,#19
	ld	(cursory_x),hl
	push	ix
	call	GETKEY
	pop	ix
	cp	27
	jp	z,quitinput
	cp	13
	jp	z,_input_ret
	cp	8
	jr	z,_input_bs
	cp	"."
	jp	z,_input_punt
	cp	" "+1
	jr	c,inputhoofd
input_char	ld	hl,Foutchar
	ld	b,14
_input_char1	cp	(hl)
	jr	z,inputhoofd
	inc	hl
	djnz	_input_char1
	cp	128
	jr	nc,inputhoofd
	cp	"a"
	jr	c,_input_char2
	cp	"z"+1
	jr	nc,_input_char2
	and	%11011111
_input_char2:	ld	c,(ix)
	dec	c
	ld	b,0
	ld	hl,fcb_work+1
	add	hl,bc
	ld	(hl),a
	ld	a,(ix)
	cp	11
	jp	z,_quitinput1
	inc	(ix)
	jp	inputhoofd
Foutchar:	defb	34,",/\[];:'+*?()"

_input_bs	ld	hl,fcb_work+1
	ld	c,(ix)
	dec	c
	jp	z,inputhoofd
	dec	c
	ld	b,0
	add	hl,bc
	ld	(hl)," "
_input_bs1:	ld	a,(ix)
	cp	1
	jp	z,inputhoofd
	cp	10
	jr	z,_input_bs2
	dec	(ix)
	dec	hl
	ld	a,(hl)
	cp	" "
	jr	z,_input_bs1
	jp	inputhoofd
_input_bs2:	ld	(ix),9
	jp	inputhoofd
_input_punt	ld	a,(ix)
	cp	9
	jp	nc,inputhoofd
	ld	(ix),9
	jp	inputhoofd
_input_ret	ld	a,(ix)
	cp	1
	jr	nz,_quitinput1
quitinput	ld	hl,buffer1024
	ld	de,fcb_work+1
	ld	bc,11
	ldir
_quitinput1	call	beradrname
	jr	c,_quitinput2
	ld	hl,fcb_work+1
	ld	bc,11
	ldir		;filename to FCB
	call	jon2
	call	prtfilenaam
_quitinput2	ld	a,1
	ld	(cursoronoff),a
	ld	hl,#3e18
	ld	b,14
	call	WISBALK
	jp	diskhoofdprt

;------ special errors
Errors:	defw	Protected,Offline,Ioerror,Ioerror,Ioerror,Writeerror
	defw	Ioerror,Ioerror
Protected:	defb	"Write protected !",0
Offline:	defb	" Disk offline !",0
Writeerror:	defb	"  Write error !",0
Ioerror:	defb	"Disk I/O error !",0
Abortretry:	defb	"Abort or retry ? (a/r)",0

olderroradres	defw	0
Specialerror	defw	Specialerr1
Sp_disk	defw	0

Specialerr1	push	hl
	push	de
	push	bc
	ld	a,(Asmbusy)
	or	a
	call	z,inidir	;screen blank
	pop	bc
	push	bc
	ld	a,c
	and	%00001110
	ld	e,a
	ld	d,0
	ld	hl,Errors
	add	hl,de
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	a,(Asmbusy)
	or	a
	ld	hl,12*80+(80-17)/2
	jr	z,_specialer1
	ld	hl,18*80+(80-17)/2
_specialer1	push	hl
	call	PRINTTEKST
	ld	bc,Abortretry
	pop	hl
	ld	de,2*80-2
	add	hl,de
	call	PRINTTEKST	;abort or retry
	call	beep
	call	GETKEY
	push	af
	ld	a,(Asmbusy)
	or	a
	call	z,inidir
	ld	hl,18*80
	ld	b,3
	call	inidircont	;LEAVE IT !
	pop	af
	and	%11011111
	jr	z,_retry
	cp	"R"
	jr	z,_retry
	ld	hl,#ffff
	ld	(oudslot),hl
	ld	(oudslot+2),hl
	ld	bc,(Oldsubrouti)
	call	zetslot
	pop	bc
	ld	a,c
	and	%00001100
	ld	de,fcb_work
	ld	c,#10
	call	nz,bdos	;close file (not with offline/protected)
	ld	sp,(Sp_disk)
	jp	diskerrcont
_retry:	pop	bc
	pop	de
	pop	hl
	ld	c,1
	ret

printhok	LD	B,(IX)
	dec	b
	inc	ix
	inc	ix
	inc	ix
	push	bc
	call	printlinehok
	call	printlinehok
	pop	bc
	ld	a,b
	or	a
	jr	z,_printhok2
_printhok1	push	bc
	push	iy
	call	printlinehok
	pop	iy
	pop	bc
	djnz	_printhok1
_printhok2	ld	iy,Menuhokcont
	call	printlinehok
printlinehok	call	SETVRAMWRITE
	ld	de,80
	add	hl,de
_printlineh2:	ld	a,(iy)
	inc	iy
	or	a
	ret	z
	ld	b,a
	ld	a,(iy)
	inc	iy
	or	a
	jr	z,_printhoktxt
_printlineh1:	nop
	nop
	out	(#98),a
	djnz	_printlineh1
	jr	_printlineh2
_printhoktxt	ld	a,b
	cp	3
	ld	a,0
	jr	c,_printlineh1	;anyway huh
	ld	a,0
	out	(#98),a
	ld	a,0
	out	(#98),a
	dec	b
	dec	b
	dec	b
	dec	b
_printhoktx1:	ld	a,(ix)
	inc	ix
	out	(#98),a
	djnz	_printhoktx1
	ld	a,0
	out	(#98),a
	ld	a,0
	out	(#98),a
	jr	_printlineh2

Menuhok	defb	1,24,0,23,1,25,0	;above
	defb	1,22,0, 0,1,20,1,23,1,25,0	;1st line
	defb	1,22,0, 0,1,22,1,0,1,22,0	;middle part
Menuhokcont	defb	1,26,1,23,1,18,0,23,1,27,1,0,1,22,0	;1st under menu
	defb	2,0,1,26, 0,23,1,27,0
printmemview	ld	ix,#fcc1
	ld	iy,Doelhokken
	ld	b,4
_memview3	push	bc
	ld	a,4+"0"
	sub	b
	ld	(Primairslot),a
	ld	l,(iy)
	ld	h,(iy+1)	;target ask
	bit	7,(ix)
	ld	b,4
	jr	nz,_memview1
	ld	b,1
_memview1	push	bc
	push	hl
	call	printslot
	pop	hl
	push	hl
	ld	de,#1819
	call	onelinehok
	ld	b,3
_memview2:	push	bc
	ld	de,#1616
	call	onelinehok
	ld	de,#1413
	call	onelinehok
	pop	bc
	djnz	_memview2
	ld	de,#1616
	call	onelinehok
	ld	de,#1a1b
	call	onelinehok
	pop	hl
	ld	de,9
	add	hl,de
	pop	bc
	djnz	_memview1	;print all subslots (1 or 4)
	inc	iy
	inc	iy
	inc	ix
	pop	bc
	djnz	_memview3	;all primary slots
	ld	hl,4*80+37
	ld	b,2
_memviewget1	push	bc
	ld	ix,Memviewtxt1
	ld	b,5
_memviewget2	push	bc
	push	hl
	ld	e,(ix)
	inc	ix
	ld	d,(ix)
	inc	ix
	ld	b,4
	call	PRINTHEXADECI
	pop	hl
	ld	de,160
	add	hl,de
	pop	bc
	djnz	_memviewget2
	ld	de,80
	add	hl,de
	pop	bc
	djnz	_memviewget1
	ret
Memviewtxt1	defw	0,#4000,#8000,#c000,#ffff
vultabelin	ld	ix,tab_ROMRAM
	ld	iy,Memadressen
	ld	b,4
_vultabel1	push	bc
	ld	l,(iy)
	inc	iy
	ld	h,(iy)
	inc	iy
	ld	b,4
_vultabel3	push	bc
	push	hl
	push	ix
	ld	de,0
	ld	(Grootteram),de
	ld	b,3
_vultabel2	push	bc
	push	hl
	ld	a,(ix)
	or	a
	jr	z,_leeg
	dec	a
	jr	z,_rom
	ld	a,(ix+1)
	or	a
	jr	nz,mapper
	ex	de,hl
	ld	hl,(Grootteram)
	ld	bc,16
	add	hl,bc
	ld	(Grootteram),hl
	ex	de,hl
	ld	bc,Ram
	jr	_ram
mapper	ld	a,b
	cp	2
	ld	bc,Ram
	jr	nz,_ram	;Ram, .... kB, Ram, Ram
	ex	de,hl
	ld	l,(ix+1)
	ld	h,0
	inc	hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl	;*16
	ld	(Grootteram),hl
	ex	de,hl
	ld	b,4+128
	call	PRINTDECIMAAL
	ld	a,"k"
	out	(#98),a
	nop
	nop		;Z80 !
	ld	a,"B"
	out	(#98),a
	jr	_leeg
_rom	ld	bc,Rom
_ram	call	PRINTTEKST
_leeg:	ld	de,16*2
	add	ix,de
	pop	hl
	ld	de,160
	add	hl,de
	pop	bc
	djnz	_vultabel2
	push	hl
	ld	hl,-48
	ld	de,(Grootteram)
	add	hl,de
	ld	bc,Ram
	pop	hl
	call	c,PRINTTEKST	;also Ram in page 3 if there is >=48kB
	pop	ix
	inc	ix
	inc	ix
	pop	hl
	ld	de,9
	add	hl,de
	pop	bc
	dec	b
	jp	nz,_vultabel3
	pop	bc
	dec	b
	jp	nz,_vultabel1
	ret
Rom:	defb	" Rom  ",0
Ram:	defb	" Ram  ",0
Memadressen:	defw	5*80+2,5*80+46,16*80+2,16*80+46
Grootteram:	defw	0
vulrestin	ld	a,(#faf8)
	ld	c,0
	ld	hl,Memviewtxt3
	call	printinblok	;Sub-rom in page 0
	ld	ix,#fb21
	ld	b,4
_nextdiskrom:	push	bc
	ld	a,(ix+1)
	or	a
	jr	z,_nextdromtst
	ld	c,1
	ld	hl,Memviewtxt4
	call	printinblok	;Disk ROM in page 1
	ld	a,(ix)
	add	a,"0"
	out	(#98),a
_nextdromtst:	pop	bc
	inc	ix
	inc	ix
	djnz	_nextdiskrom
	ld	hl,#401c
	ld	de,Opll
	call	zoekinmem
	ld	hl,Memviewtxt5
	ld	a,c
	ld	c,1
	call	nc,printinblok	;Music in page 1
	ld	hl,#4010
	ld	de,Musicbox
	call	zoekinmem
	ld	hl,Memviewtxt6
	ld	a,c
	ld	c,1
	push	af
	push	hl
	call	nc,printinblok	;Audio in page 1
	pop	hl
	pop	af
	ld	c,2
	call	nc,printinblok	;Audio in page 2
	ret
Memviewtxt3:	defb	"Sub-rom",0
Memviewtxt4:	defb	"D-rom:",0
Memviewtxt5:	defb	" Music",0
Memviewtxt6:	defb	" Audio",0
zoekinmem	ld	c,#80
	ld	b,16
_nextcomp1:	push	hl
	push	de
_nextcomp:	ld	a,(de)
	or	a
	jr	z,_foundit
	ld	a,c
	push	bc
	push	de
	call	#0c
	pop	de
	pop	bc
	ex	de,hl
	cp	(hl)
	ex	de,hl
	inc	hl
	inc	de
	jr	z,_nextcomp
	pop	de
	pop	hl
	inc	c
	djnz	_nextcomp1
	scf
	ret
_foundit	pop	de
	pop	hl
	ret
Opll:	defb	"OPLL",0
Musicbox:	defb	"MUSICBOX",0
;---- IN: A=slot, C=page, HL=text
printinblok	push	hl
	ld	b,c
	inc	b
	ld	hl,5*80+1-160-9
	ld	de,160
_printinblk1:	add	hl,de
	djnz	_printinblk1
	bit	0,a
	jr	z,_printinblk2	;in front at slot 0 and 2
	ld	de,44
	add	hl,de
_printinblk2:	bit	1,a
	jr	z,_printinblk4	;at the top at slot 0 and 1
	ld	de,11*80
	add	hl,de
_printinblk4:	and	%1100
	srl	a
	srl	a
	ld	b,a
	inc	b
	ld	de,9
_printinblk3:	add	hl,de
	djnz	_printinblk3
	pop	bc
	jp	PRINTTEKST
printslot	ld	de,3
	add	hl,de
	bit	7,(ix)
	jr	nz,_printprse
	inc	hl
	ld	a,(Primairslot)
	jp	WRITEVRAM
_printprse:	ld	a,(Primairslot)
	call	WRITEVRAM
	ld	a,"-"
	out	(#98),a
	ld	a,4+"0"
	sub	b
	out	(#98),a
	ret
Primairslot:	defb	0
onelinehok	ld	bc,80
	add	hl,bc
	call	SETVRAMWRITE
	ld	a,d
	out	(#98),a
	cp	22
	ld	a,23
	ld	b,7
	jr	nz,_onelinehok1
	xor	a
_onelinehok1:	out	(#98),a
	nop
	nop
	djnz	_onelinehok1
	ld	a,e
	out	(#98),a
	ret
Doelhokken:	defw	3*80,3*80+44,14*80,14*80+44

;********************** MOUSE CONTROL*************************************
mseprt	equ	#fc82	;mouse port number, 0=not found
OFFSET	LD	A,B	;mouse offsets
	LD	(MAXOFF),A
	SRL	A
	LD	(OFFST),A
	LD	A,C
	LD	(MAXOF1),A
	SRL	A
	LD	(OFFS1),A
	RET
rdmous	LD	A,(mouse)
	OR	A
	RET	Z
	DI
	CALL	fill_delay	;enter correct delay address in getpadrout
	LD	A,#10	;input1,pin8input1 high,pin8ing2low
	LD	(mseprt),A
	CALL	chms0
	JR	NC,found
	LD	A,#60	;input2,pin8input2 high,pin8ing1low
	LD	(mseprt),A
	CALL	chms0
	RET	C	;no mouse connected
found	PUSH	IX
	LD	A,(stat_getkey)	;1=check mouse fire buttons only
	OR	A
	JR	Z,_found
	LD	A,(trgflg)
	AND	#50	;get 1st fire buttons port1 and port2
	CP	#50	;1 of the two pressed?
	JR	Z,no_fire1	;no, neither of them pressed
_found	PUSH	HL	;save mouse offsets
	LD	IX,OFFSTX
	LD	A,L
	LD	DE,28*256+29
	CALL	count	;put L/R characters in keybuffer
	POP	HL
	INC	IX
	INC	IX
	INC	IX
	LD	A,H
	LD	DE,31*256+30
	CALL	count	;put U/D characters in keybuffer
no_fire1	ld	ix,frfake
	CALL	fire1
	CALL	fire2
	POP	IX
	RET
fire1	LD	A,(fr1)
	LD	B,A
	ld	a,(trgflg)
	AND	#50
	CP	B
	RET	Z	;yes, still the same position
	LD	(fr1),A
	CP	#50
	RET	Z	;fire button1 not pushed
	LD	D,#00	;put character zero in keybuf
_fire1	LD	B,#01
	JP	cntend
fr1	db	0
fire2	LD	A,(fr2)
	LD	B,A
	LD	A,(trgflg)
	AND	#A0
	CP	B
	RET	Z
	LD	(fr2),A
	CP	#A0
	RET	Z
	LD	D,#01	;put character 1 in keyboard buffer
	JR	_fire1
fr2	db	0
frfake	db	0,0,1
chms0	ld	b,8	;check 8 times
chms1	CALL	getpad
	LD	A,H
	CP	#01
	JR	NZ,chms2
	LD	A,L
	CP	#01
	JR	NZ,chms2
	DJNZ	chms1
	SCF
	RET
chms2	AND	A	;clear carry
	RET

count	BIT	7,A	;offset negative?
	JR	NZ,_cntdown
	ADD	A,(IX+#00)
	LD	B,A
	AND	#07
	LD	(IX+#00),A	;save the remaining pixels
	SRL	B
	SRL	B
	SRL	B
	RET	Z	;number of fully moved courses in B
cntend	LD	HL,(#F3F8)	;this place needs a new sign
cntu_skip	INC	(IX+#01)	;every (ix+2) characters put a byte
	LD	A,(IX+#02)	;in the key buffer
	CP	(IX+#01)	;serves to slow down the mouse a bit
	JR	NZ,skip_ureset
	LD	(IX+#01),#00	;counter back to zero
	LD	A,D
	CALL	putkeybuf
skip_ureset	DJNZ	cntu_skip
	LD	(#F3F8),HL
	RET
putkeybuf	LD	(HL),A
	INC	HL
	LD	A,L
	CP	#18
	RET	NZ
	LD	HL,#FBF0
	RET
_cntdown	NEG		;make positive
	LD	L,A	;l=number of pixels to subtract
	LD	A,(IX+#00)
	LD	H,A	;h and a=number of remaining pixels
	SUB	L	;calculate new number of remaining pixels
	AND	#07
	LD	(IX+#00),A	;and save
	LD	A,#07	;number of pixels for calculation
	SUB	H
	ADD	A,L
	SRL	A
	SRL	A
	SRL	A
	RET	Z
	LD	B,A
	LD	HL,(#F3F8)
cntd_skip	DEC	(IX+#01)
	BIT	7,(IX+#01)
	JR	Z,skip_dreset
	LD	A,(IX+#02)
	DEC	A
	LD	(IX+#01),A
	LD	A,E
	CALL	putkeybuf
skip_dreset	DJNZ	cntd_skip
	LD	(#F3F8),HL
	RET

OFFSTX	db	0
OFFST	db	0
MAXOFF	db	1
OFFSTY	db	0
OFFS1	db	0
MAXOF1	db	1

;get paddle data offsets:out: HL #yyxx offsets  in: mseprt
getpad	PUSH	BC
	PUSH	DE
	LD	DE,(mseprt)
	LD	A,#0F	;read psg r15 port B
	OUT	(#A0),A
	NOP
	NOP
	IN	A,(#A2)
	AND	#8F
	OR	E
	LD	E,A	;byte to write in E
	LD	B,40	;delay z80
	LD	C,20	;delay r800
	CALL	gpad2	;get top 4 bits
	CALL	gpad0	;get bottom 4 bits and put everything in A
	LD	L,A	;xoffset
	CALL	gpad1	;get the top 4 bits right away
	CALL	gpad0	;get the lower 4 bits right away
	LD	H,A	;yoffset
	POP	DE
	POP	BC
	RET
gpad0	RLCA		;do read value *16
	RLCA
	RLCA
	RLCA
	LD	D,A
	CALL	gpad1	;read bottom mouse bits directly
	OR	D
	NEG		;correct
	RET
gpad1	LD	BC,#0708	;short delay
gpad2	LD	A,#0F
	OUT	(#A0),A
	LD	A,E
	OUT	(#A1),A
	LD	A,(mseprt)
	AND	#30	;get input: #20=2 #10=1
	XOR	E	;invert the pin8bit
	LD	E,A
invul_delay	CALL	0
	LD	A,#0E
	OUT	(#A0),A
	NOP
	NOP
	IN	A,(#A2)
	AND	#0F
	RET
delay_Z80	DJNZ	delay_Z80
	RET
delay_R800	IN	A,(#E6)	;get lowbyte TurboR system timer
	LD	B,A
_delay_R800	IN	A,(#E6)
	SUB	B	;how much is the counter already higher?
	CP	C	;even less than we need?
	JR	C,_delay_R800	;yes, still waiting
	RET
fill_delay	LD	HL,delay_Z80
	LD	A,(msxtype)
	CP	#03
	JR	C,_fill_delay
	LD	A,#06	;??????????????
	OUT	(#E4),A
	IN	A,(#E5)
	CP	#60
	JR	Z,_fill_delay
	LD	HL,delay_R800
_fill_delay	LD	(invul_delay+1),HL
	RET

janeetoetsen	LD	A,(msxtype)	;only turboR
	CP	#03
	RET	NZ
	DI
	IN	A,(#AA)	;put row number 11
	AND	#F0
	OR	#0B
	NOP
	OUT	(#AA),A
	NOP
	NOP
	IN	A,(#A9)	;read row
	CPL
	AND	#0A
	ret	z	;neither yes nor no
	ld	b,#80
	bit	3,a
	jr	nz,zetcpu	;no test
	inc	b	;yes test
zetcpu	ld	a,b
	PUSH	IX
	LD	IX,#0180
	CALL	gobios
	POP	IX
	RET
hertztoetsen	LD	A,(matrix+6)
	AND	#02
	RET	NZ	;ctrl not pressed
	LD	A,(matrix)
	RLCA
	RLCA
	LD	B,#80
	JR	NC,zetspeed	;6key pressed
	RLCA
	RET	C	;5key not pressed
	LD	B,#82
zetspeed	DI
	LD	A,(#FFE8)	;read vdp10
	AND	#7D
	OR	B	;set bit 2 sorted, bit7 high (212)
	LD	(#FFE8),A	;write away
	OUT	(#99),A
	LD	A,#89
	OUT	(#99),A
	JP	WISKEYBUFFER

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

tab_memtabel
textbuffer1	ds	33,0
databuffer1	ds	13,0
textbuffer2	ds	33,0
databuffer2	ds	13,0
textbuffer3	ds	33,0
databuffer3	ds	13,0
textbuffer4	ds	33,0
databuffer4	ds	13,0
labelbuffer	ds	9,0

;**************************************************************************
;everything from here will be erased (one time use routines on startup)
buffer1024

hook	jr	hookcontinue
hook_slot	db	0
hook_blok	db	0
cmd_id	db	"COMPASS",0	;ID
hook_tab_tpa	db	0,0,0,0	;is filled in by start compass
tab_tpa	equ	hook_tab_tpa-hook+hookadres
hook_tab_cur	db	0,0,0,0	;idem
current_p0	equ	hook_tab_cur-hook+hookadres
current_p1	equ	hook_tab_cur-hook+hookadres+1
current_p2	equ	hook_tab_cur-hook+hookadres+2
current_p3	equ	hook_tab_cur-hook+hookadres+3
hookcontinue	LD	B,A
	LD	A,(matrix+6)
	AND	#01
	JR	NZ,hook_notkey
	LD	A,(matrix+7)
	AND	#04
	jr	nz,hook_notkey
	ld	a,(ctngcode)
	rrca
	jr	c,hook_hoofd
hook_notkey	LD	A,B
orighookchget	ds	5,0
hook_hoofd	LD	A,(hook_slot-hook+hookadres)
	PUSH	AF
	LD	H,#80
	CALL	#0024
	LD	A,(hook_blok-hook+hookadres)
	call	SETPAGE2_DOS2	;correct block number
	call	SETPAGE0_DOS2
	POP	AF
	CALL	#8000+set_slot_p0
	JP	shellentry
cmd	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	DEC	HL
	LD	DE,cmd_id-hook+hookadres
test_cmd	LD	A,(DE)
	INC	DE
	OR	A
	JR	Z,end_test
	LD	B,A
	RST	#10	;get character from command line
	AND	#DF	;change lowercase to uppercase.
	CP	B
	JR	Z,test_cmd
end_test	POP	HL
	POP	DE
	POP	BC
	JR	Z,hook_hoofd	;why isn't it picked up anymore???
	POP	AF	;answer: stack doesn't matter anymore, and so as not to mess flags
orighookcmd	ds	5,0
hook_back	LD	A,(#FCC1)
	LD	H,#00
	CALL	#0024
	LD	A,(tab_tpa+0)
	call	SETPAGE0_DOS2
	LD	HL,hook_feda-hook+hookadres
	LD	(#FEDB),HL
	LD	A,#C3
	LD	(#FEDA),A
	LD	IY,(#F347)
	LD	IX,#4022	;jump to basic
	JP	#001C
hook_feda	LD	A,#C9
	LD	(#FEDA),A
disable_feda	PUSH	HL
	PUSH	BC
	LD	HL,hook_text-hook+hookadres
_hook_feda2	LD	A,(HL)
	INC	HL
	OR	A
	JR	Z,_hook_feda1
	CALL	#00A2	;chput
	JR	_hook_feda2
_hook_feda1	POP	BC
	POP	HL
	RET
hook_text	db	10,"Press [SHIFT] + [ESC] or type CMD COMPASS "
	db	"to return.",10,0
getpage0_dos2	db	#3a	;ld a,(nn)
fill_getpage0	dw	current_p0	;under dos2:f2c7
	RET
GETPAGE0_DOS2	equ	getpage0_dos2-hook+hookadres
getpage1_dos2	db	#3a
fill_getpage1	dw	current_p1	;under dos2:f2c8
	RET
GETPAGE1_DOS2	equ	getpage1_dos2-hook+hookadres
getpage2_dos2	db	#3a
fill_getpage2	dw	current_p2	;under dos2:f2c9
	RET
GETPAGE2_DOS2	equ	getpage2_dos2-hook+hookadres
setpage0_dos2	db	#32	;ld (nn),a
fill_setpage0	dw	current_p0	;under dos2:f2c7
	OUT	(#FC),A
	RET
SETPAGE0_DOS2	equ	setpage0_dos2-hook+hookadres
setpage1_dos2	db	#32
fill_setpage1	dw	current_p1	;under dos2:f2c8
	OUT	(#FD),A
	RET
SETPAGE1_DOS2	equ	setpage1_dos2-hook+hookadres
setpage2_dos2	db	#32
fill_setpage2	dw	current_p2	;under dos2:f2c9
	OUT	(#FE),A
	RET
SETPAGE2_DOS2	equ	setpage2_dos2-hook+hookadres
hook_end

fill_inst	LD	A,(kbuf)	;virgin version?
	OR	A
	RET	Z
	LD	A,(kbuf+#104)	;no, get installations
	LD	(Backuponoff),A	;save backup status
	ld	a,(kbuf+1)	;was there a search mem done in the COM?
	or	a
	jr	z,work_default	;if so don't install the saved one
	LD	HL,kbuf+#cb	;memory setting (use default)
	LD	DE,tab_memory	;the default is filled in by
	LD	BC,8	;starting compass
	LDIR
work_default	LD	HL,(kbuf+#ec)	;palettebytes color 0,(0)
	LD	(color),HL
	LD	HL,(kbuf+#ee)	;palettebytes color 1,(15)
	LD	(color+30),HL
	LD	HL,(kbuf+#f0)	;palettebytes color 2,(3)
	LD	(color+6),HL
	LD	HL,(kbuf+#f2)	;palettebytes color 3,(2)
	LD	(color+4),HL
	CALL	setcolors
	LD	HL,kbuf+#d3	;idhex,idbin,mouse,clipper
	LD	DE,tab_inst
	LD	BC,tab_inst_end-tab_inst
	LDIR
	LD	BC,(slotdebugger)
	CALL	zetslot
	JP	SETDEBPARS

bios	JP	SETVRAMWRITE	;080
	JP	SETVRAMREAD	;083
	JP	RAMTOVRAM	;086
	JP	FILLVRAM	;089
	JP	WISBLINKTABEL	;08c
	JP	CLS	;08f
	JP	PRINTTEKST	;092
	JP	SETCOLOR1	;095
	JP	SETCOLOR2	;098
	JP	PRINTDECIMAAL	;09b
	JP	PRINTHEXADECI	;09e
	JP	PRINTBINAIR	;0a1
	JP	SETBALK	;0a4
	JP	WISBALK	;0a7
	JP	WRITEVRAM	;0aa
	JP	READVRAM	;0ad
	JP	GETFROMRAM	;0b0
	JP	PUTTORAM	;0b3
	JP	GODISKDRIVE	;0b6
	JP	PRINTBLOK	;0b9
	JP	TEXTTOBLOK	;0bc
	JP	INPUTTEXT	;0bf
	JP	CLOSEFILE	;0c2
	JP	PRINTMENU	;0c5
	JP	KIESOPTIE	;0c8
	JP	WISOUDMENU	;0cb
	JP	BERGETALASM	;0ce
	JP	BEREKENGETAL	;0d1
	JP	MEMVIEW	;0d4
	JP	CALCULATOR	;0d7
	JP	MEMORY	;0da
	JP	PRINTBLOKKLEI	;0dd
	JP	STARTPROGRAM	;0e0
	JP	VRAMTORAM	;0e3
	JP	OLDSCREEN	;0e6
	JP	SCREENCOMPASS	;0e9
	JP	MOVEPROG	;0ec
	JP	MAININSTALL	;0ef       newbinid
	JP	GOTOEDITOR	;0f2
	JP	GOTOASS	;0f5
	JP	SLOT	;0f8
	JP	GETKEY	;0fb
	JP	OFFSET	;0fe
	JP	WISKEYBUFFER	;101
	JP	PUSHANYKEY	;104
	JP	PRINTINI	;107
	JP	WAITFORKEY	;10a
	JP	LINETOASSEMB	;10d
	JP	GETREGISTERS	;110
	JP	GOTODEBUGGER	;113
	JP	MAININSTALL	;116
	JP	GETPAGES	;119
	JP	DOINCLUDE	;11c
	JP	SAVEINSTALL	;11f
	JP	GETPAGE0_DOS2
	JP	SETPAGE0_DOS2
	JP	GETPAGE1_DOS2
	JP	SETPAGE1_DOS2
	JP	GETPAGE2_DOS2
	JP	SETPAGE2_DOS2
	JP	GETKEY2
endbios

startcompass	di
	ld	(#8000+si_place1),hl
	ld	(#8000+si_place2),hl
	ld	(#8000+si_lenght),bc
	ld	a,e
	ld	(#8000+dosversion),a
	ld	a,d
	ld	(#8000+stat_mem),a
	ld	hl,-512
	add	hl,sp
	ld	(#8000+reg_sp),hl
	LD	HL,#8000+hook
	LD	DE,hookadres
	LD	BC,hook_end-hook
	LDIR
	LD	HL,#C000	;ROMRAMtable
	LD	DE,#8000+tab_ROMRAM
	LD	BC,#60
	LDIR
	LD	DE,#8000+tab_memtabel	;mem_table
	LD	BC,#C1
	LDIR
	LD	DE,#8000+tab_compass	;compass blocks
	LD	BC,8
	LDIR
	ld	de,tab_tpa
	ld	bc,4
	ldir
	LD	A,(#8000+slothoofdp)	;get slot code
	LD	(hook_slot-hook+hookadres),A
	LD	H,#00
	CALL	#0024
	LD	A,(#8000+slothoofdp+1)	;get block num
	LD	(hook_blok-hook+hookadres),A
	ld	(current_p0),a
	OUT	(#FC),A
	;from now on no more +#8000 needed
	ld	(current_p2),a
	ld	a,(tab_tpa+3)
	ld	(current_p3),a
	ld	a,(tab_compass+7)	;the last loaded segment
	ld	(current_p1),a
	LD	A,(dosversion)
	CP	#02
	jr	c,dos1versie
	ld	hl,current_p0
	ld	de,#f2c7
	ld	bc,4
	ldir
	LD	HL,#F2C7
	LD	(fill_getpage0-hook+hookadres),HL
	LD	(fill_setpage0-hook+hookadres),HL
	INC	L
	LD	(fill_getpage1-hook+hookadres),HL
	LD	(fill_setpage1-hook+hookadres),HL
	INC	L
	LD	(fill_getpage2-hook+hookadres),HL
	LD	(fill_setpage2-hook+hookadres),HL
	jr	no_change
dos1versie	ld	hl,(#f349)
	ld	(oldf349),hl
	ld	hl,(#f34b)	;secure dosinterrupt,etc on return to BASIC
	ld	(#f349),hl
	ld	(newf349),hl
no_change	LD	A,(#FCC1)	;put msxtype in our own bios
	LD	HL,msxtype
	CALL	#000C
	LD	(msxtype),A
	CALL	chk_comline	;put filename in vram
	ld	hl,bios
	ld	de,#0080
	ld	bc,endbios-bios
	ldir
	ld	hl,#fcc4
	ld	b,4
	xor	a
_startcompass	or	(hl)	;create special byte for debugger
	rlca		;bit0-3: 1 if corresponding slot is exp
	dec	hl
	djnz	_startcompass
	ld	(debuggerreg),a
	LD	A,(#FCC1)	;set default working memory setting
	LD	(page0),A
	LD	A,(#F344)
	LD	(page1),A
	LD	(page2),A
	ld	(page3deb),a
	LD	(page3),A
	ld	hl,tab_tpa
	ld	a,(hl)
	ld	(page0+1),a
	inc	hl
	ld	a,(hl)
	ld	(page1+1),a
	inc	hl
	ld	a,(hl)
	ld	(page2+1),a
	inc	hl
	ld	a,(hl)
	ld	(page3deb+1),a
	ld	(page3+1),a
	jp	shellentry

	ds	#4000-$,0	;(fill with padding just to be sure)
