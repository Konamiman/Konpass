;Assembly module #1.2.09
;JDS 7/9/1999

;if the msx crashes while assembling it is the ds #7000-$,0
;at the end of the source (the source is then too big)
;either by ds $-free

;contains patch for the INCLUDE issues in monitor segment
patchinclmon	equ	#7ff0

	.label	14
jon_len_code	equ	127	;earlier at 64, 127=max due to (iy+)
jon_len_rel	equ	127	;earlier at 64

bdos:	equ	#f37d
Doubleadres:	equ	#3f40
Kbuf:	equ	#f41f	;318 byte buffer

setvramwrite:	equ	#80
printtekst	equ	#92
printdecimaa:	equ	#9b
printhexadec:	equ	#9e
writevram:	equ	#aa
readvram:	equ	#ad
puttoram:	equ	#b3
texttoblok:	equ	#bc
closefile:	equ	#c2
bergetalasm:	equ	#ce
printblokkle:	equ	#dd
slot:	equ	#f8
wiskeybuffer	equ	#101
gotodebugger:	equ	#113
doinclude:	equ	#11c

Cursoronoff:	equ	#fca9

Commline:	equ	12

Tsr_vram:	equ	#2400	;vram address TSR offsets (also for public)
Ext_vram:	equ	#3000

	org	#4000

	jp	assembledisk	;#4000
	jp	assembleren	;#4003
	jp	labbufvol	;#4006
	jp	prterrlines	;#4009
	jp	testlabel1	;#400c
	jp	geeflabdata	;#400f
	jp	relocatable	;#4012
	jp	asstsr	;#4015

Assembledisk:	defb	0	;leave these 3 in this order
Tsr:	defb	0
Relocatable:	defb	0

;------ Assemble TSR
asstsr:
	ld	(Used_fcb),de
	ld	(Foutadres),iy
	xor	a
	ld	(Veranderd),a
	ld	(Relocatable),a
	ld	(Assembledisk),a
	inc	a
	ld	(Tsr),a
	jr	_relcont
Offsetadres:	defw	0
Tsrhooks:	defb	0
Tsrpass:	defb	0

;------ Relocatable assembly

relocatable:
	ld	(Used_fcb),de
	ld	(Foutadres),iy
	xor	a
	ld	(Veranderd),a
	ld	(Tsr),a
	ld	(Assembledisk),a
	inc	a
	ld	(Relocatable),a
	jr	_relcont

