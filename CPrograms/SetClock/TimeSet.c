#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <peekpoke.h>
#include <ctype.h>

#include "TimeUtils.h"
#include "DateUtils.h"
#include "GenUtils.h"

extern unsigned char g_rtcStartAdr;
extern unsigned char g_rtcNrBytes;
extern unsigned int  g_rtcAryPtr;
extern unsigned char g_rtcRegs[20];
extern unsigned char g_inputBuf[80];

extern unsigned char g_numBuf[8];	// buffer for parsed number or string
extern unsigned char g_nrDigits;	// number of characters in the string



unsigned char aryIndxT;
unsigned char hr, min, sec;

#define CURRTIME 2

void printCurrentTime(void)
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



//----------------------------------------------
// Allow the user to enter a time string from
//	the keyboard. Some error checking is done
//	to ensure obvious errors are not passed
//	through.
//
// The function leaves the new data in the
//	global RTC data array if all is well,
//	else it leaves the array alone.
//
// This function uses the despised goto
//	to branch to the error routine. This
//	is one of the few good uses for a goto
//	so not quibbling will be entertained.
//
unsigned char setTime(void)
{
// get the user's input
	gotoxy(0, 20);
	printf("Enter time hh:mm:ss: ");
	gets(g_inputBuf);
// clip the string length
	g_inputBuf[79] = '\0';

//--- get the hours
	aryIndxT = 0;
// skip any spaces
	aryIndxT = gobbleSpaces(aryIndxT);
// get the first digits
	aryIndxT = getNum(aryIndxT);
	if ((g_nrDigits == 0) || (g_nrDigits > 2))
	{
	// error
		goto errorExit;
	} else {
		hr = atoi(g_numBuf);
	}

// skip past the separator character
	aryIndxT++;

//--- get the minutes
// get the first digits
	aryIndxT = getNum(aryIndxT);
	if (g_nrDigits != 2)
	{
	// error
		goto errorExit;
	} else {
		min = atoi(g_numBuf);
		if (min > 59) goto errorExit;
		min = charToBcd(min);
	}
// skip past the separator character
	aryIndxT++;


//--- get the seconds
// get the first digits
	aryIndxT = getNum(aryIndxT);
	if (g_nrDigits != 2)
	{
	// error
		goto errorExit;
	} else {
		sec = atoi(g_numBuf);
		if (sec > 59) goto errorExit;
		sec = charToBcd(sec);
	}

//
//--- check for AM or PM
// This section of code checks the hours
//	value against limits that are set
//	by the user's input. If the user
//	has appended an A or P to the time,
//  the hours are checked against a 12
//	hour clock else 24 hours.
//
// This routine also sets the mode select
//	bits for the RTC to match what the user
//	wanted.
//
//
	switch (g_inputBuf[aryIndxT])
	{
	case 'A':
	case 'a':
		if (hr > 12) goto errorExit;
		hr = charToBcd(hr);
		hr &= 0x1F;
		hr |= 0x40;
		break;

	case 'P':
	case 'p':
		if (hr > 12) goto errorExit;
		hr = charToBcd(hr);
		hr &= 0x1F;
		hr |= 0x60;
		break;

	default:
		if (hr > 23) goto errorExit;
		hr = charToBcd(hr);
		hr &= 0x3F;
		break;
	}

	g_rtcRegs[2]	= hr;
	g_rtcRegs[1]	= min;
	g_rtcRegs[0]	= sec;
	printCurrentTime();
	return 0;


errorExit:
	gotoxy(0, 22);
	printf("Error in the time input string.\n");
	return 0xFF;
}

