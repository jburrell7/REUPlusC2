
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <peekpoke.h>
#include <ctype.h>

#include "TimeUtils.h"
#include "DateUtils.h"
#include "GenUtils.h"
#include "DateUtils.h"


// Program wide lobal variables
extern unsigned char g_rtcRegs[20];
extern unsigned char g_inputBuf[80];
extern unsigned char g_numBuf[8];	// buffer for parsed number or string
extern unsigned char g_nrDigits;	// number of characters in the string


// local globals
unsigned char day, month, dayNr;
unsigned int year;
unsigned char aryIndxD;


unsigned char getDateInput(void)
{
// get the user's input
	gotoxy(0, 20);
	printf("Enter date dd:mm:yyyy: ");
	gets(g_inputBuf);
// clip the string length
	g_inputBuf[79] = '\0';
//--- get the date
	aryIndxD = 0;

	return 0;
}


unsigned char parseDay(void)
{
// skip any spaces
	aryIndxD = gobbleSpaces(aryIndxD);
// get the day digits
	aryIndxD = getNum(aryIndxD);
	if ((g_nrDigits == 0) || (g_nrDigits > 2))
	{
	// error
		day = 255;
	} else {
		day = atoi(g_numBuf);
	}

// perform a quick sanity check. more will
//	be done later.
	if ((day == 0) || (day > 31)) day = 255;

	return day;

}


unsigned char parseMonth(void)
{

//--- get the month
	aryIndxD = getAlphanum(aryIndxD);
	switch (g_nrDigits)
	{
	case 0:
	// we must have at least one character
		month = 255;
		break;
	case 1:
	case 2:
	// these MUST be numeric digits
		month = atoi(g_numBuf);
		if ((month < 1) || (month > 12)) month = 255;
		break;
	case 3:
    // we assume this is a month name
    // 255 will be returned if the month string is invalid
    //	else a value between 1 and 12
    	month = getMonthNr();
		break;
	default:
	// bad input
		month = 255;
	}

	return month;
}

unsigned char parseYear(void)
{

	aryIndxD = getNum(aryIndxD);
	if (g_nrDigits != 4) year = 0x00FF;
	year = atoi(g_numBuf);
	if (year < 2000) year = 2000;
	if (year > 2199) year = 3000;

	return year;

}

unsigned char setDate(void)
{
// get the user's input
	getDateInput();

//-- parse out the fields from the user input
//
// the parsers will return 255 if there was a
//	parsing error
	if (parseDay() == 255) goto errorExit;
	aryIndxD++;
	if (parseMonth() == 255) goto errorExit;
	aryIndxD++;
	if (parseYear() == 255) goto errorExit;
	aryIndxD++;

// at this point we have a valid month and year
//	data so we verify the date falls in the correct
//	range for the month
//
	if (checkMonthLength(day, month, year) == 255) goto errorExit;

// we now have valid, range checked day, month, and year data
//	so we now compute the day number from that data

	dayNr = dayOfWeek(day, month, year);
	if (dayNr == 255) goto errorExit;

	g_rtcRegs[3]	= dayNr;

	g_rtcRegs[4]	= charToBcd(day);

	month			= charToBcd(month);
	if (year > 2099) month |= 0x80;
	g_rtcRegs[5]	= month;

	g_rtcRegs[6]	= charToBcd(year % 100);

	return 0;

errorExit:
	gotoxy(0, 22);
	printf("Error in the date input string\n");
	return 255;

}



