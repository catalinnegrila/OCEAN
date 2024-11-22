#include "pthread_utils.h"

// Globals for PThreadUtils
int threads_total = 0;
enum acq_state {start_som=0,find_sync=1, id_tag};
//static int LastFishIsDown = 0;
/*
** FUNCTION NAME: FastCTDCreateThreads(pthread_t* threadList, FastCTDStructPtr fctd)
** PURPOSE: Create all threads for CTD, PCode, Winch, write data into file, checking communication and stop application
** DATE: Mar 31, 2005
*/
void fctd_epsi_create_threads_f(pthread_t* pthreads_list, fctd_epsi_ptr_t fctd)
{
	int thnum = 0, terr=0;

	// Fish CTD
	if (fctd->ctd_flag&&!fctd->done) // need to change the name since it acquires SOM data: EFE, SBE, ALT, & VOL - mnbui 4 March 2021
	{
		printf("Acquire CTD data ...\n");
		terr = pthread_create(&pthreads_list[thnum],NULL,read_ctd_data_from_port_f,(void*)&(fctd->fish)); // name: ReadSOMdataFromPort - mnbui & alb - 4 March 2021
		thnum++;
	}
	// PCode
	if (fctd->pcode_flag&&!fctd->done)
	{
		printf("Acquire PCode data ...\n");
		terr = pthread_create(&pthreads_list[thnum],NULL,ReadPCodeDataFromPort,(void*)&(fctd->pcode));
		thnum++;
	}
	// Winch
	if (fctd->write_data_network_flag&&!fctd->done)
	{
		printf("Acquire Winch data ...\n");
		terr = pthread_create(&pthreads_list[thnum],NULL,tcp_ip_server_f,(void*)fctd);
		thnum++;
	}
	// Write data into a file
	terr = pthread_create(&pthreads_list[thnum],NULL,write_ctd_data_to_file_f,(void*)fctd);
	thnum++;
	// Checking for lost communication
	terr = pthread_create(&pthreads_list[thnum],NULL,check_if_data_is_blocked_f,(void*)fctd);
	thnum++;
	// Stop app from the user
	terr = pthread_create(&pthreads_list[thnum],NULL,stop_ftcd_epsi_f,(void*)fctd);
	thnum++;
	
	threads_total = thnum;
}

/*
** FUNCTION NAME: FastCTDJoinThreads(pthread_t threadList[])
** PURPOSE: Join all threads.
** DATE: Mar 31, 2005
*/
void fctd_epsi_join_threads_f(pthread_t threadList[])
{
	int thnum = 0, terr = 0;
	for (thnum = 0; thnum< threads_total; thnum++)
	{
		terr = pthread_join(threadList[thnum],NULL);    
		if (terr)
		{
			printf("ERROR! Join a thread #%d.\n", thnum);
			abort();
		}
	}
}

// copy from /usrs/include/mach/thread_policy.h since it's commented out in that file
kern_return_t   thread_policy_set(thread_act_t thread,thread_policy_flavor_t flavor, thread_policy_t policy_info, mach_msg_type_number_t count);

int set_realtime_f(int period, int computation, int constraint) {

    struct thread_time_constraint_policy ttcpolicy;
    int ret;

    ttcpolicy.period=period; // HZ/160
    ttcpolicy.computation=computation; // HZ/3300;
    ttcpolicy.constraint=constraint; // HZ/2200;
    ttcpolicy.preemptible=0;

    if ((ret=thread_policy_set(mach_thread_self(),
        THREAD_TIME_CONSTRAINT_POLICY, (int *)&ttcpolicy,
        THREAD_TIME_CONSTRAINT_POLICY_COUNT)) != KERN_SUCCESS) {
            fprintf(stderr, "set_realtime() failed.\n");
            return 0;
    }
    return 1;
}


