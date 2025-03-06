#include "ctd.h"

#define PRESS_AVG 16
// average pressure (16 to 1)
//static Boolean firstTime = TRUE;
//static int CTD_Length = 24;

#define STAR_INDX 5
/*
 ** Function Name:
 ** int AverageFishData(FishCTDStructPtr fishCTDPtr, unsigned long *avgTime, float *avgPress,float *avgTemp, float *avgCond, float *avgAltTime)
 ** Purpose: Average data of CTD 16 to one for sending to winch.
 */

int AverageFishData(fish_ctd_ptr_t fishCTDPtr, unsigned long *avgTime, float *avgPress,float *avgTemp, float *avgCond, float *avgAltTime)
{
    int result = 0, indx;
    unsigned int count;
    float press = 0.0; //, avgPress= 0;
    float altTime = 0.0; //, avgPress= 0;
    float temp = 0.0; //, avgTemp = 0;
    float cond = 0.0; //, avgCond = 0;
    unsigned long realTimestamp=0, timestamp = 0, headTimestamp = 0;
    static float totalpress = 0.0;
    static float totalAltTime = 0.0;
    static float totaltemp = 0.0;
    static float totalcond = 0.0;
    static unsigned long totaltime = 0;
    
    // JMK 24 April 2005 To get current average rather than random average
    fishCTDPtr->GetPressIndx=fishCTDPtr->CTD_ParseIndx-PRESS_AVG-1;
    
    for (count=0; count<=PRESS_AVG; count++)
    {
        // get the index of the current data
        indx = fishCTDPtr->GetPressIndx % MAX_CIRBUFF;
        // print out the last of average data - MNB Jun 9, 2011
        if (count == PRESS_AVG)
            printf("%s",fishCTDPtr->ctd_cir_buff[indx].DataStr);
        
        if ((fishCTDPtr->ctd_cir_buff[indx].ParseDone) && (fishCTDPtr->CTD_ParseIndx > fishCTDPtr->GetPressIndx))
        {
            // get the current data
            realTimestamp = fishCTDPtr->ctd_cir_buff[indx].timeInHundredsecs;
            headTimestamp = realTimestamp/10000;
            timestamp = realTimestamp%10000;
            press = fishCTDPtr->ctd_cir_buff[indx].FishCTDdata.pressure;
            altTime = fishCTDPtr->ctd_cir_buff[indx].FishCTDdata.altTime;
            temp = fishCTDPtr->ctd_cir_buff[indx].FishCTDdata.temperature;
            cond = fishCTDPtr->ctd_cir_buff[indx].FishCTDdata.conductivity;
            
            // average fish pressure 16 -> 1 send to wich.
            if (count==PRESS_AVG)
            {
                // average time
                totaltime += timestamp;
                *avgTime = totaltime/(PRESS_AVG+1);
                *avgTime += headTimestamp*10000;
                totaltime = 0;
                totalpress += press;
                *avgPress = totalpress/(PRESS_AVG+1);
                totalpress = 0.0;
                totalAltTime += altTime;
                *avgAltTime = totalAltTime/(PRESS_AVG+1);
                totalAltTime = 0.0;
                *avgTemp = totaltemp/(PRESS_AVG+1);
                totaltemp = 0.0;
                *avgCond = totalcond/(PRESS_AVG+1);
                totalcond = 0.0;
                result = 1;
            }
            else
            {
                totaltime += timestamp;
                *avgTime = 0;
                totalpress += press;
                *avgPress = 0.0;
                totalAltTime += altTime;
                *avgAltTime = 0.0;
                totaltemp += temp;
                *avgTemp = 0.0;
                totalcond += cond;
                *avgCond = 0.0;
                result = 0;
            }
            fishCTDPtr->GetPressIndx++;
        }
    }// end of for loop
    return result;
}

/*
 ** Function Name:
 ** int CurrentFishData(FishCTDStructPtr fishCTDPtr, unsigned long *CTDtime, float *CTDpress, float *CTDtemp, float *CTDcond, float *AltTime);
 ** Purpose: Current CTD data for sending to winch.
 ** added by San Nguyen
 */
int CurrentFishData(fish_ctd_ptr_t fishCTDPtr, unsigned long *CTDtime, float *CTDpress, float *CTDtemp, float *CTDcond, float *AltTime)
{
    int result = 0, indx;
    unsigned long realTimestamp=0;// headTimestamp = 0;
    
    indx=fishCTDPtr->CTD_ReadBufferIndx;
    // get the index of the current data
    indx %= MAX_CIRBUFF;
    // print out data string - MNB Jun 9, 2011
    printf("%s",fishCTDPtr->ctd_cir_buff[indx].DataStr);
    
    if (!fishCTDPtr->ctd_cir_buff[indx].in_use)
    {
        // get the current data
        realTimestamp = fishCTDPtr->ctd_cir_buff[indx].timeInHundredsecs;
        //         headTimestamp = realTimestamp/10000;
        *CTDtime = realTimestamp%10000;
        *CTDpress = fishCTDPtr->ctd_cir_buff[indx].FishCTDdata.pressure;
        *CTDtemp = fishCTDPtr->ctd_cir_buff[indx].FishCTDdata.temperature;
        *CTDcond = fishCTDPtr->ctd_cir_buff[indx].FishCTDdata.conductivity;
        // TODO mnbui 12Mar21: get altimeter from global altimeter parameter
        *AltTime = fishCTDPtr->LatestAltTime;
        result = 1;
    }
    
    return result;
}

int CurrentFishData2(fish_ctd_ptr_t fishCTDPtr, unsigned long *CTDtime, float *CTDpress, float *CTDtemp, float *CTDcond, float *AltTime)
{
    int result = 0, indx;
    unsigned long realTimestamp=0;// headTimestamp = 0;
    
    indx=fishCTDPtr->CTD_ReadBufferIndx_2;
    // get the index of the current data
    indx %= MAX_CIRBUFF;
    // print out data string - MNB Jun 9, 2011
    printf("%s",fishCTDPtr->ctd_cir_buff[indx].DataStr);
    
    if (!fishCTDPtr->ctd_cir_buff[indx].in_use){
        if(fishCTDPtr->CTD_ReadBufferIndx_2 < fishCTDPtr->CTD_Write2BufferIndx)
        {
            // get the current data
            realTimestamp = fishCTDPtr->ctd_cir_buff[indx].timeInHundredsecs;
            //         headTimestamp = realTimestamp/10000;
            *CTDtime = realTimestamp%10000;
            *CTDpress = fishCTDPtr->ctd_cir_buff[indx].FishCTDdata.pressure;
            *CTDtemp = fishCTDPtr->ctd_cir_buff[indx].FishCTDdata.temperature;
            *CTDcond = fishCTDPtr->ctd_cir_buff[indx].FishCTDdata.conductivity;
            // TODO mnbui 12Mar21: get altimeter from global altimeter parameter
            *AltTime = fishCTDPtr->LatestAltTime;
            result = 1;
            fishCTDPtr->CTD_ReadBufferIndx_2++;
        }else if (fishCTDPtr->CTD_ReadBufferIndx_2 < (fishCTDPtr->CTD_Write2BufferIndx+1)){
            fishCTDPtr->CTD_ReadBufferIndx_2 = fishCTDPtr->CTD_Write2BufferIndx+1;
        }
    }
    
    return result;
}


/*
 Model: FAST CAT CTD 49
 CTD's data format:  Raw data in Hexadecimal - 24 chars: 22 ASCII chars (hex) + 2 chars (carriage return & line feed) : 11 bytes per scan
 example: ttttttccccccppppppvvvv = 0A53711BC7220C14C17D82
 Temperature = tttttt = 0A5371 (676721 decimal)
 tempeatrue A/D counts = 676721
 Conductivity = cccccc = 1BC722 (1820450)
 conductivity frequency = 1820450/256 = 7111.133 Hz
 Pressure = pppppp = 0C14C1 (791745 decimal)
 pressure A/D counts = 791745
 Pressure temperature compensation = vvvv = 7D82 (32,130 decimal)
 pressure temperature = 32,130 / 13,107 = 2.4514 volts
 
 Model: 911 CTD:
 There are 12 words per scan, 3 bytes/word -> 36 bytes/scan.
 Word 0	Byte 0 -> 2:	Primary Temperature
 Word 1	Byte 3 -> 5:	Primary Conductivity
 Word 2	Byte 6 -> 8:	Pressure
 Word 11	Byte 33	   :	Pressure Sensor Temperature MSBs
 Byte 34	   :	4 MSB = Pressure Sensor Temperature LSBs
 CALCULATION:	( perform in ConvertBinData() )
 1. Frequencies:
 FT (Temperature) = Byte(0)*256 + Byte(1) + Byte(2)/256		(Hz)
 FC (Temperature) = Byte(3)*256 + Byte(4) + Byte(5)/256		(Hz)
 FP (Temperature) = Byte(6)*256 + Byte(7) + Byte(8)/256		(Hz)
 2. Temperature:
 T = 1/{Ta+Tb*[ln(Tfo/FT)]+Tc*[ln(Tfo/FT)]^2+Td*[ln(Tfo/FT)]^3} - 273.15	(˚C)
 3. Pressure:
 Pressure Temperature Compensation:
 12-bit pressure temperature compensation word =
 Byte(33)*16 + Byte(34)/16
 U = M * (12-bit pressure temperature compensation word) + B		(˚C)
 Pc = Pc1 + Pc2*U + Pc3*U^2
 Pd = Pd1 + Pd2*U
 Pto = Pt1 + Pt2*U + Pt3*U^2 + Pt4*U^3 + Pt5*U^4		(µsec)
 
 freq = (Pto/FT)^2
 P = Pc*[1 - freq]*[1 - Pd*(1 - freq)]				(psia)
 
 or the other way of calculation: (we use this following formular)
 
 freq = (Pto*FT)^2*1e-12;				1e-12: convert from µsec -> sec
 P = {Pc*(1 - freq)*[1 - Pd*(1 - freq)]}/1.47 - 10	(dbar)
 1.47 = convert from psia to decibar
 10   = offset, the pressure at the surface of the ocean = 10
 
 4. Conductivity:
 C = (Ca*FC^Cm + Cb*FC^2 + Cc + Cd*T)/[10(1 + CPCor*P)]
 
 */

float CalculateTemp(fish_ctd_ptr_t FishCTDPtr, long tempInHex)
{
    float MV, R;
    float temp = 0.0;
    
    MV = (tempInHex - 524288)/1.6e+007;
    R = (MV * 2.295e+10 + 9.216e+8) / (6.144e+4 - MV*5.3e+5);
    temp = 1/( FishCTDPtr->FastCTDSetup.ctd_coeff.ta0
              + FishCTDPtr->FastCTDSetup.ctd_coeff.ta1*log(R)
              + FishCTDPtr->FastCTDSetup.ctd_coeff.ta2*log(R)*log(R)
              + FishCTDPtr->FastCTDSetup.ctd_coeff.ta3*log(R)*log(R)*log(R)) - 273.15;
    return temp;
}

