/*
 *  Winch.h
 *  FastCTD
 *
 *  Created by Mai Bui on 1/19/05.
 *  Copyright 2005 __MyCompanyName__. All rights reserved.
 *
 */
#ifndef NETWORK_H
#define NETWORK_H
#include <CoreFoundation/CoreFoundation.h>

#include "serial_port_utils.h"
#include "tcpip_utils.h"
#include "utilities.h"

//#define WINCH_MAXLEN 100



typedef struct
{
//	Boolean WinchDone;
//	int WinchPhase;
//	int WinchReqReadSize;
	int printData;	// use the same way of CTD:  0: status, 1: engineer format, 2: debug
	Boolean TCPIPdone;
	TCPSocketStruct TCPIPSocket;
//	unsigned long PackCnt;
//	int haveNewData;
//	Boolean getStatusFish;
}network_t, *network_ptr_t;

//Boolean AcquireWinchDataTCPIP(network_ptr_t WinchPtr);
//int	InitWinch(network_ptr_t);
//int ParsingWinch(network_ptr_t);
//void *ReadWinchControl(void *arg);
Boolean SendData2Winch(network_ptr_t WinchPtr, unsigned long CTDtime, float CTDpress,float CTDtemp, float CTDcond, float AltTime);

#endif
