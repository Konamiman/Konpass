	;Konpass #1.3 - COM file
	;the logo routine can be improved
	;based on v1.1, but completely rewritten and reworked
	;25-10-98 JDS
	;Copyright 1998 by Compjoetania The Next Generation

	;Assemble with Nestor80 (https://github.com/konamiman/Nestor80):
	;N80 COMFILE.ASM KONPASS.COM

_FOPEN: equ 0Fh
_FCLOSE: equ 10h
_SETDTA: equ 1Ah
_RDBLK: equ 27h
_OPEN: equ 43h
_CLOSE: equ 45h
_READ: equ 48h
_SEEK: equ 4Ah
_PARSE: equ 5Bh
_GENV: equ 6Bh
_SENV: equ 6Ch

bdos:	equ	#0005
headln:	equ	128	;length of the header (DATfile)
headlncom:	equ	110	;length of the header (COM file)

kbuf:	equ	#f41f
temp_page3:	equ	kbuf
savepage:	equ	temp_page3+0
RAM_count:	equ	temp_page3+1
queuebc:	equ	#f9f5

ctngcode:	equ	#ff79

env_item_buffer: equ 3F00h

	ORG	#0100

	jp	skipid
	db	13,"Konpass #1.3 COMfile",13,10
    db  "(C) 2025 by Konamiman",13,10
    db 10
    db  "Based on Compass #1.2.09 by Compjoetania TNG",13,10,26
	ds	#0100+headlncom-2-$,0	;reserve bytes
	db	#09,#12	;IDbyte subnr (bit7=beta),mainnr
skipid:	LD	HL,queuebc+6
	LD	DE,compass_ID
	LD	B,#08
J0109:	LD	A,(DE)
	INC	DE
	CP	(HL)
	INC	HL
	JR	NZ,J0119
	DJNZ	J0109
	LD	DE,txt_inmem
	LD	C,#09
	call	bdos
	ei
	ld b,30	;Delay half a second for the message to be visible
resuming:
	halt
	djnz resuming
	jp queuebc+2
J0119:	ei
	halt

	ld	a,(#fbeb)
	push af

	;We need to load config early on,
	;to have a proper value of i_skipsrcmem available.
	call fill_dosnr

	ld a,(stat_dos)
	cp 2
	jr c,dont_get_env_program
	LD	HL,env_program
	LD	DE,env_item_buffer
	LD	BC,#FF00+_GENV
	CALL	bdos	;get env item PROGRAM
	ld a,(8000h)
	OR	A
	jp z,noprog_error
dont_get_env_program:

	call load_config

	pop af
	rrca
	jr	c,noshift	;SHIFT key pressed?
	ld	a,(i_limit)
	ld	(nr_max),a
	xor	a	;this will force a mem search
	ld (nr_max+1),a
	ld	(i_skipsrcmem),a	;instead of installing memory
noshift:
	LD	A,(#FCC1)
	LD	HL,#002D
	CALL	#000C
	OR	A
	LD	DE,txt_msx1
	LD	C,#09
	JP	Z,bdos
	ld	hl,ctngcode
	res	0,(hl)

J0145:	DI
	XOR	A
	OUT	(#99),A
	NOP
	LD	A,#90
	OUT	(#99),A
	LD	HL,startpalet
	LD	BC,#209A
	OTIR
	ld	a,15
	LD	(#F3E9),A
	xor	a
	ld	(#f3ea),a
	ld	(#f3eb),a
	LD	IX,#0062	;set colors
	LD	IY,(#FCC0)
	CALL	#001C
	ld	a,80
	ld	(#f3ae),a
	XOR	A	;screen 0
	LD	IX,#005F
	LD	IY,(#FCC0)
	CALL	#001C
;main program
	LD	DE,txt_intro
	CALL	print
	ld de,txt_nocfg
	ld a,(saved_config_available)
	or a
	call z,print
	CALL	fill_stat_mem
	ld	de,txt_manage
	call	print
	ld	a,(stat_mem)
	add	a,a
	ld	e,a
	ld	d,0
	ld	hl,tab_manage
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	call	print

	ld a,(stat_mem)
	and 1
	jr z,locate_dos2_ram_end

	;If mapper support routines are available,
	;get the address of the mappers table
	;and use that table for:
	;
	;1. Calculating RAM_count
	;2. Filling the appropriate entries in work_ROMRAM
	;
	;By doing that, later chk_ROMRAM will skip
	;the size calculation for mapped RAM slots.

	ld de,0401h
	call 0FFCAh ;HL = Mappers table
	ld de,0		;DE = Segments count
locate_dos2_ram_loop:
	ld a,(hl)	;Slot number
	or a
	jr z,locate_dos2_ram_end

	;Calculate the entry for the slot number in work_ROMRAM:
	;(slot*8)+subslot*2 for page 0, +32 for page 1, +64 for page 2
	ld ix,work_ROMRAM
	ld b,a
	rla
	rla
	rla
	and 11000b
	ld c,a	;C = main slot*8
	ld a,b
	rra
	and 00110b	;A = subslot*2
	or c
	ld c,a
	ld b,0
	add ix,bc

	ld (ix),2	;Mark as RAM in pages 0,1,2
	ld (ix+32),2
	ld (ix+64),2
	
	inc hl		;Point to "total segments"
	ld c,(hl)

	dec c
	ld (ix+1),c	;Save segments count -1 for pages 0,1,2
	ld (ix+32+1),c
	ld (ix+64+1),c
	inc c

	ex de,hl
	ld b,0	
	add hl,bc	;Update segments count
	ex de,hl

	ld bc,7
	add hl,bc	;Point to table for next mapper
	jr locate_dos2_ram_loop

locate_dos2_ram_end:
	ld (RAM_count),de

locate_dos2_ram_done:
	LD	DE,txt_ROMRAM
	CALL	print
	CALL	chk_ROMRAM
	ld	de,txt_done
	CALL	print
	ld	hl,(RAM_count)
	call	print_memory
	ld de,txt_lf
	call print
	ld	a,(i_skipsrcmem)	;saved version without shiftboot?
	or	a
	jr	nz,meminst	;yes, install immediately then
	ld	de,txt_limit	;unsaved version or with shift
	call	print
	ld	hl,(nr_max)
	call	print_memory
memsrc:
	ld	de,txt_search
	call	print
	call	src_mem
	jr	nc,okidoki
	ld	hl,ctngcode
	set	0,(hl)
	ld	de,txt_nofree
	jp	print
meminst:
	ld	de,txt_inst
	call	print
	call	inst_mem
	jr	nc,okidoki
	ld	de,txt_notfree
	call	print
	ld	a,#ae	;poke new opcode: res 5,(ix+0)
	ld	(m_res6),a	;this serves to revert the free-routine (as it had been changed)
	xor	a	;just to do (had changed)
	ld	(i_skipsrcmem),a	;default memuse in the datfile
	jr	memsrc
okidoki:
	ld	de,txt_okused
	call	print
	call	get_used

	ld	de,txt_load
	call	print
	LD	A,(#F343)	;page2 dosslot
	LD	C,A	;in C:slot code
	ld	a,(tab_TPA+2)
	LD	B,a	;in B: block nr
	CALL	ld_blokb_2c

	LD	A,(stat_dos)
	CP	#02
	LD	DE,fcb_compass	;prepare open file (dos1)
	LD	C,_FOPEN
	JR	c,go_load

go_load_dos2:
	LD	HL,env_compass	;fill KONPASS with the contents of
	LD	DE,env_item_buffer	;the PROGRAM env item
	LD	C,_SENV
	CALL	bdos
	or	a
	jp	nz,env_error
	LD	DE,env_item_buffer	;create filehandle for dat file
	LD	BC,_PARSE
	CALL	bdos
	EX	DE,HL
	LD	A,'.'	;DE pointing at 'k' of konpass
	LD	(fcb_compass+8),A
	LD	HL,fcb_compass+1
	LD	BC,12	;also copy terminating zero
	LDIR		;replace filename with dat version
	LD	DE,env_item_buffer	;the handle is now ready
	XOR	A
	LD	C,_OPEN	;open file handle (dos2)
go_load:
	CALL	bdos
	OR	A
	JP	NZ,loaderror
	LD	A,B	;save new handlenr (dos2)
	LD	(new_handle),A
	ld	de,0
	ld	hl,headln
	ld	a,(stat_dos)
	cp	2
	jr	c,schuifop
	xor	a
	ld	c,_SEEK
	call	bdos

schuifop:
	LD	(fcb_compass+33),HL
	LD	(fcb_compass+35),DE
	ld	l,1	;size at 1 byte
	LD	(fcb_compass+14),HL

	LD	DE,#8140
	CALL	set_DTA
	LD	HL,#3EC0
	CALL	load_data
	LD	BC,(compass_1)
	CALL	slot_en_move
	LD	HL,#0000	;complete part 1 with the dosstart
	LD	DE,#4000
	LD	BC,#0140
	LDIR

	LD	DE,#8000
	CALL	set_DTA

	LD	HL,#4000
	CALL	load_data
	LD	BC,(compass_0)
	CALL	slot_en_move

	LD	HL,#4000
	CALL	load_data
	LD	BC,(compass_2)
	CALL	slot_en_move

	LD	HL,#4000
	CALL	load_data
	LD	BC,(compass_3)
	CALL	slot_en_move

	LD	A,(stat_dos)	;close file
	CP	#02
	LD	DE,fcb_compass	;close file (dos1) ready
	LD	C,16
	JR	C,go_close
	LD	A,(new_handle)
	LD	B,A
	LD	C,#45
go_close:
	call	bdos
	ld	de,txt_lddone
	call	print
	ei
	halt
	ld	a,(#fbec)
	and	#10
	jr	nz,go_launch
stop_wacht1:
	ld	a,(#fbec)
	and	#10
	jr	z,stop_wacht1
stop_wacht2:
	ld	a,(#fbec)
	and	#10
	jr	nz,stop_wacht2
go_launch:
	ld	de,txt_launch
	call	print

	LD	HL,inst	;settings
	LD	DE,kbuf
	LD	BC,inst_end-inst
	LDIR
	LD	HL,work_ROMRAM	;ROM/RAM table to #c000
	LD	DE,#C000	;mem_table to #c060
	LD	BC,#60+#c1+8+4	;compass segments to #c121
	LDIR		;tpasegmentnrs to #c129

	LD	BC,(compass_1)	;turn on start segment on page2
	CALL	ld_blokb_2c
	ld	de,(stat_dos)	;dosversion in E,statmem in D
	ld	bc,inst_end-inst
	JP	#8149

noprog_error:
	ld de,txt_noprog
	jr	free_all
env_error:
	ld	de,txt_err_env
	jr	free_all
err_in_call:
	POP	HL	;discard return address
loaderror:
	LD	DE,txt_lderr
free_all:
	call	print
	ld	hl,ctngcode
	set	0,(hl)
	jp	m_freeall	;segments released


	;Return: Cy=0 if ok, 1 if file not found or unreadable
load_config:
	call _load_config
	ret c
	ld a,0FFh
	ld (saved_config_available),a
	ret

_load_config:
	LD	A,(stat_dos)
	CP	#02
	jr c,load_config_dos1

load_config_dos2:
	LD	HL,env_program
	LD	DE,#8100
	LD	BC,#FF00+_GENV
	CALL	bdos	;get env item PROGRAM

	ld hl,8000h
	ld de,8100h
	ld bc,128
	ldir

	ld a,'.'
	ld (fcb_cfg+1+7),a
	ld de,8100h
	ld bc,_PARSE
	call bdos
	ex de,hl
	ld hl,fcb_cfg+1
	ld bc,12
	ldir

	ld de,8100h
	ld a,1
	ld c,_OPEN
	call 5
	scf
	ret nz

	push bc
	ld c,_READ
	ld de,inst
	ld hl,inst_end-inst
	call bdos
	pop bc
	push af

	ld c,_CLOSE
	call bdos
	pop af
	ret z
	scf
	ret

load_config_dos1:
	ld de,fcb_cfg
	ld c,_FOPEN
	call bdos
	or a
	scf
	ret nz
	
	ld de,inst
	ld c,_SETDTA
	call bdos

	ld a,1
	ld (fcb_cfg+14),a
	ld c,_RDBLK
	ld de,fcb_cfg
	ld hl,inst_end-inst
	call bdos

	;No need to close the FCB since the fille hasn't been written to
	or a
	ret

;************************************************end main ,start routines
;fills in doskernel number
;1=DOS1 2=DOS2 or higher ;)
fill_dosnr:
	LD	C,#6F
	CALL	bdos
	LD	A,B
	CP	2
	LD	A,1
	JR	C,J20F4
	INC	A
J20F4:
	LD	(stat_dos),A
	RET

;fill in memory status
;0=DOS1,use own 1=DOS2 mapper support 2=Memman+DOS1 3=Memman+DOS2
fill_stat_mem:
	DI
	XOR	A
	LD	DE,#4D1E	;Memman Inichk
	CALL	#FFCA
	CP	#4D
	JR	NZ,no_memman
	ld	hl,-#0204	;test for version 2.4
	add	hl,de
	jr	nc,old_memman
	ld	bc,#0400
	ld	de,tab_TPA
haal_TPA_Mm:
	push	bc
	push	de
	ld	b,c
	ld	de,#4d21	;get tpa
	call	#ffca
	pop	de
	pop	bc
	ld	a,h
	ld	(de),a
	inc	de
	inc	c
	djnz	haal_TPA_Mm
use_memman:
	ld	a,(stat_dos)
	dec	a
	ld	a,2
	jr	z,J2125
	inc	a
	jr	J2125
old_memman:
	ld	de,txt_old
	call	print
	jr	use_memman
no_memman:
	LD	HL,#FB20
	BIT	0,(HL)
	LD	A,#00
	JR	Z,J2125
	XOR	A	;extra check for presence of dos2map.
	LD	DE,#0402
	LD	HL,#0000
	CALL	#FFCA
	LD	A,H
	OR	L
	JR	Z,J2125
	LD	A,B
	LD	(primmap_slot),A
	LD	(jp_all_seg),HL	;1st entry ALL_SEG
	INC	HL
	INC	HL
	INC	HL
	LD	(jp_fre_seg),HL	;FRE_SEG
	ld bc,7*3
	add hl,bc	;PUT_P0
	ld (fix_page0_setp0+1),hl
	ld a,0CDh	;"call" opcode
	ld (fix_page0_setp0),a
	ld bc,2*3
	add hl,bc	;PUT_P1
	ld (slot_en_move_putp1+1),hl
	ld bc,2*3
	add hl,bc	;PUT_P2
	ld (ld_blokb_2c_putp2+1),hl
	ld (chk_ROMRAM_setp2+1),hl
	ld (chk_ROMRAM_setp2),a

get_tpa_segs:
	ld bc,-3*3
	add hl,bc	;Now HL points to GET_P0
	ld b,4
	ld ix,tab_TPA
	ld de,6
get_tpa_segs_loop:
	call call_hl	
	ld (ix),a
	add hl,de
	inc ix
	djnz get_tpa_segs_loop

	LD	A,#01
J2125:	LD	(stat_mem),A
	RET

call_hl: jp (hl)


; Scan all slots and fill work_ROMRAM appropriately.
; If mapper support routines are available the entries for mapped RAM slots
; will already have been filled with information from the mappers table,
; thus the process of counting the available segments won't be repeated.

chk_ROMRAM:
	LD	A,(#F341)	;chk_ROMRAM also available in page 2
	LD	H,#80	;(used when checking page 0)
	CALL	#0024
	LD	A,(tab_TPA)
chk_ROMRAM_setp2:
	OUT	(#FE),A
	nop		;Space for patching with a CALL PUT_P2
	LD	IX,work_ROMRAM
	LD	B,3	;do for 3 pages: 0,1,2
	xor a	;start with page 0
	ld	(savepage),a	;save to page 3
	ld a,(stat_mem)
	and 1
	jr nz,skip_reset_ramcount	;Since it has been calculated already
	ld hl,0
	ld	(RAM_count),hl
skip_reset_ramcount:

loop_page:
	PUSH	BC
	LD	DE,#FCC1
	LD	C,#80	;provisional slot code
	LD	B,4
loop_slot:
	PUSH	BC
	PUSH	DE
	LD	A,(DE)
	AND	#80
	ld	a,(savepage)
	JR	NZ,expanded
	RES	7,C
	CALL	chk_notexp
	LD	DE,#0008	;next prim.slot (and automatic
	ADD	IX,DE	;IX possibly to next page)
	JR	J21BB
expanded:
	CALL	chk_exp
J21BB:
	POP	DE	;next primary slot
	POP	BC
	INC	DE
	INC	C
	DJNZ	loop_slot
	POP	BC
	LD	HL,savepage	;next page
	INC	(HL)
	DJNZ	loop_page
	LD	A,(#F343)	;restore and ret from chk_ROMRAM
	LD	H,#80	;note that the correct mapperpage
	CALL	#0024	;not yet set up for page 2
	LD	A,(#F342)	;likewise for page 1
	LD	H,#40
	JP	#0024

chk_exp:
	LD	HL,get_memtype
	LD	(cl_adres),HL
	OR	A
	JR	NZ,go2_2
	LD	de,#8000
	ADD	HL,DE
	LD	(cl_adres),HL
	ADD	IX,DE
	JP	#8000+go2_2
go2_2:
	LD	B,4	;do for each subslot
J21F5:	PUSH	BC
	db	#cd	;call
cl_adres:
	dw	0
	INC	IX	;next subslot
	INC	IX
	POP	BC
	INC	C	;change the slot code
	INC	C
	INC	C
	INC	C
	DJNZ	J21F5
	LD	A,(savepage)
	OR	A
	RET	NZ
fix_page0:
	LD	A,(#F341)	;restore slot setting page 0
	CALL	#8000+set_slot_p0
	LD	A,(#8000+tab_TPA)	;and also page
fix_page0_setp0:
	OUT	(#FC),A
	nop		;Space for patching with a CALL PUT_P0
	ld	de,#8000	;note: -#8000 =#8000
	add	ix,de	;#8000 SUBSTRACT from IX
	RET

chk_notexp:
	OR	A
	JR	NZ,get_memtype
	JP	#8000+go2_1
go2_1:
	LD	DE,#8000
	ADD	IX,DE
	CALL	#8000+get_memtype
	JR	fix_page0

get_memtype:
	LD	A,(IX+#00)	;was there already a mapper here
	OR	A	;reported?
	RET	NZ	;yes, don't test then
	LD	A,(savepage)
	OR	A
	JR	Z,chk_0
	DEC	A
	JR	Z,chk_1
	LD	HL,#8000
	JR	J225B
chk_0:
	LD	A,C
	CALL	#8000+set_slot_p0
	ld	hl,0
	JR	Ram_of_Rom
chk_1:
	LD	HL,#4000
J225B:	PUSH	HL
	LD	A,C
	CALL	#0024
	POP	HL
;in: IX(pointer to 2bytes),HL(address in the page),pagenr on savepage
Ram_of_Rom:
	LD	A,(HL)	;test for Ram
	ld	b,a
	INC	(HL)
	inc	a
	CP	(HL)
	LD	(HL),b
	JR	NZ,no_ram
	LD	(IX+#00),#02
	ld	a,(savepage)
	add	a,#fc
	ld	c,a
	LD	B,#00
J2292:	OUT	(C),B	;set byte hl to 0 on every ram block
	LD	A,(HL)	;order: 0,255,254,253,...
	LD	(HL),0
	PUSH	AF
	DJNZ	J2292
	LD	B,0
	LD	D,B
J229D:	OUT	(C),D
	LD	A,(HL)
	OR	A
	JR	NZ,J22A7	;ram block 1 switched for the second time?
	LD	(HL),D
	INC	D
	DJNZ	J229D
J22A7:	dec	d	;then subtract 2 from it
	dec	d
	LD	(IX+#01),D	;save maxnr for mapperram
	jr	z,vast_ram	;with fixed ram maxnr=0
	LD	(IX+#20),2	;put ramcode for page 1and2
	LD	(IX+#40),2
	LD	(IX+#21),D
	LD	(IX+#41),D
	push	hl
	ld	hl,(RAM_count)
	ld	e,d
	ld	d,0
	add	hl,de
	inc	hl
	ld	(RAM_count),hl
	pop	hl
vast_ram:
	LD	B,#00
	LD	D,#01
J22B7:	OUT	(C),D
	POP	AF
	LD	(HL),A
	INC	D
	DJNZ	J22B7
	RET
no_ram:
	push	hl
	ld	de,#03ff
	ld	b,15
	ld	a,e
telop1:
	xor	(hl)
	add	hl,de
	djnz	telop1
	pop	hl
	ld	c,a
	or	a	;all of them #ff
	ret	z
	ld	b,15
	ld	a,e
telop2:
	xor	(hl)
	add	hl,de
	djnz	telop2
	cp	c	;if the 2 checksums are not the same,
	ret	nz	;then there was a reading error and therefore no rom
	inc	(ix)	;really rom
	RET

;routine (in page 2) that switches slot A on page 0
set_slot_p0:
	ld	b,a
	bit	7,a
	jr	nz,set_exp	;expanded slot?
	IN	A,(#A8)	;no, just switch it
	AND	#fc
	OR	B	;note: bits 2-6 are 0 for notexp.slot
	OUT	(#A8),A
	RET
set_exp:
	rrca
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
	ld	d,a	;new ffff-stand in d
	ld	a,e
	out	(#a8),a	;restore page 3
	ld	hl,#fcc5
	ld	a,b
	and	#03
	ld	c,a
	ld	b,0
	add	hl,bc
	ld	(hl),d
	ld	a,c
	jr	set_slot_p0

print_dec:
	ld	de,decstr+5
	ld	a,"$"
	ld	(de),a
	ld	c,-10
get_dig:
	xor	a
	ld	b,16
divide:
	adc	hl,hl
	adc	a,a
	add	a,c
	jr	c,oksub
	sub	c
oksub:
	djnz	divide
	adc	hl,hl
	add	a,"0"
	dec	de
	ld	(de),a
	ld	a,h
	or	l
	jr	nz,get_dig
	ld	hl,decstr
	ex	de,hl
	ld	c,5
	ldir
	ld	de,decstr
	ld	c,9
	jp	bdos

get_used:
	ld	ix,mem_tabel
	ld	de,#2e
	ld	a,4	;four for compass blocks
	ld	b,4	;do for the 4 buffers
sommeer:
	add	a,(ix)	;add number of sbuffer segments
	add	a,(ix+#21)	;add number of data buffer segments
	add	ix,de	;to next buffer
	djnz	sommeer
	add	a,(ix)	;add number of label buffer segments
	ld	l,a
	ld	h,0
;input: hl=number of segments, print 'a segments (xxxxkB RAM)',13,10
print_memory:
	push	hl
	call	print_dec
	ld	de,txt_segments
	call	print
	pop	hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	call	print_dec
	ld	de,txt_kB_RAM
print:
	LD	C,#09
	JP	bdos

;*****************************************************memory routines
;NOTE: there is a difference between a tpa segment and a tpaslot segment
;tpa-segment is thus (in many cases) ramblock 0,1,2 or 3 of the primary mapper
;tpaslot_segment can be any primary mapper ram block

src_mem:
	CALL	m_tabel	;create table with segments
	ret	c	;no tpaslotsegm found
	call	m_count_free	;if you don't have 4 segments,
	ld	hl,3	;don't start it! The compass blocks
	call	m_vgl_HLDE	;after all, are not allowed in tpa segments
	jp	nc,m_freeall	;so no m_add_321 applicable
	LD	DE,buffer
	LD	HL,compass_1	;request tpaslotsegm for cblock 1
	CALL	m_src_dosram	;always works, after all we had 1
	LD	DE,buffer	;the next 3 segments can always
	ld	hl,compass_0	;be found/located because we had four segm.
	CALL	m_use_zet6_hl	;search for compass block 0
	inc	hl	;skip compass block 1
	inc	hl
	CALL	m_use_zet6_hl	;search for compass block 2
	CALL	m_use_zet6_hl	;search for compass block 3

	CALL	m_count_free	;count the number of unused blocks
	LD	IX,buffer	;select first label block
	LD	BC,#0109	;this should also be in the tpaslot
	CALL	m_usepages
	jr	nc,m_okee
	call	m_add_321	;failed, add tpa segs
	call	m_count_free	;now it must work
	ld	ix,buffer
	ld	bc,#0109
	call	m_usepages
	jp	c,m_freeall	;technically not necessary

m_okee:
	call	m_count_free	;when you come here there are at least 2 more
	ld	hl,1	;tpasegm left. Use this if you run out of
	call	m_vgl_HLDE	;2 more for sbuf1+data1
	call	nc,m_add_321

	LD	IX,buffer	;then select 1 sourcebufblock
	LD	BC,#0101
	CALL	m_usepages	;always works

	LD	BC,#0105	;select 1 data block at sbuf 1
	CALL	m_usepages	;always works

	LD	IY,m_priortab	;add more if needed
J23BC:	LD	A,(IY+#00)
	INC	IY
	OR	A
	JR	Z,J23DE	;end of priority tab; no good
	CP	#FF	;configuration found anymore,
	JR	Z,J23D5	;check if there are 2 more
	LD	B,A	;get number
	LD	C,(IY+#00)	;get type
	INC	IY
	CALL	m_usepages	;put in use
	JR	C,J23DE	;it's not possible, then stop
	JR	J23BC	;okay
J23D5:	LD	A,D	;are there 2 segments left?
	OR	A
	JR	NZ,J23BC	;if so, try to use them
	LD	A,E
	CP	#02
	JR	NC,J23BC
J23DE:	CALL	m_free	;free what was not used
	XOR	A
	RET

m_tabel:
	ld	hl,(nr_max)
	LD	A,(stat_mem)	;search until you find at least 2 segm in the tpaslot
	OR	A	;and until you have at least nr_max segm
	JP	NZ,m_manage	;or search until memory runs out
	push	hl
	ld	ix,tempbuffer	;use the top 2 segments of the
	ld	a,(#f344)	;mainmapper as 2 tpaslot segments
	ld	(ix),a	;save 1st slot code
	ld	b,a
	and	#03
	rlca
	rlca
	rlca
	ld	c,a	;c=primaryslot*8
	ld	a,b
	and	#0c
	rrca
	add	a,c
	ld	e,a
	ld	d,0
	ld	hl,work_ROMRAM+1
	add	hl,de
	ld	a,(hl)	;get maxblocknr primary mapper
	pop	hl
	dec	hl
	cp	4	;test if the mapper is >64kB
	ret	c
	ld	(ix+1),a	;save 1st segment num
	jr	z,go_on	;2nd tpa segment would otherwise be number 3
	;                           ;this should not be added yet
	ld	(ix+2),b	;save 2nd slot
	dec	a
	ld	(ix+3),a	;save 2nd segment num
	dec	hl
go_on:
	ld	ix,buffer
	ld	de,work_ROMRAM+#41	;why for page2?*******
	LD	IY,#FCC1	;--> it's actually the same
	LD	BC,#1000	;16=go through the 16 subslots, C=def.slot
J256B:	PUSH	BC
	PUSH	DE
	BIT	7,(IY+#00)	;is it in an extended slot?
	JR	Z,in_not_exp
	SET	7,C	;change the slot code
in_not_exp:
	ld	a,(#f344)	;skip the tpa slot
	cp	c
	jr	z,volgend
	call	m_scanslot	;input: C=slot code DE=address with maxsegnr
	jr	c,found_genoeg
volgend:
	POP	DE
	POP	BC
	INC	DE
	INC	DE
	LD	A,C	;change the slot code
	AND	#0C
	CP	#0C	;was it a subslot 3?
	LD	A,C
	LD	C,#04	;no, just add 1 subslot
	JR	NZ,J25B2
	INC	IY	;yes, next primary slot IY
	LD	C,%11110101	;next prim slot,sec.slot to zero,bit7=0
J25B2:	ADD	A,C
	LD	C,A
	DJNZ	J256B
	call	m_add_temp	;insert 2or1 previously found tpa
	ld	a,(#f344)
	ld	c,a
	ld	de,tempbuffer+1	;address where maxpagenr is
	ld	a,(de)	;take into account that the highest nums
	dec	a	;are already out of the door
	dec	a	;even if only 1 is gone,
	ld	(de),a	;then the segments are part of the tpa area anyway
	call	m_scanslot	;add the tpaslotsegs last
	LD	(IX+#00),#00	;terminating zero slot code
	or	a	;clear carry
	ret
found_genoeg:
	pop	de	;stack cleanup
	pop	bc
	call	m_add_temp	;add 2or1 previously found tpa
	LD	(IX+#00),#00	;terminating zero slot code
	or	a	;clear carry
	ret

m_scanslot:
	LD	A,(DE)
	or	a	;mapperram here?
	ret	Z	;no, (rom or fixed ram)
	LD	A,(#F344)	;are we in the DOSRAM?
	CP	C
	ld	a,(de)	;loads maxpagenr before DE
	ld	e,0	;is used
	ld	d,a
	ld	b,a
	JR	NZ,J2589	;no, register everything
	inc	e	;e on 1
J2589:
	inc	b	;effective number of blocks
J258B:
	LD	A,H
	OR	L
	scf
	ret	Z	;we already have enough (nr_max blocks!)
	bit	0,e	;are we in the tpa slot?
	jr	z,m_do_reg	;no, register immediately
	ld	a,d
	push	hl
	call	m_chk_tpa	;is it a tpa segment?
	pop	hl
	jr	z,m_do_skip	;yes, don't register then
m_do_reg:
	DEC	HL	;search 1 page less
	LD	(IX+#00),C	;save slot code
	INC	IX
	LD	(IX+#00),D	;save ram block number
	INC	IX
m_do_skip:
	dec	d
	djnz	J258B
	or	a	;reset carry
	ret
m_chk_tpa:
	ld	hl,tab_TPA	;check for page 0
	cp	(hl)
	ret	z
	inc	hl	;check for page 1
	cp	(hl)
	ret	z
	inc	hl	;check for page 2
	cp	(hl)
	ret	z
	inc	hl	;check for page 3
	cp	(hl)
	ret

m_manage:
	ld	ix,tempbuffer
	call	m_alloc_tpa	;allocate 2 tpaslotsegm. to temp buffer
	ret	c
	call	m_alloc_tpa
	;the first is for cblock1
	;the second may be missing, it is for the label buffer
	;if it's missing it'll be set in the maintpa segm later.
	;Note: the last 2 bytes of tempbuffer will then be 0
	;this is taken into account in m_add_temp
	ld	ix,buffer	;note: 2 tpa found, then ix already good
m_all_notpa:
	call	m_alloc_notpa
	JR	C,m_outofnottpa	;we're out of non-tpa segments
	LD	A,H
	OR	L
	JR	NZ,m_all_notpa
	call	m_add_temp	;add the two tpaslotsegs
	ld	(ix),0
	or	a	;clear carry
	ret
m_outofnottpa:
	call	m_add_temp	;insert the two tpaslotsegs
m_all_tpa:
	call	m_alloc_tpa
	JR	C,m_outoftpa	;we're out of non-tpa segments
	LD	A,H
	OR	L
	JR	NZ,m_all_tpa
m_outoftpa:
	ld	(ix),0
	or	a	;clear carry
	ret

m_add_temp:
	push	hl	;insert the 1 or 2 segments
	ld	hl,tempbuffer
	push	ix
	pop	de
	ldi
	ldi
	xor	a
	cp	(hl)
	jr	z,m_skip_2
	ldi		;also add 2nd
	ldi
m_skip_2:
	push	de
	pop	ix
	pop	hl
	ret
m_alloc_tpa:
	ld	bc,#4300	;memman:prefer tpa dos2:tpa only
	call	m_all_save
	ret	c	;abort, no more tpa
	ld	a,(#f344)	;check on memman: was it a tpa
	cp	b	;dos always gives tpa
	ret	z
m_free_it:
	inc	hl
	dec	ix
	ld	c,(ix)
	dec	ix
	ld	b,(ix)
	push	hl
	call	m_free_b_c
	pop	hl
	scf
	ret

m_alloc_notpa:
	ld	a,(stat_mem)
	cp	2
	jr	nc,m_alloc_mntpa	;a little more difficult with memman
	ld	c,#10	;dos2:definitely no tpa
	jr	m_all_save	;=call m_all_save, ret
m_alloc_mntpa:
	ld	b,0
m_try_nottpa: 
	push	bc
	ld	b,#03	;memman:fseg
	call	m_all_save
	jr	c,m_alles_op
	ld	a,(#f344)	;check on memman: was it a
	cp	b	;non-tpa?
	jr	nz,m_ja_eindelyk
	pop	bc
	djnz	m_try_nottpa
	di
	halt		;Normally we'll never reach this point,
	;as you can never request 256 tpasegm with memman,
	;since a mapper only counts 256 segm, and 0 is never freed.
m_ja_eindelyk:
	pop	bc	;get b
	dec	ix
	push	ix	;(save this place)
	dec	ix
	call	m_free_tpa
	pop	bc	;get that place/spot where the 'not-tpa' was located.
	ld	a,(bc)	;get segment num
	ld	e,a
	dec	bc
	ld	a,(bc)	;get slot code
	ld	(ix),a
	inc	ix
	ld	(ix),e
	inc	ix
	or	a	;clear carry
	ret
m_alles_op:
	pop	bc
	call	m_free_tpa
	scf
	ret
m_free_tpa:
	ld	a,b
	or	a
	ret	z
	push	bc
	call	m_free_it
	pop	bc
	inc	b
	jr	m_free_tpa

m_all_save:
	push	hl
	call	Mm_dos2_alloc
	pop	hl
	ret	c
	LD	(IX+#00),B	;save slot code
	INC	IX
	LD	(IX+#00),A	;save ram block number
	INC	IX
	dec	hl
	ret
Mm_dos2_alloc:
	LD	A,(stat_mem)
	DEC	A
	JR	NZ,m_Mm_alloc
	LD	A,(primmap_slot)	;only dos 2
	OR	C	;try to allocate segments
	LD	B,A
	LD	A,#01	;allocate system segments
	db	#c3	;jump
jp_all_seg:
	dw	0
m_Mm_alloc:
	PUSH	IX
	LD	DE,#4D0A
	CALL	#FFCA
	POP	IX
	LD	A,H
	OR	L
	SCF		;hl=0000 =segments are used up
	RET	Z
	LD	B,L	;Memman segment code appears to consist of
	LD	A,H	;H=mapperblock L=slot code
	CCF
	RET

m_count_free:
	LD	HL,buffer
	LD	DE,#0000	;count of slot codes with bit6 low=unused
J2608:	LD	A,(HL)
	OR	A
	RET	Z	;end of the list
	BIT	6,(HL)
	JR	NZ,J2610
	INC	DE
J2610:	INC	HL
	INC	HL
	JR	J2608

m_vgl_HLDE:
	LD	A,H
	SUB	D
	RET	NZ
	LD	A,L
	SUB	E
	RET

m_freeall:
	ld	a,#b6	;poke new opcode: res 6,(ix+0)
	ld	(m_res6),a	;as a result, also the used
m_free: 
	LD	A,(stat_mem)
	OR	A
	scf
	RET	Z	;only if there is a mem manager
	LD	IX,buffer-2
m_freenext:
	INC	IX
	INC	IX
	db	#DD,#CB,0	;res 5,(ix+0): so this does nothing
m_res6:
	db	#AE	;to free EVERYTHING: poke here #B6
	LD	A,(IX+#00)	;this is opcode for res 6,(ix+0)
	OR	A
	scf
	RET	Z	;done
	bit	4,a	;is it a tpa segment?
	jr	nz,m_freenext	;yes, don't free it then
	BIT	6,A	;do not free segments that are in use,
	JR	NZ,m_bit6seg	;and give them the reserved status under memman
	ld	b,a	;slot code in b
	LD	c,(IX+#01)	;page number in c
	call	m_free_b_c
	jr	m_freenext

m_bit6seg:
	LD	A,(stat_mem)
	CP	#02	;memman?
	jr	c,m_freenext
	LD	L,(IX+#00)
	RES	6,L	;restore the original slot code
	LD	H,(IX+#01)	;(without bit 6 set)
	LD	DE,#4D0B	;give reserved status (memman only)
	PUSH	IX
	CALL	#FFCA
	pop	ix
	JR	m_freenext

m_free_b_c:
	LD	A,(stat_mem)
	CP	#02
	JR	nc,m_fre_Mm
	ld	a,c
	db	#c3	;jump: free under dos2
jp_fre_seg:
	dw	0
m_fre_Mm:
	LD	L,B	;free under memman
	LD	H,C
	LD	DE,#4D14
	PUSH	IX
	CALL	#FFCA
	POP	IX
	ret

J24AE:	INC	DE
	INC	DE
m_use_zet6_hl:
	LD	A,(DE)
	BIT	6,A	;already used?
	JR	NZ,J24AE
	and	#8f	;clear any tpa bit
m_dosram_fnd:
	LD	(HL),A
	INC	HL
	ld	a,(de)	;get original (with possibly bit4 high)
	OR	#40	;put bit 6
	LD	(DE),A
	INC	DE
	LD	A,(DE)
	INC	DE
	LD	(HL),A
	INC	HL
	XOR	A
	RET

m_src_dosram:
	LD	A,(#F344)
	LD	B,A
J249F:	LD	A,(DE)
	OR	A	;end already reached?
	SCF
	RET	Z
	BIT	6,A	;already in special use?
	JR	NZ,J24AA
	and	#8f	;clear any tpa bit
	CP	B
	JR	Z,m_dosram_fnd
J24AA:	INC	DE
	INC	DE
	JR	J249F

m_add_321:
	LD	A,(#F344)
	LD	C,A
	push	hl
	ld	hl,tab_TPA
	LD	B,#03
J2462:	PUSH	BC
	LD	A,(hl)
	inc	hl
	LD	B,C
	CALL	m_src_b_a	;is this segment already in our table?
	JR	NC,J2478	;dosrampage was found
	set	4,b	;set bit as sign of tpa segment
	LD	(IX+#00),B	;not found, add them by ourselves
	INC	IX
	LD	(IX+#00),C
	INC	IX
	LD	(IX+#00),#00
J2478:	POP	BC
	DJNZ	J2462
	pop	hl
	RET

m_src_b_a:
	LD	C,A	;look for a page in slot B, nr A
	LD	IX,buffer-2	;this page may be used
	;off: Not Carry: ok, IX
	;Carry set: not found, ix on the zero byte
J2485:
	INC	IX
	INC	IX
	LD	A,(IX+#00)
	OR	A
	SCF
	RET	Z
	AND	#8f	;don't let bits 6 and 4 come through
	CP	B
	JR	NZ,J2485
	LD	A,(IX+#01)
	CP	C
	JR	NZ,J2485
	RET

m_usepages:
	PUSH	DE
	LD	HL,mem_tabel
	LD	A,C
	CP	#05	;source buffer type? (1-4)
	JR	NC,m_no_sbuf	;new
	LD	DE,#002E
J23F7:	DEC	a	;set hl correctly depending on sbufnr
	JR	Z,m_setuse
	ADD	HL,DE
	JR	J23F7
m_no_sbuf:
	CP	#09	;data block type?
	JR	Z,m_datablok
	LD	DE,#0021
	ADD	HL,DE
	LD	DE,#002E
	SUB	#04
J240A:	DEC	A
	JR	Z,m_setuse
	ADD	HL,DE
	JR	J240A
m_datablok:
	LD	DE,#00B8
	ADD	HL,DE

m_setuse:
	POP	DE	;set B free pages on entry hl in use
	DEC	IX	;DE(free pages) is reduced
	DEC	IX	;bit 6 is set to high
m_nxtblok:
	INC	IX
	INC	IX
	LD	A,(IX+#00)
	OR	A
	SCF
	RET	Z
	BIT	6,A	;already used for compass?
	JR	NZ,m_nxtblok
	LD	A,C
	CP	#09
	JR	NZ,m_register	;register, when not for labelsegment
	LD	A,(HL)
	OR	A	;in case of a label segment we may also
	JR	NZ,m_register	;register if it's not the first one
	ld	a,(ix)
	and	#8f	;possibly reset bit 4 (tpa-seg)
	exx		;save c
	ld	c,a	;a first label segment. must be in the
	ld	a,(#f344)	;tpaslot
	cp	c
	exx		;restore c
	jr	nz,m_nxtblok
m_register:
	PUSH	BC
	PUSH	DE
	PUSH	HL
	ld	e,(hl)
	INC	(HL)
	INC	HL
	RLC	E
	LD	D,#00
	ADD	HL,DE
	LD	A,(IX+#00)
	SET	6,(IX+#00)
	and	#8f	;clear any tpa-bit
	LD	(HL),A
	INC	HL
	LD	A,(IX+#01)
	LD	(HL),A
	POP	HL
	POP	DE
	DEC	DE
	POP	BC
	DJNZ	m_nxtblok
	OR	A	;success
	RET

inst_mem:
	ld	a,(i_cblocks+2)	;check if the tpaslot is the same
	ld	b,a
	ld	a,(#f344)
	cp	b
	scf
	ret	nz
	CALL	m_tabel
	ret	c	;no 2 tpa segs found
	CALL	m_add_321

	LD	B,#04	;install 4 buffers
	LD	IY,i_mem_sbuf
	LD	DE,#002E
	CALL	m_chk_alloc
	JP	C,m_freeall

	LD	B,#04	;install 4 data buffers
	LD	IY,i_mem_sbuf+#21
	LD	DE,#002E
	CALL	m_chk_alloc
	JP	C,m_freeall

	LD	B,#01	;install 1 label buffer
	LD	IY,i_mem_sbuf+#B8
	CALL	m_chk_alloc
	JP	C,m_freeall

	CALL	C26B4	;install 4 compass blocks
	JP	C,m_freeall	;***easy to make like previous**

	LD	HL,i_mem_sbuf
	LD	DE,mem_tabel
	LD	BC,#C1
	LDIR
	LD	HL,i_cblocks
	LD	DE,compass_0
	LD	BC,8
	LDIR
	call	m_free
	XOR	A
	RET

C26B4:	LD	B,#01
	PUSH	BC
	LD	B,#04
	LD	IY,i_cblocks-1
	JR	J26C3

m_chk_alloc:
	PUSH	BC
	LD	B,(IY+#00)
J26C3:	PUSH	IY
	INC	IY
	PUSH	DE
	LD	A,B
	OR	A
	JR	Z,J26E9	;all segment. finished on this entry
J26CC:	PUSH	BC
	LD	B,(IY+#00)
	INC	IY
	LD	A,(IY+#00)
	INC	IY
	CALL	m_src_b_a
	POP	BC
	JR	C,J26F3	;segment not found
	SET	6,(IX+#00)
	DJNZ	J26CC
J26E9:	POP	DE
	POP	IY
	ADD	IY,DE
	POP	BC
	DJNZ	m_chk_alloc
	XOR	A
	RET
J26F3:	POP	DE
	POP	IY
	POP	BC
	SCF
	RET

;******************************************** end of mem routines
ld_blokb_2c:
	di
	ld a,(stat_mem)
	and 1
	jr z,ld_blokb_2c_dos1

ld_blokb_2c_dos2:
	ld a,b
ld_blokb_2c_putp2:
	call 0
	jr skipmap2

ld_blokb_2c_dos1:
	ld	a,b
	OUT	(#FE),A
skipmap2:
	LD	A,C
	LD	H,#80
	CALL	#0024
	RET

set_DTA:
	LD	(curr_DTA),DE
	LD	C,_SETDTA
	JP	bdos

load_data:
	LD	A,(stat_dos)
	CP	#02
	LD	DE,fcb_compass	;prepare load in dos1
	LD	C,#27
	JR	C,eindload
	LD	DE,(curr_DTA)	;load in dos2
	LD	A,(new_handle)
	LD	B,A
	LD	C,#48
eindload:
	CALL	bdos
	OR	A
	ret	z
	JP	err_in_call

slot_en_move:
	di
	ld a,(stat_mem)
	and 1
	jr z,slot_en_move_dos1

slot_en_move_dos2:
	ld a,b
slot_en_move_putp1:
	call 0
	jr skipmap1

slot_en_move_dos1:
	LD	a,b
	OUT	(#FD),A
skipmap1:
	LD	A,C
	LD	H,#40
	CALL	#0024
	LD	HL,#8000
	LD	D,#40
	ld	e,l
	ld	b,d
	ld	c,e
	LDIR
	RET

;*********************************************************data area
compass_ID:	db	"KONPASS",0
txt_inmem:	db	"Konpass already in memory, resuming... $"
txt_msx1:	db	"Minimal MSX 2 required !",13,10,"$"
startpalet:	db	#00,#00,#00,#00,#77,#07,#04,#00
	db	#17,#01,#27,#03,#51,#01,#27,#06
	db	#71,#01,#73,#03,#61,#06,#63,#06
	db	#11,#04,#65,#02,#55,#05,#77,#07
txt_intro:	db	"Konpass #1.3, (C) 2025 by Konamiman",13,10
	db  "Based on Compass #1.2.09, (C)1998 by Compjoetania TNG",13,10,10,"$"
txt_old:	db	7,"Notice: You are using a version of Memman older "
	db	"than version 2.40 .",13,10
	db	"TPA segments will be assumed to have numbers 3,2,1 "
	db	"and 0.",13,10,10,"$"
txt_ROMRAM:	db	"Locating ROM/RAM: $"
txt_done:	db	"done, found $"
txt_segments:	db	" segments ($"
txt_kB_RAM:	db	"kB RAM)",13
txt_lf:	db 10,"$"
txt_manage:	db	"Memory management: $"
tab_manage:	dw	txt_none
	dw	txt_DOS2
	dw	txt_Memman1
	dw	txt_Memman2
txt_none:	db	"none",13,10,"$"
txt_DOS2:	db	"DOS2 mapper support",13,10,"$"
txt_Memman1:	db	"Memman (DOS1 environment)",13,10,"$"
txt_Memman2:	db	"Memman (DOS2 environment)",13,10,"$"
txt_limit:	db	"Memory allocation limited to $"
txt_inst:	db	"Installing saved memory: $"
txt_notfree:	db	"Not free or different memory configuration !",13,10,"$"
txt_okused:	db	"Ok, used $"
txt_search:	db	"Searching free memory: $"
txt_nofree:	db	"Insufficient free memory !",13,10,"$"
txt_load:	db	"Loading Konpass: $"
txt_err_env:	db	"aborted",13,10,10,"Not enough memory to create the "
	db	"KONPASS environment item!",13,10,"$"
txt_lderr:	db	"Load error !",13,10,10,"$"
txt_lddone:	db	"done",13,10,10,"All engines ready.",13,10,"$"
txt_launch:	db	"Launching Konpass...",13,10,"$"
txt_noprog: db "aborted",13,10,10,"The PROGRAM environment item "
	db	"does not exist!",13,10,"$"
txt_nocfg:  db "KONPASS.CFG not found, will use default config",13,10,10,"$"

nr_max:	dw	14*256	;default: search as much as possible
stat_dos:	db	0
stat_mem:	db	0
primmap_slot:	db	0

;ROMRAM slot table format:
;+0: Slot 0-0, page 0: 0=nothing, 1=ROM, 2=RAM (mapped or not)
;+1: If mapped RAM: segments count minus one, otherwise 0
;+2,3: Slot 0-1, page 0
;+4,5: Slot 0-2, page 0
;+6,7: Slot 0-3, page 0
;+8,9: Slot 1-0, page 0
;...and so on until Slot 3-3, page 0.
;Then repeat for page 1 and then for page 2.
work_ROMRAM:	ds	#60,0

mem_tabel:	ds	#c1,0
compass_0:	dw	0
compass_1:	dw	0
compass_2:	dw	0
compass_3:	dw	0
tab_TPA:	db	3,2,1,0	;default TPAsegments for page 0,1,2 and 3
decstr:	ds	6,0
env_program:	db	"PROGRAM",0
env_compass:	db	"KONPASS",0
fcb_compass:
	db	0,"KONPASS DAT"
	ds	25,0
fcb_cfg:
	db	0,"KONPASS CFG"
	ds	25,0
new_handle:	db	0
curr_DTA:	dw	0
m_priortab:	db	4,1,1,5,255,1,2,1,6,4,1,1,5,1
	db	9,4,2,1,6,3,1,1,5,1,9,255,1,3,1,7
	db	4,2,1,6,4,3,1,7,3,2,1,6,4,3,1,7
	db	255,1,4,1,8,3,3,1,7,4,4,1,8,4,4,1
	db	8,3,4,1,8,0
saved_config_available: db 0

inst:	db	0	;0=another virginal program
	                        ;-->then show src_mem
	db	0	;don't skip src_mem
i_new:	equ	inst+#00	;brand new compass 0=yes
i_skipsrcmem:	equ	inst+#01	;should the searchmem be skipped w?0=no
i_mem_sbuf:	equ	inst+#02	;sbuf,datbuf,labelbuf config
i_cblocks:	equ	inst+#c3	;compass blocks
i_limit:	equ	inst+#11b	;max.number of blocks to be allocated (5-96)
	ds	(i_limit)-$,0	;area for all kinds of settings
	db	9	;max blocks to install in limit mode
inst_end:

tempbuffer:	ds	4,0
buffer:	;buffer: overwrites logoprog