float CalculatePress(fish_ctd_ptr_t FishCTDPtr, long pressTempInDec, long pressInDec)
{
    double y = 0.0, t = 0.0, x = 0.0, n = 0.0;
    double press = 0.0;
    
    y = pressTempInDec/13107;
    //JMK 29Aug06 fixed to be a0+T*a1+T^2*a2
    t = FishCTDPtr->FastCTDSetup.ctd_coeff.ptempa0 + FishCTDPtr->FastCTDSetup.ctd_coeff.ptempa1*y
    + FishCTDPtr->FastCTDSetup.ctd_coeff.ptempa2*y*y;
    x = pressInDec - FishCTDPtr->FastCTDSetup.ctd_coeff.ptca0 - FishCTDPtr->FastCTDSetup.ctd_coeff.ptca1*t
    - FishCTDPtr->FastCTDSetup.ctd_coeff.ptca2*t*t;
    n = x*FishCTDPtr->FastCTDSetup.ctd_coeff.ptcb0/(FishCTDPtr->FastCTDSetup.ctd_coeff.ptcb0
                                                    + FishCTDPtr->FastCTDSetup.ctd_coeff.ptcb1*t
                                                    + FishCTDPtr->FastCTDSetup.ctd_coeff.ptcb2*t*t);
    press = FishCTDPtr->FastCTDSetup.ctd_coeff.pa0 + FishCTDPtr->FastCTDSetup.ctd_coeff.pa1*n
    + FishCTDPtr->FastCTDSetup.ctd_coeff.pa2*n*n;
    press = (press - 14.6959488) * 0.689476;	// convert psia to decibars
    return (float)press;
}

float CalculateCond(fish_ctd_ptr_t FishCTDPtr, float temp, float press, long condInHex)
{
    float condFreq = 0.0, f= 0.0, cond = 0.0, cond1 = 0.0, cond2 = 0.0;
    
    condFreq = condInHex/256;
    f = condFreq/1000.0;
    // in Siemens/meter unit
    cond1 = ( FishCTDPtr->FastCTDSetup.ctd_coeff.cg
             + FishCTDPtr->FastCTDSetup.ctd_coeff.ch*f*f
             + FishCTDPtr->FastCTDSetup.ctd_coeff.ci*f*f*f
             + FishCTDPtr->FastCTDSetup.ctd_coeff.cj*f*f*f*f);
    cond2 = 1 + FishCTDPtr->FastCTDSetup.ctd_coeff.ctcor*temp + FishCTDPtr->FastCTDSetup.ctd_coeff.cpcor*press;
    cond = cond1/cond2;
    return cond;
}

float CalculateSoundVel(fish_ctd_ptr_t FishCTDPtr,float C, float T, float P){
    //     float sound_vel;
    P /= 10;  // convert db to bars as used in UNESCO routines
    
    //------------
    // eqn 34 p.46
    //------------
    float c00 = 1402.388;
    float c01 =    5.03711;
    float c02 =   -5.80852e-2;
    float c03 =    3.3420e-4;
    float c04 =   -1.47800e-6;
    float c05 =    3.1464e-9;
    
    float c10 =  0.153563;
    float c11 =  6.8982e-4;
    float c12 = -8.1788e-6;
    float c13 =  1.3621e-7;
    float c14 = -6.1185e-10;
    
    float c20 =  3.1260e-5;
    float c21 = -1.7107e-6;
    float c22 =  2.5974e-8;
    float c23 = -2.5335e-10;
    float c24 =  1.0405e-12;
    
    float c30 = -9.7729e-9;
    float c31 =  3.8504e-10;
    float c32 = -2.3643e-12;
    
    float Cw =    c00 + (c01 + (c02 + (c03 + (c04 + c05*T)*T)*T)*T)*T;
    Cw += (c10 + (c11 + (c12 + (c13 + c14*T)*T)*T)*T)*P;
    Cw +=(c20 + (c21 + (c22 + (c23 + c24*T)*T)*T)*T)*P*P;
    Cw += (c30 + c31*T + c32*T*T)*P*P*P;
    
    //-------------
    // eqn 35. p.47
    //-------------
    float a00 =  1.389;
    float a01 = -1.262e-2;
    float a02 =  7.164e-5;
    float a03 =  2.006e-6;
    float a04 = -3.21e-8;
    
    float a10 =  9.4742e-5;
    float a11 = -1.2580e-5;
    float a12 = -6.4885e-8;
    float a13 =  1.0507e-8;
    float a14 = -2.0122e-10;
    
    float a20 = -3.9064e-7;
    float a21 =  9.1041e-9;
    float a22 = -1.6002e-10;
    float a23 =  7.988e-12;
    
    float a30 =  1.100e-10;
    float a31 =  6.649e-12;
    float a32 = -3.389e-13;
    
    float A = a00 + a01*T + a02*T*T + a03*T*T*T + a04*T*T*T*T;
    A += (a10 + a11*T + a12*T*T + a13*T*T*T + a14*T*T*T*T)*P;
    A += (a20 + a21*T + a22*T*T + a23*T*T*T)*P*P;
    A +=(a30 + a31*T + a32*T*T)*P*P*P;
    
    
    //------------
    // eqn 36 p.47
    //------------
    float b00 = -1.922e-2;
    float b01 = -4.42e-5;
    float b10 =  7.3637e-5;
    float b11 =  1.7945e-7;
    
    float B = b00 + b01*T + (b10 + b11*T)*P;
    //------------
    // eqn 37 p.47
    //------------
    float d00 =  1.727e-3;
    float d10 = -7.9836e-6;
    
    float D = d00 + d10*P;
    
    float S = CalculateSalt(C, T, P);
    
    //------------
    // eqn 33 p.46
    //------------
    float svel = Cw + A*S + B*S*sqrt(S) + D*S*S;
    
    return svel;
}

float CalculateSalt(float C,float T, float P){
    float c3515 = 42.914;
    
    float R = C*10/c3515;
    
    //sw_salrt
    float c0 =  0.6766097;
    float c1 =  2.00564e-2;
    float c2 =  1.104259e-4;
    float c3 = -6.9698e-7;
    float c4 =  1.0031e-9;
    
    float rt = c0 + (c1 + (c2 + (c3 + c4*T)*T)*T)*T;
    
    //sw_salrp
    float d1 =  3.426e-2;
    float d2 =  4.464e-4;
    float d3 =  4.215e-1;
    float d4 = -3.107e-3;
    
    float e1 =  2.070e-5;
    float e2 = -6.370e-10;
    float e3 =  3.989e-15;
    
    float Rp = 1 + ( P*(e1 + e2*P + e3*P*P) )/(1 + d1*T + d2*T*T +(d3 + d4*T)*R);
    
    float Rt = R/(Rp*rt);
    
    //sw_sals
    float a0 =  0.0080;
    float a1 = -0.1692;
    float a2 = 25.3851;
    float a3 = 14.0941;
    float a4 = -7.0261;
    float a5 =  2.7081;
    
    float b0 =  0.0005;
    float b1 = -0.0056;
    float b2 = -0.0066;
    float b3 = -0.0375;
    float b4 =  0.0636;
    float b5 = -0.0144;
    
    float k  =  0.0162;
    
    float Rtx   = sqrt(Rt);
    float del_T = T - 15;
    float del_S = (del_T/(1+k*del_T))*(b0 + (b1 + (b2+ (b3 + (b4 + b5*Rtx)*Rtx)*Rtx)*Rtx)*Rtx);
    
    float S = a0 + (a1 + (a2 + (a3 + (a4 + a5*Rtx)*Rtx)*Rtx)*Rtx)*Rtx;
    
    S = S + del_S;
    
    return S;
}
#define CKS_len 5   // 5 = *<ck1><ck2>\r\n
#define CTDlen 114

uint32_t hex2int(char *hex)
{
    uint32_t val = 0;
    while (*hex)
    {
        uint8_t byte = *hex++;
        if (byte >= '0' && byte <= '9') byte = byte - '0';
        else if (byte >= 'a' && byte <= 'f') byte = byte - 'a' + 10;
        else if (byte >= 'A' && byte <= 'F') byte = byte - 'A' + 10;
        val = (val << 4) | (byte & 0xf);
    }
    return val;
}
// take the string with the
uint32_t hex2int_n(char *hex, uint32_t numChar)
{
    uint32_t val = 0;
    int i =0;
    for (i =0; i< numChar; i++)
    {
        uint8_t byte = *hex++;
        if (byte >= '0' && byte <= '9') byte = byte - '0';
        else if (byte >= 'a' && byte <= 'f') byte = byte - 'a' + 10;
        else if (byte >= 'A' && byte <= 'F') byte = byte - 'A' + 10;
        val = (val << 4) | (byte & 0xf);
    }
    return val;
}


enum acq_state {start_som=0,find_sync=1, id_tag};



/*
 ** Function Name: Boolean FishCTD_AcquireData(FishCTDStructPtr fishCTDPtr)
 ** Purpose: Acquire CTD's data: find a sync and get the whole packet (CTD has a fixed length)
 */
// change the algorithm: read all data: CTD, efe & volt and save all of them into the file with the current timestamp
// $VOLT000000000000d965,11767*03
// $EFE000000000000d991,0938,0000,0000.... binary data...
// $SBE49000000000000d891,0075,0000000000000000d84c055D6609E7B2080D724DD6
// 000000000000d889055D6609E7B2080D724DD7
// "$S49000000000000d909,0075,0000000000000000d8c5055D6609E7B2080D724DD8\r\n000000000000d903055D6609E7B2080D724DD9\r\n*42\r\n";
//            16        1 4  1    16                                     28
// find the sync = '$' instead of \r\n
// case 'search_sync': find the sync: '$'
// case 'id_tag': after get the '$', find the identify the tag
//          if = '$S49' (little endian)
//          case '$EFE'
//          case '$VOL'
//          if not: go back to the case 'search_sync' to find the sync '$'
// case 'acq_packet': read the whole fix-leghth packet (with the size of the packet:
// SBE (size = 119) = (tag: 4=1($)+3(TAG_id)) (header:22=2+16+1+4+1)+(data: 88 = 16(st)+28)*2, EFE = ...)
//(size after $S49)SBE = (header:16+1+4+1)+(16(time stamp)+28)*2 : header is fixed, 16(st): fix, 28(sbe_output_format), 2(sbe_numelemt_record)
// EFE's size = look at the document
// VOLT's size =
//                      after reading data, check a valid packet by checking the last 3 characters: "*"
//      if not get "*" -> log to lost the sync, and go back case 'search_sync'
//      if get "*ck" -> check the checksum to define the packet is valid:
//      if it's succeed => valid packet, get host timestamp, store raw packet with the host timestamp into the file
//      if not succeed => report the error packet,
// '$host_timestamp'+'data'
//  example: "$HTS...(16chars)\r\n$EFE...."
//           "$HTS...(16chars)\r\n$S49...."
//           "$HTS...(16chars)\r\n$ALT...."
//           "$HTS...(16chars)\r\n$VOL...."

