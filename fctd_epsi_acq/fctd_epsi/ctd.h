#ifndef CTD_H
#define CTD_H

#include "serial_port_utils.h"
#include "globals.h"
#include "utilities.h"
#include "file_utils.h"
//#include "PThreadUtils.h"


#define AVG_WINDOWINPACKS 5	// 5 packet(string) of FishCTD's data for average.

//#define CTD_LENGTH 72  // 6(T) + 6(C) + 6(P) + 4(temperature compensation) data + 40 chars + 8 checksum and  2(carriage return & line feed)
//#define CTD_LENGTH 24  // 6(T) + 6(C) + 6(P) + 4(temperature compensation) data and  2(carriage return & line feed)

//CTD data now has
// $OPGCTD TTTTTT CCCCCC PPPPPP TPTP MICRMICRMICRMICRMICRMICRMICRMICRMICRMICR GYROGYROGYRO ACCEACCEACCE COMPCOMPCOMP ALTI NCOUNTER \n\r
// (7)a    (6)b   (6)c   (6)d   (4)e (40)f                                    (12)g        (12)h        (12)i        (4)j (8)k     (2)l
// a: CTD string identifier (7 chars) [offset: 0]
// b: temperature (6 chars) [offset: 7]
// c: conductivity (6 chars)[offset: 13]
// d: pressure (6 chars) [offset: 19]
// e: temperature compensation (4 chars) [offset: 25]
// f: microconductivity (40 chars) (10 samples, 4char per sample)[offset: 29]
// g: gyro from YEI (12 chars) [offset: 69]
// h: acceleration from YEI (12 chars) [offset: 81]
// i: compass from YEI (12 chars) [offset: 93]
// j: altimeter (4 chars) [offset: 105]
// k: record counter (8 chars) [offset: 109]
// l: carriage and newline (2 chars) [offset: 117]
// CTD_LENGTH doesn't count the CTD string identifier

// CTD data (March 2021) - mnbui
// $S49 ...
//"$S49000000000000d909,0075,0000000000000000d8c5055D6609E7B2080D724DD8\r\n000000000000d903055D6609E7B2080D724DD9\r\n*42\r\n";
//  sync&TAG_id: $S49 = 4
//  16(timestamp)+1(,)+4(packetlen)+1(,)+16(timestamp)+22(sbe_data)+2(\r\n)+22(sbe_data)+2(\r\n)
//  SBE49 data (22):ttttttccccccppppppvvvv\r\n
//  $S49timestamp(16),stringlen_inhex(4),timestamp(16)24sbe_data(24)sbe_data(24)*ck(2)\r\n

typedef struct
{
    char strcal[MAX_LENGTH];
    uint32_t strcal_length;
    char serialnum[25];
    char tcalDate[25];
    float ta0;
    float ta1;
    float ta2;
    float ta3;
    char ccalDate[25];
    float cg;
    float ch;
    float ci;
    float cj;
    float ctcor;
    float cpcor;
    char pcalDate[25];
    float pa0;
    float pa1;
    float pa2;
    float ptca0;
    float ptca1;
    float ptca2;
    float ptcb0;
    float ptcb1;
    float ptcb2;
    float ptempa0;
    float ptempa1;
    float ptempa2;
}ctd_coeff_t, *ctd_coeff_ptr_t;

typedef struct
{
    char serialnum[25];
    char strcal[256];
    char calDate[25];
    float Sv;
    float Capacitance;
}probe_coeff_t, *probe_coeff_ptr_t;

typedef struct
{
    // later ... FastCTDApp version
    // later ... Time stamp
    ctd_coeff_t ctd_coeff;
    //ALB 19 August 2024
    probe_coeff_t probe1_coeff;
    probe_coeff_t probe2_coeff;
    probe_coeff_t probe3_coeff;
    probe_coeff_t probe4_coeff;
}fctd_setup_t, *fctd_setup_ptr_t;

