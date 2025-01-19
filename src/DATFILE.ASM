; Main source file for the KONPASS.DAT file
; Assemble with Nestor80 (https://github.com/konamiman/Nestor80):
; N80 DATFILE.ASM KONPASS.DAT --direct-output-write --no-string-escapes

header:
    db    13,"Konpass #1.3 DATfile",13,10
    db    "(C) 2025 by Konamiman",13,10
    db 10
    db    "Based on Compass #1.2.09, (C)1998 by Compjoetania TNG",13,10,26
header_end:

    ds 128-(header_end-header)

    module main
    include "MAIN.ASM"
    endmod

    module editor
    include "EDITOR.ASM"
    endmod

    module asmrout
    include "ASMROUT.ASM"
    endmod

    module monitor
    include "MONITOR.ASM"
    endmod

    module debugger
    include "DEBUGGER.ASM"
    endmod
    
