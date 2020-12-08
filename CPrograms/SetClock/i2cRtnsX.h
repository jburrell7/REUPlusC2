

void i2cSendStart(void);
void i2cSendStop(void);
unsigned char i2cSendByte(unsigned char byte);
unsigned char __fastcall__ i2cSendNBytes(unsigned char nrBytes, unsigned int bufAdr);
unsigned char i2cGetByteAck(void);
unsigned char i2cGetByteNack(void);
unsigned char __fastcall__ i2cGetNBytes(unsigned char nrBytes, unsigned int bufAdr);