typedef struct
{
    float temperature;
    float conductivity;
    float pressure;
    float altTime;
}ctd_data_t, *ctd_data_f_t;

typedef struct
{
    struct timeval UnixTime;
    unsigned long timeInHundredsecs;
//    unsigned long dropNum;
    ctd_data_t FishCTDdata;
//    int FishIsDown;
//    Boolean FishChangesCourse;
    char DataStr[MAX_LENGTH];
    uint32_t data_length;
    Boolean ParseDone;
    int in_use;
}ctd_rec_t, *ctd_rec_ptr_t;

typedef struct
{
    long PressWindow[AVG_WINDOWINPACKS];
    long LastPressAvg;
    long CurrPressAvg;
    unsigned int CurrIndx;
    unsigned int LastIndx;
}ctd_press_avg_t, *ctd_press_avg_ptr_t;

//ADDED mnbui 12Mar21 - add the alt data
typedef struct
{
    struct timeval UnixTime;
    unsigned long timeInHundredsecs;
    char data_str[MAX_LENGTH];
    uint32_t data_length;
    float altimeter_time;
    int doneRead;
}alti_rec_t, *alti_rec_ptr_t;
//ADDED mnbui 12Mar21 - add the efe data
typedef struct
{
    struct timeval UnixTime;
    unsigned long timeInHundredsecs;
    char data_str[MAX_DATA_LENGTH];
    uint32_t data_length;
    int doneRead;
}som_rec_t, *som_rec_ptr_t;
//ADDED mnbui 12Mar21 - add the volt data
typedef struct
{
    struct timeval UnixTime;
    unsigned long timeInHundredsecs;
    char DataStr[MAX_LENGTH];
}volt_buff_t, *volt_buff_ptr_t;
//ADDED alb 17Mar21 - add the vec nav
typedef struct
{
    struct timeval UnixTime;
    unsigned long timeInHundredsecs;
    char DataStr[MAX_LENGTH];
    uint32_t data_length;
}vnav_buff_t, *vnav_buff_ptr_t;
// runtime structure
typedef struct
{
    int CTDPortnum;
    char CTDPortName[32];
    int CommandPortnum;
    char CommandPortName[32];

    int total_cal_line;
    Boolean Done;
    int printData;	// 0: status, 1: engineer format, 2: debug
    int engDispRate;
    int CTDPhase;
    int CTDReqReadSize;
    SerialPortData SerialPort4CTD;
    SerialPortData SerialPort4Command;
    ctd_rec_t ctd_cir_buff[MAX_CIRBUFF];
    fctd_setup_t FastCTDSetup; // FastCTDSetup.
    unsigned int CTD_ParseIndx;
    unsigned int CTD_Write2BufferIndx;
    unsigned int CTD_ReadBufferIndx;
    unsigned int CTD_ReadBufferIndx_2; // for tcp ip
    unsigned int GetPressIndx;
    unsigned long ctd_PackCnt;		// Read counter from serial port
    Boolean getStatusFish;
    unsigned long dropNum;
//    ctd_press_avg_t FishPressAvg;
    //	char ParsingStr[CTD_LENGTH];	// contents data for parsing task
    char ParsingStr[255];	// contents data for parsing task
    int CTDlength;    // length of the CTD's string
    int Altilength;    // ADDED mnbui 12Mar21 - length of the Alti's string
    alti_rec_t AltCirBuff[MAX_CIRBUFF]; // ADDED mnbui 12Mar21
    unsigned int AltWrite2BufferIndx;
    unsigned int AltReadBufferIndx;
    float LatestAltTime;
    float LatestCTDPress;
    float LatestCTDTemp;
    float LatestCTDCond;
    unsigned long LatestCTDTime;
    int Efelength;    // ADDED mnbui 12Mar21 - length of the EFE's string
    som_rec_t som_cir_buff[MAX_CIRBUFF]; // ADDED ALB
    unsigned int SOM_Write2BufferIndx;
    unsigned int SOM_ReadBufferIndx;
//    int Voltlength;    // ADDED mnbui 12Mar21 - length of the VOLT's string
//    volt_buff_t VoltCirBuff[MAX_CIRBUFF]; // ADDED mnbui 12Mar21
//    unsigned int VoltWrite2BufferIndx;
//    unsigned int VoltReadBufferIndx;
//    int Vnavlength;    // ADDED ALB 17march2021- length of the VecNav's string
//    vnav_buff_t VnavCirBuff[MAX_CIRBUFF]; // ALB 17march2021
//    unsigned int VnavWrite2BufferIndx;
//    unsigned int VnavReadBufferIndx;
    
    uint8_t settings[1024];
    uint32_t settings_length;
    
    char experiment[32];
    char cruise[32];
    char vehicle[32];
    char fish_pc[32];
    char fish_flag[32];
    char survey[32];
    char SerialNum[32]; // JMK 17 April 05, New variable for CTD serial number....
    char FPO7_Probe_cal_path[256]; // ALB 19 august 2024, Probe calibration path....
    char shear_Probe_cal_path[256]; // ALB 19 august 2024, Probe calibration path....
    char CTD_cal_path[256]; // ALB 23 Sept 2024, CTD calibration path....
    char ch1_sn[32]; // ALB 19 august 2024, New variable for ch1 serial number....
    char ch2_sn[32]; // ALB 19 august 2024, New variable for ch2 serial number....
    char ch3_sn[32]; // ALB 19 august 2024, New variable for ch3 serial number....
    char ch4_sn[32]; // ALB 19 august 2024, New variable for ch4 serial number....

}fish_t, *fish_ctd_ptr_t;

