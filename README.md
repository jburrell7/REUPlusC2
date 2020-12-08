# REUPlusC2
This project implements an open source REU for the Commodore 64.

The hardware consists of two PCBs with an optional third peripheral PCB.

**Cyclone II Development Board**

The development uses an Intel EP2C5T144C8N FPGA and provides the FPGA and its configurator, one push button, three LEDs and the voltage converters for the FPGA power supplies.
The board also provides a total of 86 3.3V TTL compatible I/O pins, some of which are dedicated and cannot be used by peripherals. The board is modified by:
1. Removing the LEDs connected to FPGA pins 3, 7, and 9.
2. Moving the RC network on pin 73.
3. Removing the resistors on pins 26, 27, 80, and 81.

**Custom carrier board**

The main functions of the custom carrier board are to provide: 
1. A mechanical and electrical interface for the FPGA board. 
2. A card edge connector compatible with the C64 
3. The logic level shifters required to convert between the C64 5V signals and the FPGA 3.3V signal levels. 
4. Interfacing and power for the peripheral items on the PCB

**Optional Peripheral Board**

This board provides:
1. A battery backed real time clock using a Maxim DS3231SN#-ND RTC device using an I2C interface. The RTC has an onboard 32.768kHz crystal.
2. 512kBytes of EEPROM using 2@ AT24CM02-SSHM-T I2C EEPROMs.
3. A simple 80 column text video output using standard 640X480 VGA. The terminal is a modified version of Grant Searle's terminal provided in his Multicomp project.

**REU Functionality**

As implemented on this device, the REU has full access to 32MBi of SDRAM storage with all logic for the REU is implemented in a FSM programmed into the FPGA.

As of 7 December 2020, the REU has been tested using the software on the 1764-DEMO.D64 disk image. Note that all testing is performed on a C64C using an SD2IEC interface.
The software that has been successfully run is:

"1764 RAMTEST.BAS"
"POUND.BAS"
"GLOBE.BAS"
"SAMAREU.PRG"
So far, all programs have run successfully. Note however, none of these programs tests all 32MBi of memory and none perform what would be considered a proper memory test.

I am presently writing tests that will do that.

**Z80 Coprocessor**
As of 7 December 2020, the FPGA also contains a T80 core that is envisioned for with CP/M on the C64. When activated, the Z80 will use the REU memory for program storage and the C64 as an I/O processor and the C64 will act as an I/O processor for the Z80.
The C64 will not have access to any of the 32MBi SDRAM when the Z80 is running, but provision has been made to suspend the Z80 and allow the C64 to access the SDRAM. This will allow
the Z80 to transfer screen data to the C64 or receive disk data from the C64.

This functionality has not been tested as of 7 December 2020.

*** End of document ***
