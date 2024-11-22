//
//  main.m
//  FastCTD
//  May 4th, 2004: Put the code from "FASTCATCTD" written by ANSI-C
//  12/1/04: make the app can quit when the user press key 's'
//  Created by Mai Bui on Mon May 03 2004.
//  Copyright (c) 2004 __MPL-SIO-UCSD__. All rights reserved.
//  Revise: Compile with Xcode 11.6 - 2 March 2021
//

//#include <Cocoa/Cocoa.h>
#include <stdio.h>
#include <unistd.h>
#include "globals.h"
#include "file_utils.h"
#include "serial_port_utils.h"
#include "fctd_epsi.h"
#include "pthread_utils.h"
#include "ctd.h"
#include "pcode.h"
#include "network.h"
#include "udp_utils.h"
#include "tcpip_utils.h"
#include <sys/time.h>
/* try to have warning if have a style development -> not work
#ifdef MYAPP_DEVELSTYLE
warning "Danger, Mai!"
#endif
*/

int OpenSerialPort4AllSensors(fctd_epsi_ptr_t FCTDPtr);

/*
** FUNCTION NAME: Usage()
** PURPOSE: a quick guide how to use app
** DATE: Mar 31, 2005
*/
void Usage( void);
void Usage( void)
{
	printf("Usage: fastCTD CTD 21 Pcode 22 Winch 23 f 8 d /Usr/CTDdataDirectory s 24 tcpPort 2342 statFishInW 1\n");
	printf("\t21: for keyspan box #2, port #1\n\tSize of data file = 8KB (default = 12KB)\n");
	printf("Note: all options for app are set in 'Setup' file");
}
/*
** FUNCTION NAME: CheckInput()
** PURPOSE: get options of user from the command line, overwrite options in "Setup" file
** DATE: Mar 31, 2005
*/
int CheckInput(int argc, const char* argv[], fctd_epsi_ptr_t fctd)
{
	int i;
	int portnum = 0, baudrate;
    int portnum_mod = 0;    // use the temporary var for calculate the mod - mnbui 3 Mar 2021

	// Check the number of the argument, get the value of the serial port number to send data out.
	switch(argc)
	{
/*		case 1:
			printf("You need to input sensor's name following by its serial port number\n");
			Usage();
			return 0;
		break;
*/
		case 2:
		case 4:
		case 6:
		case 8:
		case 10:
		case 12:
		case 14:
		case 16:
		case 18:
			printf("INCOMPLETED INPUT!!!: Sensor's name following by its serial port number\n");
			printf(" or: Size file is not correct\n or: destfile is not exist\n or miss port# for write data out.\n");
			Usage();
			return 0;
		break;
		case 3:
		case 5:
		case 7:
		case 9:
		case 11:
		case 13:
		case 15:
		case 17:
		case 19:
		    for (i=1; i<argc; i++)
			{
				// CTD
				if (!strcmp(argv[i],"CTD"))
				{
					fctd->ctd_flag = true;
					portnum = atoi(argv[i+1]);
                    portnum_mod = portnum % 10;
					if((1<= portnum_mod)&&(portnum_mod)<=4)
						fctd->fish.CTDPortnum = fctd->fish.SerialPort4CTD.portnum = portnum;
					else
					{
						printf("WRONG CTD INPUT: Port number must be in range 11->14 or 21->24\n");
						return 0;
					}
					baudrate = atoi(argv[i+2]);
					fctd->fish.SerialPort4CTD.speed = baudrate;
				}
				// display CTD data
				if (!strcmp(argv[i],"raw"))
				{
					fctd->fish.printData = atoi(argv[i+1]);
				}

				// PCode
				if (argv[i][0]=='P')
				{
					fctd->pcode_flag = true;
					portnum = atoi(argv[i+1]);
                    portnum_mod = portnum % 10;
                    if((1<= portnum_mod)&&(portnum_mod)<=4)
						fctd->pcode.SerialPort4PCode.portnum = fctd->pcode.PCodePortnum = portnum;
					else
					{
						printf("WRONG PCode INPUT: Port number must be in range 11->14 or 21->24\n");
						Usage();
						return 0;
					}
					baudrate = atoi(argv[i+2]);
					fctd->pcode.SerialPort4PCode.speed = baudrate;
				}
				// TCP/IP socket
				if (!strcmp(argv[i],"tcpPort"))
				{
					portnum = atoi(argv[i+1]);
						fctd->network.TCPIPSocket.portnum = portnum;
				}
				// File's Size
				if (argv[i][0]=='f')
				{
					fctd->data_file.dataFileSize = atoi(argv[i+1]);
				}
				// File's destination
				if (argv[i][0]=='d')
				{
					sprintf(fctd->data_file.path,"%s/",argv[i+1]);
				}
				// File's name
				if (argv[i][0]=='n')
				{
					sprintf(fctd->data_file.runname,"%s",argv[i+1]);
				}
//				// total of drops in file
//				if (argv[i][0]=='t')
//				{
//					fctd->RecHeader.total_drops = atoi(argv[i+1]);
//				}
				// Write data via Serial port
				if (argv[i][0]=='s')
				{
					fctd->wr_data_serial_port_flag = TRUE;
					portnum = atoi(argv[i+1]);
                    portnum_mod = portnum % 10;
                    if((1<= portnum_mod)&&(portnum_mod)<=4)
						fctd->serial_port_4_data_out.portnum = portnum;
					else
					{
						printf("WRONG INPUT: Port number must be in range 11->14 or 21->24\n");
						Usage();
						return 0;
					}
				}
				// Write data to network (UDP broadcast)
				if (argv[i][0]=='i')
				{
					fctd->write_data_network_flag = TRUE;
					fctd->udp_socket.portnum = atoi(argv[i+1]);
				}
//				if (!strcmp(argv[i],"statFishInW"))
//				{
//					if (atoi(argv[i+1]) == 1)
//					{
//						fctd->dropnumBaseonWinch = TRUE;
//						fctd->network.getStatusFish = TRUE;
//					}
//					else fctd->ctd.getStatusFish = TRUE;
//				}
			}
		break;
	}
	return 1;
}	// end of CheckInput()

