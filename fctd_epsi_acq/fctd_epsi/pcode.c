#include "pcode.h"
#include "globals.h"
#define PCODE_MAXLEN 100
#define PCODE_ONESTRLEN 75

int	InitPCode(pcode_ptr_t PCodePtr)
{
	PCodePtr->PCodePhase = 1;
	PCodePtr->PCodeDone = FALSE;
	PCodePtr->PCodeReqReadSize = 1;
	PCodePtr->SerialPort4PCode.reqReadSize = 1;
	return 1;
}
void *ReadPCodeDataFromPort(void *arg)
{
	pcode_t *PCodePtr=NULL;

	PCodePtr = (pcode_t*)arg;
		
	while(!PCodePtr->PCodeDone){
		if(PCode_AcquireData(PCodePtr)==0)
			continue;
		// copy data into circle buffer when we get the whole PCode packet
		if(PCodePtr->SerialPort4PCode.doneRead)
		{
			ParsingPCode(PCodePtr);
		}
	}
	printf("End of ReadPCodefromPort() in Pthread.c\n");

	return NULL;
}
// Not use this function any more, write data into circular buffer when we get a valid string in aquire routine
void WritePCodeDataIntoBuffer(char *str, pcode_ptr_t PCodePtr)
{
	int indx;
	char timeStr[25];
	struct timeval timev, *timevPtr;
	struct timezone timez, *timezPtr;
	char ctime = 'T';
	timevPtr = &timev;
	timezPtr = &timez;
	
	gettimeofday(timevPtr, timezPtr);
	itoa((int)timevPtr->tv_sec,timeStr);
	
	// find the current index
	indx = PCodePtr->SerialPort4PCode.Write2BufferIndx%MAX_CIRBUFF;
	snprintf(PCodePtr->SerialPort4PCode.SerialDataCirBuff[indx].DataStr,
		sizeof(PCodePtr->SerialPort4PCode.SerialDataCirBuff[indx].DataStr),
		"%c%s%s",ctime,timeStr,str);
	PCodePtr->SerialPort4PCode.Write2BufferIndx++;
	PCodePtr->SerialPort4PCode.SerialDataCirBuff[indx].ParseDone = FALSE;
}

