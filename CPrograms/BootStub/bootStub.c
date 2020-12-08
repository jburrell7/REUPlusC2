#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <peekpoke.h>
#include <ctype.h>
#include <string.h>

#define ROMSELREG 0xDF28


int main()
{
unsigned char inChar;

	cprintf("Boot file test program\n\r");
	cprintf("Press a key to exit program\n\r");
	cprintf("to BASIC\n\r");

	inChar = cgetc();

// disable the boot ROM
	POKE(ROMSELREG, 0x80);
// jump to the reset vector
	__asm__("jmp ($FFFC)");

	return 0;

}
