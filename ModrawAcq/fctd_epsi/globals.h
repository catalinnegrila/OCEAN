#ifndef GLOBALS_H
#define GLOBALS_H

//#include <stdlib.h>
//#include <stdio.h>
//#include <CoreFoundation/CoreFoundation.h>

/*
#include <pthread.h>
#include <time.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <paths.h>
#include <termios.h>
#include <sysexits.h>
#include <sys/param.h>

#include <CoreFoundation/CoreFoundation.h>

#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#include <mach/mach_init.h>
#include <mach/thread_policy.h>

#include <err.h>
*/
#include <sys/time.h>


#define MAX_CIRBUFF 1024
#define MAX_LENGTH  1024
#define MAX_DATA_LENGTH 100000
//#define CTD_LENGTH 24  // 6(T) + 6(C) + 6(P) + 4(temperature compensation) data and  2(carriage return & line feed)
// SBD 49 FASTCAT, SN: 4933450-0057 - 2/13/04
//#define CTD_LENGTH 68  // 6(T) + 6(C) + 6(P) + 4(temperature compensation) data + 40 chars + 4 checksum and  2(carriage return & line feed)
#define MAX_FILE_SIZE 4000 // maxfsize = 4000;
#define MAXNAMELEN 25
#define pi 3.1415926
#define FILESIZE_LIMIT 100000000	// 100MB

#define DATA_TAG_SIZE 5  //$NAME
#define TIMESTAMP_LEN 16
#define NUM_SAMPLE_LEN 8
#define DATA_HEADER_SIZE 32  //$EFE3 00 00 00 00 00 29 c0 ce 00 00 03 66*26
#define HEADER_SIZE_WTCKS 29 //HEADER_SIZE minus '*'(1) & cksum(2)
#define STAR_INDX 5 // at the end of data string: *<ck1><ck2>\r\n
#define ALT_HEX_STR_POS 22 // 5(TAG)+16(timestamp)+1
#define CKS_DATA_LEN 5   // 5 = *<ck1><ck2>\r\n
#define CKS_HEADER_LEN 3   // 3 = *<ck1><ck2>

enum Sensors { CTD = 1, PCode, Winch};
//extern time_t offsetTime;

#endif