/*
** FUNCTION NAME: InitApp(FastCTDStructPtr *FCTDPtr, char SPList[][MAXNAMELEN])
** PURPOSE: Initialize all parameters for FastCTD app.  Allocate main Fast CTD structure
** DESCRIPTION: Initialize all parameters for all sensors, find-open request serial ports and create data file
** DATE: Mar 31, 2005
*/
int	init_app(fctd_epsi_ptr_t *fctd_epsi_ptr, char SPList[][MAXNAMELEN])
{
	int fd = -1;
	char timeStr[32] = "\0";
	char temp[TOTAL_SERIALPORT][MAXNAMELEN] = {"\0"};

	memcpy(SPList,temp,sizeof(temp));
	// for ASCII file
	if ((*fctd_epsi_ptr)->data_file.path[0]=='\0') strcpy((*fctd_epsi_ptr)->data_file.path,"/Users/Shared/");

    //ALB 2024/08/20 open the serial port before fctd_epsi_init so I can gtalk to the fish and grab
    //ALB the SBE calibration coefficients.
    // Open the aquired sensors's port
    OpenSerialPort4AllSensors(*fctd_epsi_ptr);

    // Initialize CTD's data structure
	fctd_epsi_init(*fctd_epsi_ptr);


	// open UDP broadcast port if apply
	if ((*fctd_epsi_ptr)->write_data_network_flag)
	{
		InitUDP(&((*fctd_epsi_ptr)->udp_socket.sockaddInfo),(*fctd_epsi_ptr)->udp_socket.portnum);
		(*fctd_epsi_ptr)->udp_socket.udpfd = u_openudp();
	}

    
	// FCTD server opens TCP/IP connection for client (Winch)
	(*fctd_epsi_ptr)->network.TCPIPSocket.remoteSocketfd = -1;
	if ((*fctd_epsi_ptr)->write_data_network_flag)
	{
		if((fd = ServerStartListening((*fctd_epsi_ptr)->network.TCPIPSocket.portnum))==-1)
		{
			fprintf (stderr, "FCTD fails in listening.  error: %d / %s\n",
						 errno, strerror(errno));
			close (fd);
		}
		(*fctd_epsi_ptr)->network.TCPIPSocket.fdTCPIP = fd;
		printf("Success opentcp port, go to accept loop\n");
	}

	// Create data file - in ascii file for now
	if(fnew_f(&((*fctd_epsi_ptr)->data_file))==0){ 
		printf("Could not create the new file in Init\n");
		return 0;
	}
//	// initialize the drop number of the file
//	(*FCTDPtr)->dropnum4newfile = (*FCTDPtr)->network.dropNum;
	
	// get offset time for saving into data file later
	(*fctd_epsi_ptr)->offset_time = Get_Offset_Time(timeStr, 1);	
	
	return 1;
}