//$GPGGA,030542.761,3506.1963,N,12902.3561,E,3,08,0.9,034.8,M,-025.4,M,,*4A\r\n	= 75
//       time       lat         lon
//$GPVTG,281.4,T,288.3   ,M,000.0       ,N,000.0,K*40\r\n					    = 43
//       cogT    magnetic   speed(knots)   sog
//$GPZDA,030544.00,14,01,2000,00,00,*4A\r\n										= 39
enum PCodeType{GPGGAstr,GPVTGstr,GPZDAstr};
int ParsingPCode(pcode_ptr_t PCodePtr)
{
	char *dataSep = ",";
	char *brkd;
	char *pcodeData;
	char tempStr[PCODE_MAXLEN] = "\0";
	int i=0, j,k;
	enum PCodeType pcodestr = GPVTGstr;
	float mlat, lat = 0, mlon, lon = 0;
	int dlat, dlon;
	float temp = 0.0;
	int indx;
	
	indx = PCodePtr->ParseIndx % MAX_CIRBUFF;
    if ((!PCodePtr->SerialPort4PCode.SerialDataCirBuff[indx].ParseDone) && (PCodePtr->ParseIndx < PCodePtr->SerialPort4PCode.Write2BufferIndx))
	{
		PCodePtr->SerialPort4PCode.SerialDataCirBuff[indx].ParseDone = TRUE;
		strcpy(PCodePtr->ParsingStr,PCodePtr->SerialPort4PCode.SerialDataCirBuff[indx].DataStr);
		PCodePtr->ParseIndx++;
		for (pcodeData = strtok_r(PCodePtr->ParsingStr, dataSep, &brkd); pcodeData;pcodeData=strtok_r(NULL,dataSep,&brkd))
		{
			if (i==0)
			{
				if (!strcmp(pcodeData,"$GPGGA"))
				{
						pcodestr = GPGGAstr;
//                        printf("%s",PCodePtr->SerialPort4PCode.SerialDataCirBuff[indx].DataStr);
				}
                if (!strcmp(pcodeData,"$INGGA"))
                {
                        pcodestr = GPGGAstr;
//                        printf("%s",PCodePtr->SerialPort4PCode.SerialDataCirBuff[indx].DataStr);
                }
				if (!strcmp(pcodeData,"$GPVTG"))
				{
                    pcodestr = GPVTGstr;
//                    printf("%s",PCodePtr->SerialPort4PCode.SerialDataCirBuff[indx].DataStr);
				}
                if (!strcmp(pcodeData,"$INVTG"))
                {
                    pcodestr = GPVTGstr;
//                    printf("%s",PCodePtr->SerialPort4PCode.SerialDataCirBuff[indx].DataStr);
                }
                if (!strcmp(pcodeData,"$GPZDA")){
						pcodestr = GPZDAstr;
                }
                if (!strcmp(pcodeData,"$INZDA")){
                        pcodestr = GPZDAstr;
                }
                
				i++;
				continue;	
			}
			if (pcodestr==GPGGAstr)
			{
				switch(i)
				{
					case 1:	// time
						PCodePtr->PCodeData.time = atof(pcodeData);
						i++;
					break;
				// the format of PCode:
				// 	 the first two digits is degrees and the rest is minutes
				// ex: lat: ,3242.395,N, => degrees = 32, minutes = 42.395
				//	   lon: ,11714.1730,W,=> degrees = 117, minutes = 14.173
					case 2:	//lat
						for (j=0;j<2;j++)
							tempStr[j] = pcodeData[j];
						dlat = atoi(tempStr);
						for (j=2,k=0;j<strlen(pcodeData);j++,k++)
							tempStr[k] = pcodeData[j];
						tempStr[k] = '\0';
						mlat = atof(tempStr);
						lat = dlat + (mlat/60);
						i++;
					break;
					case 3:	//lat direction
						if (pcodeData[0] == 'S')
							lat *= -1;
						PCodePtr->PCodeData.lat = lat;
						i++;
					break;
					case 4:	//lon
						for (j=0;j<2;j++)
							tempStr[j] = pcodeData[j];
						dlon = atoi(tempStr);
						for (j=2,k=0;j<strlen(pcodeData);j++,k++)
							tempStr[k] = pcodeData[j];
						tempStr[k] = '\0';
						mlon = atof(tempStr);
						lon = dlon + (mlon/60);
						i++;
					break;
					case 5:	//lon direction
						if (pcodeData[0] == 'E')
							lon *= -1;
						PCodePtr->PCodeData.lon = lon;
						i++;
					break;
					case 6:
						PCodePtr->PCodeData.flag = (long)(pcodeData - 0x30);
						i++;
					break;
				}
				if (i==7) break;	// ignore the rest
			}
	//$GPVTG,281.4,T,288.3   ,M,000.0       ,N,000.0,K*40\r\n					    = 43
	//       cogT    magnetic   speed(knots)   sog
			if (pcodestr==GPVTGstr)
			{
				switch(i)
				{
					case 1:	// cogT
						PCodePtr->PCodeData.cogT = atof(pcodeData);
						temp = PCodePtr->PCodeData.cogT/180.0*pi;
						PCodePtr->PCodeData.cogT_cos = cos(temp);
						PCodePtr->PCodeData.cogT_sin = sin(temp);
						i += 6;	// skip T, magnetic, M, speed, N
					break;
					case 7: // sog
						PCodePtr->PCodeData.sog = atof(pcodeData)*100000.0/3600.0;
						i++;
					break;
				}
				if (i>7) break;
			}
			if (pcodestr==GPZDAstr)	// not use this data for now.
			{
	//				printf("GPZDA Data = %s\n",pcodeData);
			}
		}
	}
    return 0;
}

int SetOptionSerialPort4PCode(pcode_ptr_t PCodePtr)
{
	cfsetspeed(&PCodePtr->SerialPort4PCode.spOptions, PCodePtr->SerialPort4PCode.speed);	// use GG24 replace PCode - MNB 7/27/06
    return 0;
}

