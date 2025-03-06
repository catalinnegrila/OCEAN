#ifndef FILEUTILS_H
#define FILEUTILS_H

#include <sys/time.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
//JMK 23 April 2006
#include <errno.h>
#include <string.h>
#include <fcntl.h>	// for open file's mode
#include <sys/types.h>
#include <sys/stat.h>

#include "globals.h"


typedef struct
{
	long totalsecs;	// from Jan 1, 1970
	int day;
	int month;
	int year;
	int hour;
	int min;
	int sec;
}time_struct_t, *time_struct_ptr_t;

typedef struct
{
	FILE *fp;
	int fd;
	char path[225];
	char runname[25];
	char filename[225];
	ssize_t totalBytesWrFile;
	ssize_t dataFileSize;
    time_struct_t fileTime;
	int ftype;
}file_t, *file_ptr_t;

void 	fclose_f(file_t*);
void	fname_create_f(file_ptr_t);
int		fnew_f(file_ptr_t);
int		fget_str_f(char *, int , FILE *);
int		getchar_ignore_comments_f(FILE *);
void	get_path_f(char [],char*);
int		fopen_f(char *, int);
int		fopen_in_wdir_f(char *, int);

#endif