/*
** FUNCTION NAME: OpenSerialPort4AllSensors(FastCTDStructPtr FCTDPtr, char SPList[][MAXNAMELEN])
** PURPOSE: Open the one apply for sensors: CTD, PCode, data out via serial port (if apply)
** DATE: Mar 31, 2005
*/
int OpenSerialPort4AllSensors(fctd_epsi_ptr_t FCTDPtr)
{
	// CTD install
	if (FCTDPtr->ctd_flag)
	{
        // Initialize port to receive data
		InitSerialPort(&FCTDPtr->fish.SerialPort4CTD, FCTDPtr->fish.CTDPortName);
		SetOptionSerialPort4FishCTD(&FCTDPtr->fish);
		if ((OpenSerialPort(&((FCTDPtr)->fish.SerialPort4CTD)))!=0)	// != 0 -> failed
			return EX_IOERR;

        //ALB 2024/08/20 Initialize port to send command to fish
        //TODO how do I do if the read and command port are the same.
        if (strcmp(FCTDPtr->fish.CTDPortName,FCTDPtr->fish.CommandPortName)!=0){
            InitSerialPort(&FCTDPtr->fish.SerialPort4Command, FCTDPtr->fish.CommandPortName);
            SetOptionSerialPort4FishCommand(&FCTDPtr->fish);
            if ((OpenSerialPort(&((FCTDPtr)->fish.SerialPort4Command)))!=0)    // != 0 -> failed
                return EX_IOERR;
        }
	}
	// PCode install
	if ((FCTDPtr)->pcode_flag)
	{
        InitSerialPort(&FCTDPtr->pcode.SerialPort4PCode, FCTDPtr->pcode.PCodePortName);
        SetOptionSerialPort4PCode(&FCTDPtr->pcode);
        if ((OpenSerialPort(&((FCTDPtr)->pcode.SerialPort4PCode)))!=0)	// != 0 -> failed
            return EX_IOERR;
	}
	// Write data via serial port
	if ((FCTDPtr)->wr_data_serial_port_flag)
	{
		InitSerialPort4Writting(&(FCTDPtr)->serial_port_4_data_out, FCTDPtr->serial_port_4_data_out.serialPortName);
		cfsetspeed(&(FCTDPtr)->serial_port_4_data_out.spOptions, FCTDPtr->serial_port_4_data_out.speed);	// 38400
		if ((OpenSerialPort((&(FCTDPtr)->serial_port_4_data_out)))!=0)	// != 0 -> failed
			return EX_IOERR;
	}
	return 1;
}

/*
** FUNCTION NAME: FreeAllMemory(FastCTDStructPtr FCTDPtr)
** PURPOSE: Clean memory: Close all serial port, TCP/IP port and deallocate FastCTD struct
** DATE: Mar 31, 2005
*/
int	FreeAllMemory(fctd_epsi_ptr_t FCTDPtr)
{	
	// Close all files
	if (FCTDPtr->data_file.fd) fctd_write_header_to_file(FCTDPtr,2);
	fclose_f(&FCTDPtr->data_file);

	// Close all serial ports
	// Close serial port getting CTD data
	if (FCTDPtr->ctd_flag)
	{
		if ((FCTDPtr->fish.SerialPort4CTD.portnum)!=0){
			CloseSerialPort(&(FCTDPtr->fish.SerialPort4CTD));
			printf("Close CTD port\n");}
        //ALB 2024/08/20 close command port if different from CTD port
        if (FCTDPtr->fish.SerialPort4CTD.portnum!=FCTDPtr->fish.SerialPort4Command.portnum){
            if ((FCTDPtr->fish.SerialPort4Command.portnum)!=0){
                CloseSerialPort(&(FCTDPtr->fish.SerialPort4Command));
                printf("Close Command port\n");}
        }
	}
	// Close serial port getting PCode data
	if (FCTDPtr->pcode_flag)
	{
		if ((FCTDPtr->pcode.SerialPort4PCode.portnum)!=0){
			CloseSerialPort(&(FCTDPtr->pcode.SerialPort4PCode));printf("Close PCode port\n");}
	}
	// Close serial port sending data out
	if (FCTDPtr->wr_data_serial_port_flag)
	{
		if ((FCTDPtr->serial_port_4_data_out.portnum)!=0){
			CloseSerialPort(&(FCTDPtr->serial_port_4_data_out));printf("Close serial port for sending data\n");}
	}
	printf("All serial ports closed.\n");

	// close TCP/IP connection port
	if (FCTDPtr->network.TCPIPSocket.fdTCPIP)
		close (FCTDPtr->network.TCPIPSocket.fdTCPIP);

	// Free memory for FastCTDPtr
	if(FCTDPtr){ free(FCTDPtr); FCTDPtr = NULL;}

	return 1;
}

