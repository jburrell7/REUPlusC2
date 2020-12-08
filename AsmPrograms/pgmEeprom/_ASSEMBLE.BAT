
echo off

..\..\tasm -65 -b pgmEeprom.asm pgmEeprom.bin pgmEeprom.lst
copy /Y pgmEeprom.bin ..\..\pgmEeprom.bin

rem del /Q ..\..\pgmEeprom.bin
rem copy .\pgmEeprom.bin ..\..\pgmEeprom.bin

rem tasm -65 -b -dVICECART bootRom.asm bootRomVice.bin bootRomVice.lst
rem tasm -65 -b  bootRom.asm bootRomC64.bin bootRomC64.lst
rem tasm -65 -b -dEMUMODE bootRom.asm bootRomEmu.bin bootRomEmu.lst

pause


