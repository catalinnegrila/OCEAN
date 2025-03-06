#ifndef SERIALPORTUTILS_H
#define SERIALPORTUTILS_H

#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <sysexits.h>
#include <CoreFoundation/CoreFoundation.h>
//#include <IOKit/IOKitLib.h>
//#include <IOKit/serial/IOSerialKeys.h>

#include <stdio.h>
#include <sys/time.h>
#include <pthread.h>
#include <string.h>
#include <errno.h>
#include <paths.h>
#include <sys/param.h>
//#include <IOKit/IOBSD.h>
#include <mach/mach_init.h>
#include <mach/thread_policy.h>
#include <err.h>


#include "globals.h"
#define TOTAL_KEYSPANBOX 2
#define TOTAL_SERIALPORT TOTAL_KEYSPANBOX*4

/* define in Unix library
     struct timeval {
             long    tv_sec;         // seconds since Jan. 1, 1970
             long    tv_usec;        // and microseconds
     };
*/
typedef struct SerialDataStruct
{
	struct timeval UnixTime;		// since Jan 1, 1970
	unsigned long timeInHundredsecs;	// since Jan 1, current year
	char DataStr[MAX_LENGTH];
	Boolean ParseDone;	
}SerialDataStruct, *SerialDataStructPtr;
typedef struct SerialPortStruct
{
	char serialPortName[255];
	int spd;
	int reqReadSize;
	ssize_t totalBytesSPread;
	SerialDataStruct SerialDataCirBuff[MAX_CIRBUFF];
	int doneRead;
	unsigned long PackCnt;		// Read counter from serial port
	unsigned long Write2BufferIndx;		// CTD packet count is written into the circle buffer
	unsigned long ReadBufferIndx;			// CTD packet count is read from the circle buffer
	struct termios spOptions;
	struct termios gOriginalTTYAttrs;   // Hold the original termios attributes so we can reset them
	int portnum;
	speed_t speed;
}SerialPortData, *SerialPortDataPtr;

void CloseSerialPort(SerialPortDataPtr);
void InitSerialPort(SerialPortDataPtr, char*);
void InitSerialPort4Writting(SerialPortDataPtr serport, char* spName);
int OpenSerialPort(SerialPortDataPtr);
Boolean RealeaseSPRead(SerialPortDataPtr);
void SetOptionsSerialPort(SerialPortDataPtr);
ssize_t WriteData(int fd, char* tempString);

#endif
