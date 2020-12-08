

#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <peekpoke.h>
#include <ctype.h>

#include "TimeUtils.h"
#include "GenUtils.h"

extern unsigned char g_rtcRegs[20];
extern unsigned char g_numBuf[8];	// buffer for parsed number or string





//------------------------------------------
// Print the name of the day
//
// Inputs
//	dayNr		1 <= dayNr <= 7
//
// The function prints the name of the
//	day from an array of day names
//
unsigned char dayStr[] = "Sun\0Mon\0Tue\0Wed\0Thu\0Fri\0Sat\0";
void printDayName(unsigned char dayNr)
{
	--dayNr;
	if (dayNr > 6) dayNr = 6;
	printf("%s", (&dayStr[0] + (dayNr << 2)));
}


unsigned char monthStr[] = "Jan\0Feb\0Mar\0Apr\0May\0Jun\0Jul\0Aug\0Sep\0Oct\0Nov\0Dec\0";
void printMonthName(unsigned char monthNr)
{
	--monthNr;
	if (monthNr > 11) monthNr = 11;
	printf("%s", (&monthStr[0] + (monthNr << 2)));
}



void printDate(void)
{
	printDayName(g_rtcRegs[3] & 0x07);
	printf(" %02x ", g_rtcRegs[4] & 0x3F);
	printMonthName(bcdToChar(g_rtcRegs[5] & 0x1F));
	printf(" ");

// deal with the century
	if (g_rtcRegs[5] & 0x80)
	{
		printf("21");
	} else {
		printf("20");
	}

	printf("%02x", g_rtcRegs[6]);
}


//-------------------------------------------------------
// compute a number between 1 and 7 the corresponds to
//	the day of the week based on the full date
//
// Sun = 1, Mon = 2, Tue = 3, Wed = 4, Thu = 5
// Fri = 6, Sat = 7
//
unsigned char dayOfWeek(unsigned char day, unsigned char month, unsigned int year)
{
unsigned long factor, x;
unsigned char dx;

// range check the inputs and exit with an error if any are
//	bad
	if ((day > 31) || (month > 12) || (year < 1582)) return 0xFF;
	if ((day == 0) || (month == 0)) return 0xFF;


	factor = 365L * year + day + 31L * (month - 1);
	switch (month)
	{
	case 1:
	case 2:
		factor += (year - 1) >> 2;
		x = ((3L * ((year - 1) / 100L)) >> 2) + 1;
		factor -= x;
		break;
	default:
		factor -= ((month << 2) + 23L) / 10L;
		factor += year >> 2;
		factor -= ((3L * (year / 100L)) >> 2) + 1;
		break;
	}

	dx = (unsigned char)(factor % 7) + 1;

	return dx;

}


unsigned char isLeapYear(unsigned int y)
{
	if(y % 400) return 1;
	if(y % 100) return 0;
	if (y % 4) return 1;
	return 0;
}

unsigned char monLen[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
unsigned char checkMonthLength(unsigned char d, unsigned char m, unsigned int y)
{
	m--;
	if (m == 1)
	{
		if (d <= (monLen[1] + isLeapYear(y))) return 0;
	} else {
		if (d <= monLen[m]) return 0;
	}
	return 255;
}


//----------------------------------------------------------
// Generate a month number from a text input
// This routine will recognize a month based on
// the first letter or the first letter and
// some other letter in the three letter
// abreviation.
//
// Obvious errors will give a rejection but
// names are not rigorously checked.
//
// The following months have only their first
//	letters checked:
//	Feb, Sep, Oct, Nov, Dec
//
// These month names are checked with two
//	letters.
//
//  Jan		Ja*
//	Apr		Ap*
//	Jun		J*n
//	Jul		J*l
//	Aug		Au*
//	May		M*y
//	Mar		M*r
//

unsigned getMonthNr(void)
{
	switch(g_numBuf[0])
	{
	case 'j':
	case 'J':
	// January
		if ((g_numBuf[2] == 'a') || (g_numBuf[2] == 'A')) return 1;
	// June
		if ((g_numBuf[2] == 'n') || (g_numBuf[2] == 'N')) return 6;
	// July
		if ((g_numBuf[2] == 'l') || (g_numBuf[2] == 'L')) return 7;
	// ??
		return 255;
		break;
	case 'f':
	case 'F':
		return 2;
		break;
	case 'm':
	case 'M':
		if ((g_numBuf[2] == 'r') || (g_numBuf[2] == 'R')) return 3;
		if ((g_numBuf[2] == 'y') || (g_numBuf[2] == 'Y')) return 5;
		return 255;
		break;
	case 'a':
	case 'A':
	// April
		if ((g_numBuf[1] == 'p') || (g_numBuf[1] == 'P')) return 4;
		if ((g_numBuf[1] == 'u') || (g_numBuf[1] == 'U')) return 8;
		return 0;
		break;
	case 's':
	case 'S':
	// September
		return 9;
		break;
	case 'o':
	case 'O':
	// October
		return 10;
		break;
	case 'n':
	case 'N':
	// November
		return 11;
		break;
	case 'd':
	case 'D':
	// December
		return 12;
		break;
	default:
	// ??
		return 0xFF;
	}
}