/*
** FUNCTION NAME: RunApp(FastCTDStructPtr FastCTDPtr, pthread_t ThList[])
** PURPOSE: Create all thread for FastCTD app
** DATE: Mar 31, 2005
*/
void RunApp(fctd_epsi_ptr_t FastCTDPtr, pthread_t ThList[])
{
	// THREADS TASKS:  HAPPEN HERE ... *************************
	// Start background tasks that doo all the realtime work.
	// Each sensor has its own thread and one thread for write data to file, thread timeout control
	// one thread for checking stop command from user
	
	// Create all threads for CTD
	fctd_epsi_create_threads_f(ThList, FastCTDPtr);
}

/*
** FUNCTION NAME: ReadSetupFile(FastCTDStructPtr FastCTDPtr)
** PURPOSE: Read Setup file to get all options before run FastCTD app
** DESCRIPTION:
**		1. Get the current working to get the whole path of the Setup file
**		2. Open the setup file
**		3. Read the setup file and parse them to get all options
** DATE: Mar 31, 2005
*/
int ReadSetupFile(fctd_epsi_ptr_t fctd_epsi_ptr)
{
	char confstr[MAX_LENGTH] = "\0";
	char* sep = "=, '";
	char *strPtr;
	int portnum = 0, baudrate = 0;
	int val = 0, total_line = 0;
//    int portnum_mod = 0;

	char filename[1024], fname[] = "Setup", path[1024]="\0";
	FILE *fp = NULL;
	
	strcpy(filename, fctd_epsi_ptr->app_path);
	// filename = application_path/fname
	sprintf(filename,"%s%s",path,fname);

	// open the Setup file
	if((fp = fopen(filename, "r"))==NULL)
	{
		fprintf(stderr,"Could not open file %s for reading: %d - %s\n",filename,errno, strerror(errno));
		  return 0;
	}

	// read options to the end of the file: ignore comment line (start with %) and empty line
	while(fget_str_f(confstr,sizeof(confstr),fp))
	{
		if (confstr[0]=='\0') break;	// the end of the file -> done
		total_line++;
		strPtr = strtok(confstr,sep);	// ignore space
		
		if (*strPtr=='%'||*strPtr=='\n')	// ignore % and empty line
			continue;

		// CTD
		if (!strcmp("CTD.CTDPortName",strPtr))	// CTD's serial port name
		{
			fctd_epsi_ptr->ctd_flag = true;
			strPtr = strtok(NULL,sep);	// get the name of the serial port
            strcpy(fctd_epsi_ptr->fish.CTDPortName,strPtr);
            printf("CTD port name: %s\n",fctd_epsi_ptr->fish.CTDPortName);
		}
        if (!strcmp("CTD.CommandPortName",strPtr))    // CTD's serial port name
        {
            strPtr = strtok(NULL,sep);    // get the name of the serial port
            strcpy(fctd_epsi_ptr->fish.CommandPortName,strPtr);
            printf("Command port name: %s\n",fctd_epsi_ptr->fish.CommandPortName);
        }
		if (!strcmp("CTD.speed",strPtr))	// CTD's baudrate
		{
			strPtr = strtok(NULL,sep);	// get number
			baudrate = atoi(strPtr);		// convert string to number
			fctd_epsi_ptr->fish.SerialPort4CTD.speed     = baudrate;
            fctd_epsi_ptr->fish.SerialPort4Command.speed = baudrate;
		}
		if (!strcmp("CTD.printData",strPtr))	// diplay CTD data
		{
			strPtr = strtok(NULL,sep);	// get number
			val = atoi(strPtr);		// convert string to number
			fctd_epsi_ptr->fish.printData = val;
            fctd_epsi_ptr->pcode.printData = val;  // set for PCode also - MNB Jun 21, 2011
            fctd_epsi_ptr->network.printData = val;  // set for Winch also - MNB Jun 21, 2011
		}
		if (!strcmp("CTD.engDispRate",strPtr))	// get the rate for printing data in engineer mode
		{
			strPtr = strtok(NULL,sep);	// get number
			val = atoi(strPtr);		// convert string to number
            if (val > 16)
            {
                fctd_epsi_ptr->fish.engDispRate = 16;
            }
            else
            {
                if (val == 3) 
                    fctd_epsi_ptr->fish.engDispRate = 2;
                else if (val > 4 && val < 8) 
                    fctd_epsi_ptr->fish.engDispRate = 4;
                else if (val > 8 && val < 16) 
                    fctd_epsi_ptr->fish.engDispRate = 8;
                else
                   fctd_epsi_ptr->fish.engDispRate = val;
            }
 		}
        //ALB 19 august 2024:  add mission name...
        if (!strcmp("CTD.experiment",strPtr))    // channel 1 probe serial number
        {
            strPtr = strtok(NULL,sep);    // get string's length
            strcpy(fctd_epsi_ptr->fish.experiment,strPtr);
        }
        //ALB 19 august 2024:  add cruise name...
        if (!strcmp("CTD.cruise",strPtr))
        {
            strPtr = strtok(NULL,sep);
            strcpy(fctd_epsi_ptr->fish.cruise,strPtr);
        }
        //ALB 19 august 2024:  add vehicle name...
        if (!strcmp("CTD.vehicle",strPtr))
        {
            strPtr = strtok(NULL,sep);
            strcpy(fctd_epsi_ptr->fish.vehicle,strPtr);
        }
        //ALB 19 august 2024:  add fish pressure case name...
        if (!strcmp("CTD.fish_pc",strPtr))
        {
            strPtr = strtok(NULL,sep);
            strcpy(fctd_epsi_ptr->fish.fish_pc,strPtr);
        }
        //ALB 23 Sept 2024:  add fish pressure case name...
        if (!strcmp("CTD.survey",strPtr))
        {
            strPtr = strtok(NULL,sep);
            strcpy(fctd_epsi_ptr->fish.survey,strPtr);
        }
        //ALB 19 august 2024:  add fish pressure case name...
        if (!strcmp("CTD.fishflag",strPtr))
        {
            strPtr = strtok(NULL,sep);
            strcpy(fctd_epsi_ptr->fish.fish_flag,strPtr);
        }

		if (!strcmp("CTD.CTDlength",strPtr))	// length of CTD's string
		{
			strPtr = strtok(NULL,sep);	// get string's length
			fctd_epsi_ptr->fish.CTDlength = atoi(strPtr);
		}
		//JMK 17 April 05:  record the serial number...
		if (!strcmp("CTD.SerialNum",strPtr))	// length of CTD's string
		{
			strPtr = strtok(NULL,sep);	// get string's length
			strcpy(fctd_epsi_ptr->fish.SerialNum,strPtr);
		}
        //ALB 19 august 2024:  Probe calibration path...
        if (!strcmp("CTD.shear_Probecal_path",strPtr))    // channel 1 probe serial number
        {
            strPtr = strtok(NULL,sep);    // get string's length
            strcpy(fctd_epsi_ptr->fish.shear_Probe_cal_path,strPtr);
        }
        //ALB 19 august 2024:  Probe calibration path...
        if (!strcmp("CTD.FPO7_Probecal_path",strPtr))    // channel 1 probe serial number
        {
            strPtr = strtok(NULL,sep);    // get string's length
            strcpy(fctd_epsi_ptr->fish.FPO7_Probe_cal_path,strPtr);
        }
        //ALB 23 sept 2024:  CTD calibration path...
        if (!strcmp("CTD.CTD_cal_path",strPtr))    // channel 1 probe serial number
        {
            strPtr = strtok(NULL,sep);    // get string's length
            strcpy(fctd_epsi_ptr->fish.CTD_cal_path,strPtr);
        }
        //ALB 19 august 2024:  record the probes serial number...
        //ALB  on epsi ch1 = t1, ch2 = t2, ch3 = s1, ch4 = s2
        //ALB  on fctd ch1 = 000, ch2 = 000, ch3 = 000, ch4 = uConductivity
        if (!strcmp("CTD.ch1_sn",strPtr))    // channel 1 probe serial number
        {
            strPtr = strtok(NULL,sep);    // get string's length
            strcpy(fctd_epsi_ptr->fish.ch1_sn,strPtr);
        }
        //ALB 19 august 2024:  record the probes serial number...
        //ALB  on epsi ch1 = t1, ch2 = t2, ch3 = s1, ch4 = s2
        //ALB  on fctd ch1 = 000, ch2 = 000, ch3 = 000, ch4 = uConductivity
        if (!strcmp("CTD.ch2_sn",strPtr))    // channel 1 probe serial number
        {
            strPtr = strtok(NULL,sep);    // get string's length
            strcpy(fctd_epsi_ptr->fish.ch2_sn,strPtr);
        }
        //ALB 19 august 2024:  record the probes serial number...
        //ALB  on epsi ch1 = t1, ch2 = t2, ch3 = s1, ch4 = s2
        //ALB  on fctd ch1 = 000, ch2 = 000, ch3 = 000, ch4 = uConductivity
        if (!strcmp("CTD.ch3_sn",strPtr))    // channel 1 probe serial number
        {
            strPtr = strtok(NULL,sep);    // get string's length
            strcpy(fctd_epsi_ptr->fish.ch3_sn,strPtr);
        }
        //ALB 19 august 2024:  record the probes serial number...
        //ALB  on epsi ch1 = t1, ch2 = t2, ch3 = s1, ch4 = s2
        //ALB  on fctd ch1 = 000, ch2 = 000, ch3 = 000, ch4 = uConductivity
        if (!strcmp("CTD.ch4_sn",strPtr))    // channel 1 probe serial number
        {
            strPtr = strtok(NULL,sep);    // get string's length
            strcpy(fctd_epsi_ptr->fish.ch4_sn,strPtr);
        }

        
		// Winch
		if (!strcmp("TCPIPSocket.portnum",strPtr))	// port number for TCP/IP socket: communicate to winch
		{
			strPtr = strtok(NULL,sep);	// get port number in tring
			portnum = atoi(strPtr);     // convert string to number
			fctd_epsi_ptr->network.TCPIPSocket.portnum = portnum;
		}
        
		// PCode set up
		if (!strcmp("PCode.PCodePortName",strPtr))	// PCode's serial port name
		{
			fctd_epsi_ptr->pcode_flag = true;
			strPtr = strtok(NULL,sep);	// get the name of the serial port
			strcpy(fctd_epsi_ptr->pcode.PCodePortName,strPtr);
		printf("PCode port name: %s\n",fctd_epsi_ptr->pcode.PCodePortName);
		}
		if (!strcmp("PCode.speed",strPtr))	// CTD's baudrate
		{
			strPtr = strtok(NULL,sep);	// get port number
			baudrate = atoi(strPtr);		// convert string to number
			fctd_epsi_ptr->pcode.SerialPort4PCode.speed = baudrate;
		}

		if (!strcmp("Ascii_dataFile.runname",strPtr))	// run name for data file
		{
			strPtr = strtok(NULL,sep);	// get the name of the data file
			strcpy(fctd_epsi_ptr->data_file.runname,strPtr);
		}
		if (!strcmp("Ascii_dataFile.path",strPtr))	// directory of storing data file
		{
			strPtr = strtok(NULL,sep);	// get the name of the data file
			strcpy(fctd_epsi_ptr->data_file.path,strPtr);
		}
		if (!strcmp("Ascii_dataFile.dataFileSize",strPtr))	
		{
			strPtr = strtok(NULL,sep);	// getF the size of the data file
			fctd_epsi_ptr->data_file.dataFileSize = atoi(strPtr);
		}
//		if (!strcmp("SerialPort4DataOut.portnum",strPtr))	// Send data via serial port -> get port number
//		{
//			strPtr = strtok(NULL,sep);	// get the port number
//			portnum = atoi(strPtr);
//			if (portnum == 0)
//				FastCTDPtr->wr_data_serial_port_flag = FALSE;
//			else
//			{
//				FastCTDPtr->wr_data_serial_port_flag = TRUE;
//                portnum_mod = portnum %10;
//                if((1<=portnum_mod)&&(portnum_mod<=4))
//					FastCTDPtr->serial_port_4_data_out.portnum = portnum;
//				else
//				{
//					printf("WRONG INPUT: Port number must be in range 11->14 or 21->24\n");
//					return 0;
//				}
//			}
//		}
		if (!strcmp("DataOut.speed",strPtr))	// CTD's baudrate
		{
			strPtr = strtok(NULL,sep);	// get port number
			baudrate = atoi(strPtr);		// convert string to number
			fctd_epsi_ptr->serial_port_4_data_out.speed = baudrate;
		}
		if (!strcmp("UDPSocket.portnum",strPtr))	// Send data to network (UDP broadcast) -> get port number
		{
			strPtr = strtok(NULL,sep);	// get the port number
			portnum = atoi(strPtr);
			if (portnum == 0)
				fctd_epsi_ptr->write_data_network_flag = FALSE;
			else
			{
				fctd_epsi_ptr->write_data_network_flag = TRUE;
				fctd_epsi_ptr->udp_socket.portnum = portnum;
			}
		}
	}
	if (fp) {fclose(fp);fp = NULL;}

	return 1;
} // end of ReadSetupFile