// This routine get one byte at a time
Boolean PCode_AcquireData(pcode_ptr_t PCodePtr)
{
	ssize_t numBytes = 0;	// Number of bytes read or written
	int indx;
	struct timeval *timevPtr;
	struct timezone timez, *timezPtr;
	char*	buffPtr;	// Current char in buffer
	char	tstr[1024] = "\0";    
	int		local = 1;
	char	timeStr[125] = "\0";

	buffPtr = tstr;
	PCodePtr->SerialPort4PCode.reqReadSize = 1;
	switch (PCodePtr->PCodePhase)
	{
		case 1:	//looking for a $ sign
			// read one by one byte
			numBytes = read(PCodePtr->SerialPort4PCode.spd, buffPtr, PCodePtr->SerialPort4PCode.reqReadSize);
			PCodePtr->SerialPort4PCode.doneRead = 0;
			if (numBytes == -1)
			{
				printf("Error reading from serial port of PCode at phase 0 - %s(%d).\n",
					strerror(errno), errno);
				return false;
			}
			if (numBytes>0) // get some thing
			{				
				if (*buffPtr == '$')	// find a sync -> save this char and go to case 1 to get the next char
				{
					PCodePtr->charsIn = 0;
					PCodePtr->PCodePhase = 2;
					// save this char in PCode string
					PCodePtr->CommingStr[PCodePtr->charsIn] = *buffPtr;
					PCodePtr->charsIn++;
				}
			}

		break;
		case 2: // read the next bytes after $ sign until get the line feed
			numBytes = read(PCodePtr->SerialPort4PCode.spd, buffPtr, PCodePtr->SerialPort4PCode.reqReadSize);
			if (numBytes == -1)
			{
				printf("Error reading from serial port of PCode at phase 1 - %s(%d).\n",
					strerror(errno), errno);
				return false;
			}
			if (numBytes > 0)
			{
				// put this char into PCode string
				PCodePtr->CommingStr[PCodePtr->charsIn] = *buffPtr;
				PCodePtr->charsIn++;
				// set VMIN to 1byte for serial port
				if(PCodePtr->charsIn >= PCODE_MAXLEN)
				{
					PCodePtr->charsIn = 0;
					PCodePtr->PCodePhase = 1;
					PCodePtr->SerialPort4PCode.doneRead = 0;
				}
				else
				{
					// if get the whole packet (the end with the linefeed, store it in cirbuff
					if (*buffPtr == 0xa)	// if get a linefeed (0xa)
					{
						PCodePtr->CommingStr[PCodePtr->charsIn-1] = '\n';	// terminate PCode string
						PCodePtr->CommingStr[PCodePtr->charsIn] = '\0';	// JMK 16 Apr 05: terminate PCode string with CR/LF
						// Write data into the circular buffer
						indx = PCodePtr->SerialPort4PCode.Write2BufferIndx%MAX_CIRBUFF;
						strncpy(PCodePtr->SerialPort4PCode.SerialDataCirBuff[indx].DataStr,PCodePtr->CommingStr,PCodePtr->charsIn);

                        // Get the current time, get offset time and calculate the number of seconds since Jan 1, 2005 to now and save it.
						timevPtr = &PCodePtr->SerialPort4PCode.SerialDataCirBuff[indx].UnixTime;
						timezPtr = &timez;
						gettimeofday(timevPtr, timezPtr);
						
						PCodePtr->SerialPort4PCode.SerialDataCirBuff[indx].timeInHundredsecs = Get_Time_In_Hundred_Secs(timeStr, local);

						// Increase the write count
						PCodePtr->SerialPort4PCode.Write2BufferIndx++;
						PCodePtr->SerialPort4PCode.SerialDataCirBuff[indx].ParseDone = FALSE;
						PCodePtr->SerialPort4PCode.PackCnt ++; // increase the package PCode count

						PCodePtr->charsIn = 0;
						PCodePtr->PCodePhase = 1;
						PCodePtr->SerialPort4PCode.doneRead = 1;
					}
				}
			}
		break;
	}
	return TRUE;
}