/*
** FUNCTION NAME: StopFastCTD(void *arg)
** PURPOSE: Stop app when user type 's'
** DATE: Mar 31, 2005
*/
void *stop_ftcd_epsi_f(void *arg)
{
	char gc;
    static char som_cmd[MAX_DATA_LENGTH] = "\0";
    ssize_t    numBytes = 0;    // Number of bytes read or written
    uint32_t delay=0xFFFFFF;


	fctd_epsi_t *fCTDPtr = (fctd_epsi_ptr_t)arg;
	while(!fCTDPtr->done)
	{
		gc = getchar();

        //ALB adding a key to simply restart acquiring data without restart the fish.
        //ALB This is in case the TCPIP com with the Ipad (and/or Matlab time series is not updating)
        if (gc=='r')
        {
            if (strcmp(fCTDPtr->fish.CTDPortName,fCTDPtr->fish.CommandPortName)!=0){
                fprintf(stdout, "opening Command Port\r\n");
                InitSerialPort(&fCTDPtr->fish.SerialPort4Command, fCTDPtr->fish.CommandPortName);
                SetOptionSerialPort4FishCommand(&fCTDPtr->fish);
                if ((OpenSerialPort(&((fCTDPtr)->fish.SerialPort4Command)))!=0)    // != 0 -> failed
                    fprintf(stdout, "Cannot open Command Port before re-setting data acquisition\r\n");
                //ALB Delay to re-open the command port
                while (delay>0){
                    delay--;
                }
                delay=0xFFFFFF;
            }
            fCTDPtr->fish.CTDPhase = find_sync;
            read_ctd_data_from_port_f(fCTDPtr);

        }
        
		if (gc=='q' || gc=='s')
		{
            
            if (strcmp(fCTDPtr->fish.CTDPortName,fCTDPtr->fish.CommandPortName)!=0){
                fprintf(stdout, "opening Command Port\r\n");
                InitSerialPort(&fCTDPtr->fish.SerialPort4Command, fCTDPtr->fish.CommandPortName);
                SetOptionSerialPort4FishCommand(&fCTDPtr->fish);
                if ((OpenSerialPort(&((fCTDPtr)->fish.SerialPort4Command)))!=0)    // != 0 -> failed
                    fprintf(stdout, "Cannot open Command Port before quitting\r\n");
                //ALB Delay to re-open the command port
                while (delay>0){
                    delay--;
                }
                delay=0xFFFFFF;

            }

            
            fprintf(stdout, "som.stop\r\n");
            sprintf(som_cmd,"%s\r\n","som.stop");
            if (strcmp(fCTDPtr->fish.CTDPortName,fCTDPtr->fish.CommandPortName)!=0){
                numBytes = write(fCTDPtr->fish.SerialPort4Command.spd, som_cmd, strlen(som_cmd));
            }else{
                numBytes = write(fCTDPtr->fish.SerialPort4CTD.spd, som_cmd, strlen(som_cmd));
            }
            while (delay>0){
                delay--;
            }
            delay=0xFFFFFF;
            
            fprintf(stdout, "Quitting FastCTD DAQ.\n");

 
			fCTDPtr->done = TRUE;
			if(fCTDPtr->ctd_flag) {
                fCTDPtr->fish.Done = TRUE;
                if (strcmp(fCTDPtr->fish.CTDPortName,fCTDPtr->fish.CommandPortName)!=0){
                    
                    fprintf(stdout, "Closing Command port.\n");
                    RealeaseSPRead(&fCTDPtr->fish.SerialPort4Command);
                }
                fprintf(stdout, "Closing CTD port.\n");
                RealeaseSPRead(&fCTDPtr->fish.SerialPort4CTD);
            }
			if(fCTDPtr->pcode_flag){
                fCTDPtr->pcode.PCodeDone = TRUE;
                fprintf(stdout, "Closing pcode.\n");
                RealeaseSPRead(&fCTDPtr->pcode.SerialPort4PCode);
            }
			if(fCTDPtr->network.TCPIPSocket.fdTCPIP)
                fprintf(stdout, "Closing TCPIP socket.\n");
                close(fCTDPtr->network.TCPIPSocket.fdTCPIP);	// to terminate accept()
		}
	}
    
    pthread_exit(NULL);
}

