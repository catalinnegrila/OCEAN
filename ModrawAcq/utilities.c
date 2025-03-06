/*
 *  Utilities.c
 *  FastCTD
 *
 *  Created by Mai Bui on 1/1/05.
 *  Copyright 2005 __MyCompanyName__. All rights reserved.
 *
 */

#include "utilities.h"

double AlphaToFloat(char str[], int len)
{
	int dotIndx = 0, indx = 0;
	double val = 0.0;
	double fac;
	int i, sign = 1;
		
	sign = (str[0] == '-') ? -1 : 1;
	if ((str[0]=='-')||(str[0]=='+'))
		indx++;
	//find dot's index
	for (i=indx; i<len && str[i]!='.';i++){};
	dotIndx = i;
	
	if (dotIndx != indx)
	{
	   val = str[dotIndx-1] - 0x30; //get the first decimal number
	   //get the decimal numbers
	   fac = 10;
	   for (i=dotIndx-2; i>=indx; i--)
	   {
	      val += (str[i]-0x30)*fac; 
	      fac *= 10;
	   }
	}
	// get the pricision numbers
	fac = 0.1;
	for (i=dotIndx+1; i<len; i++)
	{
		val += (str[i]-0x30)*fac;
		fac *= 0.1;
    }
	val = val*sign;
   	return val;
}
void reserve(char str[])
{
   int i, j, c;
   for (i=0, j=(int32_t)strlen(str)-1; i<j; i++, j--)
   {
       c = str[i];
       str[i] = str[j];
       str[j] = c;
   }
}
void itoa( int num, char str[])
{
   int i=0, sign;

   if ((sign = num)<0)	// if num is a negative number
      num = -num;	// only get a positive
   do
   {
      str[i++] = num%10 + '0';
   }while((num /= 10) > 0);	// get the next precision, until to the end of number
   if (sign < 0)		// put sign for this string
      str[i++] = '-';
   str[i] = '\0';
   // to here: if num = 1234 -> str = 4321, so this str need to be reserved
   reserve(str);	// reverse the string
} 

// change from hex to decimal
// letter: A -> F (char) = 0x41 -> 0x46 (hex) = 65 -> 70 (decimal value in ascii table)
//     so if want to get decimal value, must subtract from 55 (=0x37) => A -> F (char) = 10 -> 15 (decimal)
// number: 0 -> 9 (char) = 0x30 -> 0x39 (hex) = 48 -> 57 (decimal value in ascii table) = 0 -> 9 (decimal)
//     so if want to get decimal value, must subtract from 48 (=0x30) => 0 -> 9 (char) = 0 -> 9 (decimal)
// if char is > 0x39 => letter, otherwise => number
// Fish CTD has format (raw data in Hexadecimal): 22chars = 6(t)6(c)6(p)4(v)
// ttttttccccccppppppvvvv = 0A53711BC7220C14C17D82 (for example)
// with this example:
//    '0' -> change to decimal (0 -> 15) -> put it in the 4 right most bits -> get value
//    'A':
//		  -> shift left 4 bits the '0' value
//        -> change to decimal (0 -> 15) -> put it in the 4 right most bits -> accumulate value
//    '5': do the same above 'A' steps
//    until the end of the string
long HexStr2Dec(char str[])
{
    int indx = 0, len;
    long val=0;
    
    len = (int)strlen(str);
    
    if (str[indx]> 0x40 && str[indx]< 0x47) // letter: A -> F: 0x41 -> 0x46
        val = ((long)(str[indx] - 0x37));
    else if (str[indx]> 0x60 && str[indx]< 0x67) // letter: A -> F: 0x41 -> 0x46
        val = ((long)(str[indx] - 0x57));
    else if (str[indx]>= 0x30 && str[indx]<= 0x39)    // number: 0 -> 9: 0x30 -> 0x39
        val = ((long)(str[indx] - 0x30));
    indx++;
    for (indx=indx;indx<len;indx++)
    {
        val = val << 4;    // shift left 4 bits, put the next char into the right most 4 bits and accumulate them
        if (str[indx]> 0x40 && str[indx]< 0x47) // letter: A -> F: 0x41 -> 0x46
            val += ((long)(str[indx] - 0x37));
        else if (str[indx]> 0x60 && str[indx]< 0x67) // letter: A -> F: 0x41 -> 0x46
            val += ((long)(str[indx] - 0x57));
        else if (str[indx]>= 0x30 && str[indx]<= 0x39)    // number: 0 -> 9: 0x30 -> 0x39
            val += ((long)(str[indx] - 0x30));
    }
    return val;
}

/*
Routine: Get_Host_Time_In_Secs()
Purpose: Calculate the number of seconds from at the beginning of this year up to now.
Pass Params: number of seconds (GM time) from at the beginning of this year up to now, GM time string.
Return: number of seconds (GM time) from at the beginning of this year up to now.
*/

