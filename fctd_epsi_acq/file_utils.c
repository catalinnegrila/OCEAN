/*
	Files Utilities:
	
	- Create new file: CreatNewFile()
	- Create a file name: CreateFileName()
	- CloseCurrFile()
*/ 
#include "file_utils.h"
#include <unistd.h>
   // FOPEN() access modes
   #define FO_READ      0     // Open for reading (default)
   #define FO_WRITE     1     // Open for writing
   #define FO_READWRITE 2     // Open for read or write

   // FOPEN() sharing modes (combine with open mode using +)
   #define FO_COMPAT    0     // Compatibility (default)
   #define FO_EXCLUSIVE 16    // Exclusive use
   #define FO_DENYWRITE 32    // Prevent others writing
   #define FO_DENYREAD  48    // Prevent others reading
   #define FO_DENYNONE  64    // Allow others to read/write
   #define FO_SHARED    64    // Same as FO_DENYNONE
/*
** Function Name: void CloseCurrFile(Files *fpData)
** Purpose: Close file with the mode read only
*/
void fclose_f(file_t *file_ptr)
{
//	mode_t mode = S_IRUSR | S_IRGRP | S_IROTH;
	// Set the file read only, first: get a FILE*, so that you can flush
    FILE* fid = fdopen(file_ptr->fd, "a");          // First get a FILE*, so 
    fflush(fid);								  // that you can flush.
    fchmod(file_ptr->fd, S_IRUSR | S_IRGRP | S_IROTH);

	// close all files
	if (file_ptr->fd) {
		close(file_ptr->fd); 
		file_ptr->fd = -1;
	}
}

/*
** Function Name: void CreateFileName(FilesPtr fpDataPtr)
** Purpose: Create data file with has time when it's created and have 2 type: ascii file and mat file
**          but we have only ascii file for now
*/
void fname_create_f(file_ptr_t file_ptr)
{
	struct timeval timev, *timev_ptr;
	struct tm time_info, *time_info_ptr;
	struct timezone timez, *timez_ptr;
	time_t timevalue;

	timev_ptr = &timev;
	timez_ptr = &timez;
	time_info_ptr = &time_info;

	gettimeofday(timev_ptr, timez_ptr);
	timevalue = timev_ptr->tv_sec;
	time_info_ptr = localtime(&timevalue);

	// save time of file
	file_ptr->fileTime.totalsecs = timevalue;
	file_ptr->fileTime.day = time_info_ptr->tm_mday;
	file_ptr->fileTime.month = time_info_ptr->tm_mon+1;
	file_ptr->fileTime.year = (time_info_ptr->tm_year+1900)%2000;
	file_ptr->fileTime.hour = time_info_ptr->tm_hour;
	file_ptr->fileTime.min = time_info_ptr->tm_min;
	file_ptr->fileTime.sec = time_info_ptr->tm_sec;
	
	// create the name for the file
    switch(file_ptr->ftype)
	{
		case 0: // for raw data
//			sprintf(file_ptr->filename,"%s%s%02d_%02d_%02d_%02d%02d%02d.raw",file_ptr->path,file_ptr->runname,file_ptr->fileTime.year,file_ptr->fileTime.month,file_ptr->fileTime.day,file_ptr->fileTime.hour,file_ptr->fileTime.min,file_ptr->fileTime.sec);
//ALB change .raw to .modraw
            sprintf(file_ptr->filename,"%s%s%02d_%02d_%02d_%02d%02d%02d.modraw",file_ptr->path,file_ptr->runname,file_ptr->fileTime.year,file_ptr->fileTime.month,file_ptr->fileTime.day,file_ptr->fileTime.hour,file_ptr->fileTime.min,file_ptr->fileTime.sec);
		break;
		case 1: // for matlab data
			sprintf(file_ptr->filename,"%s%s%02d_%02d_%02d_%02d%02d%02d.mat",file_ptr->path,file_ptr->runname,file_ptr->fileTime.year,file_ptr->fileTime.month,file_ptr->fileTime.day,file_ptr->fileTime.hour,file_ptr->fileTime.min,file_ptr->fileTime.sec);
		break;
		default:
		break;
	}
}

/*
** Function Name: int CreateNewFile(FilesPtr fpDataPtr)
** Purpose: create file name for writing
*/
int fnew_f(file_ptr_t file_ptr)
{
	int fmode = 0; // for writing

	fname_create_f(file_ptr);
//	if ((fpDataPtr->fp = OpenFile(fpDataPtr->filename,fmode))==NULL) return 0;
	if ((file_ptr->fd = fopen_f(file_ptr->filename,fmode))==-1) return 0;
	//JMK 24 April 2005: Added print statement here so we know file opened:
	fprintf(stdout,"Opening %s\n",file_ptr->filename);
	return 1;
}

/*
** Function Name: int Filegets(char *s, int n, FILE *fp)
** Purpose: Get a string from a stream, skipping all C and C++ style comments
*/
int fget_str_f(char *s, int n, FILE *fp)
{
	int c;
	int i = 0;
	char init_str[MAX_LENGTH] = "\0";

	//  Clear buffer
	memcpy(s,init_str,sizeof(init_str));

	
	//  Skip leading whitespace
    while (((c=getchar_ignore_comments_f(fp)) != EOF) && isspace(c)){}
    i = 0;
	// start getting each line
	while ((i < n) && (c != EOF) && (c != '\n')){
		s[i++] = c;
		c = getchar_ignore_comments_f(fp);
	}
	return(c);
}