beep:
	push	af
	push	bc
	push	de
	push	hl
	push	ix
	push	iy
	ld	iy,(#fcc0)
	ld	ix,#c0
	call	#1c
	ld	iy,(#fcc0)
	ld	ix,#9f
	call	#1c
	pop	iy
	pop	ix
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

;------ Assemble to disk

assembledisk:
	ld	(Used_fcb),de
	ld	(Foutadres),iy
	xor	a
	ld	(Veranderd),a
	inc	a
	jr	_assembledi1

assembleren:
	xor	a
_assembledi1:
	ld	(Assembledisk),a
	xor	a
	ld	(Relocatable),a
	ld	(Tsr),a
_relcont:
	ld	(Sp_labelasse),sp
	xor	a
	ld	(Tsrpass),a
	ld	a,(Veranderd)
	or	a
	call	nz,GOedit_ret1
	ld	a,1
	ld	(Cursoronoff),a
	ld	a,(Aantallabelb)
	ld	b,a
	ld	ix,Labelbuffers
	call	GO_wisbuffe1	;clear label buffer

	ld	hl,8*80+24
	ld	de,Ass_hok
	call	printblokkle
	ld	hl,Ass_text
	call	texttoblok
	ld	a,(Tsr)
	or	a
	ld	hl,Ass_text1
	call	nz,texttoblok

	xor	a
	ld	(Aantalerrors),a
	inc	a
	ld	(Huidigerror),a
	ld	(Balkerror),a

	ld	hl,11*80+35
	ld	(Okadres),hl

	call	labelassembl

	ld	hl,(Okadres)
	ld	a,(Aantalerrors)
	or	a
	jr	nz,_errorfound
	ld	bc,Ok
	call	printtekst
	ld	hl,12*80+35
nogkeerpass2:
	ld	(Okadres),hl
	call	codeassemble
	ld	sp,(Sp_labelasse)
	ld	hl,(Okadres)
	ld	a,(Aantalerrors)
	or	a
	jr	nz,_errorfound
	ld	bc,Ok
	call	printtekst

	ld	a,(Tsr)
	or	a
	jr	z,_asse1
	ld	a,(Tsrpass)
	or	a
	jr	nz,_asse1
	inc	a
	ld	(Tsrpass),a
	ld	(Assembledisk),a
	ld	hl,(Offsetadres)
	ld	de,Tsr_vram
	or	a
	sbc	hl,de
	ld	(Lengteoffset),hl
	ld	hl,13*80+35
	jr	nogkeerpass2
Lengteoffset:	defw	0
Okadres:	defw	0

_asse1:
	ld	a,(Assembledisk)
	or	a
	jp	nz,patchinclmon	;PATCH to 7ff0 in monitor
	;jp nz,closefile
	ld	hl,Ass_text2
	call	texttoblok
	ld	hl,14*80+35
	ld	de,(Firstorg)
	ld	b,4
	call	printhexadec
	ld	hl,15*80+35
	ld	de,(Assembladres)
	dec	de
	ld	b,4
	call	printhexadec
_pushkeyback	call	GOpushanykey
	call	GOwiscommlin
	jp	GOeditor_con

includeerror:
_errorfound:
_labbufvol:
	ld	a,(Aantalerrors)
	ld	e,a
	ld	d,0
	ld	b,3+128
	dec	a
	ld	a," "
	jr	z,_errorfoun1
	ld	a,"s"
_errorfoun1:	ld	(Error+6),a	;1 error and 0/2 errors
	call	printdecimaa
	ld	h,#80
	ld	bc,Error
	call	printtekst
	LD	SP,(Sp_labelasse)
	LD	HL,Assembledisk
	LD	A,(HL)
	INC	HL
	OR	(HL)
	INC	HL
	OR	(HL)

	jp	nz,patchinclmon	;PATCH for 7ff0 in monitor
	;jp      nz,closefile

	call	GOpushanykey	;3F5E
	call	GOprintscher	;3F73
	jp	GOprinterror	;3F7A

ESCtest	DI
	IN	A,(#AA)
	AND	#F0
	ADD	A,#07
	OUT	(#AA),A
	NOP
	IN	A,(#A9)
	AND	#04
	RET	NZ
_ESCtest	IN	A,(#AA)
	AND	#F0
	ADD	A,#07
	OUT	(#AA),A
	NOP
	IN	A,(#A9)
	AND	#04
	JR	Z,_ESCtest
	CALL	wiskeybuffer
	LD	SP,(Sp_labelasse)
	LD	HL,(Okadres)
	LD	BC,txt_aborted
	CALL	printtekst
	LD	HL,Assembledisk
	LD	A,(HL)
	INC	HL
	OR	(HL)
	INC	HL
	OR	(HL)
	jp	nz,patchinclmon	;PATCH for 7ff0 in monitor
	;JP      NZ,closefile
	JR	_pushkeyback

Ok:	defb	"Ok",0
Error:	defb	" errors found !",0
txt_aborted	db	"Aborted",0

Ass_hok:	defw	Hk1,Hk2,Hk2,Hk2,Hk2,Hk2,Hk2,Hk2,Hk3,0
Hk1:	defb	1,24,30,23,1,25,0
Hk2:	defb	1,22,30,0,1,22,0
Hk3:	defb	1,26,30,23,1,27,0
Ass_text:	defw	9*80+(80-8)/2
	defb	"Assemble",0
	defw	11*80+27
	defb	"Pass 1:",0
	defw	12*80+27
	defb	"Pass 2:",0
	defw	0
Ass_text1:	defw	13*80+27
	defb	"Pass 3:",0
	defw	0
Ass_text2:
	defw	14*80+27
	defb	"Start:",0
	defw	15*80+27
	defb	"End:",0
	defw	0

;--------------- Define labels and stop in label buffer

labelassembl:
	ld	hl,Labels1
	ld	de,Labels1+1
	ld	bc,26*3+1*3-1
	ld	(hl),0
	ldir
	ld	hl,#8000
	ld	(Eindlabadres),hl
	xor	a
	ld	(Firstbp),a
	ld	(Macro),a
	ld	(Domacro),a
	ld	(Huidigmacro),a
	ld	(Csegcomm),a
	ld	(Dsegcomm),a
	ld	(Phase),a
	LD	(D5DBD),A	;presumably, check it**********

	inc	a
	ld	(Eindlabblok),a
	ld	(Segment),a	;start segment = CSEG
	ld	hl,0
	ld	(Turborcomm),hl
	ld	(Aantallabels),hl
	ld	(Sym_waarde),hl
	ld	(Cseg),hl
	ld	(Dseg),hl
	ld	(Aseg),hl
	ld	(Firstcseg),hl
	ld	(Firstdseg),hl
	ld	hl,#0100
	ld	(Assembladres),hl	;assemble on #0100
	call	setif_ini
	ld	hl,#1910	;***********************************
	ld	(Erroradres),hl	;target in vram for errors
	ld	hl,#1c00	;************************************
	ld	(Macro_opslag),hl	;target in vram for macros
	ld	a,(Tsr)
	or	a
	jr	z,_labelass1
	ld	hl,#4000
	ld	(Assembladres),hl
	xor	a
	ld	(Tsrhooks),a
	inc	a
	ld	(Segment),a	;CSEG

_labelass1:
	ld	a,(Relocatable)
	or	a
	jr	z,_labelass2
	ld	hl,Tsr_vram	;#2400***************     ********
	ld	(Publicadres),hl
	ld	hl,Ext_vram	;#3000************************
	ld	(Externadres),hl
	ld	hl,0
	ld	(Aantalpublic),hl
	ld	(Aantalextern),hl
	ld	(Assembladres),hl

_labelass2:
	ld	hl,0
	ld	(Aantalused),hl
	ld	(Aantalused+2),hl
	call	includeinit
_nextlabelas:
	xor	a
	ld	(Equ_found),a
	ld	(Ass_error),a
	inc	a
	ld	(Pass),a
	CALL	ESCtest
	ld	de,(Assemblregel)
	call	geefadrregel
	jp	c,end_found
	call	zettextblok
	call	zinassembl	;get sentence and split
	jp	c,end_found	;end of text (after macro)

	ld	hl,Label
	ld	a,(hl)
	or	a
	jr	z,_nolabel
	cp	"*"
	jp	z,_ass_error	;ignore "*" from gen80 !

	call	welassembl
	jr	c,_nolabel	;no code because of if
	call	putlabel
	ld	(Labeladres),hl
	ld	(Labelblok),a
	ld	(Labeladrdoel),de
	ld	a,b
	ld	(Labelblkdoel),a
	call	c,labelbestond	;label already existed
	ld	a,(Ass_error)
	or	a
	jr	nz,_ass_error	;error with labels
	ld	hl,(Aantallabels)
	inc	hl
	ld	(Aantallabels),hl
_nolabel:
	ld	a,(Macro)
	push	af
	call	assemble	;assemble 1 line
	pop	bc
	ld	a,(Macro)
	ld	c,a
	or	b
	jr	z,_nomacro
	ld	a,c
	cp	b	;Do not enter "MACRO" and "ENDM"
	call	z,vulmacroin
	ld	a,(Macro)
	or	a
	jr	nz,_ass_error

_nomacro:
	ld	a,(Endcode)
	or	a
	jp	nz,end_found	;"END" found"
	ld	a,(Ass_error)
	or	a
	jp	nz,_noequ	;ass_error    ;ERROR !

	call	welassembl
	jp	c,_ass_error	;no code because of if
	ld	a,(Equ_found)
	or	a
	jr	z,_noequ

	ld	a,(Labelblkdoel)
	call	zetlabblok
	ld	de,(Labeladrdoel)
	ld	hl,(Equ_adres)
	ld	a,l
	call	putlabbuffer
	ld	a,h
	call	putlabbuffer
	ld	a,(Equ_segment)
	and	%11000000
	cp	%11000000
	jr	nz,_welequ1
	ld	a,%01000000	;if both => CSEG
_welequ1:
	call	putlabbuffer	;type=0 & ABS/CSEG/DSEG
_noequ:
	ld	a,(Lengtecode)
	or	a
	jr	z,_ass_error
	push	af
	ld	a,(Relocatable)
	or	a
	call	nz,Setfirst
	pop	af
	cp	#ff
	ld	bc,(Lengte_defs)
	jr	z,_noequ1	;defs
	ld	c,a
	ld	b,0
_noequ1:	ld	hl,(Assembladres)
	add	hl,bc
	ld	(Assembladres),hl
_ass_error:
	ld	a,(Domacro)
	or	a
	jp	nz,_nextlabelas
	ld	hl,(Assemblregel)
	ld	a,l
	inc	hl
	ld	(Assemblregel),hl
	dec	a
	and	%00111111
	jp	nz,_nextlabelas
	ld	a,(Teken+1)
	xor	%10000
	ld	(Teken+1),a
	ld	hl,11*80+35
Teken:	ld	a,"-"
	call	writevram
	jp	_nextlabelas

Setfirst:
	ld	a,(Segment)
	dec	a
	jr	z,_set1stcseg
	dec	a
	ret	nz
_set1stdseg:
	ld	a,(Dsegcomm)
	or	a
	ret	nz
	inc	a
	ld	(Dsegcomm),a
	ld	hl,(Assembladres)
	ld	(Firstdseg),hl
	ret
_set1stcseg:
	ld	a,(Csegcomm)
	or	a
	ret	nz
	inc	a
	ld	(Csegcomm),a
	ld	hl,(Assembladres)
	ld	(Firstcseg),hl
	ret

Labelblok:	defb	0
Labeladres:	defw	0
Labeladrdoel:	defw	0
Labelblkdoel:	defb	0

includeinit	ld	hl,0
	ld	(Bufferopen),hl
	ld	(Bufferopen+2),hl
	xor	a
	ld	(Aantalinclud),a
	ld	hl,Ramincl
	ld	(Includeram),hl
includeini:
	ld	a,(Sourcebuffer)
	call	openadres
;                 ld      a,(hl)
;                 or      a
;                 jp      nz,bufferinuse
	ld	(hl),1
	ld	hl,1	;LEAVE IT
	ld	(Assemblregel),hl	;rule 1
	ret

end_found:
	call	end_foundini
	ret	c
	jp	_nextlabelas

end_foundini:
	ld	a,(Sourcebuffer)
	call	openadres
	ld	(hl),0
	ld	hl,Aantalinclud
	ld	a,(hl)
	or	a
	scf
	ret	z
	dec	(hl)
	ld	hl,(Includeram)
	dec	hl
	ld	a,(hl)
	ld	(Upperonoff),a
	dec	hl
	ld	a,(hl)
	ld	(Labellengte),a
	dec	hl
	ld	d,(hl)
	dec	hl
	ld	e,(hl)
	inc	de
	ld	(Assemblregel),de
	dec	hl
	ld	(Includeram),hl
	ld	a,(hl)
	call	GOsetbuf
	xor	a
	ld	(Endcode),a
	ret

setif_ini:
	ld	hl,Ifs-1
	ld	(If_adres),hl
	ld	de,Ifs
	ld	bc,16
	ld	(hl),0
	ldir
	xor	a
	ld	(If_wacht),a
	ret


welassembl:	;[C]=don't assemble
	push	hl
	ld	hl,(If_adres)
	ld	a,(hl)
	pop	hl
	or	a
	ret	z	;no if
	cp	#81
	ret	z	;do assemble
	scf
	ret

;--------------- Assemble code and send to memory

codeassemble:
	call	saveoldsegm
	ld	hl,(Cseg)
	LD	(Cseglength),HL
	ld	hl,(Dseg)
	ld	de,(Firstdseg)
	or	a
	sbc	hl,de
	ld	(Dseglength),hl

	ld	a,2
	ld	(Pass),a
	xor	a
	ld	(Firstcomm),a
	ld	(Firstbp),a
	ld	(Macro),a
	ld	(Domacro),a
	ld	(Huidigmacro),a
	ld	(Phase),a
	LD	(D5DBD),A
	inc	a
	ld	(Segment),a	;start segment = CSEG
	ld	hl,0
	ld	(Turborcomm),hl
	ld	(Firstorg),hl
	ld	(Sym_waarde),hl
	ld	(Cseg),hl
	ld	(Dseg),hl
	ld	(Aseg),hl
	ld	hl,#0100
	ld	(Tijdelasmadr),hl
	ld	(Assembladres),hl	;assemble on #0100
	ld	hl,(Bufferpage0)
	ld	(Tijdelbuffer),hl
	ld	de,1024
	add	hl,de
	ld	(Eindebuffer),hl
	call	setif_ini
	ld	hl,#1c00	;********************************
	ld	(Macro_opslag),hl	;target in vram for macros
	ld	a,(Tsr)
	or	a
	jr	z,_codeass1
	ld	hl,#4000
	ld	(Assembladres),hl
	ld	hl,Tsr_vram	;#2400*****************
	ld	(Offsetadres),hl
	xor	a
	ld	(Tsrhooks),a
_codeass1:
	ld	a,(Relocatable)
	or	a
	jp	z,_codeass2
	ld	hl,0
	ld	(Assembladres),hl
	ld	a,9
	ld	(Bitinfo),a
	call	speciallink
	ld	a,%0010
	ld	b,4
	call	putbits	;file name
	ld	de,(Used_fcb)
	inc	de
	ld	b,6
	call	putname

	ld	bc,(Aantalpublic)
	inc	bc
	ld	hl,Tsr_vram	;2400**************
_vulpublicin:
	dec	bc
	ld	a,b
	or	c
	jr	z,_setlength
	push	bc
	ld	de,Label
	ld	b,-1	;B=length
_getpublic:
	inc	b
	call	readvram
	inc	hl
	ld	(de),a
	inc	de
	or	a
	jr	nz,_getpublic
	push	hl
	push	bc
	call	speciallink
	ld	a,%0000
	ld	b,4
	call	putbits	;file name
	pop	bc
	ld	a,b
J455D	cp	7	;********************label used?
	jr	c,_vulpublin1
	ld	b,6
_vulpublin1:
	ld	de,Label
	call	putname
	pop	hl
	pop	bc
	jr	_vulpublicin

Dseglength:	defw	0
Cseglength:	defw	0
_setlength:
	call	speciallink
	ld	a,%101000
	ld	b,6
	call	putbits
	ld	de,(Dseglength)
	call	putadres
	call	speciallink
	ld	a,%110101
	ld	b,6
	call	putbits
	ld	de,(Cseglength)
	call	putadres

	call	speciallink
	ld	a,%101101
	ld	b,6
	call	putbits
	ld	de,0
	call	putadres	;loc. counter: #0000+Cseg

_codeass2:
	call	includeinit

_nextcodeass:
	call	ESCtest
	ld	de,(Assemblregel)
	call	geefadrregel
	jp	c,_endcodeass
	call	zettextblok
	call	zinassembl	;get sentence and split
	jp	c,_endcodeass	;end of text (after macro)

	ld	a,(Label)
	cp	"*"
	jp	z,_nocode	;ignore "*" from gen80 !

	call	assemble	;assemble 1 line
	ld	a,(Macro)
	or	a
	jp	nz,_nocode

	ld	a,(Endcode)
	or	a
	jp	nz,_endcodeass	;"END" found
	ld	a,(Ass_error)
	or	a
	jp	nz,_ass_error2	;ERROR !

	ld	a,(Lengtecode)
	or	a
	jr	z,_nocode
	ld	b,a

	ld	a,(Firstcomm)
	or	a
	call	z,set1storg
	call	welassembl
	jr	c,_nocode	;don't assemble because of if

	ld	a,b
	cp	#ff
	jp	z,_do_defs

	ld	a,(Relocatable)
	or	a
	push	af
	call	z,totijdbuffer	;save to temporary buffer
	pop	af
	call	nz,torelbuffer
_ass_error1:
	ld	a,(Lengtecode)
	ld	c,a
	ld	b,0
	ld	hl,(Assembladres)
	add	hl,bc
	ld	(Assembladres),hl

skip_inc_adres	ld	a,(Tsr)
	or	a
	jr	z,_nocode
	ld	a,(Tsrpass)
	or	a
	jr	z,_nocode
	ld	a,l
	cp	#24
	jr	nz,_nocode
	ld	a,h
	cp	#40
	jr	nz,_nocode

	ld	hl,(Lengteoffset)
	push	hl
	inc	hl
	inc	hl
	ld	(Code),hl
	ld	b,2
	call	totijdbuffer
	pop	bc
	ld	a,b
	or	c
	jr	z,_nocode
	ld	hl,Tsr_vram
_looptsr:
	push	bc
	push	hl
	call	readvram
	ld	(Code),a
	ld	b,1
	call	totijdbuffer
	pop	hl
	inc	hl
	pop	bc
	dec	bc
	ld	a,b
	or	c
	jr	nz,_looptsr

_nocode:
	ld	a,(Domacro)
	or	a
	jp	nz,_nextcodeass
	ld	hl,(Assemblregel)
	ld	a,l
	inc	hl
	ld	(Assemblregel),hl
	dec	a
	and	%00111111
	jp	nz,_nextcodeass
	ld	a,(Teken1+1)
	xor	%10000
	ld	(Teken1+1),a
	ld	hl,(Okadres)
Teken1:	ld	a,"-"
	call	writevram
	jp	_nextcodeass

_ass_error2	ld	hl,(If_adres)
	ld	a,(hl)
	cp	#80
	jr	nz,_ass_error1
	jr	skip_inc_adres
_endcodeass:
	ld	a,(Relocatable)
	or	a
	jr	z,_endcodeass1

	call	publics
	call	externals

	call	speciallink
	ld	a,%111000
	ld	b,6
	call	putbits
	ld	de,0
	call	putadres	;End of module: #0000 Abs
_endcodeass2:
	ld	a,(Bitinfo)
	cp	1
	jr	z,_endcodeass3
	xor	a
	call	putbit
	jr	_endcodeass2
_endcodeass3:
	ld	a,%10011110
	call	putbyte	;End of file
	xor	a
	call	putbit
	ld	a,1
	ld	(Assembledisk),a
_endcodeass1:
	call	_totijdbuf3	;remainder to ram
	ld	a,(Firstcomm)
	or	a
	call	z,set1storg
end_found1:
	call	end_foundini
	ret	c
	jp	_nextcodeass

set1storg:
	inc	a
	ld	(Firstcomm),a
	ld	de,(Assembladres)
	ld	(Firstorg),de
	ret

Firstcomm:	defb	0
Firstorg:	defw	0

externals:
	ld	a,%0110
	ld	(Publ_ext+1),a
	ld	bc,(Aantalextern)
	inc	bc
	ld	hl,Ext_vram
	jr	_publics1

publics:
	ld	a,%0111
	ld	(Publ_ext+1),a
	ld	bc,(Aantalpublic)
	inc	bc
	ld	hl,Tsr_vram
_publics1:
	dec	bc
	ld	a,b
	or	c
	ret	z
	push	bc
	ld	de,Label
	ld	b,-1	;B=length
_publics2:
	inc	b
	call	readvram
	inc	hl
	ld	(de),a
	inc	de
	or	a
	jr	nz,_publics2
	push	hl
	push	bc
	call	speciallink
Publ_ext:	ld	a,%0111
	ld	b,4
	call	putbits	;file name
	ld	hl,Label
	call	labelexist
	ex	de,hl
	call	zetlabblok
	call	getlabbuffer
	call	getlabbuffer	;+next address
	call	getlabbuffer	;+next block
_publics3:	call	getlabbuffer
	and	%10000000
	jr	z,_publics3
	call	getlabbuffer
	ld	l,a
	call	getlabbuffer
	ld	h,a
	push	hl
	call	getlabbuffer
	rlca
	call	putbit
	rlca
	call	putbit
	pop	de
	call	putadres
	pop	bc
	ld	a,b
	cp	7
	jr	c,_publics4
	ld	b,6
_publics4:
	ld	de,Label
	call	putname
	pop	hl
	pop	bc
	jr	_publics1

;----- Send name field
;----- IN: DE=address name, B=number of characters (max. 6)
putname:
	push	bc
	ld	a,b
	ld	b,3
	call	putbits
	pop	bc
_putname1:
	push	bc
	ld	a,(de)
	inc	de
	cp	"a"
	jr	c,_putname2
	and	255-(97-65)
_putname2:
	call	putbyte
	pop	bc
	djnz	_putname1
	ret

;----- Send special link item id
speciallink:
	ld	a,%100
	ld	b,3
	jr	putbits

;----- Send address to buffer
;----- IN: DE=address
putadres:
	ld	a,e
	call	putbyte
	ld	a,d
	jr	putbyte

;----- Send 1 byte to buffer
;----- IN: A=byte
putbyte:
	ld	b,8
_putbyte1:
	rlca
	push	af
	call	putbit
	pop	af
	djnz	_putbyte1
	ret

;----- Send B bits from A to buffer (Bits in A right!)

putbits:
	push	bc
_putbits1:
	rrca
	djnz	_putbits1
	pop	bc
_putbits2:
	rlca
	call	putbit
	djnz	_putbits2
	ret

;----- Send 1 bit to buffer

putbit:
	push	af
	ld	hl,Bitinfo
	dec	(hl)
	call	z,_putbit1
	inc	hl
	pop	af
	rl	(hl)
	ret
_putbit1:
	push	af
	push	bc
	push	de
	push	hl
	ld	(hl),8
	ld	a,1
	ld	(Assembledisk),a
	inc	hl
	ex	de,hl
	ld	b,1
	call	_bytenaarbuf
	xor	a
	ld	(Assembledisk),a
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

Bitinfo:	defb	9
Huidigbyte:	defb	0


;----- run DEFS

_do_defs:
	ld	hl,(Lengte_defs)
	ld	a,(Relocatable)
	or	a
	jr	nz,_defs_rel
	ld	a,l
	or	a
	jr	z,_do_defs1
	ld	b,l
	push	hl
	call	vultijdbuffe
	pop	hl
_do_defs1:	ld	a,h
	or	a
	jr	z,_do_defs2
	push	hl
	ld	b,0
	call	vultijdbuffe
	pop	hl
	dec	h
	jr	_do_defs1
_do_defs2:
	ld	bc,(Lengte_defs)
	ld	hl,(Assembladres)
	add	hl,bc
	ld	(Assembladres),hl
	jp	_nocode

_defs_rel:
	ld	a,l
	or	a
	jr	z,_defs_rel1
	ld	b,l
	push	hl
	call	vultijdrel
	pop	hl
_defs_rel1:	ld	a,h
	or	a
	jr	z,_do_defs2
	push	hl
	ld	b,0
	call	vultijdrel
	pop	hl
	dec	h
	jr	_defs_rel1

vultijdbuffe:
	ld	hl,(Tijdelbuffer)
	ld	a,(Eindebuffer)
	ld	c,a	;high byte end
_vultijdbuf1:
	ld	a,(Vul_defs)
	ld	(hl),a
	inc	hl
	ld	a,l
	cp	c
	call	z,_totijdbuf2
	djnz	_vultijdbuf1
	ld	(Tijdelbuffer),hl
	ret

vultijdrel:
	push	bc
	xor	a
	call	putbit
	ld	a,(Vul_defs)
	call	putbyte
	pop	bc
	djnz	vultijdrel
	ret

;----- IN: B=length

torelbuffer:
	ld	iy,Code
_torelbuff1:
	push	bc
	ld	a,(iy+jon_len_code)
	or	a
	jr	z,_torelbuff2	;regular code
	ld	(iy+jon_len_code),0
	scf
	call	putbit
	ld	b,2
	call	putbits
	ld	e,(iy)
	inc	iy
	ld	d,(iy)
	inc	iy
	call	putadres
	pop	bc
	dec	b	;1 extra byte used
	ret	z	;not possible, but just to be sure
	jr	_torelbuff3
_torelbuff2:
	xor	a
	call	putbit
	ld	a,(iy)
	inc	iy
	call	putbyte
	pop	bc
_torelbuff3:
	djnz	_torelbuff1
	ret

;----- IN: B=length

totijdbuffer:
	ld	a,(Tsr)
	or	a
	jr	z,_totijdbuf4
	ld	a,(Tsrpass)
	or	a
	ret	z
_totijdbuf4:
	ld	de,Code
_bytenaarbuf:
	ld	hl,(Tijdelbuffer)
	ld	a,(Eindebuffer)
	ld	c,a	;low byte end
_totijdbuf1:
	ld	a,(de)
	inc	de
	ld	(hl),a
	inc	hl
	ld	a,l
	cp	c
	call	z,_totijdbuf2
	djnz	_totijdbuf1
	ld	(Tijdelbuffer),hl
	ret

_totijdbuf2:	;send to ram/disk
	ld	a,(Eindebuffer+1)
	cp	h
	ret	nz	;not end yet
	push	bc
	push	de
	ld	a,(Assembledisk)
	or	a
	jr	nz,_codetodisk
	ld	de,(Tijdelasmadr)
	ld	bc,1024
	call	puttoram
codediskcont:
	ld	hl,(Tijdelasmadr)
	ld	de,1024
	add	hl,de
	ld	(Tijdelasmadr),hl
	pop	de
	pop	bc
	ld	hl,(Bufferpage0)
	ret
_codetodisk:
	ld	hl,1024
	call	savedisk
	jr	codediskcont

_totijdbuf3:	;send to ram in the meantime
	ld	hl,(Tijdelbuffer)
	ld	de,(Bufferpage0)
	ld	(Tijdelbuffer),de
	or	a
	sbc	hl,de
	ld	a,h
	or	l
	jr	z,_totijdb3_1	;nothing to send
	ld	a,(Assembledisk)
	or	a
	jr	nz,codetodis1
	ld	b,h
	ld	c,l
	ld	de,(Tijdelasmadr)
	call	puttoram
_totijdb3_1:	ld	hl,(Assembladres)
	ld	(Tijdelasmadr),hl
	ret
codetodis1:
	call	savedisk
	jr	_totijdb3_1

Tijdelbuffer:	defw	0	;current address temporary buffer
Tijdelasmadr:	defw	0	;assemble address start buffer
Eindebuffer:	defw	0	;end of temporary buffer

;----- get sentence to assemble and split      OUT: [C]=end text (after macro)

zinassembl:
	ld	hl,Zin
	ld	a,(Domacro)
	or	a
	jr	nz,textmacro
_zinassembl1:	call	gettxtbuffer
	ld	(hl),a
	inc	hl
	bit	7,a
	jr	z,_zinassembl1
	ld	(hl),0
	dec	hl
	res	7,(hl)	;SENTENCE is line with tabs, 0=end
	call	splitline
	xor	a
	ld	(hl),a	;last exit
	ret

;---------- Enter labels for macro text

textmacro:
	ld	a,(Macrotxtblk)
	call	zetlabblok
	ld	de,(Macrotxtadr)
_textmacro0:
	dec	hl
_textmacro1:
	inc	hl
	call	getlabbuffer
	ld	(hl),a
	or	a
	jr	z,_textmacrend
	cp	#ff
	jr	z,_textmacrstp
	cp	"@"
	jr	nz,_textmacro1
	call	vulmacrlabin
	ld	de,(Macrocntadr)
	ld	a,(Macrocntblk)
	call	zetlabblok
	jr	_textmacro0

_textmacrend:
	ld	(Macrotxtadr),de
	ld	a,(Labbloknr)
	ld	(Macrotxtblk),a
	call	splitline
	ld	(hl),0	;last exit
	xor	a
	ret
_textmacrstp:	;end of macro reached
	ld	hl,Huidigmacro
	dec	(hl)
	jr	z,_lastmacro
	call	loadmacro
	ld	hl,Zin
	jp	textmacro
_lastmacro:
	xor	a
	ld	(Domacro),a
	ld	de,(Assemblregel)
	inc	de
	ld	(Assemblregel),de
	call	geefadrregel
	ret	c	;end of text (after macro)
	call	zettextblok
	jp	zinassembl	;continue with just assembling


;----- replace macro label with given text

vulmacrlabin:	;fill in macro label
	push	hl
	ld	hl,Kbuf+200
_textmacro2:
	ld	(hl),a
	inc	hl
	ld	(Macrocntadr),de
	ld	a,(Labbloknr)
	ld	(Macrocntblk),a
	call	getlabbuffer
	call	tekenlabelok
	jr	nc,_textmacro2	;fetch label with @
	ld	(hl),0

	call	macrolabadrs
	jp	c,labelnotdefi
	pop	hl
_vultxtin3:
	ld	a,(de)
	inc	de
	or	a
	ret	z
	ld	(hl),a
	inc	hl
	jr	_vultxtin3

Macrocntadr:	defw	0
Macrocntblk:	defb	0

Turborcomm:	defw	0	;number of turbo-r commands


;----- text to macro

vulmacroin:
	ld	a,(Macrobufblk)
	call	zetlabblok
	ld	de,(Macrobufadr)
	ld	hl,Zin
_vulmacroin1:
	ld	a,(hl)
	inc	hl
	call	putlabbuffer
	or	a
	jr	nz,_vulmacroin1
	ld	(Macrobufadr),de
	ld	a,(Labbloknr)
	ld	(Macrobufblk),a
	ret

;----- Retrieves address contents of macro label
;----- OUT: DE=address, [C]=label not defined

macrolabadrs:
	ld	de,Kbuf
	ld	b,0
_textmacro4:	;check which label
	ld	hl,Kbuf+200
	inc	b
_textmacro3:
	ld	a,(de)
	inc	de
	cp	#ff
	scf
	ret	z
	cp	(hl)
	inc	hl
	jr	nz,_textmacro5
	or	a
	jr	nz,_textmacro3
	jr	_vultxtin
_textmacro5:
	or	a
	jr	z,_textmacro4
	ld	a,(de)
	inc	de
	jr	_textmacro5
_vultxtin:
	ld	de,Kbuf+100	;long enough?***********************
	dec	b
	ret	z
_vultxtin1:
	ld	a,(de)
	inc	de
	or	a
	jr	nz,_vultxtin1
	djnz	_vultxtin1
	ret

;----- pass label data address to editor

geeflabdata:
	ld	hl,Labels1
	ld	de,Kbuf
	ld	bc,3*26+3*1
	ldir
	ld	hl,(Aantallabels)
	ret


;----- label to label buffer   IN: HL=address
;---------- OUT: [C]=already existed, HL=address, A=block number (1-..)
;            if [NC]: DE=target address address/block, B=target block num
;*** Label: address+block next, label (end=bit7), address, block, type
;    kind: 0=normal, <>0=macro

Aantallabels:	defw	0
Labels1:	defs	3*26+3*1	;26+1 times address, block

putlabel:
	ld	a,(Labelpublic)
	or	a
	jr	z,putlabel1
	ld	a,(Relocatable)
	or	a
	jr	nz,putlabel2
	call	relcommand
	jr	putlabel1
putlabel2:
	push	hl
	ex	de,hl
	call	savepublic1
	pop	hl
putlabel1:
	call	labelcorrect	;test for good label
	jr	nc,_putlab1
	ld	a,b
	or	a
	jp	z,badlabel	;wrong
	jp	labeltoolong
_putlab1:
	ld	a,(Macro)
	or	a
	ret	nz	;Do not fill in labels in macro itself
	ld	a,1
	call	labelexist	;with fill in
	ccf
	ret	c	;already existed

	push	af
	push	hl
	ex	de,hl	;de=target
	call	zetlabblok
	xor	a
	call	putlabbuffer
	xor	a
	call	putlabbuffer
	xor	a
	call	putlabbuffer	;address+block next = 0,0,0
	ld	hl,Label	;hl=source
	ld	c,3+1	;3 characters (address/block next)

_putnext:
	ld	a,(Upperonoff)
	or	a
	ld	a,(hl)
	inc	hl
	jr	z,_putnext1	;not upper
	cp	"a"
	jr	c,_putnext1
	cp	"z"+1
	jr	nc,_putnext1
	and	255-32
_putnext1:	ld	b,a
	ld	a,(hl)
	or	a
	ld	a,b
	jr	z,_end_put
	call	putlabbuffer
	inc	c
	jr	_putnext
_end_put:
	or	%10000000
	call	putlabbuffer	;last letter => bit 7 high
	ld	a,(Labbloknr)
	push	af
	push	de	;*************** 7-3-95
	ld	hl,(Assembladres)
	ld	a,l
	call	putlabbuffer
	ld	a,h
	call	putlabbuffer	;type not filled in (was already 0)
	ld	a,(Relocatable)
	ld	b,a
	ld	a,(Tsr)
	or	b
	jr	z,_end_put2
	ld	a,(Segment)	;0=ABS, 1=CSEG, 2=DSEG
	rrca
	rrca
	call	putlabbuffer	;Type = %??000000
_end_put2:
	ld	b,0
	ld	hl,(Eindlabadres)
	add	hl,bc
;              push    hl                  ******************* 7-3-95
	ld	c,2+1	;+address+type
	add	hl,bc
	bit	6,h
	jr	z,_end_put1
	res	6,h
	ex	de,hl
	ld	hl,Eindlabblok
	inc	(hl)
	ex	de,hl
_end_put1:
	ld	(Eindlabadres),hl
	pop	de	;de=target address address+type
	pop	bc	;b=target block    " " " " " "
	pop	hl	;starting address label
	pop	af	;starting block label
	or	a
	ret
Eindlabadres:	defw	0
Eindlabblok:	defb	0


;---------- Does label already exist?
;----- IN: HL=address label, A: 0=search only, 1=also fill in address
;----- OUT: [C]=no, HL=address (if [C]=>target tag), A=block num, DE=end tag

labelexist:
	ld	(Alleenzoek),a
	ld	(Adreslabel),hl
	ld	a,(hl)
	ld	hl,Labels1+26*3
	cp	"A"
	jr	c,_labexist1	;special
	cp	"Z"+1
	jr	c,_labexist2	;letter
	cp	"a"
	jr	c,_labexist1	;special

_labexist2:	and	%11011111
	sub	"A"
	ld	b,a
	add	a,a
	add	a,b	;*3  
	ld	e,a
	ld	d,0
	ld	hl,Labels1
	add	hl,de
_labexist1:
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	a,d
	or	e
	jp	z,_labexist3	;first with this letter
	ld	(Nextadres),de
	ld	a,(hl)
	ld	(Nextblok),a
	xor	a
	ld	(Laatste),a

_nextexist:
	ld	a,(Laatste)
	or	a
	jp	nz,_labnotfound

	ld	a,(Nextblok)
	ld	(Testblok),a
	call	zetlabblok
	ld	de,(Nextadres)
	ld	(Testadres),de
	call	getlabbuffer
	ld	l,a
	call	getlabbuffer
	ld	h,a
	or	l
	jr	nz,_nietlaatste
	ld	a,1
	ld	(Laatste),a
_nietlaatste:	call	getlabbuffer
	ld	(Nextadres),hl
	ld	(Nextblok),a	;for next time

	ld	hl,(Adreslabel)
_nextcompare:
	call	getlabbuffer
	ld	b,a
	bit	7,b
	jr	nz,_maybe
	ld	a,(Upperonoff)
	or	a
	ld	a,(hl)
	jr	z,_nextcompar1	;no upper
	cp	"a"
	jr	c,_nextcompar1
	cp	"z"+1
	jr	nc,_nextcompar1
	and	255-32
_nextcompar1:
	cp	b
	jr	nz,_nextexist
	inc	hl
	jr	_nextcompare

_maybe:
	res	7,b
	ld	a,(Upperonoff)
	or	a
	ld	a,(hl)
	jr	z,_maybe1	;no upper
	cp	"a"
	jr	c,_maybe1
	cp	"z"+1
	jr	nc,_maybe1
	and	255-32
_maybe1:
	cp	b
	jr	nz,_nextexist
	inc	hl
	ld	a,(hl)
	call	tekenlabelok
	jr	nc,_nextexist	;not end
_labelfound:
	ex	de,hl
	ld	hl,(Testadres)
	ld	a,(Testblok)
	or	a
	ret

Testblok:	defb	0
Testadres:	defw	0
Nextblok:	defb	0
Nextadres:	defw	0
Adreslabel:	defw	0
Laatste:	defb	0	;1=last test (next address=0)
Alleenzoek:	defb	0	;0=search only, 1=also fill in address

_labnotfound:
	ld	a,(Alleenzoek)
	or	a
	jr	z,_labnotfoun1	;only search
	ld	a,(Testblok)
	call	zetlabblok
	ld	de,(Testadres)
	ld	hl,(Eindlabadres)
	ld	a,l
	call	putlabbuffer
	ld	a,h
	call	putlabbuffer
	ld	a,(Eindlabblok)
	call	putlabbuffer
_labnotfoun1:
	ld	hl,(Eindlabadres)
	ld	a,(Eindlabblok)
	scf
	ret

_labexist3:	;1st of this letter/character
	ld	a,(Alleenzoek)
	or	a
	jr	z,_labnotfoun1	;only search

	ld	a,(Eindlabblok)
	ld	(hl),a
	dec	hl
	ld	de,(Eindlabadres)
	ld	(hl),d
	dec	hl
	ld	(hl),e
	ex	de,hl
	scf
	ret


;----- Test if label is correct    IN: HL=start address    OUT: [C]=incorrect
;----- OUT: B=0 => bad label, B=1 => label too long

labelcorrect:
	ld	b,0
	ld	a,(hl)
	cp	"0"
	jr	c,_labelcorre1
	cp	"9"+1
	ret	c
_labelcorre1:
	ld	a,(Idhex+2)
	or	a
	jr	nz,_hex_na
	ld	a,(Idhex)
	cp	(hl)
	scf
	ret	z	;is hex
_hex_na:
	ld	a,(hl)
	cp	"#"
	scf
	ret	z
	cp	"&"
	jr	nz,_bin_voor
	inc	hl
	ld	a,(hl)
	dec	hl
	and	%11011111
	cp	"H"
	scf
	ret	z
_bin_voor:
	ld	a,(Idbin+2)
	or	a
	jr	nz,_bin_na
	ld	a,(Idbin)
	cp	(hl)
	scf
	ret	z	;is bin
_bin_na:
	ld	a,(hl)
	cp	"%"
	scf
	ret	z
	cp	"&"
	jr	nz,_bin_na1
	inc	hl
	ld	a,(hl)
	dec	hl
	and	%11011111
	cp	"B"
	scf
	ret	z
_bin_na1:
	push	hl
	ld	a,(hl)
	or	a
	scf
	jr	z,_not_ok	;empty
	ld	a,(Labellengte)
	inc	a
	ld	b,a
_labelcorre2:
	ld	a,(hl)
	or	a
	jr	z,_label_ok
	call	tekenlabelok
	jr	c,_not_ok
	inc	hl
	djnz	_labelcorre2
	pop	hl
	inc	b	;b=1
	scf
	ret		;label too long
_label_ok:
_not_ok:
	pop	hl
	ld	b,0
	ret

;---------- Test characters that can come after label  [C]=not found

testfound1:
	ld	b,15
	ld	de,Testfound
_testfound2:	ld	a,(de)
	cp	(hl)
	ret	z
	inc	de
	djnz	_testfound2
	scf
	ret
Testfound:	defb	0,34," ,^*/+-()=<>@"


;----- may character appear in label ?  OUT: [C]=no
tekenlabelok:
	ex	af,af'
	ld	a,(Macro)
	or	a
	jr	z,_tekenlabok1
	ex	af,af'
	cp	"@"
	ret	z	;@ is also allowed with macro
	ex	af,af'
_tekenlabok1:
	ex	af,af'
	cp	"!"
	ret	c
	ret	z
	cp	"$"
	ret	z
	cp	"#"
	ret	z
	cp	"."
	ret	z
	cp	"0"
	ret	c
	cp	"9"+1
	ccf
	ret	nc
	cp	"A"
	ret	c
	cp	"Z"+1
	ccf
	ret	nc
	cp	"_"
	ret	z
	cp	"a"
	ret	c
	cp	"z"+1
	ccf
	ret

;----- split sentence into label, command, register 1 and register 2

Labelpublic:	defb	0	;1=label:: , so public

splitline:
	xor	a
	ld	(Label),a
	ld	(Commando),a
	ld	(Labelpublic),a
	LD	HL,reg_kweenie	;= Sentence-5  ************************
	LD	(reg1_pointer),HL	;=Sentence-4
	LD	(reg2_pointer),HL	;=Sentence-2
	ld	de,Zin	;label
	ld	hl,Label
_splitlabel1:	ld	a,(de)
	inc	de
	or	a
	ret	z
	cp	9
	jr	z,_splitcomman
	cp	" "
	jr	z,_splitcomman
	cp	":"
	jr	z,_splitcomman
	cp	";"
	ret	z
	ld	(hl),a
	inc	hl
	jr	_splitlabel1
_splitcomman:
	ld	(hl),0
	ld	a,(de)
	cp	":"
	jr	nz,_splitcomm1
	ld	a,1
	ld	(Labelpublic),a
	inc	de
_splitcomm1:	ld	a,(de)
	inc	de
	cp	9
	jr	z,_splitcomm1
	cp	" "
	jr	z,_splitcomm1
	dec	de
	ld	hl,Commando	;command
_splitcomma1:	ld	a,(de)
	inc	de
	or	a
	ret	z
	cp	9
	jr	z,_splitregis1
	cp	" "
	jr	z,_splitregis1
	cp	";"
	ret	z
	ld	(hl),a
	inc	hl
	jr	_splitcomma1
_splitregis1:
	xor	a
	ld	(hl),a
	ld	(Splitaanhali),a
	inc	hl
	ld	(reg1_pointer),hl
_splitreg1_0:
	ld	a,(de)
	inc	de
	cp	" "
	jr	z,_splitreg1_0
	cp	9
	jr	z,_splitreg1_0
	dec	de
_splitreg1_1:	ld	a,(de)
	inc	de
	or	a
	jr	z,noreg2
	cp	9
	jr	z,_splitreg1_1
	cp	34	;"  
	call	z,_split_aanha
	cp	"'"
	call	z,_split_aanha
	ld	b,a
	ld	a,(Splitaanhali)
	or	a
	ld	a,b
	jr	nz,_splitreg1_2
	cp	","
	jr	z,_splitregis2
	cp	";"
	jr	z,noreg2
	cp	" "
	jr	z,_splitreg1_1
_splitreg1_2:	ld	(hl),a
	inc	hl
	jr	_splitreg1_1
noreg2	ld	(hl),0
	inc	hl
	ld	(reg2_pointer),hl	;needed for IF ar1>arg2
	ret
_splitregis2:
	xor	a
	ld	(hl),a
	ld	(Splitaanhali),a
_splitreg2_3:	ld	a,(de)
	inc	de
	cp	9
	jr	z,_splitreg2_3	;get rid of all tabs
	cp	" "
	jr	z,_splitreg2_3	;remove all spaces
	dec	de
	INC	HL
	LD	(reg2_pointer),HL
_splitreg2_1:	ld	a,(de)
	inc	de
	or	a
	jr	z,_endreg2
	cp	9
	jr	z,_weltab
	cp	" "
	jr	nz,_nottab
_weltab:
	ld	ix,(reg2_pointer)	;*******************************
	ld	b,a
	ld	a,(Splitaanhali)
	cp	34
	jr	z,_nottab1
	cp	"'"
	jr	nz,_splitreg2_1
	ld	a,(ix)
	and	255-32
	cp	"A"
	jr	nz,_nottab1
	ld	a,(ix+1)
	and	255-32
	cp	"F"
	jr	nz,_nottab1
	ld	a,(ix+2)
	cp	"'"
	jr	z,_endreg2	;end after af'
_nottab1:	ld	a,b
_nottab:
	cp	34	;"  
	call	z,_split_aanha
	cp	"'"
	call	z,_split_aanha
	ld	b,a
	ld	a,(Splitaanhali)
	or	a
	ld	a,b
	jr	nz,_splitreg2_2
	cp	";"
	jr	z,_endreg2
_splitreg2_2:	ld	(hl),a
	inc	hl
	jr	_splitreg2_1

_endreg2:	ld	de,(reg2_pointer)	;*****************************
	ld	a,(de)
	or	a
	ret	nz	;after "," or 2nd register
	inc	a
	LD	DE,(reg1_pointer)	;*******************************
	ld	(de),a	;destroy register 1
	ret

_split_aanha:
	ld	b,a
	ld	a,(Splitaanhali)
	or	a
	jr	z,_split_aanh1
	cp	b
	ld	a,b
	ret	nz
	xor	a
	ld	(Splitaanhali),a
	ld	a,b
	ret
_split_aanh1:
	ld	a,b
	ld	(Splitaanhali),a
	ret

Splitaanhali:	defb	0

;----- Translate 1 line to code

assemble:
	xor	a
	ld	(Ass_error),a
	ld	(Lengtecode),a
	ld	(Endcode),a

	ld	hl,(Assembladres)
	ld	(Assembladre1),hl	;copy for defb and defw
	ld	a,(Commando)
	or	a
	ret	z	;no command
	ld	(Sp_assemble),sp	;for errors

	call	testcommando
	jr	c,_testmacro
	ld	iy,Code
	jp	(hl)

_testmacro:
	ld	a,(Macro)
	or	a
	ret	nz
	call	welassembl
	ret	c	;don't assemble because of if
	ld	hl,Commando
	xor	a
	call	labelexist
	jp	c,badcommand	;no macro either
	call	zetlabblok
	ex	de,hl
	call	getlabbuffer
	call	getlabbuffer
	call	getlabbuffer	;address+block next
_testmacro1:
	call	getlabbuffer
	and	%10000000
	jr	z,_testmacro1	;name
	call	getlabbuffer
	call	getlabbuffer
	call	getlabbuffer
	and	1
	jp	z,badcommand	;label is not a macro

	push	de
	ld	hl,Huidigmacro
	ld	a,(hl)
	inc	(hl)
	or	a
	call	nz,savemacro
	ld	hl,Sym
	ld	de,Kbuf
	ld	bc,10	;@SYM and @sym
	ldir
	ex	de,hl
	pop	de
_testmacro3:
	call	getlabbuffer
	ld	(hl),a
	inc	hl
	inc	a
	jr	nz,_testmacro3	;macro labels to Kbuf
	ld	a,(Labbloknr)
	ld	(Macrotxtblk),a
	ld	(Macrotxtadr),de

	ld	hl,Kbuf+100	;***************************
	ld	de,(Sym_waarde)
	inc	de
	ld	(Sym_waarde),de
	ld	b,2
_vulsym:
	ld	a,d
	call	vulsymin
	ld	a,e
	call	vulsymin
	ld	(hl),0
	inc	hl
	djnz	_vulsym

	ld	ix,(reg1_pointer)	;***************************
	call	macrolist
	jr	c,_testmacrend
	ld	ix,(reg2_pointer)	;******
_testmacro2:	call	macrolist
	jr	c,_testmacrend
	cp	","
	jr	z,_testmacro2
_testmacrend:
	ld	b,30
fillwith0:
	ld	(hl),0
	inc	hl
	djnz	fillwith0	;fill remainder with 0
	ld	a,1
	ld	(Domacro),a
	ret

Domacro:	defb	0	;insert macro ? 0=no, 1=yes
Macrotxtblk:	defb	0	;block+address macro-text
Macrotxtadr:	defw	0

vulsymin:
	ld	c,a
	and	%11110000
	rlca
	rlca
	rlca
	rlca
	call	vulsymin1
	ld	a,c
	and	%00001111
vulsymin1:
	add	a,"0"
	cp	"9"+1
	jr	c,vulsymin2
	add	a,"A"-"0"-10
vulsymin2:	ld	(hl),a
	inc	hl
	ret
Sym:	defb	"@SYM",0,"@sym",0
Sym_waarde:	defw	0


;----- list macro labels with values ​​in memory

macrolist:
	ld	a,(ix)
	or	a
	scf
	ret	z	;end
	xor	a
	ld	(Macroaanhal),a	;quotes off
_macrolist1:
	ld	a,(ix)
	inc	ix
	or	a
	jr	z,_macrolstend
	ld	b,a
	ld	a,(Macroaanhal)
	or	a
	ld	a,b
	jr	nz,_macrolist2
	cp	","
	jr	z,_macrolstend
_macrolist2:
	cp	34
	jr	z,_macroaanhal
	cp	"'"
	jr	z,_macroaanhal
_macrolist3:
	ld	(hl),a
	inc	hl
	jr	_macrolist1
_macrolsten1:
	ld	(hl),a
	inc	hl
_macrolstend:
	ld	(hl),0
	inc	hl
	ret
Macroaanhal:	defb	0

_macroaanhal:
	ld	b,a
	ld	a,(Macroaanhal)
	or	a
	jr	z,_macroaanh1
	cp	b
	jr	nz,_macroaanh2
	xor	a
	ld	(Macroaanhal),a
	jr	_macroaanh2
_macroaanh1:
	ld	a,b
	ld	(Macroaanhal),a
_macroaanh2:
	ld	a,b	;LEAVE IT !
	jr	_macrolist3

;----- Save/load macro to/from vram

savemacro:
	ld	hl,(Macro_opslag)
	push	hl
	call	setvramwrite
	ld	a,(Macrotxtblk)
	ld	de,(Macrotxtadr)
	call	_savemacro1
	ld	de,Kbuf
_savemacro3:
	ld	a,(de)
	inc	de
	out	(#98),a
	inc	hl
	inc	a
	jr	nz,_savemacro3
	ld	b,100	;***************************
	ld	de,Kbuf+100
_savemacro4:
	ld	a,(de)
	inc	de
	out	(#98),a
	inc	hl
	djnz	_savemacro4
	pop	de
	call	_savemacro2
	ld	(Macro_opslag),hl	;address for next macro
	ret
_savemacro1:
	out	(#98),a
	inc	hl
_savemacro2:
	ld	a,e
	out	(#98),a
	inc	hl
	ld	a,d
	out	(#98),a
	inc	hl
	ret

loadmacro:
	ld	hl,(Macro_opslag)
	dec	hl
	call	readvram
	ld	d,a
	dec	hl
	call	readvram
	ld	e,a
	ex	de,hl
	ld	(Macro_opslag),hl
	call	_loadmacro1
	ld	(Macrotxtblk),a
	ld	(Macrotxtadr),de
	ld	hl,Kbuf
_loadmacro2:
	in	a,(#98)
	ld	(hl),a
	inc	hl
	inc	a
	jr	nz,_loadmacro2
	ld	b,100	;****************************
	ld	hl,Kbuf+100
_loadmacro3:
	in	a,(#98)
	ld	(hl),a
	inc	hl
	djnz	_loadmacro3
	ret
_loadmacro1:
	call	readvram
	inc	hl
	ex	af,af'
	call	readvram
	inc	hl
	ld	e,a
	call	readvram
	inc	hl
	ld	d,a
	ex	af,af'
	ret

Macro_opslag:	defw	0
Huidigmacro:	defb	0


;----- Test if command exists       OUT: [C]=no, HL=start address
;----- length and 1st code entered
testcommando	ld	a,(Commando)	;normally <128
	add	a,a	;times two
	ld	l,a
	ld	h,tabcom/256
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	ld	a,(hl)	;getnumber with this initial letter
	or	a
	scf
	ret	z	;no commands with this letter
	inc	hl
	ld	b,0
zoekcommand	ex	af,af'
	ld	c,(hl)
	inc	hl
	ld	de,Commando+1
_zoekcommand	ld	a,(de)
	and	#df
	cp	(hl)
	jr	nz,verhooghl
	inc	hl
	or	a
	jr	z,comfound
	dec	c
	inc	de
	jr	_zoekcommand
verhooghl	add	hl,bc
	ex	af,af'
	dec	a
	jr	nz,zoekcommand
	scf
	ret
comfound	ld	a,(hl)
	ld	(Lengtecode),a
	inc	hl
	ld	a,(hl)
	ld	(Code),a
	inc	hl
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	ret		;carry is off


Assembladres:	defw	0
Assembladre1:	defw	0	;copy for defb and defw
Assemblregel:	defw	0
Lengtecode:	defb	0	;#ff=defs
Code:	defs	jon_len_code,0
Relcode:	defs	jon_len_rel,0	;at each byte: 0=abs, 1=cseg, 2=dseg
Lengte_defs:	defw	0
Vul_defs:	defb	0
Endcode:	defb	0	;0=not end, 1=end code
Equ_adres:	defw	0	;address at equ
Equ_found:	defb	0	;0=not found, 1=yes
Pass:	defb	0


;$$$$$ adc
_adc:
	call	test_standa1
	ret	nc
	call	test1stregis
	jp	c,badmnemonic
	ld	b,#4a
_adc_cont:	cp	12
	jp	nz,badmnemonic
	push	bc
	call	test2ndregis
	pop	bc
	cp	10
	jp	c,badmnemonic
	cp	13+1
	jp	nc,badmnemonic
	sub	10
	add	a,a
	add	a,a
	add	a,a
	add	a,a
	or	b
	ld	(iy+1),a
	ld	(iy),#ed
	inc	(iy-1)
	ret

;$$$$$ add
_add:
	call	test_standa1
	ret	nc
	call	test1stregis
	jp	c,badmnemonic
	cp	12
	jr	nz,_add_ix_iy
	call	test2ndregis	;HL,
	cp	10
	jp	c,badmnemonic
	cp	13+1
	jp	nc,badmnemonic
_add_cont:	sub	10
	add	a,a
	add	a,a
	add	a,a
	add	a,a
	or	#9
	ld	(iy),a
	ret
_add_ix_iy:	cp	14
	ld	(iy),#dd
	jr	z,_add_ix_iy1
	cp	15
	ld	(iy),#fd
	jp	nz,badmnemonic
_add_ix_iy1:	push	af
	inc	(iy-1)
	call	test2ndregis
	pop	bc
	jp	c,badmnemonic
	cp	b
	ld	(iy+1),#29
	ret	z	;IX,IX and IY,IY
	inc	iy
	cp	10
	jr	z,_add_cont
	cp	11
	jr	z,_add_cont
	cp	13
	jr	z,_add_cont
	jp	badmnemonic

;$$$$$ and
_and:
	call	test_standa1
	ret	nc
	jp	badmnemonic

;$$$$$ bit
_bit:
	ld	a,(iy)
	ld	(iy),#cb
	ld	(iy+1),a
	LD	HL,(reg1_pointer)
;             call    getal8bit 
	ld	a,(hl)
	cp	"0"
	jp	c,getaltegroot
	cp	"8"
	jp	nc,getaltegroot
	sub	"0"
	add	a,a
	add	a,a
	add	a,a
	or	(iy+1)
	ld	(iy+1),a
	call	test2ndregis
	cp	24
	jr	z,bit_ix2
	cp	25
	jr	z,bit_iy2
	cp	8
	jr	nc,_bit_ix_iy
	add	a,(iy+1)
	ld	(iy+1),a
	ret
_bit_ix_iy:	ld	(iy),#dd
	jr	z,_bit_ix_iy1
	set	5,(iy)
	cp	9
	jp	nz,badmnemonic
_bit_ix_iy1:	ld	a,(iy+1)
	add	a,6
	ld	(iy+3),a
	ld	(iy+1),#cb
	ex	de,hl
	ld	(iy-1),4
	call	getal8bit
	jp	c,badmnemonic
	ld	(iy+2),a
	ld	a,(hl)
	cp	")"
	jp	nz,badmnemonic
	ret

bit_ix2:	ld	(iy),#dd	;(ix) and (iy)
	jr	_bit_ix_iy2
bit_iy2:	ld	(iy),#fd
_bit_ix_iy2:	ld	a,(iy+1)
	add	a,6
	ld	(iy+3),a
	ld	(iy+1),#cb
	ld	(iy+2),0
	ld	(iy-1),4
	ret


;$$$$$ call
_call:
	call	voorwaarde
	jr	c,_call1
_call_cont1:	add	a,a
	add	a,a
	add	a,a
	or	(iy)
	ld	(iy),a
	LD	HL,(reg2_pointer)
_call_cont:	call	getal16bit
	jp	c,badmnemonic
	ld	(iy+1),e
	ld	(iy+2),d
	ld	a,1
	jp	vuladresin
_call1:	ld	(iy),#cd
	LD	HL,(reg1_pointer)
	jr	_call_cont

;$$$$$ ccf
_ccf	LD	HL,(reg1_pointer)
	LD	A,(HL)
	LD	HL,(reg2_pointer)
	OR	(HL)
	jp	nz,badmnemonic
	ret

;$$$$$ cpd
_cpd:	ld	a,(iy)
	ld	(iy+1),a
	ld	(iy),#ed
	jr	_ccf

;$$$$$ dec
_dec:
	LD	HL,(reg2_pointer)
	LD	A,(HL)
	or	a
	jp	nz,badmnemonic
	call	test2ndregis
	jp	c,badmnemonic
	ld	b,#0b
	ld	c,#25
_dec_cont:
	cp	8
	jr	nc,_dec_ix
	add	a,a	;dec standard
	add	a,a
	add	a,a
	or	(iy)
	ld	(iy),a
	ret
_dec_ix:	cp	10	;dec (ix+ (iy+
	jr	nc,_dec_ix1
	ld	b,a
	ld	a,(iy)
	add	a,#30
	call	test_standa2
	jp	c,badmnemonic
	ret
_dec_ix1:	cp	24	;dec (ix) (iy)
	jr	c,_dec_bc_de
	cp	25+1
	jr	nc,_dec_bc_de
	ld	b,a
	ld	a,(iy)
	add	a,#30
	jp	test_standa4	;continue with standard
_dec_bc_de:	cp	14	;dec bc de hl sp
	jr	nc,_dec_ix_iy
	sub	10
	add	a,a
	add	a,a
	add	a,a
	add	a,a
	or	b
	ld	(iy),a
	ret
_dec_ix_iy:	cp	16	;dec ix iy
	jr	nc,_dec_ixh
	inc	(iy-1)
	ld	(iy),#dd
	cp	14
	jr	z,_dec_ix_iy1
	set	5,(iy)
_dec_ix_iy1:	ld	a,b
	or	#20
	ld	(iy+1),a
	ret
_dec_ixh:	cp	18
	jp	c,badmnemonic
	cp	22
	jp	nc,badmnemonic
	sub	18
	ld	b,a
	and	1
	add	a,a
	add	a,a
	add	a,a
	add	a,c
	ld	(iy+1),a
	jp	test_standa3

;$$$$$ djnz
_djnz:
	LD	HL,(reg2_pointer)
	LD	A,(HL)
	or	a
	jp	nz,badmnemonic
	LD	HL,(reg1_pointer)
_djnz_cont:	call	getal16bit
	ex	af,af'
	ld	a,(Pass)
	dec	a
	ret	z	;At pass1 => back
	ex	af,af'
	jp	c,badmnemonic
	ex	de,hl	;hl=number
	ld	de,(Assembladres)
J565D	inc	de	;******************used?
	inc	de
	xor	a
	sbc	hl,de
	ex	de,hl	;de=address
	ld	a,d
	dec	a
	cp	#fe
	jp	c,offsettegroo
	call	testoffset
	jp	c,offsettegroo
	ld	(iy+1),e
	ret

;$$$$$ ex
_ex:
	call	test1stregis
	jp	c,badmnemonic
	cp	17
	jr	nz,_ex_de_hl
	call	test2ndregis
	jp	c,badmnemonic
	ld	(iy),#e3
	cp	12
	ret	z	;(sp),hl
	ld	(iy+1),#e3
	ld	(iy),#dd
	inc	(iy-1)
	cp	14
	ret	z	;(sp),ix
	set	5,(iy)
	cp	15
	ret	z	;(sp),iy
	jp	badmnemonic
_ex_de_hl:	cp	11
	jr	nz,_ex_af_af
	call	test2ndregis
	cp	12
	jp	nz,badmnemonic
	ld	(iy),#eb
	ret
_ex_af_af:	cp	16
	jp	nz,badmnemonic
	ld	(iy),#08
	call	test2ndregis
	cp	16
	ret	z	;af,af  
	cp	30
	ret	z	;af,af'  
	jp	badmnemonic

;$$$$$ im
_im	LD	HL,(reg2_pointer)
	LD	A,(HL)
	or	a
	jp	nz,badmnemonic
	LD	HL,(reg1_pointer)
	call	getal16bit
	jp	c,badmnemonic
	ld	a,d
	or	a
	jp	nz,badmnemonic
	ld	a,e
	or	a
	ld	(iy+1),#46
	ret	z
	dec	a
	set	4,(iy+1)
	ret	z
	dec	a
	set	3,(iy+1)
	ret	z
	jp	badmnemonic

;$$$$$ in
_in:	call	test1stregis
	jp	c,badmnemonic
	ld	(iy),#ed
	cp	7
	jr	z,_in_a
	cp	6
	jp	z,badmnemonic
	cp	22
	jr	z,_in_f
	cp	8
	jp	nc,badmnemonic
_in_cont:	add	a,a
	add	a,a
	add	a,a
	or	#40
	ld	(iy+1),a
	call	test2ndregis
	jp	c,badmnemonic
	cp	23
	ret	z
	jp	badmnemonic
_in_f:	sub	22-6
	ld	hl,(Turborcomm)
	inc	hl
	ld	(Turborcomm),hl
	jr	_in_cont
_in_a:	call	test2ndregis
	jr	c,_in_a_port
	ld	(iy+1),#78
	cp	23
	ret	z
	jp	badmnemonic
_in_a_port:	ld	hl,(reg2_pointer)
	ld	a,(hl)
	cp	"("
	jp	nz,badmnemonic
	inc	hl
	call	getal8bit
	jp	c,badmnemonic
	ld	(iy+1),e
	ld	(iy),#db
	ld	a,(hl)
	cp	")"
	jp	nz,badmnemonic
	ret

;$$$$$ inc
_inc:
	LD	HL,(reg2_pointer)
	LD	A,(HL)
	or	a
	jp	nz,badmnemonic
	call	test2ndregis
	jp	c,badmnemonic
	ld	b,#03
	ld	c,#24
	jp	_dec_cont

;$$$$$ jp
_jp:
	call	test2ndregis
	jr	nc,_jp2
	call	voorwaarde
	jp	nc,_call_cont1	;jp condition
	ld	(iy),#c3
	LD	HL,(reg1_pointer)
	jp	_call_cont
_jp2:	ld	b,a
	LD	HL,(reg2_pointer)
	LD	A,(HL)
	or	a
	jp	nz,badmnemonic
	ld	a,b
	ld	(iy),#dd
	ld	(iy+1),#e9
	dec	(iy-1)
	cp	24
	ret	z	;(ix)
	set	5,(iy)
	cp	25
	ret	z	;(iy)
	ld	(iy),#e9
	dec	(iy-1)
	cp	6
	ret	z	;(hl)
	jp	badmnemonic

;$$$$$ jr
_jr:
	call	voorwaarde
	jr	c,_jr1
	cp	4
	jp	nc,badmnemonic
_jr_cont:	add	a,a
	add	a,a
	add	a,a
	or	#20
	ld	(iy),a
	LD	HL,(reg2_pointer)
	jp	_djnz_cont
_jr1:	ld	(iy),#18
	LD	HL,(reg1_pointer)
	jp	_djnz_cont

;$$$$$ ld
_ld:
	call	test1stregis
	jp	c,_ld_getal_re
	ld	(iy),#02
	cp	28
	jp	z,_ld_bc1_de1
	ld	(iy),#12
	cp	29
	jp	z,_ld_bc1_de1
	cp	6
	jp	c,_ld_b_c
	jp	z,_ld_hl
	cp	7
	jp	z,_ld_a
	cp	8
	jp	z,_ld_ix_iy
	cp	24
	jp	z,_ld_ix_iy2
	cp	9
	jp	z,_ld_ix_iy
	cp	25
	jp	z,_ld_ix_iy2
	cp	13+1
	jp	c,_ld_bc_de
	ld	(iy),#dd
	jp	z,_ld1_ix_iy
	set	5,(iy)
	cp	15
	jp	z,_ld1_ix_iy
	ld	(iy+1),#47
	cp	26
	jp	z,_ld_i_r
	ld	(iy+1),#4f
	cp	27
	jp	z,_ld_i_r
	cp	18
	jp	c,badmnemonic
	cp	21+1
	jp	nc,badmnemonic

_ld_ixh_ixl:	;ld ixh/ixl/iyh/iyl,r1/number
	ld	hl,(Turborcomm)
	inc	hl
	ld	(Turborcomm),hl
	inc	(iy-1)
	sub	18
	bit	1,a
	ld	(iy),#dd
	jr	z,_ld_ixh_ixl1
	set	5,(iy)
_ld_ixh_ixl1:	ld	(iy+1),#60
	bit	0,a
	jr	z,_ld_ixh_ixl2
	set	3,(iy+1)
_ld_ixh_ixl2:	push	af
	call	test2ndregis
	pop	bc
	jr	c,_ld_ixh_geta
	cp	4
	jr	c,_ld_ixh_ok
	cp	7
	jr	z,_ld_ixh_ok
	cp	18
	jp	c,badmnemonic
	cp	19+1
	jr	c,_ld_ixh_1
	cp	21+1
	jp	nc,badmnemonic
_ld_iyh_1:	bit	1,b	;,iyh/iyl
	jp	z,badmnemonic
	add	a,#64-20
	jr	_ld_ixh_3
_ld_ixh_1:	bit	1,b	;,ixh/ixl
	jp	nz,badmnemonic
	add	a,#64-18
_ld_ixh_3:	ld	(iy+1),a
	bit	0,b
	ret	z
	set	3,(iy+1)
	ret
_ld_ixh_ok:	add	a,(iy+1)	;,b/c/d/e/a
	ld	(iy+1),a
	ret
_ld_ixh_geta:	bit	0,b
	ld	(iy+1),#26
	jr	z,_ld_ixh_get1
	ld	(iy+1),#2e
_ld_ixh_get1:	ld	hl,(reg2_pointer)
	inc	(iy-1)
	call	getal8bit
	jp	c,badmnemonic
	ld	(iy+2),a
	ret
_ld_i_r:
	ld	(iy),#ed
	inc	(iy-1)
	call	test2ndregis
	jp	c,badmnemonic
	cp	7
	jp	nz,badmnemonic
	ret
_ld1_ix_iy:	;ld ix/iy,
	ld	(iy-1),4
	LD	HL,(reg2_pointer)
	call	getalhaakjes
	jr	c,_ld1_ix_iy1
	ld	(iy+1),#2a
	ld	(iy+2),e
	ld	(iy+3),d
	ld	a,2
	jp	vuladresin
_ld1_ix_iy1:	call	getal16bit
	jp	c,badmnemonic
	ld	(iy+1),#21
	ld	(iy+2),e
	ld	(iy+3),d
	ld	a,2
	jp	vuladresin
_ld_bc_de:	;ld bc/de/hl/sp,
	push	af
	ld	(iy-1),3
	LD	HL,(reg2_pointer)
	call	getalhaakjes
	jr	nc,_ld_bc_de1
	call	test2ndregis
	pop	bc
	jr	nc,_ld_sp
	push	bc
	LD	HL,(reg2_pointer)
	call	getal16bit
	pop	bc
	jp	c,badmnemonic
	ld	a,b
	ld	c,1
_ld_bc_cont:	sub	10
	add	a,a
	add	a,a
	add	a,a
	add	a,a
	or	c
	ld	(iy),a
	ld	(iy+1),e
	ld	(iy+2),d
	ld	a,1
	jp	vuladresin
_ld_bc_de1:	pop	af
	cp	12
	jr	z,_ld_hl2
	inc	(iy-1)
	ld	(iy),#ed
	inc	iy
	ld	c,#4b
	jr	_ld_bc_cont
_ld_hl2:	ld	(iy),#2a
	ld	(iy+1),e
	ld	(iy+2),d
	ld	a,1
	jp	vuladresin
_ld_sp:	ex	af,af'
	ld	a,b
	cp	13
	jp	nz,badmnemonic
	ex	af,af'
	dec	(iy-1)
	ld	(iy+1),#f9
	ld	(iy),#dd
	cp	14
	ret	z
	set	5,(iy)
	cp	15
	ret	z
	ld	(iy),#f9
	dec	(iy-1)
	cp	12
	ret	z
	jp	badmnemonic
_ld_ix_iy:
	call	test_ix_iy
	jr	_ld_ix_iy_co
_ld_ix_iy2:	;ld (ix/(iy,r1
	call	test_ix_iy2
_ld_ix_iy_co:	jp	c,badmnemonic
	call	test2ndregis
	jr	c,_ld_ix_getal
	cp	6
	jp	z,badmnemonic
	cp	8
	jp	nc,badmnemonic
	add	a,#70
	ld	(iy+1),a
	ret
_ld_ix_getal:	;(ix/(iy ,number
	ld	(iy+1),#36
	LD	HL,(reg2_pointer)
	inc	(iy-1)
	call	getal8bit
	jp	c,badmnemonic
	ld	(iy+3),a
	ret
_ld_b_c:	;ld r1,r1   (< (HL))
	ld	(Ld_b_ixh),a
	add	a,a
	add	a,a
	add	a,a
	or	#40
	ld	(iy),a
	call	test_standa6
	jp	c,badmnemonic
	ld	a,(iy-1)
	cp	2
	ret	nz
	ld	a,(iy)
	cp	#dd
	jr	z,_ld_b_ixh	;ixh/ixl
	cp	#fd
	jr	z,_ld_b_ixh	;iyh/iyl
	ld	a,(iy)
	sub	#46+#3a
	ld	(iy),a	;fix error at ld r1,number
	ret
_ld_b_ixh:	ld	a,(Ld_b_ixh)
	cp	4
	ret	c
	cp	7
	ret	z
	jp	badmnemonic	;not h/l,ixh etc.
Ld_b_ixh:	defb	0
_ld_a:	;ld a,r1/number
	call	test2ndregis
	jr	c,_ld_a_getal
	cp	28
	ld	(iy),#0a
	ret	z	;a,(bc)  
	cp	29
	ld	(iy),#1a
	ret	z	;a,(de)
	cp	26
	ld	(iy+1),#57
	jr	z,_ld_a_i	;a,i
	cp	27
	ld	a,7
	jr	nz,_ld_b_c	;normal
	ld	(iy+1),#5f	;a,r
_ld_a_i:	ld	(iy),#ed
	inc	(iy-1)
	ret
_ld_a_getal:	ld	hl,(reg2_pointer)	;ld a, number
	call	getalhaakjes
	ld	a,7
	jp	c,_ld_b_c	;ld a,number = normal
	ld	(iy+1),e
	ld	(iy+2),d
	ld	(iy),#3a
	ld	(iy-1),3
	ld	a,1
	jp	vuladresin

_ld_hl:	;ld (hl),r1/number
	call	test2ndregis
	jr	c,_ld_hl1
	cp	6
	jp	z,badmnemonic
	cp	8
	jp	nc,badmnemonic
	or	#70
	ld	(iy),a
	ret
_ld_hl1:	ld	hl,(reg2_pointer)	;ld (hl),number
	inc	(iy-1)
	call	getal8bit
	jp	c,badmnemonic
	ld	(iy+1),a
	ld	(iy),#36
	ret
_ld_bc1_de1:	;ld (bc)/(de),a
	call	test2ndregis
	jp	c,badmnemonic
	cp	7
	ret	z
	jp	badmnemonic
_ld_getal_re:	;ld (number),r1
	ld	(iy-1),3
	LD	HL,(reg1_pointer)
	call	getalhaakjes	;is (number) ? Yes => DE=number
	jp	c,badmnemonic
	push	de	;number
	call	test2ndregis
	pop	de
	jp	c,badmnemonic
	ld	(iy),#32
	cp	7
	jr	z,_ld_getal_r1	;,a
	ld	(iy),#22
	cp	12
	jr	z,_ld_getal_r1	;,hl
	inc	(iy-1)
	ld	(iy),#dd
	ld	(iy+1),#22
	cp	14
	jr	z,_ld_getal_r0	;,ix
	set	5,(iy)
	cp	15
	jr	z,_ld_getal_r0	;,iy
	ld	(iy),#ed
	cp	10
	jp	c,badmnemonic
	cp	13+1
	jp	nc,badmnemonic
	sub	10
	add	a,a
	add	a,a
	add	a,a
	add	a,a
	or	#43
	ld	(iy+1),a
_ld_getal_r0:	inc	iy
_ld_getal_r1:	ld	(iy+1),e
	ld	(iy+2),d
	ld	a,1
	jp	vuladresin

;$$$$$ out
_out:
	call	test1stregis
	jr	c,_out1
	cp	23
	jp	nz,badmnemonic
	call	test2ndregis
	cp	8
	jp	nc,badmnemonic
	cp	6
	jp	z,badmnemonic
	add	a,a
	add	a,a
	add	a,a
	or	(iy)
	ld	(iy+1),a
	ld	(iy),#ed
	ret
_out1:	ld	hl,(reg1_pointer)
	ld	a,(hl)
	inc	hl
	cp	"("
	jp	nz,badmnemonic
	call	getal8bit
	jp	c,badmnemonic
	ld	(iy+1),a
	ld	(iy),#d3
	ld	a,(hl)
	cp	")"
	jp	nz,badmnemonic
	call	test2ndregis
	jp	c,badmnemonic
	cp	7
	jp	nz,badmnemonic
	ret

;$$$$$ pop + push
_pop:
	push	iy
	pop	ix
	ld	hl,(reg1_pointer)
	ld	a,(hl)
	or	a
	jp	z,badmnemonic
	push	ix
	call	_testcont
	pop	ix
	jp	c,badmnemonic
	call	testpushpop
	LD	HL,(reg2_pointer)
_pop1:
	ld	de,(reg1_pointer)	;temporary storage
	ld	a,(hl)
	or	a
	ret	z
_pop3:
	ld	a,(hl)
	or	a
	jr	z,_pop2
	inc	hl
	cp	","
	jr	z,_pop2
	ld	(de),a
	inc	de
	jr	_pop3
_pop2:
	xor	a
	ld	(de),a
	push	hl
	push	ix
	ld	hl,(reg1_pointer)
	call	_testcont
	pop	ix
	pop	hl
	jp	c,badmnemonic
	call	testpushpop
	jr	_pop1

testpushpop:
	ld	b,(iy)
	cp	16
	jr	z,_pop_af
	cp	14
	jr	z,_pop_ix
	cp	15
	jr	z,_pop_iy
	cp	10
	jp	c,badmnemonic
	cp	12+1
	jp	nc,badmnemonic
	sub	10
	add	a,a
	add	a,a
	add	a,a
	add	a,a
	or	b
_pop_cont:
	ld	(iy),a
	inc	iy
	ld	(iy),b	;for next register
	inc	(ix-1)
	ret
_pop_af:	ld	a,b
	add	a,#30
	jr	_pop_cont
_pop_ix:	ld	(iy),#dd
	jr	_pop_ix_iy
_pop_iy:	ld	(iy),#fd
_pop_ix_iy:	ld	a,b
	add	a,#20
	inc	iy
	inc	(ix-1)
	jr	_pop_cont

;$$$$$ ret
_ret:
	LD	HL,(reg2_pointer)
	LD	A,(HL)
	or	a
	jp	nz,badmnemonic
	LD	HL,(reg1_pointer)
	ld	a,(hl)
	ld	(iy),#c9
	or	a
	ret	z
	call	voorwaarde
	jp	c,badmnemonic
	add	a,a
	add	a,a
	add	a,a
	or	#c0
	ld	(iy),a
	ret

;$$$$$ rl
_rl:
	LD	HL,(reg2_pointer)
	LD	A,(HL)
	or	a
	jp	nz,badmnemonic
	ld	a,(iy)
	ld	(iy+1),a
	ld	(iy),#cb
	inc	iy
	call	test2ndregis
	jp	c,badmnemonic
	cp	18
	jr	c,_rl1
	cp	21+1
	jp	c,badmnemonic

_rl1:	ld	b,(iy)
	push	bc
	call	test_standa5
	pop	bc
	jp	c,badmnemonic
	dec	iy
	ld	a,(iy)
	cp	3
	ret	nz
	ld	(iy-1),4	;at (ix+ and (iy+ and (ix) and (iy))
	ld	a,(iy+1)
	ld	(iy),a
	ld	(iy+1),#cb
	ld	a,(iy+3)
	ld	(iy+2),a
	ld	a,b
	add	a,6
	ld	(iy+3),a
	ret

;$$$$$ rst
_rst:
	LD	HL,(reg2_pointer)
	LD	A,(HL)
	or	a
	jp	nz,badmnemonic
	LD	HL,(reg1_pointer)
	call	getal16bit
	jp	c,badmnemonic
	ld	a,d
	or	a
	jp	nz,badmnemonic
	ld	a,e
	and	%11000111
	jp	nz,badmnemonic
	ld	a,e
	or	#c7
	ld	(iy),a
	ret

;$$$$$ sbc
_sbc:
	call	test_standa1
	ret	nc
	call	test1stregis
	jp	c,badmnemonic
	ld	b,#42
	jp	_adc_cont

;$$$$$$$$$$ Special commands

;$$$$$ label length
_lablen:
	LD	HL,(reg1_pointer)
	call	getal8bit
	jp	c,badcommand
	ex	de,hl
	ld	de,6
	call	restart20
	jp	c,getaltegroot
	ld	de,21
	call	restart20
	jp	nc,getaltegroot
	ld	a,l
	ld	(Labellengte),a
	ret

;$$$$$ upper on/off
_upper:
	LD	HL,(reg1_pointer)
	ld	a,(hl)
	inc	hl
	and	255-32
	cp	"O"
	jp	nz,badcommand
	ld	a,(hl)
	inc	hl
	and	255-32
	cp	"N"
	ld	b,1
	jr	z,_upperon
	dec	b
	cp	"F"
	jp	nz,badcommand
	ld	a,(hl)
	inc	hl
	and	255-32
	cp	"F"
	jp	nz,badcommand
_upperon:
	ld	a,(hl)
	or	a
	jp	nz,badcommand
	ld	a,b
	ld	(Upperonoff),a
	ret

;$$$$$ defw
_defw:
	LD	HL,(reg1_pointer)
	call	getal16bit
	jp	c,badmnemonic
	call	_defw1
	LD	HL,(reg2_pointer)
_defw_cont:	call	getal16bit
	jr	c,_defw_end
	call	_defw1
	ld	a,(hl)
	inc	hl
	cp	","
	jr	nz,_defw_end
	jr	_defw_cont
_defw1:
	ld	(iy),e
	ld	(iy+1),d
	xor	a
	call	vuladresin
	inc	iy
	inc	iy
	ld	a,(Lengtecode)
	add	a,2
	ld	(Lengtecode),a
	ld	de,(Assembladres)
	inc	de
	inc	de
	ld	(Assembladres),de	;mock increase for $
	ret
_defw_end:
	ld	hl,(Assembladre1)
	ld	(Assembladres),hl	;old ass. address
	ret

;$$$$$defs
_defs:
	ld	a,2
	ld	(Pass),a
	LD	HL,(reg1_pointer)
	call	getal16bit
	jp	c,badmnemonic
	ld	(Lengte_defs),de
	ld	(iy-1),#ff	;length=#ff => defs
	xor	a
	ld	(Vul_defs),a
	LD	HL,(reg2_pointer)
	ld	a,(hl)
	or	a
	ret	z
	call	getal8bit
	jp	c,badmnemonic
	ld	(Vul_defs),a
	ret

;$$$$$ defb
_defb:
	ld	hl,(reg1_pointer)
	call	testdefb
	LD	HL,(reg2_pointer)
	ld	a,(hl)
	or	a
	jr	z,_defb_back
_defb1:	call	testdefb
	ld	a,(hl)
	inc	hl
	cp	","
	jr	z,_defb1
_defb_back:	ld	hl,(Assembladre1)
	ld	(Assembladres),hl
	ret

testdefb:
	call	_defb_tekst
	ret	nc
	call	getal8bit
	jp	c,badcommand
	ld	(iy),a
	inc	iy
	ld	de,(Assembladres)
	inc	de
	ld	(Assembladres),de
	ld	a,(Lengtecode)
	inc	a
	ld	(Lengtecode),a
	ret
_defb_tekst:
	push	hl
	ld	a,(Lengtecode)
	push	af
	ld	a,(hl)
	inc	hl
	cp	34	;"  
	jr	z,_weltekst
	cp	"'"
	jr	nz,_notekst
_weltekst:
	ld	b,a	;" or '
	cp	(hl)
	jr	z,_notekst	;two quotes--calculate-->0
_jon_tekst	ld	a,(hl)
	or	a
	jr	z,_notekst	;error!? (quote forgotten)
	ld	e,a
	inc	hl	;penultimate car. reaches?
	ld	a,(hl)
	cp	b
	jr	z,schakel_8bit	;if so, switch to calculate.
	ld	(iy),e
	inc	iy
	ld	de,(Assembladres)
	inc	de
	ld	(Assembladres),de
	ld	a,(Lengtecode)
	inc	a
	ld	(Lengtecode),a
	jr	_jon_tekst

_notekst:	pop	af
	ld	(Lengtecode),a
	pop	hl
	scf
	ret

schakel_8bit	dec	hl
	dec	hl
	ld	(hl),b	;place quotation mark
	pop	bc	;clean stack
	pop	bc
	scf		;continue 8bit
	ret

;$$$$$ defc
_defc:
	ld	hl,(reg1_pointer)
	call	testdefb	;CHANGED!!!!!!!!!!!!!******
	jp	c,badcommand
	set	7,(iy-1)
	ld	hl,(reg2_pointer)
	ld	a,(hl)
	or	a
	jr	z,_defc_back
_defc1:	call	testdefb
	jp	c,badcommand
	set	7,(iy-1)
	ld	a,(hl)
	inc	hl
	cp	","
	jr	z,_defc1
_defc_back:	ld	hl,(Assembladre1)
	ld	(Assembladres),hl
	ret

D5DBD:	NOP
D5DBE:	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
_jonloop	CALL	C666D
	JR	C,J5DE3
	LD	(D5E45),A
	CP	#06
	JP	Z,J5DE3
	CP	#08
	JR	C,J5DE6
	CP	#0D
	JR	NC,J5DE3
	SUB	#0A
	JR	NC,J5E02
J5DE3:	JP	badmnemonic
J5DE6:	RLCA
	RLCA
	RLCA
	ADD	A,#06
	LD	(IY+#00),A
	LD	HL,(reg2_pointer)
	CALL	getal8bit
	LD	HL,(Assembladres)
	JR	C,J5E22
	LD	(IY+#01),A
	LD	(IY-#01),#02
	JR	J5E20
J5E02:	RLCA
	RLCA
	RLCA
	RLCA
	INC	A
	LD	(IY+#00),A
	LD	HL,(reg2_pointer)
	CALL	getal16bit
	LD	HL,(Assembladres)
	JR	C,J5E22
	LD	(IY+#01),E
	LD	(IY+#02),D
	LD	(IY-#01),#03
	INC	HL
J5E20:	INC	HL
	INC	HL
J5E22:	PUSH	HL
	LD	HL,D5DBD
	LD	A,(HL)
	CP	#04
	JP	Z,toomanyloops
	INC	(HL)
	CALL	C5E3A
	LD	A,(D5E45)
	LD	(HL),A
	INC	HL
	POP	DE
	LD	(HL),E
	INC	HL
	LD	(HL),D
	RET


C5E3A:	LD	L,A
	RLCA
	ADD	A,L
	LD	L,A
	LD	H,#00
	LD	DE,D5DBE
	ADD	HL,DE
	RET

D5E45:	NOP
_jonendloop	LD	HL,D5DBD
	LD	A,(HL)
	OR	A
	JP	Z,noloopopened
	DEC	(HL)
	LD	A,(HL)
	CALL	C5E3A
	LD	A,(HL)
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	LD	DE,(Assembladres)
	CP	#08
	JR	C,J5E81
	LD	(IY-#01),#05
	EXX
	LD	HL,D5EA3
	SUB	#0A
	LD	C,A
	RLCA
	ADD	A,C
	LD	C,A
	LD	B,#00
	ADD	HL,BC
	LD	DE,Code
	LD	C,#03
	LDIR
	PUSH	DE
	POP	IY
	EXX
	INC	DE
	INC	DE
	JR	J5E9B
J5E81:	LD	(IY-#01),#03
	OR	A
	JR	NZ,J5E91
D5E88:	DEC	(IY-#01)
	LD	(IY+#00),#10
	JR	J5EA0
J5E91:	RLCA
	RLCA
	RLCA
	ADD	A,#05
	LD	(IY+#00),A
	INC	IY
J5E9B:	LD	(IY+#00),#20
	INC	DE
J5EA0:	JP	J565D
D5EA3:	DEC	BC
	LD	A,B
	OR	C
	DEC	DE
	LD	A,D
	OR	E
	DEC	HL
	LD	A,H
	OR	L

;$$$$$ mulub
_mulub:
	ld	(iy-1),2
	ld	(iy),#ed
	call	test1stregis
	jp	c,badmnemonic
	cp	7
	jp	nz,badmnemonic
	call	test2ndregis
	jp	c,badmnemonic
	cp	3+1
	jp	nc,badmnemonic
	add	a,a
	add	a,a
	add	a,a
	or	#c1
	ld	(iy+1),a
	ret

;$$$$$ muluw
_muluw:
	ld	(iy-1),2
	ld	(iy),#ed
	call	test1stregis
	jp	c,badmnemonic
	cp	12
	jp	nz,badmnemonic
	call	test2ndregis
	jp	c,badmnemonic
	cp	10
	ld	(iy+1),#c3
	ret	z
	cp	13
	ld	(iy+1),#f3
	ret	z
	jp	badmnemonic

;$$$$$ org
_org:
	call	testrel1	;not in phase mode
	ld	a,(Macro)
	or	a
	ret	nz
	call	welassembl
	ret	c	;no code because of if
	LD	HL,(reg2_pointer)
	LD	A,(HL)
	or	a
	jp	nz,badmnemonic
	ld	a,(Pass)
	push	af
	ld	a,2
	ld	(Pass),a	;now pass 2
	ld	hl,(reg1_pointer)
	call	getal16bit
	pop	bc
	jp	c,badmnemonic
	ld	(Assembladres),de
	ld	a,b	;pass
	cp	1
	ret	z
	ld	a,(Relocatable)
	or	a
	jp	z,_totijdbuf3	;send to ram, because new address

	call	speciallink
	ld	a,(Segment)
	or	%101100
	ld	b,6
	call	putbits
	ld	de,(Assembladres)
	jp	putadres	;new location counter

;$$$$$ defl
_defl:
	ld	a,(Domacro)
	or	a
	jp	z,badcommand	;only on macro call
;$$$$$ equ
_equ:
	ld	a,(Pass)
	dec	a
	ret	nz
	call	welassembl
	ret	c	;no code because of if
	ld	a,(Label)
	or	a
	jp	z,badmnemonic
	ld	a,(Macro)
	or	a
	ret	nz	;don't define macro in the middle
	LD	HL,(reg2_pointer)
	LD	A,(HL)
	or	a
	jp	nz,badmnemonic
	ld	a,2
	ld	(Pass),a	;now pass 2
	xor	a
	ld	(Equ_segment),a
	ld	hl,(reg1_pointer)
	call	getal16bit
	jp	c,badmnemonic
	ld	a,1
	ld	(Equ_found),a
	ld	(Equ_adres),de
	ret
Equ_segment:	defb	0	;is filled in by test label, pass 2

;$$$$$ end
_end:
	ld	a,(Macro)
	or	a
	ret	nz
	call	welassembl
	ret	c	;no code because of if
	ld	a,1
	ld	(Endcode),a
	ret

;$$$$$ breakp
_breakp:
	call	testrel1
	ld	a,(Macro)
	or	a
	ret	nz
	call	welassembl
	ret	c
	LD	HL,(reg1_pointer)
	LD	A,(HL)
	or	a
	jp	nz,badmnemonic

	ld	hl,Assembledisk
	ld	a,(hl)
	inc	hl
	or	(hl)
	inc	hl
	or	(hl)
	ret	nz
	ld	a,(Pass)
	dec	a
	ret	z

	ld	a,(Firstbp)
	or	a
	ld	hl,#4003
	call	z,godeb	;clear all breakpoints
	ld	a,1
	ld	(Firstbp),a
	ld	hl,(Assembladres)
	push	hl
	ld	hl,#4006
	jp	gotodebugger
godeb:
	push	hl
	jp	gotodebugger

Firstbp:	defb	0	;0=1st time, 1=2nd..next time

;$$$$$ tsrhooks
_tsrhooks:
	ld	a,(Tsr)
	or	a
	jp	z,badcommand
	ld	a,1
	ld	(Tsrhooks),a
	ret

;$$$$$ cseg
_cseg:
	call	testrel
	call	testrel1
	call	saveoldsegm
	ld	a,1
	ld	(Segment),a
	call	speciallink
	ld	a,%101101
	ld	b,6
	call	putbits
	ld	hl,(Cseg)
	ld	(Assembladres),hl
	ex	de,hl
	jp	putadres
Segment:	defb	0	;Current segment: 0=ABS, 1=CSEG, 2=DSEG
Cseg:	defw	0
Firstcseg:	defw	0
Csegcomm:	defb	0
saveoldsegm:	;Also called from beginning Codeassemble !!!
	ld	a,(Segment)
	ld	hl,(Assembladres)
	or	a
	jr	z,_save_aseg
	dec	a
	jr	z,_save_cseg
_save_dseg:	ld	(Dseg),hl	;******lqbel not used
	ret
_save_cseg:	ld	(Cseg),hl
	ret
_save_aseg:	ld	(Aseg),hl
	ret

_dseg:
	call	testrel
	call	testrel1
	call	saveoldsegm
	ld	a,2
	ld	(Segment),a
	call	speciallink
	ld	a,%101110
	ld	b,6
	call	putbits
	ld	hl,(Dseg)
	ld	(Assembladres),hl
	ex	de,hl
	jp	putadres
Dseg:	defw	0
Firstdseg:	defw	0
Dsegcomm:	defb	0

_aseg:
	call	testrel
	call	testrel1
	call	saveoldsegm
	xor	a
	ld	(Segment),a
	call	speciallink
	ld	a,%101100
	ld	b,6
	call	putbits
	ld	hl,(Aseg)
	ld	(Assembladres),hl
	ex	de,hl
	jp	putadres
Aseg:	defw	0

;$$$$$ public
_public:
	call	testrel
	ld	hl,(reg1_pointer)
	call	testoflabel
	jp	c,badcommand
	call	savepublic
	ld	hl,(reg2_pointer)
_publicloop:
	call	testoflabel
	ret	c
	push	hl
	call	savepublic
	pop	hl
_publiccont:
	ld	a,(hl)
	inc	hl
	or	a
	ret	z
	cp	","
	jr	z,_publicloop
	jp	badcommand


savepublic:
	ld	a,(Pass)
	dec	a
	jr	nz,_publicpass2
	ld	de,Label
savepublic1:	;Call from putlabel !!!
	ld	hl,(Aantalpublic)
	inc	hl
	ld	(Aantalpublic),hl
	ld	hl,(Publicadres)
_savepublic1:
	ld	a,(de)
	inc	de
	call	writevram
	inc	hl
	or	a
	jr	nz,_savepublic1
	ld	(Publicadres),hl
	ret
_publicpass2:
	push	hl
	ld	hl,Label
	call	labelexist
	pop	hl
	jp	c,publicnotfou
	ret

Aantalpublic:	defw	0
Publicadres:	defw	0

_extrn:
	call	testrel
	ld	a,(Pass)
	dec	a
	ret	nz	;only pass 1
	ld	hl,(reg1_pointer)
	call	testoflabel
	jp	c,badcommand
	call	extrn1
	ld	hl,(reg2_pointer)
	ld	a,(hl)
	or	a
	ret	z
_extrn1:
	call	testoflabel
	jp	c,badcommand
	push	hl
	call	extrn1
	pop	hl
	ld	a,(hl)
	or	a
	ret	z
	cp	","
	jp	nz,badcommand
	inc	hl
	jr	_extrn1

extrn1:
	ld	hl,Label
	call	putlabel1
	jp	c,labelbestond
	ld	a,b
	call	zetlabblok
	xor	a
	call	putlabbuffer
	xor	a
	call	putlabbuffer	;1st entry address 0
	ld	a,%00100000	;Mark external
	call	putlabbuffer
	ld	hl,(Aantalextern)
	inc	hl
	ld	(Aantalextern),hl
	ld	hl,(Externadres)
	ld	de,Label
_saveextern1:
	ld	a,(de)
	inc	de
	call	writevram
	inc	hl
	or	a
	jr	nz,_saveextern1
	ld	(Externadres),hl
	ret

Aantalextern:	defw	0
Externadres:	defw	0


testoflabel:
	call	testfound1
	ccf
	ret	c	;1st character already wrong
	ld	de,Label
_testoflab4:
	push	de
	call	testfound1
	pop	de
	jr	nc,_testoflab3
	ld	a,(hl)
	inc	hl
	ld	(de),a
	inc	de
	jr	_testoflab4
_testoflab3:
	xor	a
	ld	(de),a
	ret

Vramextrn:	defw	0
savelabel:
	call	setvramwrite
	ld	de,Label
_savelabel1:
	ld	a,(de)
	inc	de
	out	(#98),a
	inc	hl
	or	a
	jr	nz,_savelabel1
	ret

_phase:
	call	testrel
	ld	a,(Phase)
	or	a
	jp	nz,badcommand	;phase already open
	inc	a
	ld	(Phase),a
	call	saveoldsegm
	ld	a,(Segment)
	ld	(Oldsegment),a
	xor	a
	ld	(Segment),a	;simulation absolute
	ld	hl,(Assembladres)
	ld	(Oldaddress),hl	;easier for dephase
	ld	hl,(reg1_pointer)
	call	getal16bit
	jp	c,badcommand
	ld	(Phaseaddress),de
	ld	(Assembladres),de
	ret

Phase:	defb	0	;0=off, 1=on
Phaseaddress:	defw	0
Oldsegment:	defb	0
Oldaddress:	defw	0

_dephase:
	call	testrel
	ld	a,(Phase)
	or	a
	jp	z,badcommand	;phase not open
	dec	a
	ld	(Phase),a
	ld	hl,(Assembladres)
	ld	de,(Phaseaddress)
	or	a
	sbc	hl,de	;phase code length
	ex	de,hl
	ld	a,(Oldsegment)
	ld	(Segment),a
	ld	hl,(Oldaddress)
	add	hl,de	;add phase length to it
	ld	(Assembladres),hl
	ret

testrel:
	ld	a,(Relocatable)
	or	a
	jp	z,onlyrel
	ret
testrel1:
	ld	a,(Phase)
	or	a
	jp	nz,inphase
	ret

;$$$$$ if
_if:
	ld	a,(Macro)
	or	a
	ret	nz
	call	welassembl
	jr	nc,_if2
	ld	hl,If_wacht
	inc	(hl)
	ret
_if2:
	ld	a,2
	ld	(Pass),a	;now pass 2
	ld	hl,(reg1_pointer)
	call	doif
	push	af
	ld	hl,(Contifadres)
	call	testandor
	jr	nc,_andorfound
	ld	hl,(reg2_pointer)
	call	testandor
	jr	nc,_andorfound
	pop	af
	jr	_einde_if
_andorfound:
	push	bc
	call	doif
	pop	bc
	pop	de	;d=first 0/1, a=second 0/1
	dec	c
	jr	z,_do_or
	and	1
	jr	z,_einde_if
	ld	a,d
	and	1
	jr	_einde_if
_do_or:
	or	d
_einde_if:
	or	#80
	ld	hl,(If_adres)	;#81=assemble, #80=not ass.
	inc	hl
	bit	7,(hl)
	jp	nz,toomanyifs
	ld	(hl),a
	ld	(If_adres),hl
	xor	a
	ld	(If_wacht),a
	ret

Contifadres:	defw	0

testandor:
	ld	a,(hl)
	inc	hl
	or	a
	jr	z,_testandorno
	cp	" "
	jr	z,testandor
	cp	9
	jr	z,testandor
	cp	"."
	jr	nz,_testandorno
	ld	de,Testand
	ld	b,3
	push	hl
	ld	c,-1
	call	testandor1	;c=0
	pop	de
	jr	nc,_testandor2
	ex	de,hl
	ld	de,Testor
	ld	b,2
	call	testandor1	;c=1
	jr	c,_testandorno
_testandor2:
	ld	a,(hl)
	inc	hl
	cp	"."
	jr	nz,_testandorno
_testandor1:
	ld	a,(hl)
	inc	hl
	cp	9
	jr	z,_testandor1
	cp	" "
	jr	z,_testandor1
	dec	hl
	xor	a
	ret
_testandorno:
	scf
	ret

testandor1:
	inc	c
testandor1_1:
	res	5,(hl)
	ld	a,(de)
	inc	de
	cp	(hl)
	inc	hl
	scf
	ret	nz
	djnz	testandor1_1
	xor	a
	ret


Testand:	defb	"AND"
Testor:	defb	"OR"


doif:
	call	getal16bit
	jp	c,ifstring
	push	de
	ld	a,(hl)
	or	a
	ld	de,0
	ld	b,#84	;<>0  
	jr	z,_if3
	call	haalteken
	jp	c,badmnemonic
	push	af
	call	getal16bit
	jp	c,gotoifstring
	ld	(Contifadres),hl
	pop	bc
_if3:	pop	hl	;hl=1st, de=2nd
	call	testif
	ld	a,1
	ret	nc
	dec	a
	ret


gotoifstring:
	pop	af
	pop	af	;get rid of 2 calls
ifstring:
	ld	hl,(reg1_pointer)	;source
	ld	de,(reg1_pointer)	;target
	call	teststring
	jp	c,badcommand
	ld	(Lengte1),a
	xor	a
	LD	DE,(reg2_pointer)
	ld	(de),a
	ld	a,(hl)
	or	a
	ld	de,0
	ld	b,#84	;<>0   
	jr	z,_ifstring3
	call	haalteken
	jp	c,badmnemonic
	push	af
	ld	de,(reg2_pointer)	;target
	call	teststring
	jp	c,badcommand
	ld	(Contifadres),hl
	ld	(Lengte2),a
	pop	bc
_ifstring3:
	ld	hl,(reg1_pointer)
	ld	de,(reg2_pointer)
	call	testifstring
	ld	a,1
	ret	nc
	dec	a
	ret

testifstring:
	bit	7,b
	jr	nz,_testifstr1
	srl	b
	jr	c,groterstr
	srl	b
	jr	c,kleinerstr
	srl	b
	jr	c,gelijkstr
_testifstr1:	srl	b
	jr	c,grotgelstr
	srl	b
	jr	c,kleigelstr
	jr	kleigrotstr

Lengte1:	defb	0
Lengte2:	defb	0

grotgelstr:
	push	hl
	push	de
	call	gelijkstr
	pop	de
	pop	hl
	ret	nc
groterstr:
	ld	a,(Lengte2)
	ld	b,a
	ld	a,(Lengte1)
_groterstr2:
	sub	b	;[C] =>
	ret	nz
_groterstr1:
	ld	a,(de)
	or	(hl)
	scf
	ret	z
	ld	a,(de)
	inc	de
	sub	(hl)
	inc	hl
	jr	z,_groterstr1
	ccf
	ret
kleigelstr:
	push	hl
	push	de
	call	gelijkstr
	pop	de
	pop	hl
	ret	nc
kleinerstr:
	ld	a,(Lengte1)
	ld	b,a
	ld	a,(Lengte2)
	ex	de,hl
	jr	_groterstr2
kleigrotstr:
	call	gelijkstr
	ccf
	ret
gelijkstr:
	ld	a,(de)
	or	(hl)
	ret	z
	ld	a,(de)
	inc	de
	cp	(hl)
	inc	hl
	jr	z,gelijkstr
	scf
	ret

teststring:
	ld	a,(hl)
	inc	hl
	cp	34
	jr	z,_teststring1
	cp	"'"
	scf
	ret	nz
_teststring1:
	ld	b,a	;" or '
	ld	c,0
_teststringl:
	ld	a,(hl)
	inc	hl
	cp	b
	jr	z,_teststring2
	or	a
	scf
	ret	z
	ld	(de),a
	inc	de
	inc	c
	jr	_teststringl
_teststring2:
	xor	a
	ld	(de),a
	ld	a,c
	ret

testif:
	bit	7,b
	jr	nz,_testif1
	srl	b
	jr	c,testgroter
	srl	b
	jr	c,testkleiner
	srl	b
	jr	c,testgelijk
_testif1:	srl	b
	jr	c,testgrotgeli
	srl	b
	jr	c,testkleigeli
	jr	testkleigrot

testgelijk:	call	restart20
	ret	z
	scf
	ret
testgroter:	call	restart20
	ret	c	;<  
	or	a
	ret	nz	;>
	scf
	ret		;=  
testkleiner:	call	restart20
	ccf
	ret		;[C] is not smaller
testkleigrot:	call	testgelijk
	ccf
	ret
testkleigeli:	call	testgelijk
	ret	z
	jr	testkleiner
testgrotgeli:	call	testgelijk
	ret	z
	jr	testgroter

If_wacht:	defb	0	;<>0 => n * wait for next endif

	defb	0	;intro if
Ifs:	defs	16	;bit7: 1=if exists, bit0: 1=assembl.
	defb	#ff	;extra if
If_adres:	defw	Ifs-1

haalteken:
	ld	de,Tekens
	ld	b,9
_haalteken2:	push	hl
	ld	a,(de)
	inc	de
	cp	(hl)
	jr	nz,_haalteken1
	ld	a,(de)
	or	a
	jr	z,_haalteken3
	inc	hl
	cp	(hl)
	jr	z,_haalteken3
_haalteken1:	pop	hl
	inc	de
	inc	de
	djnz	_haalteken2
	scf
	ret
_haalteken3:	pop	bc
	inc	hl
	inc	de
	ld	a,(de)
	or	a
	ret
Tekens:	defb	">=",#81,"=>",#81,"<=",#82,"=<",#82,"<>",#84,"><",#84
	defb	">",0,1,"<",0,2,"=",0,4

;$$$$$ else
_else:
	ld	a,(Macro)
	or	a
	ret	nz
	ld	a,(If_wacht)
	or	a
	ret	nz
	ld	hl,(If_adres)
	ld	a,(hl)
	bit	7,a
	ret	z	;no if
	xor	1
	ld	(hl),a	;turn around
	ret

;$$$$$ endif
_endif:
	ld	a,(Macro)
	or	a
	ret	nz
	call	welassembl
	jr	nc,_endif1
	ld	hl,If_wacht
	ld	a,(hl)
	or	a
	jr	z,_endif1
	dec	(hl)
	ret
_endif1:	ld	hl,(If_adres)
	ld	a,(hl)
	or	a
	ret	z	;start buffer
	ld	(hl),0
	dec	hl
	ld	(If_adres),hl
	ret

;$$$$$ macro

;MACRO: address+block next, label, address rest, block rest (sort<>0)

Macro:	defb	0	;1=running macro

_macro:
	ld	a,(Pass)
	dec	a
	jr	nz,_macropass2

_macropass1:
	ld	a,(Macro)
	or	a
	jp	nz,macroisopen
	inc	a
	ld	(Macro),a
	ld	a,(Label)
	or	a
	jp	z,nolabelmacro

	ld	a,(Labelblkdoel)
	call	zetlabblok
	ld	de,(Labeladrdoel)
	xor	a
	call	putlabbuffer
	xor	a
	call	putlabbuffer	;no value
	ld	a,1
	call	putlabbuffer	;kind = macro

	ld	hl,(reg1_pointer)
	call	haalmacrolab
	jr	c,_macro1
	ld	hl,(reg2_pointer)
_nextmlabel:	call	haalmacrolab
	jr	nc,_nextmlabel

_macro1:
	ld	a,#ff
	call	putlabbuffer	;#ff = end of labels
	ld	(Macrobufadr),de
	ld	a,(Labbloknr)
	ld	(Macrobufblk),a
	ret
macrobadcomm:
	call	_macro1
	jp	badcommand
macrolabelto:
	call	_macro1
	jp	labeltoolong

Macrobufadr:	defw	0
Macrobufblk:	defb	0

_macropass2:
	ld	a,1
	ld	(Macro),a
	ret



;----- read macro label in     OUT: [C]=no label
haalmacrojon	inc	hl
haalmacrolab:
	ld	a,(hl)
	or	a
	scf
	ret	z
	cp	9
	jr	z,haalmacrojon	;minor bug fix in 1.2.09
	cp	" "
	jr	z,haalmacrojon	;minor bug fix in 1.2.09
	cp	"@"
	jp	nz,macrobadcomm	;no "@"
	ld	a,(Labellengte)
	ld	b,a
	ld	c,b
	inc	b
_nextmacrotk:	ld	a,(hl)
	;inc hl ;major bugfix in 1.2.09: leave HL on shutdown zero!
	or	a
	jr	z,_mlabelfound	;major bug fix 1.2.09
	inc	hl	;major bug fix 1.2.09
	cp	","
	jr	z,_mlabelfound
	call	putlabbuffer
	djnz	_nextmacrotk
	jp	macrolabelto
_mlabelfound:
	ld	a,c
	cp	b
	jp	z,macrobadcomm	;alone @
	xor	a
	call	putlabbuffer
	or	a
	ret

;$$$$$ endm

_endm:
	ld	a,(Macro)
	ld	b,a
	xor	a
	ld	(Macro),a
	ld	a,(Pass)
	dec	a
	ret	nz	;only pass 1
	ld	a,b
	or	a
	jp	z,macronotopen
	ld	a,(Macrobufblk)
	call	zetlabblok
	ld	de,(Macrobufadr)
	ld	a,#ff
	call	putlabbuffer	;#ff = end of text
	ld	a,(Labbloknr)
	ld	(Eindlabblok),a	;new end of label buffer
	ld	(Eindlabadres),de
	ret

;$$$$$ include

Includeram:	defw	0	;old buffer, rule, label, upper
Aantalinclud:	defb	0
Ramincl:	defs	4*5	;maximum, otherwise all buffers full


_include:
	ld	a,(Upperonoff)
	push	af
	ld	a,(Labellengte)
	push	af
	ld	a,(Sourcebuffer)
	ld	(Oudbuffer),a
	push	af
	ld	hl,(reg1_pointer)
	call	getal8bit
	or	a
	jp	z,badcommand
	cp	5
	jp	nc,badcommand
	ld	e,a
	call	openadres
	bit	0,(hl)
	jp	nz,bufferinuse
	ld	a,e
	call	GOsetbuf
	jp	c,bufnotexist
	ld	hl,(reg2_pointer)
	ld	a,(hl)
	or	a
	jr	z,_include1
	LD	HL,(reg2_pointer)
_include4:
	inc	hl
	ld	a,(hl)
	or	a
	jr	z,_include2
	cp	34
	jr	z,_include3
	cp	"'"
	jr	nz,_include4
_include3:
	ld	(hl),0
_include2:
	ld	a,(Pass)
	dec	a
	jr	z,_include5
	call	berusedadr
	ld	a,(hl)
	cp	2
	jr	c,_include1	;do not load !
	call	_totijdbuf3	;did load in pass 2of3: send buffer1024 because buffer1024 messed up on loading
_include5:
	ld	hl,(reg2_pointer)
	inc	hl
	call	doinclude
	jp	c,incldiskerr
	ld	a,(Pass)
	dec	a
	jr	nz,_include1
	call	berusedadr
	inc	(hl)
_include1:
	ld	hl,Aantalinclud
	inc	(hl)
	ld	hl,(Includeram)
	pop	af
	ld	(hl),a	;old buffer
	inc	hl
	ld	de,(Assemblregel)
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	pop	af
	ld	(hl),a	;label length
	inc	hl
	pop	af
	ld	(hl),a	;upper
	inc	hl
	ld	(Includeram),hl
	call	includeini
	ld	hl,0
	ld	(Assemblregel),hl	;is increased
	ret

openadres:
	ld	hl,Bufferopen-1
	add	a,l
	ld	l,a
	ret	nc
	inc	h
	ret


free	equ	((($+255)/256)*256)
	ds	free-$,0
	org	free

vijftabniks	macro
	dw	tabniks
	dw	tabniks
	dw	tabniks
	dw	tabniks
	dw	tabniks
	endm
tientabniks	macro
	vijftabniks
	vijftabniks
	endm

tabcom	tientabniks	;0...
	tientabniks
	tientabniks
	tientabniks	;..39
	vijftabniks	;...44
	dw	tabniks	;45
	dw	tabpunt	;46
	dw	tabniks
	dw	tabniks
	dw	tabniks
	tientabniks	;...59
	vijftabniks	;...64
	dw	tabA
	dw	tabB
	dw	tabC
	dw	tabD
	dw	tabE
	dw	tabniks
	dw	tabniks
	dw	tabH
	dw	tabI
	dw	tabJ
	dw	tabniks
	dw	tabL
	dw	tabM
	dw	tabN
	dw	tabO
	dw	tabP
	dw	tabniks
	dw	tabR
	dw	tabS
	dw	tabT
	dw	tabniks
	dw	tabniks
	dw	tabniks
	dw	tabX
	dw	tabniks
	dw	tabniks	;90
	vijftabniks	;..95
	dw	tabniks
	dw	tabA	;97
	dw	tabB
	dw	tabC
	dw	tabD
	dw	tabE
	dw	tabniks
	dw	tabniks
	dw	tabH
	dw	tabI
	dw	tabJ
	dw	tabniks
	dw	tabL
	dw	tabM
	dw	tabN
	dw	tabO
	dw	tabP
	dw	tabniks
	dw	tabR
	dw	tabS
	dw	tabT
	dw	tabniks
	dw	tabniks
	dw	tabniks
	dw	tabX
	dw	tabniks
	dw	tabniks	;122
	vijftabniks	;..127
tabniks	db	0
tabA	db	4
	defb	7,"DD",0,1,#80
	defw	_add
	defb	7,"ND",0,1,#a0
	defw	_and
	defb	7,"DC",0,1,#88
	defw	_adc
	defb	8,"SEG",0,0,0
	defw	_aseg
tabB	db	2
	defb	7,"IT",0,2,#40
	defw	_bit
	defb	10,"REAKP",0,0,0
	defw	_breakp
tabC	db	10
	defb	8,"ALL",0,3,#c4
	defw	_call
	defb	6,"P",0,1,#b8
	defw	_and
	defb	7,"PL",0,1,#2f
	defw	_ccf
	defb	7,"CF",0,1,#3f
	defw	_ccf
	defb	8,"PIR",0,2,#b1
	defw	_cpd
	defb	7,"PI",0,2,#a1
	defw	_cpd
	defb	7,"PD",0,2,#a9
	defw	_cpd
	defb	8,"PDR",0,2,#b9
	defw	_cpd
	defb	8,"SEG",0,0,0
	defw	_cseg
	defb	8,"OND",0,0,0
	defw	_if
tabD	db	16
	defb	6,"B",0,0,0
	defw	_defb
	defb	6,"W",0,0,0
	defw	_defw
	defb	8,"JNZ",0,2,#10
	defw	_djnz
	defb	6,"S",0,0,0
	defw	_defs
	defb	7,"EC",0,1,#05
	defw	_dec
	defb	6,"I",0,1,#f3
	defw	_ccf
	defb	6,"C",0,0,0
	defw	_defc
	defb	7,"AA",0,1,#27
	defw	_ccf
	defb	8,"EFB",0,0,0
	defw	_defb
	defb	8,"EFW",0,0,0
	defw	_defw
	defb	8,"EFS",0,0,0
	defw	_defs
	defb	8,"EFC",0,0,0
	defw	_defc
	defb	6,"M",0,0,0
	defw	_defb
	defb	8,"EFM",0,0,0
	defw	_defb
	defb	8,"EFL",0,0,0
	defw	_defl
	defb	8,"SEG",0,0,0
	defw	_dseg
tabE	db	11
	defb	7,"QU",0,0,0
	defw	_equ
	defb	6,"X",0,1,0
	defw	_ex
	defb	7,"XX",0,1,#d9
	defw	_ccf
	defb	6,"I",0,1,#fb
	defw	_ccf
	defb	8,"NDM",0,0,0
	defw	_endm
	defb	9,"NDIF",0,0,0
	defw	_endif
	defb	8,"LSE",0,0,0
	defw	_else
	defb	9,"XTRN",0,0,0
	defw	_extrn
	defb	8,"NDC",0,0,0
	defw	_endif
	defb	11,"NDLOOP",0,0,0
	defw	_jonendloop
	defb	7,"ND",0,0,0
	defw	_end
tabH	db	1
	defb	8,"ALT",0,1,#76
	defw	_ccf
tabI	db	9
	defb	7,"NC",0,1,#04
	defw	_inc
	defb	6,"N",0,2,#40
	defw	_in
	defb	7,"NI",0,2,#a2
	defw	_cpd
	defb	8,"NIR",0,2,#b2
	defw	_cpd
	defb	6,"F",0,0,0
	defw	_if
	defb	7,"ND",0,2,#aa
	defw	_cpd
	defb	8,"NDR",0,2,#ba
	defw	_cpd
	defb	11,"NCLUDE",0,0,0
	defw	_include
	defb	6,"M",0,2,#ed
	defw	_im
tabJ	db	2
	defb	6,"R",0,2,#20
	defw	_jr
	defb	6,"P",0,3,#c2
	defw	_jp
tabL	db	6
	defb	6,"D",0,1,0
	defw	_ld
	defb	8,"DIR",0,2,#b0
	defw	_cpd
	defb	7,"DI",0,2,#a0
	defw	_cpd
	defb	8,"DDR",0,2,#b8
	defw	_cpd
	defb	7,"DD",0,2,#a8
	defw	_cpd
	defb	8,"OOP",0,0,0
	defw	_jonloop
tabM	db	3
	defb	9,"ACRO",0,0,0
	defw	_macro
	defb	9,"ULUB",0,0,0
	defw	_mulub
	defb	9,"ULUW",0,0,0
	defw	_muluw
tabN	db	2
	defb	7,"OP",0,1,#00
	defw	_ccf
	defb	7,"EG",0,2,#44
	defw	_cpd
tabO	db	7
	defb	7,"UT",0,2,#41
	defw	_out
	defb	6,"R",0,1,#b0
	defw	_and
	defb	8,"TIR",0,2,#b3
	defw	_cpd
	defb	8,"UTI",0,2,#a3
	defw	_cpd
	defb	7,"RG",0,0,0
	defw	_org
	defb	8,"TDR",0,2,#bb
	defw	_cpd
	defb	8,"UTD",0,2,#ab
	defw	_cpd
tabP	db	3
	defb	7,"OP",0,0,#c1
	defw	_pop
	defb	8,"USH",0,0,#c5
	defw	_pop
	defb	10,"UBLIC",0,0,0
	defw	_public
tabR	db	15
	defb	7,"ET",0,1,#c0
	defw	_ret
	defb	8,"RCA",0,1,#0f
	defw	_ccf
	defb	7,"RA",0,1,#1f
	defw	_ccf
	defb	7,"LA",0,1,#17
	defw	_ccf
	defb	8,"LCA",0,1,#07
	defw	_ccf
	defb	7,"ES",0,2,#80
	defw	_bit
	defb	6,"L",0,2,#10
	defw	_rl
	defb	7,"LC",0,2,#00
	defw	_rl
	defb	6,"R",0,2,#18
	defw	_rl
	defb	7,"RC",0,2,#08
	defw	_rl
	defb	7,"ST",0,1,0
	defw	_rst
	defb	7,"RD",0,2,#67
	defw	_cpd
	defb	7,"LD",0,2,#6f
	defw	_cpd
	defb	8,"ETI",0,2,#4d
	defw	_cpd
	defb	8,"ETN",0,2,#45
	defw	_cpd
tabS	db	8
	defb	7,"UB",0,1,#90
	defw	_and
	defb	7,"BC",0,1,#98
	defw	_sbc
	defb	7,"CF",0,1,#37
	defw	_ccf
	defb	7,"ET",0,2,#c0
	defw	_bit
	defb	7,"LA",0,2,#20
	defw	_rl
	defb	7,"RA",0,2,#28
	defw	_rl
	defb	7,"RL",0,2,#38
	defw	_rl
	defb	7,"LL",0,2,#30	;Illegal command!!!!!
	defw	_rl
tabT	db	1
	defb	12,"SRHOOKS",0,0,0
	defw	_tsrhooks
tabX	db	1
	defb	7,"OR",0,1,#a8
	defw	_and
tabpunt	db	4
	defb	10,"PHASE",0,0,0
	defw	_phase
	defb	12,"DEPHASE",0,0,0
	defw	_dephase
	defb	10,"LABEL",0,0,0
	defw	_lablen
	defb	10,"UPPER",0,0,0
	defw	_upper

Oudbuffer:	defb	0
Bufferopen:	defb	0,0,0,0
Aantalused:	defb	0,0,0,0	;per buffer: number of times file include
	;LEAVE BACK TO EACH OTHER !

berusedadr:
	ld	a,(Sourcebuffer)
	ld	e,a
	ld	d,0
	ld	hl,Aantalused-1
	add	hl,de
	ret

;----- Test or standard: A,B A,C A,D A,E A,H A,L A,(HL) A,A A,(IX+) A,(IY+)
;                     A,..
;                     OUT: [C]=non-standard

test_standa1:
	call	test1stregis
	ret	c
	cp	7
	scf
	ret	nz	;reg1 <> A
test_standa6:	call	test2ndregis
	jp	c,_test_getal
test_standa5:	cp	24
	jp	z,test_ix_iy2	;(ix)
	cp	25
	jp	z,test_ix_iy2	;(iy)
	cp	18
	jp	nc,test_ixh
	cp	8
	jr	z,test_ix_iy
	cp	9
	jr	z,test_ix_iy
	ccf
	ret	c	;>(iy
	add	a,(iy)
	ld	(iy),a
	or	a
	ret
test_ix_iy:	ld	b,a
	ld	a,(iy)
	add	a,6
test_standa2:	ld	(iy+1),a
	ld	(iy),#dd
	ld	a,b
	cp	8
	jr	z,_test_ix_iy1
	set	5,(iy)
_test_ix_iy1:	ex	de,hl
	ld	(iy-1),3
	ld	a,(Pass)
	dec	a
	ret	z	;At pass 1 => back
	call	getal8bit
	ret	c
	call	testoffset
	jp	c,offsettegroo
	ld	(iy+2),e
	ld	a,(hl)
	cp	")"
	ret	z
	scf
	ret

test_ix_iy2:	ld	b,a
	ld	a,(iy)
	add	a,6
test_standa4:	ld	(iy+1),a
	ld	(iy+2),0	;(ix) and (iy)
	ld	(iy-1),3
	ld	(iy),#dd
	ld	a,b
	cp	24
	ret	z
	set	5,(iy)
	ret

test_ixh:	cp	22	;IXh,IXl,IYh,IYl
	ccf
	ret	c
	sub	18
	ld	b,a
	and	1
	add	a,4
	add	a,(iy)
	ld	(iy+1),a
test_standa3:	ld	hl,(Turborcomm)
	inc	hl
	ld	(Turborcomm),hl
	inc	(iy-1)
	bit	1,b
	ld	(iy),#dd
	ret	z
	set	5,(iy)
	ret
_test_getal:
	ex	de,hl
	call	getal8bit
	ret	c
	ld	(iy+1),a
	inc	(iy-1)
	ld	a,(iy)
	add	a,#46
	ld	(iy),a
	or	a
	ret

;----- check if offset is not too big   IN: DE=number  OUT: [C]=too big

testoffset:
	ld	a,d
	or	a
	ld	a,e
	jr	nz,_testoffset1
	cp	#80
	ccf
	ret
_testoffset1:	cp	#80
	ret

;----- Test 1st register      OUT: [C]=no register, A=num register (0-..)

test1stregis:
	ld	hl,(reg1_pointer)
	ld	a,(hl)
	or	a
	scf
	ret	z	;Wrong !
	ld	hl,(reg2_pointer)
	ld	a,(hl)
	or	a
	ld	a,7
	ret	z	;no reg. 2 => reg. 1 = A

C666D	ld	hl,(reg1_pointer)
_testcont:	ld	(Testadres1+1),hl
	ld	hl,Registers
	ld	ix,Registers
	ld	c,0	;num 0
_test1st_1:
Testadres1:	ld	de,0	;filled in !!!
	ld	a,(hl)
	or	a
	scf
	ret	z	;Not found !
	ld	b,4
_test1st_5:	ld	a,(de)
	cp	"a"
	jr	c,_test1st_4	;<"a"
	cp	"z"+1
	jr	nc,_test1st_4	;>"z"
	and	%11011111	;small=big
_test1st_4:	cp	(hl)
	jr	nz,_test1st_2	;not equal
	or	a
	ld	a,c
	ret	z
	inc	hl
	inc	de
	djnz	_test1st_5
	ld	a,c
	ret
_test1st_2:	ld	a,(hl)
	cp	#ff
	jr	z,_test1st_6	;(IX and (IY
_test1st_7:	ld	de,4
	add	ix,de
	push	ix
	pop	hl
	inc	c
	jr	_test1st_1

_test1st_6:	ld	a,(de)
	cp	")"
	jr	z,_test1st_7	;not (IX+/- or (IY+/-
	ld	a,c
	or	a
	ret		;(IX+/- or (IY+/-

Registers:	defb	"B",0,0,0,"C",0,0,0,"D",0,0,0,"E",0,0,0	;0-3  
	defb	"H",0,0,0,"L",0,0,0,"(HL)","A",0,0,0	;4-7  
	defb	"(IX",#ff,"(IY",#ff,"BC",0,0,"DE",0,0	;8-11  
	defb	"HL",0,0,"SP",0,0	;12-13  
	defb	"IX",0,0,"IY",0,0,"AF",0,0,"(SP)"	;14-17  
	defb	"IXH",0,"IXL",0,"IYH",0,"IYL",0	;18-21  
	defb	"F",0,0,0,"(C)",0,"(IX)","(IY)"	;22-25
	defb	"I",0,0,0,"R",0,0,0,"(BC)","(DE)"	;26-29  
	defb	"AF'",0	;30
	defb	0


	;ok until above *****************************


voorwaarde:
	ld	c,0
	ld	ix,Voorwaarden
	ld	b,8
_voorwaarde3:	ld	de,(reg1_pointer)
	ld	a,(de)
	and	%11011111
	cp	(ix)
	jr	nz,_voorwaarde1	;not equal
	inc	de
	ld	a,(ix+1)
	or	a
	jr	z,_voorwaarde2
	ld	a,(de)
	inc	de
	and	%11011111
	cp	(ix+1)
	jr	z,_voorwaarde2
_voorwaarde1:	inc	ix
	inc	ix
	inc	c
	djnz	_voorwaarde3
	scf		;not found
	ret
_voorwaarde2:	ld	a,(de)
	or	a
	ld	a,c
	ret	z
	scf
	ret

Voorwaarden:	defb	"NZ","Z",0,"NC","C",0,"PO","PE","P",0,"M",0


;----- Test 2nd register      OUT: [C]=no register, A=num register (0-..)

test2ndregis:
	ld	hl,(reg2_pointer)
	ld	a,(hl)
	or	a
	jp	nz,_testcont
	ld	hl,(reg1_pointer)
	jp	_testcont


;--------------- Errors during assembly !

Badcommand:	defb	"Bad instruction",0
Getaltegroot:	defb	"Number out of range",0
Offsettegroo:	defb	"Offset out of range",0
Mishaaksluit:	defb	"Missing ",34,")",34,0
Delingdoor0:	defb	"Division by zero",0
Badmnemonic:	defb	"Bad mnemonic",0
Labelnotdefi:	defb	"Label not defined",0
Labelismacro:	defb	"Macro used as label",0
Labeltoolong:	defb	"Label too long",0
Toomanyifs:	defb	"Too many if's",0
Labelbestond:	defb	"Redefined label",0
Badlabel:	defb	"Illegal symbol in label",0
Macroisopen:	defb	"Macro already opened",0
Nolabelmacro:	defb	"Macro not defined",0
Macronotopen:	defb	"Macro not opened",0
Onlyrel:	defb	"Relocateable instruction",0
Publicnotfou:	defb	"Public not found",0
Inphase:	defb	"Phase still active",0
Bufnotexist:	defb	"Buffer doesn't exist",0
Bufferinuse:	defb	"Buffer in use",0
Incldiskerr:	defb	"Load error",0
Toomanyloops	defb	"Too many loops",0
Noloopopened	defb	"No loop opened",0

Erroradres:	defw	#1910

badcommand:
	ld	de,Badcommand
backerror:
	ld	a,(Macro)
	or	a
backerrormac:
	call	z,backerror1	;Macro => no error messages
	ld	hl,(Assembladre1)
	ld	(Assembladres),hl
	ld	sp,(Sp_assemble)
	ret

backerror1:
	ld	a,1
	ld	(Ass_error),a
	call	welassembl
	ret	c	;do not assemble => no error
	ld	hl,Aantalerrors
	inc	(hl)
	ld	hl,(Erroradres)
	call	setvramwrite
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	(Erroradres),hl
	ld	a,e
	out	(#98),a
	nop
	nop
	ld	a,d
	out	(#98),a
	ld	a,(Assemblregel)
	out	(#98),a
	ld	a,(Assemblregel+1)
	out	(#98),a	;error address + line number to vram
	ld	a,(Sourcebuffer)
	out	(#98),a
	ld	hl,Relcode
	ld	(hl),0
	ld	de,Relcode+1
	ld	bc,jon_len_rel-1
	ldir
	ret

getaltegroot:
	ld	de,Getaltegroot
	jr	backerror
offsettegroo:
	ld	de,Offsettegroo
	jr	backerror
mishaaksluit:
	ld	de,Mishaaksluit
	jr	backerror
delingdoor0:
	ld	de,Delingdoor0
	jr	backerror
badmnemonic:
	ld	de,Badmnemonic
	jr	backerror
labelnotdefi:
	ld	de,Labelnotdefi
	jr	backerror
labelismacro:
	ld	de,Labelismacro
	jr	backerror
labeltoolon1:
	ld	de,Labeltoolong
	jr	backerror
toomanyifs:
	ld	de,Toomanyifs
	jr	backerror
macroisopen:
	ld	de,Macroisopen
	xor	a
	jp	backerrormac
nolabelmacro:
	ld	de,Nolabelmacro
	jp	backerror
macronotopen:
	ld	de,Macronotopen
	jp	backerror
onlyrel:
	ld	de,Onlyrel
	jp	backerror
publicnotfou:
	ld	de,Publicnotfou
	jp	backerror
inphase:
	ld	de,Inphase
	jp	backerror
bufnotexist:
	ld	de,Bufnotexist
	jp	backerror

toomanyloops	ld	de,Toomanyloops
	jp	backerror
noloopopened	ld	de,Noloopopened
	jp	backerror
incldiskerr:
	ld	a,(Oudbuffer)
	ld	(Sourcebuffer),a
	ld	de,Incldiskerr
	jr	_bufferinus1
bufferinuse:
	ld	de,Bufferinuse
_bufferinus1:
	call	backerror1
	ld	hl,(Okadres)
	jp	includeerror


;----- error messages with return

labelbestond:
	ld	de,Labelbestond
	call	backerror1
	ret
badlabel:
	ld	de,Badlabel
	jr	_labeltool1
relcommand:
	ld	de,Onlyrel
	jr	_labeltool1
labeltoolong:
	ld	de,Labeltoolong
_labeltool1:
	call	backerror1
	or	a
	ret

labbufvol:
	ld	hl,Labelbufvol
	ld	de,Kbuf
	ld	bc,22
	ldir
	ld	hl,80*Commline+(80-21)/2
	ld	bc,Kbuf	;label buffer full
	call	GOtxttocomm
	call	GObeep
	call	GOpushanykey
	ld	sp,(Sp_labelasse)
	call	GOwiscommlin
	jp	GOeditscreen

Labelbufvol:	defb	"Labelbuffer too small",0


Sp_labelasse:	defw	0
Sp_assemble:	defw	0
Ass_error:	defb	0	;0=no error, 1=yes




;---------- Get 8 bit number  IN: HL=start address   OUT: [C]=error, A=number

getal8bit:
	call	getal16bit
	ret	c
	ld	a,d
	dec	a
	cp	#fe
	jp	c,getaltegroot
	ld	a,e
	ret

;----- Is number 16 bits in parentheses ?    OUT: [C]=no, DE=address

getalhaakjes:
	push	hl
	ld	a,(hl)
	inc	hl
	cp	"("
	jr	nz,_haakjeback
	call	getal16bit
	jr	c,_haakjeback
	ld	a,(hl)
	inc	hl
	cp	")"
	jr	nz,_haakjeback
	ld	a,(hl)
	or	a
	jr	nz,_haakjeback
	pop	bc
	ret
_haakjeback:	pop	hl
	scf
	ret

;----- calculate number 16 bits

getal16bit:
	xor	a
	ld	(Equ_segment),a
	ld	ix,testlabel
	ld	de,(Assembladres)
	push	iy
	ld	a,(Segment)	;for TSR and Relocatable
	rrca
	rrca
	call	bergetalasm
	ld	(Equ_segment),a
	pop	iy
	ret	nc
	or	a
	scf
	ret	z	;no number found
	dec	a
	jp	z,badmnemonic	;1 
	dec	a
	jp	z,mishaaksluit	;2 
	jp	delingdoor0	;3 


;----- Save entry address with TSR

vuladresin:
	ld	b,a
	ld	a,(Pass)
	dec	a
	ret	z
	ld	a,(Relocatable)
	or	a
	jr	nz,vuladresrel
	ld	a,(Equ_segment)
	or	a
	ret	z	;absolute
	ld	a,(Tsr)
	or	a
	ret	z
	ld	a,(Tsrhooks)
	or	a
	ret	nz
	ld	a,(Tsrpass)
	or	a
	ret	nz
	push	hl
	ld	hl,(Assembladres)
	ld	a,h
	cp	#40
	jr	nz,_vuladresin1
	ld	a,l
	cp	#24
	pop	hl
	ret	c
	push	hl
_vuladresin1:
	push	de
	call	berechtadr
	ex	de,hl
	ld	hl,(Offsetadres)
	ld	a,e
	call	writevram
	inc	hl
	ld	a,d
	call	writevram
	inc	hl
	ld	(Offsetadres),hl
	xor	a
	call	writevram
	pop	de
	pop	hl
	xor	a
	ret

vuladresrel:
	push	hl
	push	de
	ld	a,(Equ_segment)
	bit	5,a
	call	nz,external
	and	%11000000
	jr	z,vuladresrel1	;absolute
	push	iy
	pop	hl
	ld	de,jon_len_code
	add	hl,de
	ld	e,b
	ld	d,0
	add	hl,de
	ld	a,(Equ_segment)
	rlca
	rlca
	and	%11
	ld	(hl),a	;ld (iy+jon_len_code+B),segment
vuladresrel1:
	pop	de
	pop	hl
	xor	a
	ret

external:
	push	af
	push	bc
	call	berechtadr	;HL=real new address
	ld	a,(Externalblk)
	call	zetlabblok
	ld	de,(Externaladr)
	ld	a,l
	call	putlabbuffer
	ld	a,h
	call	putlabbuffer
	ld	a,(Segment)
	rrca
	rrca
	or	%00100000	;characteristic: external
	call	putlabbuffer
	pop	bc
	pop	af
	ret

Externalblk:	defb	0
Externaladr:	defw	0

berechtadr:
	push	iy
	pop	hl
	ld	de,Code
	or	a
	sbc	hl,de
	ld	de,(Assembladres)
	add	hl,de
	ld	e,b
	ld	d,0
	add	hl,de
	ret


;----- is label ? for calculation number/calculator

testlabel1:
	push	hl
	ld	a,(Labellengte)
	inc	a
	ld	b,a
	ld	de,Label
_testlab1_4:	push	bc
	push	de
	call	testfound1
	pop	de
	pop	bc
	jr	nc,_testlab1_3
	ld	a,(hl)
	ld	(de),a
	inc	de
	inc	hl
	djnz	_testlab1_4
_testfout:
	pop	hl
	scf
	ret		;too long
_testlab1_3:	xor	a
	ld	(de),a
	ld	hl,Label
	call	labelcorrect	;test for good label
	jr	c,_testfout
	xor	a
	ld	hl,Label
	call	labelexist
	jr	c,_testfout

	push	de
	ex	de,hl
	call	zetlabblok
	call	getlabbuffer
	call	getlabbuffer	;+next address
	call	getlabbuffer	;+next block
_testlab1_1:	call	getlabbuffer
	and	%10000000
	jr	z,_testlab1_1
	call	getlabbuffer
	ld	l,a
	call	getlabbuffer
	ld	h,a
;              ld      a,(Labbloknr)
;              ld      (Extrnblok),a
;              ld      (Extrnadres),de
	call	getlabbuffer
	ex	de,hl
	pop	hl	;de=number
	and	1
	jr	nz,_testfout	;=macro
	ld	bc,Label
	or	a
	sbc	hl,bc
	pop	bc
	add	hl,bc	;next address
	or	a
	ret
Labsoort:	defb	0

;----- Is label ?
testlabel:
	push	hl
	ld	a,(Labellengte)
	inc	a
	ld	b,a
	ld	de,Label
_testlab4:	push	bc
	push	de
	call	testfound1
	pop	de
	pop	bc
	jr	nc,_testlab3
	ld	a,(hl)
	ld	(de),a
	inc	de
	inc	hl
	djnz	_testlab4
	jp	labeltoolon1
_testlab3:	xor	a
	ld	(de),a

	ld	hl,Label
	call	labelcorrect	;test for good label
	pop	hl
	ret	c	;label too long has already been tested
	ld	a,(Pass)
	dec	a
	jr	z,_testlab2
	ld	a,(Macro)
	or	a
	jr	nz,_testlab2	;do not test with macros
	call	welassembl
	jr	c,_testlab2	;if assemble off => don't test

	push	hl
	xor	a
	ld	hl,Label
	call	labelexist
	jp	c,labelnotdefi	;does not exist

	push	de
	ex	de,hl
	call	zetlabblok
	call	getlabbuffer
	call	getlabbuffer	;+next address
	call	getlabbuffer	;+next block
_testlab1:	call	getlabbuffer
	and	%10000000
	jr	z,_testlab1
	ld	(Externaladr),de
	ld	a,(Labbloknr)
	ld	(Externalblk),a
	call	getlabbuffer
	ld	l,a
	call	getlabbuffer
	ld	h,a
	call	getlabbuffer
;              ld      b,a
	ld	(Segmentback+1),a
	and	1
	jp	nz,labelismacro
;              ld      a,(Equ_segment)
;              or      b
;              ld      (Equ_segment),a
	ex	de,hl	;de=number
	pop	hl
	ld	bc,Label
	or	a
	sbc	hl,bc
	pop	bc
	add	hl,bc	;next address
Segmentback:	ld	a,0	;FILLED IN !!!
	or	a
	ret
_testlab2:	;Pass 1
	ld	a,(Labellengte)
	inc	a
	ld	b,a
_testlab2_2:	push	bc
	call	testfound1
	pop	bc
	jr	nc,_testlab2_1
	inc	hl
	djnz	_testlab2_2
	call	welassembl
	jp	nc,labeltoolon1
_testlab2_1:
	ld	de,1	;number 1
	or	a
	ret



;------ Print 18 errors on screen

prterrlines:
	ld	b,18
_nxtprterror:
	push	bc
	push	hl
	push	af
	call	setvramwrite
	ld	b,42
_nextwis:	ld	a,0
	out	(#98),a
	djnz	_nextwis
	call	setvramwrite
	pop	af
	cp	(iy)
	jr	z,_cntprt
	push	af
	ld	c,(ix)
	inc	ix
	ld	b,(ix)
	inc	ix
	ld	h,#80	;no vram address
	call	printtekst
	ld	bc,Inline
	ld	h,#80
	call	printtekst
	ld	e,(ix)
	inc	ix
	ld	d,(ix)
	inc	ix
	ld	b,5+128	;bit 7: no leading zeros
	ld	h,#80	;TO LEAVE !
	call	printdecimaa
	ld	a,(ix)
	inc	ix
	add	a,"0"
	ld	(Inbuf+2),a
	ld	bc,Inbuf
	ld	h,#80	;TO LEAVE !
	call	printtekst
	pop	af
	inc	a
_cntprt:
	pop	hl
	ld	de,80
	add	hl,de
	pop	bc
	djnz	_nxtprterror
	ret

Inline:	defb	" in line ",0
Inbuf:	defb	" [ ]",0

;---------- General subroutines


restart20:	ld	a,h
	sub	d
	ret	nz
	ld	a,l
	sub	e
	ret

savedisk:
	push	iy
	ld	de,(Used_fcb)
	ld	c,#26
	call	bdos	;interim save
	pop	iy
	or	a
	ret	z
	ld	ix,(Foutadres)
	jp	(ix)

;----- 1 byte to label buffer + optionally: increase buffer
;----- IN: DE=address

putlabbuffer:
	ld	(de),a
	inc	de
	bit	6,d
	ret	z
	push	af
	push	hl
	ld	hl,Labbloknr
	ld	a,(Aantallabelb)
	cp	(hl)
	jr	z,_putlabbuff1
	inc	(hl)
	ld	a,(hl)
	call	zetlabblok
	pop	hl
	pop	af
	res	6,d
	ret
_putlabbuff1:
	pop	hl
	pop	af
	jp	labbufvol

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
	jr	z,_getlabbuff1	;text buffer full
	inc	(hl)
	ld	a,(hl)
	call	zetlabblok
_getlabbuff1:	pop	hl
	pop	af
	res	6,d
	ret

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
	call	#0131	;***********************
	dec	hl
	ld	a,(hl)
	ld	h,#80
	call	slot
	pop	hl
	ret

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
	call	#0131
	dec	hl
	ld	a,(hl)
	ld	h,#80
	call	slot
	pop	hl
	ret

;----- IN: A = Block number of data buffer (1-..)
;----- Changes: AF

zetdatablok:
	ld	(Databloknr),a
	add	a,a
	push	hl
	ld	hl,Databuffers-1
	add	a,l
	ld	l,a
	jr	nc,_zetdatablo1
	inc	h
_zetdatablo1:
	ld	a,(hl)
	call	#0131
	dec	hl
	ld	a,(hl)
	ld	h,#80
	call	slot
	pop	hl
	ret

;####################################
;Enter address at line   IN: DE=line
;OUT: [C]=end text, DE=address text, A=quantity. text block
;Changes: HL,DE,AF,BC

geefadrregel:
;IN : DE=line number
;OUT: DE=address data buffer, C=how many block of data buffer
	dec	de
	ld	l,e
	ld	h,d
	ld	a,#80
	add	hl,hl	;never returns carry (line=<32768)
	add	hl,de	;this is possible (only from around line 22000)
	jr	c,vulamet1	;is fastest (not with jr nc,_vulamet1)
_vulamet1	sla	h
	rla		;                  ;also bit x to CF!
	rl	h	;bit x to bit 0 of h
	rla
	inc	a	;from 1..6 instead of 0..5
	ld	c,a
	srl	h	;bit x to CF
	rr	h	;bit x to pos. 7 (=address #8000...)
	ex	de,hl
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
vulamet1	inc	a
	jr	_vulamet1

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
_getdatbuff1:	pop	hl
	pop	af
	res	6,d
	ret

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
_gettxtbuff1:	pop	hl
	pop	af
	res	6,d
	ret

reg_kweenie	db	0
reg1_pointer	dw	0
reg2_pointer	dw	0

;----- Buffers

Buffer1:
Zin:	defs	256+64,0
Label:	equ	Zin+161	;30 characters + 0
Commando:	equ	Label+31	;store command+registers

	ds	#7000-$,#c9

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Duplicate variables/addresses

Doubleuse:

Used_fcb:	equ	Doubleadres
Foutadres:	equ	Used_fcb+2
Veranderd:	equ	Foutadres+2
GOedit_ret1:	equ	Veranderd+1
Aantallabelb:	equ	GOedit_ret1+7
Labelbuffers:	equ	Aantallabelb+1
GO_wisbuffe1:	equ	Labelbuffers+8
Huidigerror:	equ	GO_wisbuffe1+7
Balkerror:	equ	Huidigerror+1
GOpushanykey:	equ	Balkerror+1
GOwiscommlin:	equ	GOpushanykey+7
GOeditor_con:	equ	GOwiscommlin+7
GOprintscher:	equ	GOeditor_con+7
GOprinterror:	equ	GOprintscher+7
Bufferpage0:	equ	GOprinterror+7
Labbloknr:	equ	Bufferpage0+2
Idhex:	equ	Labbloknr+1
Idbin:	equ	Idhex+3
Labellengte:	equ	Idbin+3
Binheader:	equ	Labellengte+1
GOtxttocomm:	equ	Binheader+2
GObeep:	equ	GOtxttocomm+7
Aantalerrors:	equ	GObeep+7
GOassembledi:	equ	Aantalerrors+1
GOassemblere:	equ	GOassembledi+7
GOeditscreen:	equ	GOassemblere+7
Aantaltextbl:	equ	GOeditscreen+7
Textbuffers:	equ	Aantaltextbl+1
Aantaldatabl:	equ	Textbuffers+32
Databuffers:	equ	Aantaldatabl+1
Databloknr:	equ	Databuffers+12
Textbloknr:	equ	Databloknr+1
GOprterrline:	equ	Textbloknr+1
GOrelocatabl:	equ	GOprterrline+7
GOasstsr:	equ	GOrelocatabl+7
Upperonoff:	equ	GOasstsr+7
GOsetbuf:	equ	Upperonoff+1
Sourcebuffer:	equ	GOsetbuf+7

next:	equ	Sourcebuffer+1
