#ifndef PCODE_H
#define PCODE_H
#include "serial_port_utils.h"
#include "utilities.h"
#define PCODE_MAXLEN 100

//const char	carriage_return = 0xd;
//const char	line_feed = 0xa;

typedef struct PCodeDataStruct
{
	// GPGGA:
	float time;
	float lat;
	float lon;
	long flag;
	// GPVTG:
	float cogT;
	float cogT_cos;
	float cogT_sin;
	float sog;
}PCodeDataStruct, *PCodeDataStructPtr;

typedef struct PCodeStruct
{
	int PCodePortnum;
	char PCodePortName[32];
	int printData;	// use the same way of CTD:  0: status, 1: engineer format, 2: debug
	Boolean PCodeDone;
	int PCodePhase;
	int PCodeReqReadSize;
	SerialPortData SerialPort4PCode;
	int charsIn;		// keep track number of bytes for each packet
	char CommingStr[PCODE_MAXLEN];	// contents one valid packet
	char ParsingStr[PCODE_MAXLEN];	// contents data for parsing task
	int ParseIndx;
	PCodeDataStruct PCodeData;
}pcode_t, *pcode_ptr_t;

int	InitPCode(pcode_ptr_t);
Boolean PCode_AcquireData(pcode_ptr_t);
void *ReadPCodeDataFromPort(void *arg);
int SetOptionSerialPort4PCode(pcode_ptr_t);
void WritePCodeDataIntoBuffer(char *str, pcode_ptr_t PCodePtr);
int ParsingPCode(pcode_ptr_t);


#endif