/*
** Function Name: unsigned long filesize(FILE* fpIn)
** Purpose: get the size of the file with file pointer is passed in
*/
unsigned long fsize_f(FILE* file_ptr)
{
    unsigned long fs = 0;
    int i;
    while((i=getc(file_ptr))!=EOF){
        fs++;
	printf("size = %lu\n",fs);
	}
    return fs;
}

/*
** Function Name: int Getc_ignoreComm(FILE *fp)
** Purpose: 
** Get char from the file, ignore the line start with:
**        1. C-style comment (//) 
**        2. C++ style comment 
**        3. '#' sign
*/
int getchar_ignore_comments_f(FILE *file_ptr)
{
  int	c1,c2;

  c1 = fgetc(file_ptr);

  if (c1 != '/' && c1 != '#') return(c1);

  if (c1 == '#')
  {
    while ((c1 != EOF) && (c1 != '\n')) c1 = fgetc(file_ptr);
    return(c1);
  }

  if ((c2 = fgetc(file_ptr)) == '*')  // C-style comment
  {		
    do{
      c1 = c2;
      c2 = fgetc(file_ptr);
    }while (!((c1 == '*') && (c2 == '/')) && (c2 != EOF));
    
	if (c2 == EOF) return(EOF);
    c1 = getchar_ignore_comments_f(file_ptr);
  } 
  else if (c2 == '/')			// C++-sytle comment
  {
    while((c1 != EOF) && (c1 != '\n')) c1 = fgetc(file_ptr);
  }
  else 
    ungetc(c2,file_ptr);
  
  return(c1);
}
/*
** Function Name: int OpenFileInWdir(char *fname, int opt)
** Purpose: open the "fname" file in the working directory
** Description: - input fname: name of the file want to open
**                opt: read (0), write (1), write(2) only for setup file
**              - output: return file descriptor of the file
**   1. Get the current working directory 
*/
int fopen_in_wdir_f(char *fname, int opt)
{
	char cwd[256], pcwd[256], filename[256];
	char *cwdPtr = NULL;
	int fd = -1;
	
    if ((cwdPtr=getcwd(cwd, 256)) == NULL)
	{
		perror("getcwd() error");
		return 0;
	}
	// get its parent directory
	get_path_f(cwd, pcwd);
	// filename = currdir/fname
	sprintf(filename,"%s/%s",cwd,fname);
	if (opt==2)	// for setup file
	{
	   if ((fd = open(filename,O_WRONLY))==-1)
		fprintf(stderr,"Could not open file %s for writing in OpenFileInWdir(): %d - %s\n",filename,errno, strerror(errno));
	}
	else  // for writing data file and reading setup file
	{
	   if ((fd=fopen_f(filename,opt))==-1) printf("Could not open with opt %d\n",opt);
	}
	return fd;
}

/*
** Function Name: int GetPath(char filename[], char* path)
** Purpose: Get the path from the provided filename
*/
void get_path_f(char filename[], char* path)
{
	int indx = 0, i=0;
    size_t val = 0;
                                                                                                                                                                                                                                                                                                    // get index number of the last character '/' of the filename
	val = strlen(filename);
    for(indx=(int)val-1; indx>=0; indx--)   // get the whole path of object file "playback"
       if (filename[indx] == '/') break;   // get the index of the last '/' of the path

	if (indx < 0)  indx = 0;		// indx<0 when filename = "/nameoffile"
	else{
		// copy the whole path for output file's location, this one only happen when index > 0
		for (i=0; i<=indx; i++)
		   *path++ = filename[i];
		*path = '\0';
	}
}

/*
** Function Name: int OpenFile(char *filename, int rwFlag)
** Purpose: open file for reading or writing
*/
int fopen_f(char *filename, int rw_flag)
{
	int fd = 0;
			// O_WRONLY		   for read and writing
			// O_EXCL          error if create and file exists
	//mode_t wmode = O_RDWR | O_CREAT | O_EXCL | S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;
    // JMK 16April05: Fixed permissions (I hope)..
	mode_t wmode = O_RDWR | O_CREAT | O_EXCL;
	mode_t umode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;
	//mode_t rmode = S_IRUSR | S_IRGRP | S_IROTH | S_IWUSR;
	mode_t rmode = O_RDONLY;
	switch(rw_flag)
	{
		case 0:		// for writing
			if((fd = open(filename, wmode))==-1)
			{
				  fprintf(stderr,"Could not open file %s for writing data in OpenFile: %d - %s\n",filename,errno, strerror(errno));
				  return 0;
			}
			//JMK 16 April 2005:
			fchmod(fd,umode);
//			printf("");
		break;
		case 1:		// for reading
			if((fd = open(filename, rmode))==-1)
			{
				  fprintf(stderr,"Could not open file %s for reading data in OpenFile: %d - %s\n",filename,errno, strerror(errno));
				  return 0;
			}
		break;
		default:
		break;
	}
	return fd;
}