// use enum for acquistion state machine - mnbui Mar 6, 2021
// for now, we parsing CTD's data - mnbui mar 6, 2021
//char CTD_str[1024] = "\0"; // for saving one temporary CTD data during the run
//char data_str[MAX_LENGTH] = "\0";
//char data_str[MAX_DATA_LENGTH] = "\0";
//int data_length = 0;
//char str_tag[5]="\0";
/*************************************************************************************************
 * 2021 06 21 San this is a shim to make sure data is coming properly
 */
int acq_package_header_f(fish_ctd_ptr_t, char* , uint32_t *);
int acq_package_wo_data_f(fish_ctd_ptr_t, char* , uint32_t *);
int acq_package_w_data_f(fish_ctd_ptr_t, char* , uint32_t *);

int acq_package_header_f(fish_ctd_ptr_t som_acq_ptr, char* data_str, uint32_t * data_length){
    ssize_t    numBytes = 0;    // Number of bytes read or written
    char *dataStrPtr;
    //    char timeStr[125] = "\0";
    int indx = 0;
    char *tempStrPtr = NULL;
    int payloadSize = 0;
    static char str_tag[5]="\0";
    dataStrPtr = &data_str[DATA_TAG_SIZE]; // TAG_SIZE = 5 : $EFE3
    som_acq_ptr->SerialPort4CTD.reqReadSize = DATA_HEADER_SIZE-DATA_TAG_SIZE;//HEADER_SIZE = 32;
    // set VMIN to EFE_LENGTH bytes for serial port
    som_acq_ptr->SerialPort4CTD.spOptions.c_cc[ VMIN ] = (cc_t)som_acq_ptr->SerialPort4CTD.reqReadSize;
    if (tcsetattr(som_acq_ptr->SerialPort4CTD.spd, TCSANOW, &som_acq_ptr->SerialPort4CTD.spOptions) == -1)
    {
        printf("Error setting tty attributes %s(%d).\n",
               strerror(errno), errno);
        return -1;
    }
    // read the header
    numBytes = read(som_acq_ptr->SerialPort4CTD.spd, dataStrPtr, som_acq_ptr->SerialPort4CTD.reqReadSize);
    if (numBytes < 0){
        printf("Error reading id TAG from serial port at phase 1 - %s(%d).\n",    strerror(errno), errno);
        return -1;
    }
    // check the header's checksum, if succeed -> read the payload
    if (numBytes<1)
    {
        return -1;
    }
    // calculate the header checksum and compare with the checksum in the header
    if (!CheckCksumData(data_str, DATA_HEADER_SIZE, CKS_HEADER_LEN))
    {
        memcpy(str_tag,data_str+1,4);
        printf("$SOM_ACQ_%s: fail to check the header's checksum: %s\n",str_tag,data_str);
        return -1;
    }
    
    // if checksum is correct, get payload size
    indx = DATA_TAG_SIZE + TIMESTAMP_LEN;
    tempStrPtr = &data_str[indx];
    payloadSize = HexToInt_n(tempStrPtr,NUM_SAMPLE_LEN);
    
    //ALB add the checksum length to the payload size.
    payloadSize += CKS_DATA_LEN;
    *data_length= DATA_HEADER_SIZE + payloadSize;
    
    //acquire efe data: set the dataPtr after header
    som_acq_ptr->SerialPort4CTD.reqReadSize = payloadSize;//data len;
    return 0;
}
int acq_package_w_data_f(fish_ctd_ptr_t som_acq_ptr, char* data_str, uint32_t * data_length){
    ssize_t    numBytes = 0;    // Number of bytes read or written
    char *dataStrPtr;
    //    char timeStr[125] = "\0";
    int payloadSize;
    int reqReadSize;
    int status = 0;
    static char str_tag[5]="\0";

    status = acq_package_header_f(som_acq_ptr, data_str, data_length);
//    printf("data_length: %u\r\n",*data_length);
    if(status != 0)
        return -1;
    payloadSize = som_acq_ptr->SerialPort4CTD.reqReadSize;
    // set VMIN to CTD_LENGTH bytes for serial port
//    som_acq_ptr->SerialPort4CTD.spOptions.c_cc[ VMIN ] = payloadSize;//>255 ? 255:(cc_t)payloadSize;
    som_acq_ptr->SerialPort4CTD.spOptions.c_cc[ VMIN ] = payloadSize>255 ? 255:(cc_t)payloadSize;
    if (tcsetattr(som_acq_ptr->SerialPort4CTD.spd, TCSANOW, &som_acq_ptr->SerialPort4CTD.spOptions) == -1)
    {
        printf("Error setting tty attributes %s(%d).\n",
               strerror(errno), errno);
        return -1;
    }
    // read the data
    dataStrPtr = &data_str[DATA_HEADER_SIZE]; // HEADER_SIZE = 32  $EFE3000000000029c0ce00000366*26
    reqReadSize=som_acq_ptr->SerialPort4CTD.reqReadSize;
    // since EFE's data is binary, it need to read all bytes until reqReadSize=0
    int totalnumbytes=0;
    while(reqReadSize>0 && som_acq_ptr->Done==0)
    {
//        som_acq_ptr->SerialPort4CTD.spOptions.c_cc[ VMIN ] = reqReadSize;//>255 ? 255:(cc_t)payloadSize;
        som_acq_ptr->SerialPort4CTD.spOptions.c_cc[ VMIN ] = reqReadSize>255 ? 255:(cc_t)reqReadSize;
        if (tcsetattr(som_acq_ptr->SerialPort4CTD.spd, TCSANOW, &som_acq_ptr->SerialPort4CTD.spOptions) == -1)
        {
            printf("Error setting tty attributes %s(%d).\n",
                   strerror(errno), errno);
            return -1;
        }
        numBytes = read(som_acq_ptr->SerialPort4CTD.spd, dataStrPtr, reqReadSize);//try to readE
        if (numBytes<0)
        {
            printf("Error reading data from serial port at phase 1 - %s(%d).\n",    strerror(errno), errno);
            printf("wait for more data?.\n");
//            return -1;
        }
        else
        {
            // update reqReadsize
            dataStrPtr+=numBytes;
            reqReadSize-=numBytes;
            totalnumbytes+=numBytes;
        }
    }//end while(reqReadSize>0)
    
    // come back the beginning of the data for calculate data checksum
    dataStrPtr = &data_str[DATA_HEADER_SIZE];
    if (CheckCksumData(dataStrPtr, payloadSize, STAR_INDX))
    {
        memcpy(str_tag,data_str+1,4);
        printf("$SOM_ACQ_%s: success check data checksum.\n",str_tag);
        return 0;
    }
    else{
        memcpy(str_tag,data_str+1,4);
        data_str[32] = '\0';
        printf("$SOM_ACQ_%s: fail checksum: %s\n",str_tag,data_str);
        return -1;
    }
    return 0;
}
int acq_package_wo_data_f(fish_ctd_ptr_t som_acq_ptr, char* data_str, uint32_t * data_length)
{
    int status = acq_package_header_f(som_acq_ptr,data_str,data_length);
    if(status != 0)
        return -1;
    *data_length = DATA_HEADER_SIZE;
    // adding carriage return and newline to record
    data_str[(*data_length)++] = '\r';
    data_str[(*data_length)++] = '\n';
    return 0;
}