int AverageFishData(fish_ctd_ptr_t fish_ctd_ptr, unsigned long *avgTime, float *avgPress,float *avgTemp, float *avgCond, float *avgAltTime);
// San Nguyen added on 2014 Oct 31
int CurrentFishData(fish_ctd_ptr_t fishCTDPtr, unsigned long *CTDtime, float *CTDpress, float *CTDtemp, float *CTDcond, float *AltTime);
int CurrentFishData2(fish_ctd_ptr_t fishCTDPtr, unsigned long *CTDtime, float *CTDpress, float *CTDtemp, float *CTDcond, float *AltTime);
float CalculateTemp(fish_ctd_ptr_t FishCTDPtr, long tempInHex);
float CalculateCond(fish_ctd_ptr_t FishCTDPtr, float, float, long condFreq);
float CalculatePress(fish_ctd_ptr_t FishCTDPtr, long pressTemp, long pressTempComp);
float CalculateSalt(float C,float T, float P);
float CalculateSoundVel(fish_ctd_ptr_t FishCTDPtr,float cond, float temp, float press);
Boolean FishCTD_AcquireData(fish_ctd_ptr_t);
int InitFishCTD(fish_ctd_ptr_t);
//JMK 17 April 05: Added optional CalFileName argument
int GetFishCTDCal(ctd_coeff_ptr_t,char *CalFileName);
//ALB 20 August 2024: collect SBE49 cal coef from the fish
int GetFishCTDCal_fromfish(fish_ctd_ptr_t fishCTDPtr);
int parse_ctd_data_f(fish_ctd_ptr_t FishCTDPtr);
int parse_ctd_data_2_f(fish_ctd_ptr_t FishCTDPtr, ctd_rec_ptr_t ctd_rec_ptr);
float Press2Meter(float pressInDecibars);
void *read_ctd_data_from_port_f(void *arg);
int SetOptionSerialPort4FishCTD(fish_ctd_ptr_t);
int SetOptionSerialPort4FishCommand(fish_ctd_ptr_t);
void WriteFishCTDDataIntoBuffer(char *str, fish_ctd_ptr_t fishCTDPtr);
uint32_t CalculateChecksum(char *dataStr, int strLen);
int CheckCksumData(char *dataStr, int packetSize, int offset);
#endif
