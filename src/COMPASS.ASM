    ; Helper file for building COMPASS.COM and COMPASS.DAT with sjasm
    ; Requires sjasm 0.39i or newer (DON'T use sjasm 0.42)
    ; https://github.com/Konamiman/Sjasm/releases
    ;
    ; To build: sjasm -c compass.asm

    output "COMPASS.COM"

    module comfile
    include "COMFILE.ASM"
    incbin "PALET.BIN",7,32
    incbin "CTNG.COP",4,12019

    output "COMPASS.DAT"

header:
    db    13,10,"Compass #1.2.09 DATfile",13,10
    db    "(C)1998 Compjoetania The Next Generation",13,10,10
    db    "DO NOT DISTRIBUTE!",13,10,10,26
header_end:

    ds 128-(header_end-header)

    module main
    include "main.asm"

    module editor
    include "editor.asm"

    module asmrout
    include "asmrout.asm"

    module monitor
    include "monitor.asm"

    module debugger
    include "debugger.asm"