Boolean FishCTD_AcquireData(fish_ctd_ptr_t fishCTDPtr)
{
    
    //    char	*buffPtr;	// Current char in buffer
    //   char data_str[MAX_LENGTH] = "\0";
    //    char dataStr[MAX_LENGTH] = "\0";
    //    char tstr1[MAX_LENGTH] = "\0";
    ssize_t	numBytes = 0;	// Number of bytes read or written
    //    ssize_t total_numBytes = 0; //ALB
    int indx;
    static struct timezone timez, *timez_ptr;
    //    int local = 1;
    char timeStr[125] = "\0";
    static time_t timeInHundredsecs;
    static struct timeval UnixTime;
    //    int val = 0;
    //    int rate = 0; // addding rate for display - MNB Jun 16, 2011
    // time_t offsetTime;
    //    uint32_t tag_inLittle = 0;
    
    //    char ctdStr_local[1024] = "$SBE49000000000000d909,0075,0000000000000000d8c5055D6609E7B2080D724DD8000000000000d903055D6609E7B2080D724DD9*42";
    //    char strTemp[1024] = "\0";
    //    int cksum = 0;
    //    int i = 0;
    //    char *data_strPtr = CTD_str;
    static char data_str[MAX_DATA_LENGTH] = "\0";
    static uint32_t data_length = 0;
    char *data_str_ptr = data_str;
    //    uint32_t received_checksum = 0;
    //    char *alti_dataPtr = alti_str;
    //    char AltiDataStr[MAX_LENGTH] = "\0";
    //    int local_reqReadSize=0;
    static char str_tag[5]="\0";
    int status;

        uint32_t delay=0xFFFFFF;
        struct timeval timev, *timev_ptr;
        time_t timevalue;
        static char som_cmd[MAX_DATA_LENGTH] = "\0";

    //   fishCTDPtr->CTDPhase = find_sync;
    
    // initialize buffPtr
    //  buffPtr = data_str;
    switch (fishCTDPtr->CTDPhase)
    {
        // start the som with sending som.start
        case start_som:   // find a sync = '$'

            while (delay>0){
                delay--;
            }
            delay=0xFFFF;
            timev_ptr = &timev;
            timez_ptr = &timez;

            gettimeofday(timev_ptr, timez_ptr);
            timevalue = timev_ptr->tv_sec;
            fprintf(stdout, "time.set %u\r\n",(uint32_t) timevalue);
            sprintf(som_cmd,"time.set %u\r\n",(uint32_t) timevalue);
            if (strcmp(fishCTDPtr->CTDPortName,fishCTDPtr->CommandPortName)!=0){
                numBytes = write(fishCTDPtr->SerialPort4Command.spd, som_cmd, strlen(som_cmd));
            }else{
                numBytes = write(fishCTDPtr->SerialPort4CTD.spd, som_cmd, strlen(som_cmd));
            }
            while (delay>0){
                delay--;
            }
            delay=0xFFFF;


            fprintf(stdout, "som.telemetry\r\n");
            sprintf(som_cmd,"som.telemetry\r\n");
            if (strcmp(fishCTDPtr->CTDPortName,fishCTDPtr->CommandPortName)!=0){
                numBytes = write(fishCTDPtr->SerialPort4Command.spd, som_cmd, strlen(som_cmd));
            }else{
                numBytes = write(fishCTDPtr->SerialPort4CTD.spd, som_cmd, strlen(som_cmd));
            }
            while (delay>0){
                delay--;
            }
            delay=0xFFFF;

            

//            status = acq_package_w_data_f(fishCTDPtr,data_str,&data_length);


            if (strcmp(fishCTDPtr->fish_flag,"EPSI")==0){


                fprintf(stdout, "som.epsi\r\n");
                sprintf(som_cmd,"som.epsi\r\n");
                if (strcmp(fishCTDPtr->CTDPortName,fishCTDPtr->CommandPortName)!=0){
                    numBytes = write(fishCTDPtr->SerialPort4Command.spd, som_cmd, strlen(som_cmd));
                }else{
                    numBytes = write(fishCTDPtr->SerialPort4CTD.spd, som_cmd, strlen(som_cmd));
                }
                while (delay>0){
                    delay--;
                }
                delay=0xFFFFF;


            }else if(strcmp(fishCTDPtr->fish_flag,"FCTD")==0){
                fprintf(stdout, "som.fctd\r\n");
                sprintf(som_cmd,"som.fctd\r\n");
                if (strcmp(fishCTDPtr->CTDPortName,fishCTDPtr->CommandPortName)!=0){
                    numBytes = write(fishCTDPtr->SerialPort4Command.spd, som_cmd, strlen(som_cmd));
                }else{
                    numBytes = write(fishCTDPtr->SerialPort4CTD.spd, som_cmd, strlen(som_cmd));
                }
                while (delay>0){
                    delay--;
                }
                delay=0xFFFFF;

            }
            
            fprintf(stdout, "settings.mission %s %s\r\n",fishCTDPtr->experiment,fishCTDPtr->vehicle);
            sprintf(som_cmd, "settings.mission");
            if (strcmp(fishCTDPtr->CTDPortName,fishCTDPtr->CommandPortName)!=0){
                numBytes = write(fishCTDPtr->SerialPort4Command.spd, som_cmd, strlen(som_cmd));
            }else{
                numBytes = write(fishCTDPtr->SerialPort4CTD.spd, som_cmd, strlen(som_cmd));
            }

            while (delay>0){
                delay--;
            }
            delay=0xFFFFF;

            sprintf(som_cmd, " %s",fishCTDPtr->experiment);
            if (strcmp(fishCTDPtr->CTDPortName,fishCTDPtr->CommandPortName)!=0){
                numBytes = write(fishCTDPtr->SerialPort4Command.spd, som_cmd, strlen(som_cmd));
            }else{
                numBytes = write(fishCTDPtr->SerialPort4CTD.spd, som_cmd, strlen(som_cmd));
            }

            while (delay>0){
                delay--;
            }
            delay=0xFFFFF;

            sprintf(som_cmd, " %s\r\n",fishCTDPtr->vehicle);
            if (strcmp(fishCTDPtr->CTDPortName,fishCTDPtr->CommandPortName)!=0){
                numBytes = write(fishCTDPtr->SerialPort4Command.spd, som_cmd, strlen(som_cmd));
            }else{
                numBytes = write(fishCTDPtr->SerialPort4CTD.spd, som_cmd, strlen(som_cmd));
            }

            while (delay>0){
                delay--;
            }
            delay=0xFFFFF;

            
            fprintf(stdout, "som.start\r\n");
            sprintf(som_cmd,"som.start\r\n");
            if (strcmp(fishCTDPtr->CTDPortName,fishCTDPtr->CommandPortName)!=0){
                numBytes = write(fishCTDPtr->SerialPort4Command.spd, som_cmd, strlen(som_cmd));
            }else{
                numBytes = write(fishCTDPtr->SerialPort4CTD.spd, som_cmd, strlen(som_cmd));
            }

            while (delay>0){
                delay--;
            }
            delay=0xFFFF;

            //ALB releasing the Command port so we can set actuator from python on another terminal
            //ALB I need to reopen it when we do som.stop.
            if (strcmp(fishCTDPtr->CTDPortName,fishCTDPtr->CommandPortName)!=0){
                fprintf(stdout, "Closing Command port.\n");
                RealeaseSPRead(&fishCTDPtr->SerialPort4Command);
            }

            
            fishCTDPtr->CTDPhase = find_sync;
            break;


            // find the '$' as a sync, if found it, go to the phase find the id_tag
        case find_sync:   // find a sync = '$'
            //             printf("$SOM_DB: in phase find a sync...\n");
            
            
            fishCTDPtr->SerialPort4CTD.reqReadSize = 1;
            // set VMIN 1 byte for serial port
            fishCTDPtr->SerialPort4CTD.spOptions.c_cc[ VMIN ] = 1;
            if (tcsetattr(fishCTDPtr->SerialPort4CTD.spd, TCSANOW, &fishCTDPtr->SerialPort4CTD.spOptions) == -1)
            {
                printf("Error setting tty attributes %s(%d).\n",
                       strerror(errno), errno);
                return false;
            }
            if(fishCTDPtr->SerialPort4CTD.spd)
            {
                //                    printf("$SOM_DB: in phase find a sync: read a sync...\n");
                numBytes = read(fishCTDPtr->SerialPort4CTD.spd, data_str_ptr, fishCTDPtr->SerialPort4CTD.reqReadSize);
            }
            if (numBytes == -1)
            {
                printf("Error reading sync from serial port at phase 1 - %s(%d).\n",
                       strerror(errno), errno);
                // put into the log
                //               return false;
            }
            if(numBytes>0)  // get byte of data
            {
                //                    printf("get: %s\n",dataStrPtr);//mnbuiDB
                if (data_str_ptr[0]=='$')  // found the sync '$' -> read 4 more bytes
                {
                    // san 2021 06 21 got to get time when find the first of package
                    // get the local time
                    timeInHundredsecs = Get_Time_In_Hundred_Secs(timeStr,0);
                    // get the time
                    gettimeofday(&UnixTime, &timez);   // get number of seconds from Jan 1, 1970
                    fishCTDPtr->CTDPhase = id_tag;
                    
                }
                
            }
            
            break;
            // phase id_tag: get the three ID_tag characters after success finding the '$' sync
            // if success -> read the whole CTD's string with CTD_length
        case id_tag:   // find the type of the string base on the id_tag
            // set the bytes to read
            fishCTDPtr->SerialPort4CTD.reqReadSize = DATA_TAG_SIZE-1;//TAG_SIZE = 4;
            // set VMIN to CTD_LENGTH bytes for serial port
            fishCTDPtr->SerialPort4CTD.spOptions.c_cc[ VMIN ] = DATA_TAG_SIZE-1;
            if (tcsetattr(fishCTDPtr->SerialPort4CTD.spd, TCSANOW, &fishCTDPtr->SerialPort4CTD.spOptions) == -1)
            {
                printf("Error setting tty attributes %s(%d).\n",
                       strerror(errno), errno);
                return false;
            }
            data_str_ptr = &data_str[1];
            // read the tag
            numBytes = read(fishCTDPtr->SerialPort4CTD.spd, data_str_ptr, fishCTDPtr->SerialPort4CTD.reqReadSize);//try to read tagsize=3
            if (numBytes == -1)
            {
                printf("Error reading id TAG from serial port at phase 1 - %s(%d).\n",    strerror(errno), errno);
                break;
            }
            else if (numBytes>0)  // after this susseed reading, we have TAG_str = "$TAG"
            {
                /***********************************************************************
                 * San 2021 06 21 - simplified to two types of packages
                 *  one with header and data packages
                 *  one with header only, where the second number after the time is
                 *  data instead of package size
                 ***********************************************************************/
                *(uint32_t *)&str_tag=*(uint32_t*)data_str_ptr;
                switch (*(uint32_t*)data_str_ptr)    // since TAG_str is a char pointer, it need to cast to uint and we use      and we use '*' to see its value
                {
                    case '94BS': // actual TAG = 'SBE49', since sbe is little endian, we have to use '94BS'
                    case '3EFE':// actual TAG = 'EFE3', since sbe is little endian, we have to use '3EFE'
                    case '4EFE':// actual TAG = 'EFE4', since sbe is little endian, we have to use '4EFE'
                    case '14BS': // actual TAG = 'SB41', we have to read '14BS'
                    case 'VANV': // actual TAG = 'VNAV', we have to read 'VANV'
                    case '3MOS': // actual TAG = 'SOM3', we have to read '3MOS'
                    case 'MGES': // actual TAG = 'SEGM', we have to read 'MGES'
                    case 'CEPS': // actual TAG = 'SPEC', we have to read 'CEPS'
                    case 'SGVA': // actual TAG = 'AVGS', we have to read 'SGVA'
                    case 'ETAR': // actual TAG = 'RATE', we have to read 'ETAR'
                    case '0FPA': // actual TAG = 'APF0', we have to read '0FPA'
                    case '1FPA': // actual TAG = 'APF1', we have to read '1FPA'
                    case '2FPA': // actual TAG = 'APF2', we have to read '2FPA'
                    case '1VTT': // actual TAG = 'TTVP', we have to read 'PVTT'
                    case 'PVTT': // actual TAG = 'TTVP', we have to read 'PVTT'
                    case 'POCE': // actual TAG = 'ECOP', we have to read 'POCE'
                    case 'PASI': // actual TAG = 'APF0', we have to read 'ISAP' for ISA500 altimeter
                    case 'LACD': // actual TAG = 'APF0', we have to read 'DCAL' for ISA500 altimeter
                        status = acq_package_w_data_f(fishCTDPtr,data_str,&data_length);
                        
                        if(status != 0){
                            data_str[32] = '\0';
                            printf("$SOM_ACQ_%s: failed acq_package_w_data_f %s data: %32s\n",str_tag,str_tag,data_str);
                            break;
//                            fishCTDPtr->CTDPhase = find_sync;
//                            return 0;
                        }
                        if(*(uint32_t*)data_str_ptr=='3MOS'){
                          //test
                            memcpy(&fishCTDPtr->FastCTDSetup.ctd_coeff.strcal,"$",1);
                            memcpy(&fishCTDPtr->settings[1],(uint8_t*)&data_str,data_length);
                            fishCTDPtr->settings_length=data_length+1;
                        }
                        if(*(uint32_t*)data_str_ptr=='LACD'){
                          //test
                            memcpy(&fishCTDPtr->FastCTDSetup.ctd_coeff.strcal,"$",1);
                            memcpy(&fishCTDPtr->FastCTDSetup.ctd_coeff.strcal[1],(uint8_t*)&data_str,data_length);
                            fishCTDPtr->FastCTDSetup.ctd_coeff.strcal_length=data_length+1;

                                                                            
                        }
                        if((*(uint32_t*)data_str_ptr=='4EFE') |
                           (*(uint32_t*)data_str_ptr=='3EFE'))
                        {
                            uint8_t *tmp_data_ptr = (uint8_t*)&data_str[DATA_HEADER_SIZE];
                            
                            uint64_t time = *(uint64_t*)tmp_data_ptr; //little endian LSB
//                                (((uint64_t)(*tmp_data_ptr))<<0)+
//                                (((uint64_t)(*(tmp_data_ptr+1)))<<8)+
//                                (((uint64_t)(*(tmp_data_ptr+2)))<<16)+
//                                (((uint64_t)(*(tmp_data_ptr+3)))<<24)+
//                                (((uint64_t)(*(tmp_data_ptr+4)))<<32)+
//                                (((uint64_t)(*(tmp_data_ptr+5)))<<40)+
//                                (((uint64_t)(*(tmp_data_ptr+6)))<<48)+
//                                (((uint64_t)(*(tmp_data_ptr+7)))<<56);
                            tmp_data_ptr += 8;
                            uint32_t c1 = (((uint32_t)(*tmp_data_ptr))<<16) + (((uint32_t)(*(tmp_data_ptr+1)))<<8) + ((uint32_t)(*(tmp_data_ptr+2)));
                            tmp_data_ptr += 3;
                            uint32_t c2 = (((uint32_t)(*tmp_data_ptr))<<16) + (((uint32_t)(*(tmp_data_ptr+1)))<<8) + ((uint32_t)(*(tmp_data_ptr+2)));
                            tmp_data_ptr += 3;
                            uint32_t c3 = (((uint32_t)(*tmp_data_ptr))<<16) + (((uint32_t)(*(tmp_data_ptr+1)))<<8) + ((uint32_t)(*(tmp_data_ptr+2)));
                            tmp_data_ptr += 3;
                            uint32_t c4 = (((uint32_t)(*tmp_data_ptr))<<16) + (((uint32_t)(*(tmp_data_ptr+1)))<<8) + ((uint32_t)(*(tmp_data_ptr+2)));
                            tmp_data_ptr += 3;
                            uint32_t c5 = (((uint32_t)(*tmp_data_ptr))<<16) + (((uint32_t)(*(tmp_data_ptr+1)))<<8) + ((uint32_t)(*(tmp_data_ptr+2)));
                            tmp_data_ptr += 3;
                            uint32_t c6 = (((uint32_t)(*tmp_data_ptr))<<16) + (((uint32_t)(*(tmp_data_ptr+1)))<<8) + ((uint32_t)(*(tmp_data_ptr+2)));
                            tmp_data_ptr += 3;
                            uint32_t c7 = (((uint32_t)(*tmp_data_ptr))<<16) + (((uint32_t)(*(tmp_data_ptr+1)))<<8) + ((uint32_t)(*(tmp_data_ptr+2)));
                            printf("time:%016llx c1: %08x c2: %08x c3: %08x c4: %08x c5: %08x c6: %08x c7: %08x\r\n",time,c1,c2,c3,c4,c5,c6,c7);
                        }
                        
                        
                        // 3. ***** Saving data in the string, so can save in the file
                        
                        indx = fishCTDPtr->SOM_Write2BufferIndx%MAX_CIRBUFF;
                        // if we want to attach the host time, attach here....
                        memcpy(fishCTDPtr->som_cir_buff[indx].data_str,data_str,data_length);
                        fishCTDPtr->som_cir_buff[indx].data_length = data_length;
                        
                        // get the time
                        fishCTDPtr->som_cir_buff[indx].UnixTime = UnixTime;
                        fishCTDPtr->som_cir_buff[indx].timeInHundredsecs = timeInHundredsecs;
                        
                        fishCTDPtr->som_cir_buff[indx].doneRead = 1;
                        fishCTDPtr->SOM_Write2BufferIndx++; // increment the write count
                        
                        if(*(uint32_t*)data_str_ptr=='94BS'){
                            memcpy(fishCTDPtr->ctd_cir_buff[indx].DataStr,data_str,data_length);
                            fishCTDPtr->ctd_cir_buff[indx].data_length = data_length;
                            // get the time
                            fishCTDPtr->ctd_cir_buff[indx].UnixTime = UnixTime;
                            fishCTDPtr->ctd_cir_buff[indx].timeInHundredsecs = timeInHundredsecs;
                            
                            fishCTDPtr->ctd_cir_buff[indx].ParseDone = FALSE;
                            fishCTDPtr->ctd_cir_buff[indx].in_use = 0;
                            parse_ctd_data_2_f(fishCTDPtr,&fishCTDPtr->ctd_cir_buff[indx]);
                            fishCTDPtr->ctd_PackCnt++;  // update the packet Fish CTD count
                            fishCTDPtr->CTD_Write2BufferIndx++; // increment the write count
                        }
//                        data_str[32] = '\0';
                        if(*(uint32_t*)data_str_ptr=='PASI'){
                            //SN 20210318 the number is in decimal instead of hex
                            char alt_str[10];
                            strncpy(alt_str,data_str+55,7);
                            fishCTDPtr->AltCirBuff[indx].altimeter_time = atof(alt_str)/1500.0*1.0e6; /* in microseconds*/
                            //SN 20210318 commented out the line below because the number is in decimal instead of hex
                            //                                fishCTDPtr->AltCirBuff[indx].AltTime = hex2int_n(data_str+ALT_HEX_STR_POS,4)*1.0;
                            fishCTDPtr->LatestAltTime = fishCTDPtr->AltCirBuff[indx].altimeter_time;
                        }

                        break;   //end of case 'SB49' & 'SBE41'
                    case 'UTCA':  // "$ACTU" // San 2021 06 21
                    case 'TLOV':  // "$VOLT" // San 2021 06 21
                        // these do not have payload, so we only get the header
                        status = acq_package_wo_data_f(fishCTDPtr,data_str,&data_length);
                        if(status != 0){
                            data_str[32] = '\0';
                            printf("$SOM_ACQ_%s: failed acq_package_w_data_f %s data: %32s\n",str_tag,str_tag,data_str);
                            fishCTDPtr->CTDPhase = find_sync;
                            return 0;
                        }
                        // 3. ***** Saving data in the string, so can save in the file
                        
                        indx = fishCTDPtr->SOM_Write2BufferIndx%MAX_CIRBUFF;
                        // if we want to attach the host time, attach here....
                        memcpy(fishCTDPtr->som_cir_buff[indx].data_str,data_str,data_length);
                        fishCTDPtr->som_cir_buff[indx].data_length = data_length;
                        
                        // get the time
                        fishCTDPtr->som_cir_buff[indx].UnixTime = UnixTime;
                        fishCTDPtr->som_cir_buff[indx].timeInHundredsecs = timeInHundredsecs;
                        
                        fishCTDPtr->som_cir_buff[indx].doneRead = 1;
                        fishCTDPtr->SOM_Write2BufferIndx++; // increment the write count
                        
                        data_str[32] = '\0';
                        printf("$SOM_ACQ_%s: success read/write %s data: %32s\n",str_tag,str_tag,data_str);
                        break;
                        // since the system is little endian, the word is inversed.
                    case 'ITLA': // actual TAG = '$ALT', since sbe is little endian, we have to use 'TLA$'
                        // Altimeter does not have payload, so we only get the header
                        status = acq_package_wo_data_f(fishCTDPtr,data_str,&data_length);
                        if(status != 0){
                            data_str[32] = '\0';
                            printf("$SOM_ACQ_%s: failed acq_package_w_data_f %s data: %32s\n",str_tag,str_tag,data_str);
                            fishCTDPtr->CTDPhase = find_sync;
                            return 0;
                        }
                        // 3. ***** Saving data in the string, so can save in the file
                        
                        indx = fishCTDPtr->SOM_Write2BufferIndx%MAX_CIRBUFF;
                        // if we want to attach the host time, attach here....
                        strncpy(fishCTDPtr->som_cir_buff[indx].data_str,data_str,data_length);
                        fishCTDPtr->som_cir_buff[indx].data_length = data_length;
                        
                        // get the time
                        fishCTDPtr->som_cir_buff[indx].UnixTime = UnixTime;
                        fishCTDPtr->som_cir_buff[indx].timeInHundredsecs = timeInHundredsecs;
                        
                        fishCTDPtr->som_cir_buff[indx].doneRead = 1;
                        fishCTDPtr->SOM_Write2BufferIndx++; // increment the write count
                        
                        //SN 20210318 the number is in decimal instead of hex
                        char alt_str[10];
                        strncpy(alt_str,data_str+ALT_HEX_STR_POS,8);
                        /* this is commented out so that the ALTI is not fighting the ISA500 data
                        fishCTDPtr->AltCirBuff[indx].altimeter_time = atof(alt_str)*10.0; // time in "ten micro seconds" to time in microseconds
                        //SN 20210318 commented out the line below because the number is in decimal instead of hex
                        //                                fishCTDPtr->AltCirBuff[indx].AltTime = hex2int_n(data_str+ALT_HEX_STR_POS,4)*1.0;
                        fishCTDPtr->LatestAltTime = fishCTDPtr->AltCirBuff[indx].altimeter_time;
                         */
//
//                        data_str[32] = '\0';
                        
                        break;   // end of 'ALTI' case
                    default:    // not the tag's type, go back to find a sync '$'
                        fishCTDPtr->CTDPhase = find_sync;
                        break;
                }
                fishCTDPtr->CTDPhase = find_sync;
            }   // end of if (numBytes>0):reading success
            fishCTDPtr->CTDPhase = find_sync;
            break;  // end of case id_tag:
    }
    return true;
}