/*
** FUNCTION NAME: GetInfo4SetupFile(FastCTDStructPtr FastCTDPtr, char* str)
** PURPOSE: Get value of all parameters from FastCTD struct to construct a string to write to "Setup" file
** DATE: Mar 31, 2005
*/
int GetInfo4SetupFile(fctd_epsi_ptr_t fctd_epsi_ptr, char* str)
{
	char cmm1[] = "%Format: '%': for comment out, \"name=1234\"\n";
	char cmm2[] = "%TCPIP port for send and receive data\n";
	char cmm3[] = "%SENSOR SETUP\n";
	char cmm4[] = "%Serial port for Fish and PCode\n";
	char cmm5[] = "%Install Winch or not\n";
	char cmm6[] = "%FILES\n";
	char cmm7[] = "%Display CTD data: 0=raw, 1=engineer format\n";
	char cmm8[] = "%Length of CTD data: 24 or 72 (has micro-cond)\n";

	char str1[256]="\0",str2[256]="\0",str3[256]="\0",str4[256]="\0",str5[256]="\0",str6[256]="\0",str7[256]="\0",str8[125]="\0",str9[125]="\0",str13[256]="\0";
	char str10[256] = "\0", str11[256] = "\0", str12[256] = "\0", str14[256] = "\0";
	char cmm = '%';

	sprintf(str1,"TCPIPSocket.portnum=%d\n",fctd_epsi_ptr->network.TCPIPSocket.portnum);
	// CTD
	if(fctd_epsi_ptr->ctd_flag) 
		sprintf(str2,"CTD.CTDPortName='%s'\n",fctd_epsi_ptr->fish.CTDPortName);
	else 
		sprintf(str2,"%cCTD.CTDPortName='USA49W1813P1.1'\n",cmm);
	sprintf(str12,"CTD.CTDlength=%d\n",fctd_epsi_ptr->fish.CTDlength);
	sprintf(str13,"CTD.printData=%d\n",fctd_epsi_ptr->fish.printData);
	// PCode
	if (fctd_epsi_ptr->pcode_flag) 
		sprintf(str3,"PCode.PCodePortName='%s'\n",fctd_epsi_ptr->pcode.PCodePortName);
	else 
		sprintf(str3,"%cPCode.PCodePortName='USA49W1813P1.1'\n",cmm);
//	// Winch
//	if (fctd_epsi_ptr->network_flag)
//		sprintf(str4,"TCPIP4Winch\n");
//	else
//		sprintf(str4,"%cTCPIP4Winch\n",cmm);
//	if (fctd_epsi_ptr->dropnumBaseonWinch)
//		sprintf(str11,"dropnumBaseonWinch=1\n");
//	else
//		sprintf(str11,"%cdropnumBaseonWinch=1\n",cmm);
	// Setup
	sprintf(str5,"RecHeader.totalDrops=%lu\n",fctd_epsi_ptr->rec_header.total_drops);
	//JMK 16Apr05: Matlab doesn't like square brackets...
	sprintf(str6,"fpData0.runname='%s'\n",fctd_epsi_ptr->data_file.runname);
	sprintf(str7,"fpData0.path='%s'\n",fctd_epsi_ptr->data_file.path);
	sprintf(str10,"fpData0.dataFileSize=%ld\n",fctd_epsi_ptr->data_file.dataFileSize);
	if (fctd_epsi_ptr->wr_data_serial_port_flag)
		sprintf(str8,"SerialPort4DataOut.serialPortName='%s'\n",fctd_epsi_ptr->serial_port_4_data_out.serialPortName);
	else
		sprintf(str8,"SerialPort4DataOut.serialPortName='USA49W1813P1.1'\n");	
	if (fctd_epsi_ptr->write_data_network_flag)
		sprintf(str9,"UDPSocket.portnum=%d",fctd_epsi_ptr->udp_socket.portnum);
	else
		sprintf(str9,"%cUDPSocket.portnum=%d",cmm,fctd_epsi_ptr->udp_socket.portnum);
	
	sprintf(str14,"CTD.SerialNum='%s'\n",fctd_epsi_ptr->fish.SerialNum);
	
	sprintf(str,"%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s",cmm1,cmm2,str1,cmm3,str14,cmm7,str13,cmm4,str2,cmm8,str12,str3,cmm5,str4,str11,cmm6,str5,str6,str7,str10,str9);

    return 1;
}


