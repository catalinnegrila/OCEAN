#ifndef FCTD_H
#define FCTD_H

//#include<stdlib.h>
//#include<stdio.h>
//#include <unistd.h>
//#include <fcntl.h>
//#include <errno.h>
//#include <paths.h>
//#include <termios.h>
//#include <sysexits.h>
//#include <sys/param.h>

//#include <CoreFoundation/CoreFoundation.h>

//#include <IOKit/IOKitLib.h>
//#include <IOKit/serial/IOSerialKeys.h>
//#include <IOKit/IOBSD.h>
//#include <mach/mach_init.h>
//#include <mach/thread_policy.h>
//#include <err.h>

#include "globals.h"
#include "serial_port_utils.h"
#include "file_utils.h"
#include "ctd.h"
#include "pcode.h"
#include "network.h"
#include "udp_utils.h"
#include "tcpip_utils.h"

typedef struct
{
	unsigned long seq_count;
	unsigned long start_run_dropnum;
	unsigned long endrun_dropnum;
	unsigned long total_drops;
	unsigned long timestamp;
	unsigned long startrun_sys_time;
	unsigned long startrun_gps_time;
	unsigned long endrun_sys_time;
	unsigned long endrun_gps_time;
	float gps_lat;
	float gps_lon;
}rec_header_t, *rec_header_ptr_t;

typedef struct
{
	Boolean done;
	Boolean not_1st_time;
	file_t data_file;	// raw and matfile
    char SaveSetup_name[1024];    // raw and matfile
	Boolean wr_data_serial_port_flag;
	Boolean write_data_network_flag;
	UDPStruct udp_socket;
	SerialPortData serial_port_4_data_out;
	unsigned int totalByteSending;
	Boolean pcode_flag;
	Boolean ctd_flag;
//	Boolean network_flag;
//    Boolean alti_flag;
//    Boolean efe_flag;
//    Boolean volt_flag;
//    Boolean vnav_flag;
	// All sensor: CTD, PCode
	fish_t fish;
	pcode_t pcode;
	network_t network; //previously winch // San - just a hack for network currently
	rec_header_t rec_header;
//	int hdsizeInLine;
	unsigned int header_file_size_bytes;
//	Boolean dropnumBaseonWinch;	// 1: base on pressure of fish, 0: base on Winch's data
	unsigned long dropnum4newfile;
	char app_path[1024];
	time_t offset_time;	
}fctd_epsi_t, *fctd_epsi_ptr_t;


void fctd_epsi_init(fctd_epsi_ptr_t fctd);
void fctd_write_data_to_buff(char*, fctd_epsi_ptr_t);
int fctd_write_data_to_file(const char *str, uint32_t str_len,fctd_epsi_ptr_t fctd);
int fctd_write_efedata_to_file(const char *str, fctd_epsi_ptr_t fctd);
ssize_t fctd_write_header_to_file(fctd_epsi_ptr_t fctd,int head_tail);
int fctd_read_setup_write_to_file(fctd_epsi_ptr_t FastCTDPtr, FILE *fp_data, char *str,int *total_line);
int fctd_read_cal_write_to_file(char* calFileName, FILE *fp_data, char* str,int *total_line);
//int fctd_write_calfromfish_to_file(char* strcal, FILE *fp_data, char* str,int *total_line);
//alb new function to write the fish probe calibration in the .modraw header
int fctd_read_probe_write_to_file(fctd_setup_ptr_t FastCTDSetup, char* str,int *total_line);

#endif
