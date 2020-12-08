#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <peekpoke.h>
#include <ctype.h>
#include <string.h>

//#include "i2cRtnsX.h"
#include "rtcRtns.h"

#include "TimeSet.h"
#include "SetDate.h"
#include "GenUtils.h"
#include "DateUtils.h"



#define ALARM1   6
#define ALARM2   12

#define OPTIONS  11


//extern unsigned char g_rtcStartAdr;
//extern unsigned char g_rtcNrBytes;
//extern unsigned int  g_rtcAryPtr;
//extern unsigned char g_rtcRegs[20];

extern unsigned char g_rtcStartAdr;
extern unsigned char g_rtcNrBytes;
extern unsigned int  g_rtcAryPtr;
extern unsigned char g_rtcRegs[20];
extern unsigned char g_inputBuf[256];


extern unsigned char g_numBuf[8];	// buffer for parsed number or string
extern unsigned char g_nrDigits;	// number of characters in the string


unsigned char skipSpaces(unsigned char aryPtr)
{
	while(1)
	{
		if (g_inputBuf[aryPtr] = '\0') return 0xFF;
		if (isdigit(g_inputBuf[aryPtr])) return aryPtr;
		++aryPtr;
	}
}




//------------------------------------------
// Load the RTC array with default values
//
void getRtcTimeRegsX(void)
{
	g_rtcRegs[0]  = 0x47;			// time seconds
	g_rtcRegs[1]  = 0x03;			// time minutes
//	g_rtcRegs[2]  = 0x11;			// time hours
	g_rtcRegs[2]  = 0x21 | 0x40;
	g_rtcRegs[3]  = 0x05;			// day of week [1..7]
	g_rtcRegs[4]  = 0x30;			// date
	g_rtcRegs[5]  = 0x09;			// month & century bit
	g_rtcRegs[6]  = 0x20;			// year

	g_rtcRegs[7]  = 0x12;		// Alarm 1 seconds
	g_rtcRegs[8]  = 0x24;		// Alarm 1 minutes
	g_rtcRegs[9]  = 0x09;		// Alarm 1 hours
	g_rtcRegs[10] = 0x23;		// Alarm 1 day/date

	g_rtcRegs[11] = 0x22;		// Alarm 2 minutes
	g_rtcRegs[12] = 0x03;		// Alarm 2 hours
//	g_rtcRegs[13] = 0x07;		// Alarm 2 day/date
	g_rtcRegs[13] = 0x07 | 0x40;

	g_rtcRegs[14] = 0x00;
	g_rtcRegs[15] = 0x00;
	g_rtcRegs[16] = 0x00;
	g_rtcRegs[17] = 0x00;
	g_rtcRegs[18] = 0x00;
	g_rtcRegs[19] = 0x00;
}



void printBanner(void)
{
	clrscr();
	gotoxy(16,0);
	printf("Set RTC");
}


void printLongHex(unsigned long x)
{
	printf("0x%04x%04x", (unsigned int)(x >> 16), (unsigned int)(x & 0xFFFF));
}







void clrReports(void)
{
unsigned char i;

	gotoxy(0,19);

	for(i = 0; i < 20; i++)
	{
		printf("          ");
	}
}




void printOptions(void)
{
	gotoxy(2,7);
	printf("Enter one of the following charaters:\n");
	printf("R - Read RTC chip\n");
	printf("T - change time (hh:mm:ss)\n");
	printf("    add A or P for 12 hour mode\n");
	printf("    otherwise 24 hour mode assumed\n");
	printf("D - change date (dd/mm/yyyy)\n");
	printf("    the month can be numeric or\n");
	printf("    a three letter abbreviation\n");
	printf("W - write changes to RTC\n");
	printf("X - exit program\n");
}

unsigned char getInput(void)
{
	while (1)
	{
		gotoxy(2,18);
		printf("Option? :");
		gets(g_inputBuf);

		clrReports();

		switch (g_inputBuf[0])
		{
		case 'R':
		case 'r':
			getRtcTimeRegs();
			printCurrentDateTime();
			break;
		case 'T':
		case 't':
			setTime();
			printCurrentDateTime();
			break;

		case 'D':
		case 'd':
			setDate();
			printCurrentDateTime();
			break;

		case 'W':
		case 'w':
			putRtcTimeRegs();
			break;

		case 'X':
		case 'x':
			return 0;
		break;
		}
	}


}


int main (void)
{

unsigned char i;	//, j, k;
unsigned char aryIndx;
unsigned int x;

	getRtcTimeRegs();

	printBanner();
	printCurrentDateTime();

	printOptions();
	getInput();
	clrscr();

//	for(i = 0; i < 8; i++)
//	{
//		printf("%d: %02x\n", i, g_rtcRegs[i]);
//	}
//

	printf("End clock program\n");

	return 0;

}


