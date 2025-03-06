//
//  main.m
//  FastCTD
//  May 4th, 2004: Put the code from "FASTCATCTD" written by ANSI-C

//  Created by Mai Bui on Mon May 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

//#import <Cocoa/Cocoa.h>
#include "globals.h"
#include "file_utils.h"
#include "serial_port_utils.h"
#include "FastCat_CTDdaq.h"
#include "PThreadUtils.h"
#include <time.h>


// Allocate main Fast CTD structure
int	InitApp(FastCTDStructPtr *FCTDPtr, char SPList[][MAXNAMELEN])
{
	FastCTDStructPtr newCTDPtr = NULL;
	char temp[4][MAXNAMELEN] = {"\0"};
	
	// Allocate for CTD Structure
	newCTDPtr = (FastCTDStruct*)malloc(sizeof(FastCTDStruct));
	if (newCTDPtr == NULL)
		return 0;
	*FCTDPtr = newCTDPtr;
	memcpy(SPList,temp,sizeof(temp));
	
	// Initialize CTD's data structure
	FastCTDInit(*FCTDPtr);

	// Get all coefficiences from configure file over write defaults set above for CTD's data structure
	GetCoef_fromFile(*FCTDPtr);

	// Create data file and setup file
	CreateNewFile(&((*FCTDPtr)->fpData[0]));

	// find and open serial ports
	// ****** Start for Find_OpenSerialPort(...)
		FindSerialPortName(SPList);
		MakeSerialPortList(SPList);

		// Initialize Serial Ports
		InitSerialPort(&((*FCTDPtr)->SerialPort[0]), SPList[0]);
		
		// Now open the serial port we want, if that serial was open, close it and open it again.
	//	if ((*FCTDPtr)->SerialPort[0].spd!=0) CloseSerialPort((*FCTDPtr)->SerialPort[0]);	// close port 1
		if ((OpenSerialPort(&((*FCTDPtr)->SerialPort[0])))!=0)	// != 0 -> failed
			return EX_IOERR;

	//*****	Find_OpenSerialPort(SPList, &((*FCTDPtr)->SerialPort[0]));

	return 1;
}

void	ReleaseAllMemory(FastCTDStructPtr *FastCTDPtr)
{
	// Close all files
	CloseCurrFile(&(*FastCTDPtr)->fpData[0]);

	// close all serial ports
    CloseSerialPort((*FastCTDPtr)->SerialPort[0]);
    printf("All serial ports closed.\n");

	// free memory for FastCTDPtr
	if(*FastCTDPtr){ free(*FastCTDPtr); *FastCTDPtr = NULL;}
}

void RunApp(FastCTDStructPtr FastCTDPtr, pthread_t ThList[])
{
	// THREADS TASKS:  HAPPEN HERE ... *************************
	// Start background tasks that doo all the realtime work. 
	// i.e. 1) read serial port data, 2) write data, and 3)thread timeout control (three threads)
	FastCTDPtr->Done = false;
	
	// Create all threads for CTD
	FastCTDCreateThreads(ThList, FastCTDPtr);
	
	sleep(15);  // acquire data for 15 secs, for now
}

void StopApp(FastCTDStructPtr *FastCTDPtr, pthread_t ThList[])
{
	(*FastCTDPtr)->Done = true;
	
	// Handle read() is locked
	RealeaseSPRead(&(*FastCTDPtr)->SerialPort[0]);

	// Close all threads
	FastCTDJoinThreads(ThList);
}



int main(int argc, const char *argv[])
{
	pthread_t threadList[NUM_THREADS];
	FastCTDStructPtr FastCTDPtr = NULL;
	char SerialPortListName[4][MAXNAMELEN] = {"\0"};

	

	// INITIALIZATION *************************************
	if (InitApp(&FastCTDPtr, SerialPortListName)==0)
		return 1;

	RunApp(FastCTDPtr, threadList);

	StopApp(&FastCTDPtr, threadList);

	// CLEANING ********************************* ... need to clean all threads
	// ****** start for ReleaseAllMemory(...)
		CloseCurrFile(&(FastCTDPtr->fpData[0]));

		// close all serial ports
		if(FastCTDPtr->SerialPort[0].spd)
		{
			//еееее start for CloseSerialPort(...)
			if (tcsetattr(FastCTDPtr->SerialPort[0].spd, TCSANOW, &(FastCTDPtr->SerialPort[0]).gOriginalTTYAttrs) == -1)
			{
				printf("Error resetting tty attributes - %s(%d).\n",
					strerror(errno), errno);
			}

			close(FastCTDPtr->SerialPort[0].spd);
			FastCTDPtr->SerialPort[0].spd = 0;
		}
			//еееее		CloseSerialPort((SerialPortData)FastCTDPtr->SerialPort[0]);
		printf("All serial ports closed.\n");

		// free memory for FastCTDPtr
		if(FastCTDPtr){ free(FastCTDPtr); FastCTDPtr = NULL;}

	//*****	ReleaseAllMemory(&FastCTDPtr);
	return 0;

//    return NSApplicationMain(argc, argv);
}
