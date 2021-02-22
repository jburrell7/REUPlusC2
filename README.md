# REUPlusC2
This project implements an open source REU for the Commodore 64.

This is an updated version based on the final hardware design

The hardware consists of two PCBs.

**Cyclone II Development Board**

The development board uses an Intel EP2C5T144C8N FPGA and provides the FPGA and its configurator, one push button, three LEDs and the voltage converters for the FPGA power supplies. The board also provides a total of 86 3.3V TTL compatible I/O pins, some of which are dedicated and cannot be used by peripherals. The board is modified by:
1. Removing the LEDs connected to FPGA pins 3, 7, and 9.
2. Moving the RC network on pin 73.
3. Removing the resistors on pins 26, 27, 80, and 81.

A web page that is a good summary of this board can be found at:
http://land-boards.com/blwiki/index.php?title=Cyclone_II_EP2C5_Mini_Dev_Board

**Custom carrier board**

The main functions of the custom carrier board are to provide: 
1. A mechanical and electrical interface for the FPGA board. 
2. A card edge connector compatible with the C64 
3. The logic level shifters required to convert between the C64 5V signals and the FPGA 3.3V signal levels. 
4. Interfacing and power for the peripheral items on the PCB.
5. Battery backed RTC
6. 256 byte EEPROM
7. Full-sized SD card socket

**REU Functionality**

As implemented on this device, the REU has full access to 32M bytes of SDRAM storage with all logic for the REU is implemented in a FSM programmed into the FPGA.

As of 22 February 2021, the REU has been tested using the software on the 1764-DEMO.D64 disk image. Note that all testing is performed on a C64C using an SD2IEC interface.
The software that has been successfully run is:

"1764 RAMTEST.BAS"
"POUND.BAS"
"GLOBE.BAS"
"SAMAREU.PRG"
So far, all programs have run successfully. Note however, none of these programs tests all 32MBi of memory and none perform what would be considered a proper memory test.

I am presently writing tests that will do that.

**RTC**
The board has provision for a DS3231SN# RTC chip with back up battery. This device incorporates an internal 32768Hz oscillator. The RTC and battery holder can be left off of the board to save about $15 in BOM costs.

**EEPROM**
The board has provision for AT24C02C-STUM-T I2C EEPROM. This device should be included on all builds as it can be used to contain configuration information.

**SD Card**
The board has provision for a full sized SD Card connector. This should be included on all builds because utilizing the 32M byte of memory would be painful if it required using the serial bus drives to load it.