/*
** FUNCTION NAME: TCPIPSocketServer(void *arg)
** PURPOSE: Waiting for client (Winch), when has connection acquire Winch data and send Fish CTD's data to Winch.
** DATE: Mar 31, 2005
*/
void *tcp_ip_server_f(void *arg)
{
	int result, val;
	struct sockaddr_in address;
	socklen_t addressLength = sizeof(address);
    float CTDpress = NAN, CTDcond = NAN;
    float CTDtemp = NAN, AltTime = NAN;
    unsigned long CTDtime =0;

	fctd_epsi_t *fCTDPtr = (fctd_epsi_ptr_t)arg;
    
	while(!fCTDPtr->done)
	{
		// waiting for Winch asking connection
		printf("Waiting for Winch's request to accept connection...\n");
		if(fCTDPtr->network.TCPIPSocket.fdTCPIP!=-1)
		{
			result = accept (fCTDPtr->network.TCPIPSocket.fdTCPIP, (struct sockaddr *)&address, &addressLength);
			if (result == -1) {
	            fprintf (stderr, "accept failed.  error: %d / %s\n",
                     errno, strerror(errno));
				// if stop program, it will not wait for another connection.
				if (fCTDPtr->done) {printf("TCPThread is terminated by user\n");break;}
				else continue;
			}
			if (result == EWOULDBLOCK)
			{	printf("break in WOULDBLOCK\n");
				break;
			}
			printf ("accepted connection from %s:%d\n",inet_ntoa(address.sin_addr), ntohs(address.sin_port));
            
			// copy socketfd into Winch structure for receiving data
			fCTDPtr->network.TCPIPSocket.remoteSocketfd = result;
		}
		// after making a pine connection to Winch, aquire data, average FishCTD's data and send to winch.
		while (!fCTDPtr->done)
		{
			// if get data from winch
//			if (!AcquireWinchDataTCPIP(&fCTDPtr->network)) break;
            // fish's data and send them to winch.
            AltTime = fCTDPtr->fish.LatestAltTime;
            val = CurrentFishData2(&(fCTDPtr->fish), &CTDtime, &CTDpress, &CTDtemp, &CTDcond,&AltTime);
            if(!val)
                break;
            if (!SendData2Winch(&fCTDPtr->network, CTDtime, CTDpress, CTDtemp, CTDcond,  AltTime))
            {
                break;
            }
		}
        // close the connection
		if(fCTDPtr->network.TCPIPSocket.remoteSocketfd>0){ close (fCTDPtr->network.TCPIPSocket.remoteSocketfd);
            fCTDPtr->network.TCPIPSocket.remoteSocketfd = -1;
        }
	}
    pthread_exit(NULL);
}
/*
** FUNCTION NAME: WriteCTDdataIntoFile(void *arg)
** PURPOSE: Write CTD data from circular buffer into data file
** DATE: Mar 31, 2005
*/
void *write_ctd_data_to_file_f(void *arg)
{
	int indx = 0;
	char PCodeDataStr[MAX_LENGTH] = "\0";
	char tmp_str[MAX_DATA_LENGTH] = "\0";
//	char WinchDataStr[MAX_LENGTH] = "\0";
	char timeChar = 'T';
    char time_str[32] = "\0";
	ssize_t numbytes = 0;
//    char * settingsstream_cmd = "settings.stream\r\n";

	fctd_epsi_t *fctd_ptr = (fctd_epsi_ptr_t)arg;

	while(!fctd_ptr->done)
	{
		// save the header info into file: only the first time run, next time is taken care by "WriteDataIntoFile()"
		if (!fctd_ptr->not_1st_time)
		{
			fctd_write_header_to_file(fctd_ptr,1);
			fctd_ptr->not_1st_time = TRUE;
		}
		// if CTD is installed: write the CTD's data into file
        // if having network, send data via UDP
		if (fctd_ptr->ctd_flag&&!fctd_ptr->fish.Done)
		{
			// get index in cir buffer
			indx = fctd_ptr->fish.SOM_ReadBufferIndx%MAX_CIRBUFF;
			if (fctd_ptr->fish.SOM_ReadBufferIndx < fctd_ptr->fish.SOM_Write2BufferIndx || (fctd_ptr->fish.SOM_ReadBufferIndx-fctd_ptr->fish.SOM_Write2BufferIndx > 0xfffffff0)) //detect wrap around
			{
				// write the data of the CTD into the file
				// contruct the string: T+timestamp+CTDData
                sprintf(time_str, "T%010lu",fctd_ptr->fish.som_cir_buff[indx].timeInHundredsecs);
                // write local time before write SBE data
                fctd_write_data_to_file(time_str,(uint32_t)strlen(time_str),fctd_ptr);
                fctd_write_data_to_file(fctd_ptr->fish.som_cir_buff[indx].data_str,fctd_ptr->fish.som_cir_buff[indx].data_length,fctd_ptr);
                bzero(fctd_ptr->fish.som_cir_buff[indx].data_str, MAX_DATA_LENGTH);
                fctd_ptr->fish.SOM_ReadBufferIndx++;
            }else if(fctd_ptr->fish.SOM_ReadBufferIndx>(fctd_ptr->fish.SOM_Write2BufferIndx)){
                fctd_ptr->fish.SOM_ReadBufferIndx = fctd_ptr->fish.SOM_Write2BufferIndx;
            }
            
            // get index in cir buffer for CTD data
            // San 2021 06 21
            indx = fctd_ptr->fish.CTD_ReadBufferIndx%MAX_CIRBUFF;
            if (fctd_ptr->fish.CTD_ReadBufferIndx != fctd_ptr->fish.CTD_Write2BufferIndx)
            {
                // if data is sending out to network by UDP broadcast
                if (fctd_ptr->write_data_network_flag){
                    float CTDpress = NAN, CTDcond = NAN;
                    float CTDtemp = NAN, AltTime = NAN;
                    unsigned long CTDtime =0;
                    indx = fctd_ptr->fish.CTD_ReadBufferIndx%MAX_CIRBUFF;
                    if(!fctd_ptr->fish.ctd_cir_buff[indx].in_use){
                        // TODO mnbui 21Mar21: add altimeter, .. send out
                        // read alt from alt's packet
                        AltTime = fctd_ptr->fish.LatestAltTime;
                        CTDtime = fctd_ptr->fish.LatestCTDTime;
                        CTDpress = fctd_ptr->fish.LatestCTDPress;
                        CTDtemp = fctd_ptr->fish.LatestCTDTemp;
                        CTDcond = fctd_ptr->fish.LatestCTDCond;
//                        CurrentFishData(&(fctd_ptr->fish), &CTDtime, &CTDpress, &CTDtemp, &CTDcond,&AltTime); // old version has altimeter embeded in CTD's string
                        
                        sprintf(tmp_str, "%lu,%f,%f,%f,%f",CTDtime,CTDpress,CTDtemp,CTDcond,AltTime);
                        if((numbytes = u_sendto(fctd_ptr->udp_socket.udpfd,tmp_str,strlen(tmp_str),&fctd_ptr->udp_socket.sockaddInfo))==-1)
                            printf("Can not send CTD out via UDP network\n");
                    }
                }
                
                fctd_ptr->fish.CTD_ReadBufferIndx++;
            }
        }else if(fctd_ptr->fish.CTD_ReadBufferIndx>(fctd_ptr->fish.CTD_Write2BufferIndx+1)){
            fctd_ptr->fish.CTD_ReadBufferIndx = fctd_ptr->fish.CTD_Write2BufferIndx;
        }
        /*// TODO: save $EFE $VOL & $ALT , $NAV into the file
        if(fctd_ptr->efe_flag)
        {
            if (fctd_ptr->ctd.SOM_ReadBufferIndx < fctd_ptr->ctd.SOM_Write2BufferIndx)
            {
                indx = fctd_ptr->ctd.SOM_ReadBufferIndx%MAX_CIRBUFF;
                // contruct the string: T+timestamp+EfeData
                sprintf(fctd_data_str,"%c%010lu",timeChar, fctd_ptr->ctd.som_cir_buff[indx].timeInHundredsecs);
                memcpy(fctd_data_str+11,fctd_ptr->ctd.som_cir_buff[indx].DataStr,         fctd_ptr->ctd.Efelength);

                fctd_write_data_to_file(fctd_data_str, fctd_ptr);
                fctd_ptr->ctd.SOM_ReadBufferIndx++;
            }
        }
        if(fctd_ptr->alti_flag)
        {
            if (fctd_ptr->ctd.AltReadBufferIndx < fctd_ptr->ctd.AltWrite2BufferIndx)
            {
                indx = fctd_ptr->ctd.AltReadBufferIndx%MAX_CIRBUFF;
                // contruct the string: T+timestamp+altiData
                sprintf(fctd_data_str,"%c%010lu%s",timeChar, fctd_ptr->ctd.AltCirBuff[indx].timeInHundredsecs, fctd_ptr->ctd.AltCirBuff[indx].DataStr);
                 fctd_write_data_to_file(fctd_data_str, fctd_ptr);
                fctd_ptr->ctd.AltReadBufferIndx++;
            }
        }
        if(fctd_ptr->volt_flag)
        {
            if (fctd_ptr->ctd.VoltReadBufferIndx < fctd_ptr->ctd.VoltWrite2BufferIndx)
            {
                indx = fctd_ptr->ctd.VoltReadBufferIndx%MAX_CIRBUFF;
                // contruct the string: T+timestamp+voltData
                sprintf(fctd_data_str,"%c%010lu%s",timeChar, fctd_ptr->ctd.VoltCirBuff[indx].timeInHundredsecs, fctd_ptr->ctd.VoltCirBuff[indx].DataStr);
                fctd_write_data_to_file(fctd_data_str, fctd_ptr);
                fctd_ptr->ctd.VoltReadBufferIndx++;
            }
        }
        if(fctd_ptr->vnav_flag)
        {
            if (fctd_ptr->ctd.VnavReadBufferIndx < fctd_ptr->ctd.VnavWrite2BufferIndx)
            {
                indx = fctd_ptr->ctd.VnavReadBufferIndx%MAX_CIRBUFF;
                // contruct the string: T+timestamp+voltData
                sprintf(fctd_data_str,"%c%010lu%s",timeChar, fctd_ptr->ctd.VnavCirBuff[indx].timeInHundredsecs, fctd_ptr->ctd.VnavCirBuff[indx].DataStr);
                fctd_write_data_to_file(fctd_data_str, fctd_ptr);
                fctd_ptr->ctd.VnavReadBufferIndx++;
            }
        }
         */
		// if PCode is installed: write the PCode's data into file
		if (fctd_ptr->pcode_flag&&!fctd_ptr->pcode.PCodeDone)
		{
			if (fctd_ptr->pcode.SerialPort4PCode.ReadBufferIndx < fctd_ptr->pcode.SerialPort4PCode.Write2BufferIndx)
			{
				indx = fctd_ptr->pcode.SerialPort4PCode.ReadBufferIndx%MAX_CIRBUFF;
				// contruct the string: T+timestamp+PcodeData
				sprintf(PCodeDataStr,"%c%010lu%s",timeChar,
							fctd_ptr->pcode.SerialPort4PCode.SerialDataCirBuff[indx].timeInHundredsecs,
							fctd_ptr->pcode.SerialPort4PCode.SerialDataCirBuff[indx].DataStr);
				fctd_write_data_to_file(PCodeDataStr, (uint32_t)strlen(PCodeDataStr),fctd_ptr);
				// if data is sending out via serialport
				if (fctd_ptr->wr_data_serial_port_flag)
					if((fctd_ptr->totalByteSending+=WriteData(fctd_ptr->serial_port_4_data_out.spd, PCodeDataStr))==0)
						printf("Can not send PCode to the serial port\n");
//                // if data is sending out to network by UDP broadcast
//                if (fCTDPtr->WriteData2NetworkFlag)
//                    if((numbytes = u_sendto(fCTDPtr->UDPSocket.udpfd,PCodeDataStr,strlen(PCodeDataStr),&fCTDPtr->UDPSocket.sockaddInfo))==-1)
//                        printf("Can not send CTD out via network\n");
				fctd_ptr->pcode.SerialPort4PCode.ReadBufferIndx++;
			}
		}
        /*
		// if Winch is installed: write the Winch's data into file
		if (fCTDPtr->network_flag&&!fCTDPtr->network.WinchDone)
		{
			if (fCTDPtr->network.ReadBufferIndx < fCTDPtr->network.Write2BufferIndx)
			{
				indx = fCTDPtr->network.ReadBufferIndx%MAX_CIRBUFF;

				// If the new drop is base on the Winch, write the status of the CTD into the file
				if (fCTDPtr->dropnumBaseonWinch==1)
				{
					// get the Fish's status and write to the file
					if(fCTDPtr->network.WinchCirBuff[indx].FishChangesCourse)
					{
						if (fCTDPtr->network.WinchCirBuff[indx].FishStatus==2)	// start to go down for the new drop
						{
							sprintf(WinchDataStr,"%c%010lu$MODFDN\r\n",timeChar, fCTDPtr->network.WinchCirBuff[indx].timeInHundredsecs);
						}
						else if (fCTDPtr->network.WinchCirBuff[indx].FishStatus==3)	// start to go up
						{
							sprintf(WinchDataStr,"%c%010lu$MODFUP\r\n",timeChar, fCTDPtr->network.WinchCirBuff[indx].timeInHundredsecs);
						}
						fctd_write_data_to_file(WinchDataStr, fCTDPtr);
					}
				}

				// write Winch's data into the file
				// contruct the string: T+timestamp+WinchData
				sprintf(WinchDataStr,"%c%010lu%s\n",timeChar,
								fCTDPtr->network.WinchCirBuff[indx].timeInHundredsecs,
								fCTDPtr->network.WinchCirBuff[indx].DataStr);
				if(fctd_write_data_to_file(WinchDataStr, fCTDPtr)!=0)
					fCTDPtr->network.lastDropNum = fCTDPtr->network.dropNum;

				// if data is sending out via serialport
				if (fCTDPtr->wr_data_serial_port_flag)
					if((fCTDPtr->totalByteSending+=WriteData(fCTDPtr->serial_port_4_data_out.spd, WinchDataStr))==0)
						printf("Can not send Winch to the serial port\n");
				// if data is sending out to network by UDP broadcast
//                if (fCTDPtr->WriteData2NetworkFlag)
//                    if((numbytes = u_sendto(fCTDPtr->UDPSocket.udpfd,WinchDataStr,strlen(WinchDataStr),&fCTDPtr->UDPSocket.sockaddInfo))==-1)
//                        printf("Can not send CTD out via network\n");
				fCTDPtr->network.ReadBufferIndx++;
			}
		}
        */
	}
	
    pthread_exit(NULL);
}