time_t Get_Time_In_Secs(char* timeStr, int local)
{
	struct timeval timev, *timevPtr;
	struct timezone timez, *timezPtr;
	struct tm time_str, *time_strPtr;
	time_t offsetTime, Secs;
	time_t HostTimeInSecs;

	timevPtr = &timev;
	timezPtr = &timez;
	// 1. Get current year
	gettimeofday(timevPtr, timezPtr);
	Secs = timevPtr->tv_sec;

	// 2. Get gmtime -> stores in tm structure
	switch(local)
	{
		case 0:	// gmtime
			time_strPtr = gmtime(&Secs);
            break;
		case 1: // localtime
			time_strPtr = localtime(&Secs);
            break;
        default:
            time_strPtr = gmtime(&Secs);
            break;
	}
//	printf("year = %d\n", (time_strPtr->tm_year+1900));
    sprintf(timeStr,"%d/%d/%d %d:%d:%d\n",time_strPtr->tm_mon+1,time_strPtr->tm_mday,time_strPtr->tm_year+1900,time_strPtr->tm_hour,time_strPtr->tm_min,time_strPtr->tm_sec);

	// upto Jan 1, current year
    time_str.tm_year = time_strPtr->tm_year;
    time_str.tm_mon = 0;
    time_str.tm_mday = 1;
    time_str.tm_hour = 0;
    time_str.tm_min = 0;
    time_str.tm_sec = 1;
    time_str.tm_isdst = -1;
	
	// get the new seconds of current time 
	gettimeofday(timevPtr, timezPtr); // timevPtr->tv_sec is the number of seconds from Jan 1, 1970 up to now.
	
	offsetTime = mktime(&time_str);	// get number of seconds from Jan 1 1970 to the current year
	// therefore, number of seconds from Jan 1, current year up to now:
	HostTimeInSecs = (timevPtr->tv_sec - offsetTime);

	return HostTimeInSecs;
}

time_t Get_Offset_Time(char* timeStr, int local)
{
	struct timeval timev, *timevPtr;
	struct timezone timez, *timezPtr;
	struct tm time_str, *time_strPtr = NULL;
	time_t offsetTime, Secs;
	//time_t HostTimeInSecs; - mnbui 3 Mar 2021

	timevPtr = &timev;
	timezPtr = &timez;
	// 1. Get current year
	gettimeofday(timevPtr, timezPtr);
	Secs = timevPtr->tv_sec;

	// 2. Get gmtime -> stores in tm structure
	switch(local)
	{
		case 0:	// gmtime
			time_strPtr = gmtime(&Secs);
		break;
		case 1: // localtime
			time_strPtr = localtime(&Secs);
		break;
	}
//	printf("year = %d\n", (time_strPtr->tm_year+1900));
    sprintf(timeStr,"%d/%d/%d %d:%d:%d\n",time_strPtr->tm_mon+1,time_strPtr->tm_mday,time_strPtr->tm_year+1900,time_strPtr->tm_hour,time_strPtr->tm_min,time_strPtr->tm_sec);

	// upto Jan 1, current year
    time_str.tm_year = time_strPtr->tm_year;
    time_str.tm_mon = 0;
    time_str.tm_mday = 1;
    time_str.tm_hour = 0;
    time_str.tm_min = 0;
    time_str.tm_sec = 1;
    time_str.tm_isdst = -1;
		
	offsetTime = mktime(&time_str);	// get number of seconds from Jan 1 1970 to the current year

	return offsetTime;
}

/*
Routine: Get_Host_Time_In_Hundred_Secs()
Purpose: Calculate the number of hundreths of seconds from at the beginning of this year up to now.
Pass Params: number of hundreths  seconds (GM time) from at the beginning of this year up to now, GM time string.
Return: number of hundreths seconds (GM time) from at the beginning of this year up to now.
*/

time_t Get_Time_In_Hundred_Secs(char* timeStr, int local)
{
	struct timeval timev, *timevPtr;
	struct timezone timez, *timezPtr;
	struct tm time_str, *time_strPtr = NULL;
	time_t offsetTime, Secs;
	time_t HostTimeInHundredSecs;

	timevPtr = &timev;
	timezPtr = &timez;
	// 1. Get current year
	gettimeofday(timevPtr, timezPtr);
	Secs = timevPtr->tv_sec;

	// 2. Get gmtime -> stores in tm structure
	switch(local)
	{
		case 0:	// gmtime
			time_strPtr = gmtime(&Secs);
		break;
		case 1: // localtime
			time_strPtr = localtime(&Secs);
		break;
	}
//	printf("year = %d\n", (time_strPtr->tm_year+1900));
    sprintf(timeStr,"%d/%d/%d %d:%d:%d",time_strPtr->tm_mon+1,time_strPtr->tm_mday,time_strPtr->tm_year+1900,time_strPtr->tm_hour,time_strPtr->tm_min,time_strPtr->tm_sec);

	// upto Jan 1, current year
    time_str.tm_year = time_strPtr->tm_year;
    time_str.tm_mon = 0;
    time_str.tm_mday = 1;
    time_str.tm_hour = 0;
    time_str.tm_min = 0;
    time_str.tm_sec = 1;
    time_str.tm_isdst = -1;
	
	// get the new seconds of current time 
	gettimeofday(timevPtr, timezPtr); // timevPtr->tv_sec is the number of seconds from Jan 1, 1970 up to now.
	
	offsetTime = mktime(&time_str);	// get number of seconds from Jan 1 1970 to the current year
	// therefore, number hundreths of seconds from Jan 1, current year up to now:
	HostTimeInHundredSecs = (timevPtr->tv_sec - offsetTime)*100 + timevPtr->tv_usec/10000;

	return HostTimeInHundredSecs;
}
// take the string with total number of character the interger
int HexToInt_n(char *hex, int numChar)
{
    int val = 0;
    int i =0;
//    printf("hexstr to convert: %s\n",hex);
    for (i =0; i< numChar; i++)
    {
        unsigned char byte = *hex++;
        if (byte >= '0' && byte <= '9') byte = byte - '0';
        else if (byte >= 'a' && byte <= 'f') byte = byte - 'a' + 10;
        else if (byte >= 'A' && byte <= 'F') byte = byte - 'A' + 10;
        val = (val << 4) | (byte & 0xf);
    }
//    printf("val = %d\n",val);
    return val;
}
