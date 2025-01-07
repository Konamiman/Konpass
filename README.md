# Konpass

Konpass is an assembler IDE for MSX computers, complete with debugger and monitor. Minimum system requirements are a MSX2 computer with 128K RAM (256K if you use MSX-DOS 2). Konpass means "Konamiman's Phenomenal Assembler".

Konpass is a fork of Compass, originally developed in 1995 by Compjoetania and whose last version, 1.2.09, was released in 1999 by Compjoetania TNG (yes, these were two different groups of people; see [the historical versions file](docs/COMPASSV.TXT) for the full story).

Compass was a paid product, but in 2021 it was published for free including the source code: [Compass 1.2.09 repository in GitHub](https://github.com/turbor/compass-1.2-sources). Konpass was created as a set of improvements for Compass on top of these sources.

To build Konpass you need [Nestor80](https://github.com/Konamiman/Nestor80), run it like this:

```
N80 COMFILE.ASM KONPASS.COM
N80 DATFILE.ASM KONPASS.DAT --direct-output-write --no-string-escapes
```

There's also a `build.sh` script (for Linux and WSL) that will do that for you.

Konpass is [licensed under GPLv2](LICENSE), as it's Compass since its sources were published.