/*
** FUNCTION NAME: CheckDataIsBlocked(void *arg)
** PURPOSE: Checking lost communication with sensors
** DESCRIPTION:
** Checking the read (thread #1) is blocked
** by checking the last count every second:
** every  time the thread call get:    time -> to have ¶t = currtime - lasttime
**							number package -> have ¶Cnt = currCnt - lastCnt
** if the number package less than the expect number package -> send warning with total number lost package. 
**         ¶Cnt < ¶t*freq - 1
** the other words: (¶Cnt +1) * T < ¶t  (numberofPackage between 2 call * time/package < time between 2 call)
** --> comming data is stop.
** DATE: Mar 31, 2005
*/
//#define FCTD_FREQ	16
#define FCTD_FREQ    1  // march 10, 2021
#define PCODE_FREQ	1
#define WINCH_FREQ	1   // 1: for status, 1/240: for UP & DN
void *check_if_data_is_blocked_f(void *arg)
{
	struct timeval timev, *timevPtr;
	struct timezone timez, *timezPtr;
	timevPtr = &timev;
	timezPtr = &timez;
	static long CTDlastTimeInSec = 0;
	long CTDcurrTimeInSec = 0, CTDlastPacketCnt = 0, CTDcurrPacketCnt = 0, CTDtotalPackLost = 0;
	static long PCodelastTimeInSec = 0;
	long PCodecurrTimeInSec = 0, PCodelastPacketCnt = 0, PCodecurrPacketCnt = 0, PCodetotalPackLost = 0;
	long deltaTime, deltaCnt;

	fctd_epsi_t *fCTDPtr = (fctd_epsi_ptr_t)arg;
	
	while(!fCTDPtr->done)
	{
		sleep(1);
		if (fCTDPtr->ctd_flag&&!fCTDPtr->fish.Done)
		{
			// Get the current time
			gettimeofday(timevPtr, timezPtr);
			CTDcurrTimeInSec = timevPtr->tv_sec;
			// Initialize at the first call
			if (CTDlastTimeInSec==0)
			{
				CTDlastPacketCnt = fCTDPtr->fish.ctd_PackCnt;
				CTDlastTimeInSec = CTDcurrTimeInSec;
			}
			// Get the current number of package data
			CTDcurrPacketCnt = fCTDPtr->fish.ctd_PackCnt;
			// calculate ¶t and ¶Cnt
			deltaTime = CTDcurrTimeInSec - CTDlastTimeInSec;
			deltaCnt = CTDcurrPacketCnt - CTDlastPacketCnt;
			if (deltaCnt + 1 < (deltaTime*FCTD_FREQ))
			{
				CTDtotalPackLost += deltaTime*FCTD_FREQ-deltaCnt;
				printf("WARNING!!! Missing %ld string CTD data\n",CTDtotalPackLost);
			}
			else
				CTDtotalPackLost = 0;
			CTDlastPacketCnt = CTDcurrPacketCnt;
			CTDlastTimeInSec = CTDcurrTimeInSec;
		}
		if (fCTDPtr->pcode_flag&&!fCTDPtr->pcode.PCodeDone)
		{
			gettimeofday(timevPtr, timezPtr);
			PCodecurrTimeInSec = timevPtr->tv_sec;
			if (PCodelastTimeInSec==0)
			{
				PCodelastPacketCnt = fCTDPtr->pcode.SerialPort4PCode.PackCnt;
				PCodelastTimeInSec = PCodecurrTimeInSec;
			}
			PCodecurrPacketCnt = fCTDPtr->pcode.SerialPort4PCode.PackCnt;
			deltaTime = PCodecurrTimeInSec - PCodelastTimeInSec;
			deltaCnt = PCodecurrPacketCnt - PCodelastPacketCnt;

			if (deltaCnt +1 <= deltaTime*PCODE_FREQ)
			{ 
				PCodetotalPackLost += deltaTime*PCODE_FREQ-deltaCnt;
				printf("WARNING!!! Missing %ld strings PCode data\n",PCodetotalPackLost);
			}
			else
				PCodetotalPackLost = 0;
			PCodelastPacketCnt = PCodecurrPacketCnt;
			PCodelastTimeInSec = PCodecurrTimeInSec;
		}
	}
	
    pthread_exit(NULL);
}