/*
 ** Function Name: int GetFishCTDCal(CTDCoeffStructPtr coeffFishCTDPtr)
 ** Purpose: Read CTD calibration file
 */
int GetFishCTDCal(ctd_coeff_ptr_t coeffFishCTDPtr, char* calFileName)
{
    FILE* fp = NULL;
    char* sep = "= ";
    char confstr[MAX_LENGTH] = "\0";
    char *strPtr;
    
    //char cwd[256], pcwd[256], filename[256];
    //char *cwdPtr;
    
    int total_line = 0;
    
//    if ((cwdPtr=getcwd(cwd, 256)) == NULL)
//    {
//        perror("getcwd() error");
//        return 0;
//    }
//    // get its parent directory
//    get_path_f(cwd, pcwd);
//    sprintf(filename,"%s/%s",cwd,calFileName);
    fprintf(stdout,"Reading Cal file %s\n",calFileName);
    
    fp = fopen(calFileName,"r");
    if(fp==NULL){
        printf("Could not open the calibration file for fish\n");
        return 0;
    }
    
    while(fget_str_f(confstr,sizeof(confstr),fp))
    {
        if (confstr[0]=='\0') break;
        total_line++;
        
        strPtr = strtok(confstr,sep);
        
        if(*strPtr=='S')
        {
            strPtr = strtok(NULL,sep);
            strcpy(coeffFishCTDPtr->serialnum,strPtr);
        }
        else if (*strPtr=='T')
        {
            if(!strcmp("TCALDATE",strPtr))
            {
                strPtr = strtok(NULL,sep);
                strcpy(coeffFishCTDPtr->tcalDate,strPtr);
            }
            else if(!strcmp("TA0",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->ta0 = atof(strPtr);
            }
            else if(!strcmp("TA1",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->ta1 = atof(strPtr);
            }
            else if(!strcmp("TA2",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->ta2 = atof(strPtr);
            }
            else // if(!strcmp("TA3",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->ta3 = atof(strPtr);
            }
        }
        else if (*strPtr=='C')
        {
            if(!strcmp("CCALDATE",strPtr))
            {
                strPtr = strtok(NULL,sep);
                strcpy(coeffFishCTDPtr->tcalDate,strPtr);
            }
            else if(!strcmp("CG",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->cg = atof(strPtr);
            }
            else if(!strcmp("CH",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->ch = atof(strPtr);
            }
            else if(!strcmp("CI",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->ci = atof(strPtr);
            }
            else if(!strcmp("CJ",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->cj = atof(strPtr);
            }
            else if(!strcmp("CG",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->cg = atof(strPtr);
            }
            else if(!strcmp("CTCOR",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->ctcor = atof(strPtr);
            }
            else //if(!strcmp("CPCOR",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->cpcor = atof(strPtr);
            }
        }
        else if (*strPtr == 'P')
        {
            if(!strcmp("PCALDATE",strPtr))
            {
                strPtr = strtok(NULL,sep);
                strcpy(coeffFishCTDPtr->pcalDate,strPtr);
            }
            else if(!strcmp("PA0",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->pa0 = atof(strPtr);
            }
            else if(!strcmp("PA1",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->pa1 = atof(strPtr);
            }
            else if(!strcmp("PA2",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->pa2 = atof(strPtr);
            }
            else if(!strcmp("PTCA0",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->ptca0 = atof(strPtr);
            }
            else if(!strcmp("PTCA1",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->ptca1 = atof(strPtr);
            }
            else if(!strcmp("PTCA2",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->ptca2 = atof(strPtr);
            }
            else if(!strcmp("PTCB0",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->ptcb0 = atof(strPtr);
            }
            else if(!strcmp("PTCB1",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->ptcb1 = atof(strPtr);
            }
            else if(!strcmp("PTCB2",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->ptcb2 = atof(strPtr);
            }
            else if(!strcmp("PTEMPA0",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->ptempa0 = atof(strPtr);
            }
            else if(!strcmp("PTEMPA1",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->ptempa1 = atof(strPtr);
            }
            else //(!strcmp("PTEMPA2",strPtr))
            {
                strPtr = strtok(NULL,sep);
                coeffFishCTDPtr->ptempa2 = atof(strPtr);
            }
        }
    }
    
    if(fp) fclose(fp);
    return total_line;
}	// end of GetFishCTDCal()


/*
 ** Function Name: int GetFishCTDCal_fromfish(CTDCoeffStructPtr coeffFishCTDPtr)
 ** Purpose: Read CTD calibration file
 */
int GetFishCTDCal_fromfish(fish_ctd_ptr_t fishCTDPtr)
{
    //char* sep = "= ";
    //char confstr[MAX_LENGTH] = "\0";
    //char *strPtr;
    //buffer for the som command
    static char som_cmd[MAX_DATA_LENGTH] = "\0";
    
    //buffer to collect the CTDcal from fish
    ssize_t    numBytes = 0;    // Number of bytes read or written
    static char data_str[MAX_DATA_LENGTH] = "\0";
    static uint32_t data_length = 0;
    char *data_str_ptr = data_str;

    int total_line = 0;
    //ALB buffer for data string coeffFishCTDPtr->strcal
    
    // get its parent directory
    fprintf(stdout,"Reading calibration coefficients from fish\n");
    
    // ALB 2024/08/20 send "sbe.real 1" command.
    // ALB it should return :
    fprintf(stdout, "sbe.real 1\r\n");
    sprintf(som_cmd,"sbe.real 1\r\n");
    
    if (strcmp(fishCTDPtr->CTDPortName,fishCTDPtr->CommandPortName)!=0){
        numBytes = write(fishCTDPtr->SerialPort4Command.spd, som_cmd, strlen(som_cmd));
    }else{
        numBytes = write(fishCTDPtr->SerialPort4CTD.spd, som_cmd, strlen(som_cmd));
    }
    
    // set the bytes to read
    fishCTDPtr->SerialPort4CTD.reqReadSize = 100-1;//TAG_SIZE = 4;
    // set VMIN to CTD_LENGTH bytes for serial port
    fishCTDPtr->SerialPort4CTD.spOptions.c_cc[ VMIN ] = 100-1;
    if (tcsetattr(fishCTDPtr->SerialPort4CTD.spd, TCSANOW, &fishCTDPtr->SerialPort4CTD.spOptions) == -1)
    {
        printf("Error setting tty attributes %s(%d).\n",
               strerror(errno), errno);
        return false;
    }
    data_str_ptr = &data_str[1];
    // read the tag
    numBytes = read(fishCTDPtr->SerialPort4CTD.spd, data_str_ptr, fishCTDPtr->SerialPort4CTD.reqReadSize);//try to read tagsize=3
    if (numBytes == -1)
    {
        printf("Error reading id TAG from serial port at phase 1 - %s(%d).\n",    strerror(errno), errno);
        return 0;
    }
    else if (numBytes>0)  // after this susseed reading, we have TAG_str = "$TAG"
    {

        //        *(uint32_t *)&str_tag=*(uint32_t*)data_str_ptr;
        data_str_ptr = &data_str[1];

        memcpy(&fishCTDPtr->settings,(uint8_t*)&data_str,data_length);
        fishCTDPtr->settings_length=data_length;

    }

    
//    while(fget_str_f(confstr,sizeof(confstr),fp))
//    {
//        if (confstr[0]=='\0') break;
//        total_line++;
//        
//        strPtr = strtok(confstr,sep);
//        
//        if(*strPtr=='S')
//        {
//            strPtr = strtok(NULL,sep);
//            strcpy(coeffFishCTDPtr->serialnum,strPtr);
//        }
//        else if (*strPtr=='T')
//        {
//            if(!strcmp("TCALDATE",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                strcpy(coeffFishCTDPtr->tcalDate,strPtr);
//            }
//            else if(!strcmp("TA0",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->ta0 = atof(strPtr);
//            }
//            else if(!strcmp("TA1",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->ta1 = atof(strPtr);
//            }
//            else if(!strcmp("TA2",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->ta2 = atof(strPtr);
//            }
//            else // if(!strcmp("TA3",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->ta3 = atof(strPtr);
//            }
//        }
//        else if (*strPtr=='C')
//        {
//            if(!strcmp("CCALDATE",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                strcpy(coeffFishCTDPtr->tcalDate,strPtr);
//            }
//            else if(!strcmp("CG",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->cg = atof(strPtr);
//            }
//            else if(!strcmp("CH",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->ch = atof(strPtr);
//            }
//            else if(!strcmp("CI",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->ci = atof(strPtr);
//            }
//            else if(!strcmp("CJ",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->cj = atof(strPtr);
//            }
//            else if(!strcmp("CG",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->cg = atof(strPtr);
//            }
//            else if(!strcmp("CTCOR",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->ctcor = atof(strPtr);
//            }
//            else //if(!strcmp("CPCOR",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->cpcor = atof(strPtr);
//            }
//        }
//        else if (*strPtr == 'P')
//        {
//            if(!strcmp("PCALDATE",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                strcpy(coeffFishCTDPtr->pcalDate,strPtr);
//            }
//            else if(!strcmp("PA0",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->pa0 = atof(strPtr);
//            }
//            else if(!strcmp("PA1",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->pa1 = atof(strPtr);
//            }
//            else if(!strcmp("PA2",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->pa2 = atof(strPtr);
//            }
//            else if(!strcmp("PTCA0",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->ptca0 = atof(strPtr);
//            }
//            else if(!strcmp("PTCA1",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->ptca1 = atof(strPtr);
//            }
//            else if(!strcmp("PTCA2",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->ptca2 = atof(strPtr);
//            }
//            else if(!strcmp("PTCB0",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->ptcb0 = atof(strPtr);
//            }
//            else if(!strcmp("PTCB1",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->ptcb1 = atof(strPtr);
//            }
//            else if(!strcmp("PTCB2",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->ptcb2 = atof(strPtr);
//            }
//            else if(!strcmp("PTEMPA0",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->ptempa0 = atof(strPtr);
//            }
//            else if(!strcmp("PTEMPA1",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->ptempa1 = atof(strPtr);
//            }
//            else //(!strcmp("PTEMPA2",strPtr))
//            {
//                strPtr = strtok(NULL,sep);
//                coeffFishCTDPtr->ptempa2 = atof(strPtr);
//            }
//        }
//    }
    //TODO close command port?
    
//    if(fp) fclose(fp);
    return total_line;
}    // end of GetFishCTDCal()



/* ALB create a function reading the calibration coef for the fish probe
 ** Function Name: int GetFishProbeCal(CTDCoeffStructPtr coeffFishCTDPtr)
 ** Purpose: Read CTD calibration file
 */
int GetFishProbeCal(probe_coeff_ptr_t coeffFishProbePtr, char* calFileName)
{
    FILE* fp = NULL;
    char* sep = ",";
    char confstr[MAX_LENGTH] = "\0";
    char *strPtr;
    
    char cwd[256], pcwd[256], filename[256];
    char *cwdPtr;
    
    int total_line = 0;
    
    if ((cwdPtr=getcwd(cwd, 256)) == NULL)
    {
        perror("getcwd() error");
        return 0;
    }
    // get its parent directory
    get_path_f(cwd, pcwd);
    sprintf(filename,"%s",calFileName);
    fprintf(stdout,"Reading Cal file %s\n",filename);
    
    fp = fopen(filename,"r");
    if(fp==NULL){
        printf("Could not open the Probe calibration file %s for fish\n",filename);
        strcpy(coeffFishProbePtr->strcal,"N/A");
        strcpy(coeffFishProbePtr->calDate,"N/A");
        coeffFishProbePtr->Sv=0;
        coeffFishProbePtr->Sv=0;
        total_line++;
        return total_line;
    }
    
    while(fget_str_f(confstr,sizeof(confstr),fp))
    {
        if (confstr[0]=='\0') 
        {
            break;
        }
        total_line++;
        if(total_line>1){
            strcpy(coeffFishProbePtr->strcal,confstr);
            strPtr = strtok(confstr,sep);
            strcpy(coeffFishProbePtr->calDate,confstr);
            strPtr = strtok(NULL,sep);
            coeffFishProbePtr->Sv=atof(strPtr);
            strPtr = strtok(NULL,sep);
            coeffFishProbePtr->Capacitance=atof(strPtr);
        }

    }

    if(fp) fclose(fp);
    return total_line;
}    // end of GetFishProbeCal()



/*
 ** Function Name: int GetFishCTDCal(CTDCoeffStructPtr coeffFishCTDPtr)
 ** Purpose: Read CTD calibration file
 */
int InitFishCTD(fish_ctd_ptr_t fishCTDPtr)
{
    char filename[256];
    //ALB 19 August 2024 add probe calibration filename
    char probe1_cal_filename[256];
    char probe2_cal_filename[256];
    char probe3_cal_filename[256];
    char probe4_cal_filename[256];
    
    int total_cal_line;
    int probe_cal_line;

    fishCTDPtr->CTDPhase = 0;   // start with phase = 0 : find a sync - mnbui 10 Mar 2021
    fishCTDPtr->Done = false;
    fishCTDPtr->CTDReqReadSize = 1;
//    fishCTDPtr->CTD_ParseIndx = 0;
    fishCTDPtr->CTD_Write2BufferIndx = 0;
    fishCTDPtr->CTD_ReadBufferIndx = 0;
    fishCTDPtr->SOM_Write2BufferIndx = 0;
    fishCTDPtr->SOM_ReadBufferIndx = 0;
    fishCTDPtr->CTD_ReadBufferIndx_2 = 0;
    sprintf(filename,"%s/%s.CAL",fishCTDPtr->CTD_cal_path,fishCTDPtr->SerialNum);

    //ALB this is where we get the cal coef for FCTD
    //ALB only ch3 and ch4 because ch1 and ch2 are temp with no calibration.

    sprintf(probe1_cal_filename,"%s/%s/Calibration_%s.txt",fishCTDPtr->FPO7_Probe_cal_path,fishCTDPtr->ch1_sn,fishCTDPtr->ch1_sn);
    sprintf(probe2_cal_filename,"%s/%s/Calibration_%s.txt",fishCTDPtr->FPO7_Probe_cal_path,fishCTDPtr->ch2_sn,fishCTDPtr->ch2_sn);
    sprintf(probe3_cal_filename,"%s/%s/Calibration_%s.txt",fishCTDPtr->shear_Probe_cal_path,fishCTDPtr->ch3_sn,fishCTDPtr->ch3_sn);
    sprintf(probe4_cal_filename,"%s/%s/Calibration_%s.txt",fishCTDPtr->shear_Probe_cal_path,fishCTDPtr->ch4_sn,fishCTDPtr->ch4_sn);
    strcpy(fishCTDPtr->FastCTDSetup.probe1_coeff.serialnum,fishCTDPtr->ch1_sn);
    strcpy(fishCTDPtr->FastCTDSetup.probe2_coeff.serialnum,fishCTDPtr->ch2_sn);
    strcpy(fishCTDPtr->FastCTDSetup.probe3_coeff.serialnum,fishCTDPtr->ch3_sn);
    strcpy(fishCTDPtr->FastCTDSetup.probe4_coeff.serialnum,fishCTDPtr->ch4_sn);

    //ALB this is where we get the cal coef for FCTD
    //ALB only ch3 and ch4 because ch1 and ch2 are temp with no calibration.
    if ((probe_cal_line=GetFishProbeCal(&fishCTDPtr->FastCTDSetup.probe1_coeff,probe1_cal_filename)) == 0) return 0;
    if ((probe_cal_line=GetFishProbeCal(&fishCTDPtr->FastCTDSetup.probe2_coeff,probe2_cal_filename)) == 0) return 0;
    if ((probe_cal_line=GetFishProbeCal(&fishCTDPtr->FastCTDSetup.probe3_coeff,probe3_cal_filename)) == 0) return 0;
    if ((probe_cal_line=GetFishProbeCal(&fishCTDPtr->FastCTDSetup.probe4_coeff,probe4_cal_filename)) == 0) return 0;
    //ALB this is where we get the cal coef for FCTD
    if ((total_cal_line=GetFishCTDCal(&fishCTDPtr->FastCTDSetup.ctd_coeff,filename)) == 0) return 0;

//    if ((total_cal_line=GetFishCTDCal_fromfish(fishCTDPtr)) == 0){
//        printf("Could not get Calibration coefficients from CTD SBE49 %s on fish\n",fishCTDPtr->SerialNum);
//    }else{
//        if ((total_cal_line=GetFishCTDCal(&fishCTDPtr->FastCTDSetup.ctd_coeff,filename)) == 0) return 0;
//    }
    
    return total_cal_line;
}

//static int LastFishIsDown = 0;
/*
 ** Function Name: ParsingFishCTD(FishCTDStructPtr FishCTDPtr)
 ** Purpose: Parse CTD's data
 ** has micro-cond:
 **      $OPGCTD055D820A889107FE5641DBEC13EC16EC12EC10EC16EC11EC14EC11EC12EC0F9F25575F83B10000026C
 **  $OPGCTD  055D82 0A8891 07FE56 41DB EC13 EC16 EC12 EC10 EC16 EC11 EC14 EC11 EC12 EC0F 9F25575F83B10000026C
 */
// CTD data: March 2021 "$S49000000000000d909,0075,0000000000000000d8c5055D6609E7B2080D724DD8\r\n000000000000d903055D6609E7B2080D724DD9\r\n*42\r\n";
//pressure (6) = hex2int_n(dataStr[position],6)
//
//  $S49 = 4
//  16(timestamp)+1(,)+4(packetlen)+1(,)+16(timestamp)+22(sbe_data)+2(\r\n)+22(sbe_data)+2(\r\n)+1(*)+2(cksum)+2(\r\n)
//  ==> CTD length = 114
// TempStr = "$S49..."
// TODO mbui 12Mar21: get the header len from the setup file
//#define HEADER_LEN 45 //4(TAG_SIZE)+16(timestamp)+1(,)+4(packetlen)+1(,)+4(elemnt skipped)+16(timestamp)
#define TCP_NUM_DIGIT 6 // see the SBE49 manual: outpuFormat = 0 (raw data in Hexadecimal)
#define PTComp_NUM_DIGIT   4 // Pressure temperature compsensation = vvvv
int parse_ctd_data_f(fish_ctd_ptr_t FishCTDPtr)
{
    int indx = 0, j,dataIndx;
    long val = 0, val2 = 0;
    long tempInDec = 0, pressInDec = 0, condInDec = 0, pressTempInDec = 0;
    //    char tstr[25] = "\0";
    int rate = 0;
    int sbe_indx = 0;
    char *strPtr = NULL;
    
    dataIndx = FishCTDPtr->CTD_ParseIndx % MAX_CIRBUFF;
    
    if ((!FishCTDPtr->ctd_cir_buff[dataIndx].ParseDone) && (FishCTDPtr->CTD_ParseIndx != FishCTDPtr->CTD_Write2BufferIndx))
    {
        FishCTDPtr->ctd_cir_buff[dataIndx].in_use = 1;
        //ADDED MNB 11Mar21:convert to  strncpy(); with fixed length of $SB490 tag
        strncpy(FishCTDPtr->ParsingStr,FishCTDPtr->ctd_cir_buff[dataIndx].DataStr,FishCTDPtr->CTDlength);
        
        // *** convert data: temp, cond, press in hex to decimal
        // skip the tag & timestamp - mnbui 11 March 2021
        sbe_indx = DATA_HEADER_SIZE+16;    //ADDED mnbui 11 March 2021: get the index of SBE's data
        // read the SBE's data and convert it into the engineer unit
        // SBE's format: ttttttccccccppppppvvvv
        // TCP_NUM_DIGIT = 6, PTComp_NUM_DIGIT = 4
        for(j=0; j<4; j++)
        {
            indx = sbe_indx + TCP_NUM_DIGIT*j;  //start at sbe data
            strPtr = FishCTDPtr->ParsingStr+indx;
            //   printf("strPtr: %d: %s",j, strPtr);
            // ADDED mnbui 12Mar2021: convert 6 or 4 characters to get temperature, cond & pressure
            if (j<3)    // for temp,cond,pressure
                val = hex2int_n(strPtr, TCP_NUM_DIGIT);
            else
                val = hex2int_n(strPtr, PTComp_NUM_DIGIT);
            switch(j)
            {
                case 0:
                    tempInDec = val;
                    // printf("temp = %ld\n",val);
                    break;
                case 1:
                    condInDec = val;
                    //  printf("cond = %ld\n",val);
                    break;
                case 2:
                    pressInDec = val;
                    break;
                case 3:
                    pressTempInDec = val;
                    break;
            }   // end of switch(j)
        }   // end of for(j=0; j<4; j++)
        
        // *** Calculate temp, press, cond with engineer unit
        FishCTDPtr->ctd_cir_buff[dataIndx].FishCTDdata.temperature = CalculateTemp(FishCTDPtr, tempInDec);
        FishCTDPtr->ctd_cir_buff[dataIndx].FishCTDdata.pressure = CalculatePress(FishCTDPtr, pressTempInDec, pressInDec);
        FishCTDPtr->ctd_cir_buff[dataIndx].FishCTDdata.conductivity
        = CalculateCond(FishCTDPtr, FishCTDPtr->ctd_cir_buff[dataIndx].FishCTDdata.temperature, FishCTDPtr->ctd_cir_buff[dataIndx].FishCTDdata.pressure, condInDec);
        // TODO mnbui 12Mar2021 - add the altimeter (global var: somehow we get from
        // FishCTDPtr->FishCTDCirBuff[dataIndx].FishCTDdata.altTime = altTime;
        FishCTDPtr->CTD_ParseIndx++;
        FishCTDPtr->ctd_cir_buff[dataIndx].ParseDone = TRUE;
        FishCTDPtr->ctd_cir_buff[dataIndx].in_use = 0;
        
        // diplay data in engineer format in engDispRate times/sec
        if (FishCTDPtr->engDispRate != 16)
        {
            rate = 16/(FishCTDPtr->engDispRate);
            val2 = indx%rate;
            //		val2 = dataIndx%4;
            if ((FishCTDPtr->printData == 1) && (val2==0))
            {
                printf("time = %lu, temp = %f, press = %f, cond = %f",
                       FishCTDPtr->ctd_cir_buff[dataIndx].timeInHundredsecs,
                       FishCTDPtr->ctd_cir_buff[dataIndx].FishCTDdata.temperature,
                       FishCTDPtr->ctd_cir_buff[dataIndx].FishCTDdata.pressure,
                       FishCTDPtr->ctd_cir_buff[dataIndx].FishCTDdata.conductivity);
                printf("\n");
            }
        }
        // for debug mode, print out everything - MNB Jun 16, 2011
        if (FishCTDPtr->printData == 2)
        {
            printf("After parsing CTD: time = %lu, temp: %ld=>%f, press: %ld=>%f, cond: %ld=>%f",FishCTDPtr->ctd_cir_buff[dataIndx].timeInHundredsecs,
                   tempInDec,FishCTDPtr->ctd_cir_buff[dataIndx].FishCTDdata.temperature,
                   pressInDec,FishCTDPtr->ctd_cir_buff[dataIndx].FishCTDdata.pressure,
                   condInDec, FishCTDPtr->ctd_cir_buff[dataIndx].FishCTDdata.conductivity);
            printf("\n");
        }
        FishCTDPtr->ctd_cir_buff[dataIndx].in_use = 0;
    }
    return 1;
}


int parse_ctd_data_2_f(fish_ctd_ptr_t FishCTDPtr, ctd_rec_ptr_t ctd_rec_ptr)
{
    int indx = 0, j;
    long val = 0, val2 = 0;
    long tempInDec = 0, pressInDec = 0, condInDec = 0, pressTempInDec = 0;
    //    char tstr[25] = "\0";
    int rate = 0;
    int sbe_indx = 0;
    int sbe_time_indx = 0;
    char *strPtr = NULL;
    char parsing_str[1024];
    uint64_t sbe_time;
    
    ctd_rec_ptr->in_use = 1;
    //ADDED MNB 11Mar21:convert to  strncpy(); with fixed length of $SB490 tag
    memcpy(parsing_str,ctd_rec_ptr->DataStr,ctd_rec_ptr->data_length);
    
    // *** convert data: temp, cond, press in hex to decimal
    // skip the tag & timestamp - mnbui 11 March 2021
    sbe_indx = DATA_HEADER_SIZE+16;    //ADDED mnbui 11 March 2021: get the index of SBE's data
    sbe_time_indx = DATA_HEADER_SIZE;
    // read the SBE's data and convert it into the engineer unit
    // SBE's format: ttttttccccccppppppvvvv
    // TCP_NUM_DIGIT = 6, PTComp_NUM_DIGIT = 4
    for(j=0; j<4; j++)
    {
        indx = sbe_indx + TCP_NUM_DIGIT*j;  //start at sbe data
        strPtr = parsing_str+indx;
        //   printf("strPtr: %d: %s",j, strPtr);
        // ADDED mnbui 12Mar2021: convert 6 or 4 characters to get temperature, cond & pressure
        if (j<3)    // for temp,cond,pressure
            val = hex2int_n(strPtr, TCP_NUM_DIGIT);
        else
            val = hex2int_n(strPtr, PTComp_NUM_DIGIT);
        switch(j)
        {
            case 0:
                tempInDec = val;
                // printf("temp = %ld\n",val);
                break;
            case 1:
                condInDec = val;
                //  printf("cond = %ld\n",val);
                break;
            case 2:
                pressInDec = val;
                break;
            case 3:
                pressTempInDec = val;
                break;
        }   // end of switch(j)
    }   // end of for(j=0; j<4; j++)
    
    parsing_str[sbe_indx] = '\0';
    
    sbe_time = (((uint64_t)hex2int_n(parsing_str+sbe_time_indx, 8))<<32) | ((uint64_t)hex2int_n(parsing_str+sbe_time_indx+8, 8));
    sbe_time = (sbe_time/10)%10000;
    
    // *** Calculate temp, press, cond with engineer unit
    ctd_rec_ptr->FishCTDdata.temperature = CalculateTemp(FishCTDPtr, tempInDec);
    ctd_rec_ptr->FishCTDdata.pressure = CalculatePress(FishCTDPtr, pressTempInDec, pressInDec);
    ctd_rec_ptr->FishCTDdata.conductivity
    = CalculateCond(FishCTDPtr, ctd_rec_ptr->FishCTDdata.temperature, ctd_rec_ptr->FishCTDdata.pressure, condInDec);
    // TODO mnbui 12Mar2021 - add the altimeter (global var: somehow we get from
    // FishCTDPtr->FishCTDCirBuff[dataIndx].FishCTDdata.altTime = altTime;
    FishCTDPtr->LatestCTDPress = ctd_rec_ptr->FishCTDdata.pressure;
    FishCTDPtr->LatestCTDTemp = ctd_rec_ptr->FishCTDdata.temperature;
    FishCTDPtr->LatestCTDCond = ctd_rec_ptr->FishCTDdata.conductivity;
    FishCTDPtr->LatestCTDTime = sbe_time;//ctd_rec_ptr->timeInHundredsecs%10000;
    ctd_rec_ptr->ParseDone = TRUE;
    ctd_rec_ptr->in_use = 0;
    
    // diplay data in engineer format in engDispRate times/sec
    if (FishCTDPtr->engDispRate != 16)
    {
        rate = 16/(FishCTDPtr->engDispRate);
        val2 = indx%rate;
        //        val2 = dataIndx%4;
        if ((FishCTDPtr->printData == 1) && (val2==0))
        {
            printf("time = %lu, temp = %f, press = %f, cond = %f",
                   ctd_rec_ptr->timeInHundredsecs,
                   ctd_rec_ptr->FishCTDdata.temperature,
                   ctd_rec_ptr->FishCTDdata.pressure,
                   ctd_rec_ptr->FishCTDdata.conductivity);
            printf("\n");
        }
    }
    // for debug mode, print out everything - MNB Jun 16, 2011
    if (FishCTDPtr->printData == 2)
    {
        if(indx%2 == 0){
            printf("After parsing CTD: time = %u, temp: %ld=>%f, press: %ld=>%f, cond: %ld=>%f\r\n",
                   (uint32_t)sbe_time,//ctd_rec_ptr->timeInHundredsecs,
                   tempInDec,
                   ctd_rec_ptr->FishCTDdata.temperature,
                   pressInDec,
                   ctd_rec_ptr->FishCTDdata.pressure,
                   condInDec,
                   ctd_rec_ptr->FishCTDdata.conductivity);
        }
    }
    ctd_rec_ptr->in_use = 0;
    return 1;
}

/*
 ** Function Name: ReadFishCTDdataFromPort(void *arg)
 ** Purpose: Read CTD from serial port
 ** Edit: rename: ReadSOMdataFromPort() - March 2021
 */
void *read_ctd_data_from_port_f(void *arg)
{
    //    struct timespec stime;
    //    stime.tv_nsec = 1000000000;  // 1000ms
    //    stime.tv_sec = 0;
    fish_t *fCTDPtr;
    
    fCTDPtr	= (fish_ctd_ptr_t)arg;
    
    //set_realtime(1000000, 5000, 10000);
    while(!fCTDPtr->Done){
        // read data from port1
        if(FishCTD_AcquireData(fCTDPtr)<1)
            continue;
        // copy data into circle buffer when we get the whole CTD packet
        //        if(!fCTDPtr->ctd_cir_buff[(fCTDPtr->CTD_Write2BufferIndx-1)%MAX_CIRBUFF].in_use)
        //        {
        //           printf("Parsing SBE data\n");   // mnbuiDB
        //            while(fCTDPtr->CTD_ParseIndx != fCTDPtr->CTD_Write2BufferIndx){
        //                parse_ctd_data_f(fCTDPtr);
        //            }
        //        }
    }
    printf("End of ReadCTDfromPort() in Pthread.c\n");
    
    return NULL;
}

/*
 ** Function Name: SetOptionSerialPort4FishCTD(FishCTDStructPtr FishCTDPtr)
 ** Purpose: Set option of serial port for Fish CTD
 */
int SetOptionSerialPort4FishCTD(fish_ctd_ptr_t FishCTDPtr)
{
    return cfsetspeed(&FishCTDPtr->SerialPort4CTD.spOptions, FishCTDPtr->SerialPort4CTD.speed);
}
int SetOptionSerialPort4FishCommand(fish_ctd_ptr_t FishCTDPtr)
{
    return cfsetspeed(&FishCTDPtr->SerialPort4Command.spOptions, FishCTDPtr->SerialPort4Command.speed);
}

/*
 ** Function Name: WriteFishCTDDataIntoBuffer(char *str, FishCTDStructPtr fishCTDPtr)
 ** Purpose: Write CTD's data into cir buffer
 */
void WriteFishCTDDataIntoBuffer(char *str, fish_ctd_ptr_t fishCTDPtr)
{
    int indx;
    // write into FishCTD's circular buffer
    indx = fishCTDPtr->CTD_Write2BufferIndx%MAX_CIRBUFF;
    strcpy(fishCTDPtr->ctd_cir_buff[indx].DataStr, str);
    fishCTDPtr->CTD_Write2BufferIndx++;
}

uint32_t CalculateChecksum(char *dataStr, int strLen)
{
    uint8_t val = 0;
    int i = 0;
    
    for(i=0; i<strLen; i++)
    val ^= dataStr[i];
    return (uint32_t) val;
    
}

// check the data is valid by using the checksum
// caculate checksum: from the sync char to the last byte of the data before '*'
// here is the algorithm from Arnaud to get the checksum
/*for(int i=0;i<mod_som_sbe49_ptr->consumer_ptr->record_length;i++) //
 {         mod_som_sbe49_ptr->consumer_ptr->chksum ^=mod_som_sbe49_ptr->consumer_ptr->record_data_ptr[i];
 }
 */
// offset: CKS_HEADER_LEN = 3, CKS_LEN = 5 (the whole data string: header+payload)
int CheckCksumData(char *dataStr, int packetSize, int offset)
{
    uint32_t calChecksum = 0;
    uint8_t dataChecksum = 0;
    //    int i = 0;
    int starIndx;
    char cksumStr[3] = "\0";
    
    // 1. first check that the '*' is in the right location, if not -> exit
    starIndx = packetSize - offset;
    //    printf("ps = %d, offset = %d, \'%c\', %s\n",packetSize, offset, dataStr[starIndx], dataStr);
    if (dataStr[starIndx]!='*')
    {
        //        printf("Check checksum failed: to find the tailer of TAG = %c%c%c%c%c\n",dataStr[0],dataStr[1],dataStr[2],dataStr[3],dataStr[4]);
        dataStr[packetSize] = '\0';
        char * tmp_str = &dataStr[starIndx];
        printf("no star: %s\r\n",tmp_str);
        return 0;
    }
    
    //mnbuiDB
    //   printf("SOM_ACQ_DB: data before checking %d, star_loc: %d %c: %s\n",packetSize,starIndx,dataStr[starIndx],dataStr);
    // 2a. next step to convert hex cksum into proper endian interger
    cksumStr[0] = dataStr[starIndx+1];
    cksumStr[1] = dataStr[starIndx+2];
    //    printf("cks = %s\n",cksumStr);
    dataChecksum = HexToInt_n(cksumStr,2);
    // calculate checksum of received data from the sync '$' to the end of data (before '*' character)
    calChecksum = CalculateChecksum(dataStr, starIndx);
    //        for (i=0; i<starIndx; i++)
    //           calChecksum ^=(uint32_t)dataStr[i];
    //       printf("datack=%d, cal_ck = %d, 0x%x\n",dataChecksum, calChecksum, calChecksum);
    
    if (dataChecksum != calChecksum)
    {
        printf("Checksums do not match\n");
        printf("dataChecksum = %u\n",dataChecksum);
        printf("calChecksum = %u\n",calChecksum);
        return 0;
    }
    return 1;
}
