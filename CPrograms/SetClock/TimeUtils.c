#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <peekpoke.h>
#include <ctype.h>

extern unsigned char g_rtcStartAdr;
extern unsigned char g_rtcNrBytes;
extern unsigned int  g_rtcAryPtr;
extern unsigned char g_rtcRegs[20];

extern unsigned char inputBuf[256];




void printHour(unsigned char aryIndex)
{

	if (g_rtcRegs[aryIndex] & 0x40)
	{
	// 12 hour mode
		printf("%02x:", g_rtcRegs[aryIndex] & 0x1F);
	} else {
	// 24 hour mode
		printf("%02x:", g_rtcRegs[aryIndex] & 0x3F);
	}
}

void printAmPm(unsigned char aryIndex)
{
	if (g_rtcRegs[aryIndex] & 0x40)
	{
		if (g_rtcRegs[aryIndex] & 0x20)
		{
			printf("PM");
		} else {
			printf("AM");
		}
	} else {
		printf("  ");
	}
}

void printTime(unsigned char aryIndx)
{

	printHour(aryIndx + 2);
	printf("%02x:", g_rtcRegs[aryIndx + 1]);
	printf("%02x", g_rtcRegs[aryIndx]);
	printAmPm(aryIndx + 2);
}

void printTimeMode(unsigned char aryIndex)
{
	if (g_rtcRegs[aryIndex] & 0x40)
	{
		printf("12h");
	} else {
		printf("24h");
	}
}

