
echo off

rem e:\c64programs\cc65\bin\cl65 -O -t c64 setClockMain.c i2cRtnsX.s rtcRtns.c

e:\c64programs\cc65\bin\cl65 -O -t c64 setClockMain.c Globals.c TimeSet.c TimeUtils.c DateUtils.c GenUtils.c SetDate.c i2cRtnsX.s rtcRtns.c



rem e:\c64programs\cc65\bin\cc65 -T ReuRtns.c



rem e:\c64programs\cc65\bin\cc65 -T setClockMain.c



rem e:\c64programs\cc65\bin\cc65 -T staticTest.c

rem e:\c64programs\cc65\bin\cc65 -T rtcRtns.c
e:\c64programs\cc65\bin\cc65 -T DateUtils.c


e:\c64programs\cc65\bin\ca65 -l rtcRtnsX.lst -I E:\C64Programs\cc65\__MyPgms\SetClock i2cRtnsX.s

pause


