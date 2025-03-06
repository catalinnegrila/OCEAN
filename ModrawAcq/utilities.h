/*
 *  Utilities.h
 *  FastCTD
 *
 *  Created by Mai Bui on 1/1/05.
 *  Copyright 2005 __MyCompanyName__. All rights reserved.
 *
 */
#ifndef UTILITIES_H
#define UTILITIES_H
#include <strings.h>
#import <sys/time.h>   // random types
#include <stdio.h>

double AlphaToFloat(char str[], int len);
void itoa( int num, char str[]);
void reserve(char str[]);
long HexStr2Dec(char[]);
time_t Get_Offset_Time(char* timeStr, int local);
time_t Get_Time_In_Hundred_Secs(char* timeStr, int local);
time_t Get_Time_In_Secs(char* timeStr, int local);
// take the string with total number of character the interger
int HexToInt_n(char *hex, int numChar);
#endif