/*
** FUNCTION NAME: SaveSetupFile(FastCTDStructPtr FastCTDPtr)
** PURPOSE: Get value of all parameters from FastCTD struct to construct a string to write to "Setup" file
** DATE: Mar 15, 2007
*/
int SaveSetupFile(fctd_epsi_ptr_t fctd_epsi_ptr)
{
    char str[2048] = "\0";
	char filename[1024]="\0", fname[] = "Setup", path[1024]="\0";
	//JMK 25 April 2005
	struct tm *timeptr;
	time_t thetime;
	FILE *fp = NULL;
	ssize_t numBytesWr=0;
	int total_line =0;
	
	//JMK 25 April 2005 Get time...
	time(&thetime);
	timeptr=gmtime(&thetime);

	// Get the whole path of the application.
	strcpy(filename, fctd_epsi_ptr->app_path);
	// Discard the application name, only get the path of application

	// filename = application_path/fname
	sprintf(filename,"%s%s%04d%02d%02d%02d%02d",path,fname,timeptr->tm_year+1900,
	   timeptr->tm_mon+1,timeptr->tm_mday,timeptr->tm_hour,timeptr->tm_min);
	fprintf(stdout,"Setup file: %s\n",filename);
    strcpy(fctd_epsi_ptr->SaveSetup_name,filename);

	if((fp = fopen(filename, "w"))==NULL)
	{
		fprintf(stderr,"Could not open file %s for writing: %d - %s\n",filename,errno, strerror(errno));
		  return 0;
	}

	if ((numBytesWr=fctd_read_setup_write_to_file(fctd_epsi_ptr,fp,str,&total_line))==0)
		fprintf(stderr,"ERROR! Failed to read setup and write into the file\n");

	if (fp) fclose(fp);

	return (int)numBytesWr;
}// end of SaveSetupFile

