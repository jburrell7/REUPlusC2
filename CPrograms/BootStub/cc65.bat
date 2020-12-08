
echo off


e:\c64programs\cc65\bin\cl65 -O -t c64 bootStub.c
e:\c64programs\cc65\bin\cc65 -T -t c64 bootStub.c


REM ..\..\concat -e 0x70000 -n bootstub -j $080d


..\..\concat -e 0x00000 -n bootstub -j $080d
copy bootstub.prg bootstub00.prg
..\..\concat -e 0x7C000 -n bootstub -j $080d
copy bootstub.prg bootstubc0.prg



rem ..\..\concat -e 0x70000 -n PROBEFILE.bin
rem COPY PROBEFILE.prg probefile00.prg
rem ..\..\concat -e 0x7C000 -n PROBEFILE.bin
rem COPY PROBEFILE.prg probefilec0.prg



pause


