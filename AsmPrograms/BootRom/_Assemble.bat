
echo off

rem assemble the source
..\..\tasm.exe -t65 -c -b BootRom.asm BootRom.bin BootRom.lst

..\..\tasm.exe -t65 -c BootRom.asm BootRom.hex BootRom.lst
ren bootRom.hex bootRom1.hex

rem convert the binary output to a MIF file
..\..\bin2Mif -fBootRom.bin -r1024 -b
..\..\bin2Mif -fBootRom1.hex -r1024 -h



rem copy the file to the FPGA directory
rem copy /Y BootRom.bin.mif E:\GitRepositories\Reu2c5\BottomUp\Reu2c5FpgaBaselineV3\BootRom.mif

pause