int main(int argc, const char *argv[])
{
	pthread_t threadList[NUM_THREADS];
	fctd_epsi_ptr_t FastCTDPtr = NULL;
	static char SerialPortListName[TOTAL_SERIALPORT][MAXNAMELEN] = {"\0"};

    int i=0;
    char tempStr[1024] = "\0";
    char ctdStr_local[1024] = "$SBE49000000000000d909,0075,0000000000000000d8c5055D6609E7B2080D724DD8000000000000d903055D6609E7B2080D724DD9*42";
    
    for (i=0;i<4;i++)
        tempStr[i] = ctdStr_local[i];
 /*
    // test the system whether is little or big endian = mnbui Mar 8, 2021 => little
    if (CFByteOrderGetCurrent() == CFByteOrderBigEndian)
        printf("sys = Big]\n");
    if (CFByteOrderGetCurrent() == CFByteOrderLittleEndian)
    {
        printf("sys = Little\n");
        strcpy(tempStr,CFSwapInt32HostToBig((uint32_t)tempStr);
        printf("str = %s\n",tempStr);
        
    }
*/

	// INITIALIZE CTD STRUCTURE TO STORE SENSORS'S TYPE LATER *************************************
	FastCTDPtr = (fctd_epsi_t*)malloc(sizeof(fctd_epsi_t));
	if (FastCTDPtr == NULL)
		return 0;

	// Get the path of the application
    getcwd(FastCTDPtr->app_path, sizeof(FastCTDPtr->app_path));
    //strcpy(FastCTDPtr->app_path,argv[0]);
    //printf("path: %s\n",FastCTDPtr->app_path);

	// GET APP's OPTION: from Setup file ****************************
	// Open the setup file and get all options and close
	ReadSetupFile(FastCTDPtr);

    // Save the setup file.
    //ALB 2024 August 22: I save the Setup here becasue I want to append the probe serial number and SBE cal coef to it and
    // re-use it when opening a new .modraw file. 
    if (SaveSetupFile(FastCTDPtr)==0) fprintf(stderr,"Write nothing into setup file\n");

    // Get options from the user - in command line
	if(!CheckInput(argc,argv,FastCTDPtr))
	{
		// free memory for FastCTDPtr
		if(FastCTDPtr){ free(FastCTDPtr); FastCTDPtr = NULL;}
		return 1;
	}

	// INITIALIZATION *************************************
		if (init_app(&FastCTDPtr, SerialPortListName)==0){
			if(FastCTDPtr){ free(FastCTDPtr); FastCTDPtr = NULL;}
			return 1;
		}

	// RUNNING LOOP *************************************
		RunApp(FastCTDPtr, threadList);
		fctd_epsi_join_threads_f(threadList);

	// Save the setup file.   
	if (SaveSetupFile(FastCTDPtr)==0) fprintf(stderr,"Write nothing into setup file\n");

	// CLEANING ********************************* ... need to clean all threads
		FreeAllMemory(FastCTDPtr);

	return 0;
}
