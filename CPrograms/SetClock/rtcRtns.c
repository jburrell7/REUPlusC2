
#include "i2cRtnsX.h"


extern unsigned char g_rtcStartAdr;
extern unsigned char g_rtcNrBytes;
extern unsigned int  g_rtcAryPtr;
extern unsigned char g_rtcRegs[20];

void getRtcRegs(void)
{
	i2cSendStart();
	i2cSendByte(0xD0);
	i2cSendByte(g_rtcStartAdr);
	i2cSendStart();
	i2cSendByte(0xD1);
	i2cGetNBytes(g_rtcNrBytes, g_rtcAryPtr);
	i2cSendStop();
}


void setRtcRegs(void)
{
	i2cSendStart();
	i2cSendByte(0xD0);
	i2cSendByte(g_rtcStartAdr);
	i2cSendNBytes(g_rtcNrBytes, g_rtcAryPtr);
	i2cSendStop();
}



void getRtcTimeRegs(void)
{
	g_rtcStartAdr	= 0;
	g_rtcNrBytes	= 14;
	g_rtcAryPtr		= (unsigned int)&g_rtcRegs[0];
	getRtcRegs();
}

void putRtcTimeRegs(void)
{
	g_rtcStartAdr	= 0;
	g_rtcNrBytes	= 14;
	g_rtcAryPtr		= (unsigned int)&g_rtcRegs[0];
	setRtcRegs();
}


void getRtcCtlRegs(void)
{
	g_rtcStartAdr	= 14;
	g_rtcNrBytes	= 5;
	g_rtcAryPtr		= (unsigned int)&g_rtcRegs[14];
	getRtcRegs();
}


void putRtcCtlRegs(void)
{
	g_rtcStartAdr	= 14;
	g_rtcNrBytes	= 5;
	g_rtcAryPtr		= (unsigned int)&g_rtcRegs[14];
	setRtcRegs();
}

