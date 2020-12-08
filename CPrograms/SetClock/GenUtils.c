#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <peekpoke.h>
#include <ctype.h>

#include "TimeUtils.h"
#include "DateUtils.h"

extern unsigned char g_rtcStartAdr;
extern unsigned char g_rtcNrBytes;
extern unsigned int  g_rtcAryPtr;
extern unsigned char g_rtcRegs[20];
extern unsigned char g_inputBuf[256];


extern unsigned char g_numBuf[8];
extern unsigned char g_nrDigits;


unsigned char getNum(unsigned char aryIndx)
{

	g_nrDigits = 0;

	while(1)
	{
		if (isdigit(g_inputBuf[aryIndx]))
		{
			g_numBuf[g_nrDigits] = g_inputBuf[aryIndx];
			g_nrDigits++;
			aryIndx++;

			if (g_nrDigits == 4)
			{
				break;
			}
		} else {
			break;
		}
	}
	g_numBuf[g_nrDigits] = '\0';
	return aryIndx;
}

unsigned char getAlphanum(unsigned char aryIndx)
{

	g_nrDigits = 0;

	while(1)
	{
		if (isdigit(g_inputBuf[aryIndx]) || isalpha(g_inputBuf[aryIndx]))
		{
			g_numBuf[g_nrDigits] = g_inputBuf[aryIndx];
			g_nrDigits++;
			aryIndx++;

			if (g_nrDigits == 4)
			{
				break;
			}
		} else {
			break;
		}
	}
	g_numBuf[g_nrDigits] = '\0';
	return aryIndx;
}


unsigned char gobbleSpaces(unsigned char aryIndx)
{

	while(isblank(g_inputBuf[aryIndx]))
	{
		++aryIndx;
	}
	return aryIndx;

}


unsigned char charToBcd(unsigned char charVal)
{
	return ((charVal / 10) << 4) + (charVal % 10);
}

unsigned char bcdToChar(unsigned char bcdVal)
{
	return (((bcdVal >> 4) * 10) + (bcdVal & 0x0F));
}


#define CURRTIME 2

void printCurrentDateTime(void)
{
unsigned char currLine;

	currLine = CURRTIME;

// print the text items
	gotoxy(12, currLine);
	printf("Time and Date");
	++currLine;
	gotoxy(4, currLine);
	printf("Time");
	gotoxy(14, currLine);
	printf("Mode");
	gotoxy(25, currLine);
	printf("Date");
	++currLine;

// print the RTC data
	gotoxy(2, currLine);
	printTime(0);
	gotoxy(14, currLine);
	printTimeMode(2);
	gotoxy(20, currLine);
	printDate();
}

