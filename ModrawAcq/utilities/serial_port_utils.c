#include "serial_port_utils.h"

// Given the file descriptor for a serial device, close that device.
void CloseSerialPort(SerialPortDataPtr serport)
{
    // Traditionally it is good to reset a serial port back to
    // the state in which you found it.  Let's continue that tradition.
    if (tcsetattr(serport->spd, TCSANOW, &serport->gOriginalTTYAttrs) == -1)
    {
        printf("Error resetting tty attributes - %s(%d).\n",
            strerror(errno), errno);
    }

    close(serport->spd);
}


void InitSerialPort(SerialPortDataPtr serport, char* spName)
{
	// portnumber was assign in CheckInput()
	serport->reqReadSize = 1;
	serport->totalBytesSPread = 0;
	serport->doneRead = 0;
	strcpy(serport->serialPortName,spName);
	SetOptionsSerialPort(serport);
}
void InitSerialPort4Writting(SerialPortDataPtr serport, char* spName)
{
	strcpy(serport->serialPortName,spName);
	SetOptionsSerialPort(serport);
}

// Given the path to a serial device, open the device and configure it.
// Return the file descriptor associated with the device.
int OpenSerialPort(SerialPortDataPtr serport)
{
    serport->spd = open(serport->serialPortName, O_RDWR | O_NOCTTY | O_NDELAY | O_NONBLOCK);
//    //ALB 03/14/2021
//    setbuffer(serport->spd,NULL,10000);
    if (serport->spd == -1)
    {
        printf("Error opening serial port %s - %s(%d).\n",
               serport->serialPortName, strerror(errno), errno);
        goto error;
    }
	else
		printf("Open serial port: %s\n", serport->serialPortName);
    if (fcntl(serport->spd, F_SETFL, 0) == -1)
    {
        printf("Error clearing O_NDELAY %s - %s(%d).\n",
            serport->serialPortName, strerror(errno), errno);
        goto error;
    }
    
    // Get the current options and save them for later reset
    if (tcgetattr(serport->spd, &serport->gOriginalTTYAttrs) == -1)
    {
        printf("Error getting tty attributes in tcgetattr %s - %s(%d).\n",
            serport->serialPortName, strerror(errno), errno);
        goto error;
    }

    // Set the options for serial port for port #portnum
    if (tcsetattr(serport->spd, TCSANOW, &serport->spOptions) == -1)
    {
        printf("Error setting tty attributes in tcsetattr %s - %s(%d).\n",
            serport->serialPortName, strerror(errno), errno);
        goto error;
    }

    // Success
	return 0;
    
    // Failure path
error:
    if (serport->spd != -1)
        close(serport->spd);
    return 1;
}

Boolean RealeaseSPRead(SerialPortDataPtr serportPtr)
{
		serportPtr->spOptions.c_cc[ VMIN ] = 0;
		if (tcsetattr(serportPtr->spd, TCSANOW, &serportPtr->spOptions) == -1)
		{
			printf("Error setting tty attributes %s(%d).\n",
				strerror(errno), errno);
			return false;
		}
	return true;
}

void SetOptionsSerialPort(SerialPortDataPtr serport)
{
	// Set raw input, one second timeout
	// These options are documented in the man page for termios
	// (in Terminal enter: man termios)
	serport->spOptions = serport->gOriginalTTYAttrs;
	serport->spOptions.c_cflag |= (CLOCAL | CREAD | CS8);
	serport->spOptions.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
	serport->spOptions.c_oflag &= ~OPOST;
	serport->spOptions.c_cc[ VMIN ] = 1;
	serport->spOptions.c_cc[ VTIME ] = 20;   // 2  secs
}

// Given the file descriptor for a serial port, send some hello
// Return true if successful, otherwise false.
ssize_t WriteData(int fd, char* tempString)
{
    ssize_t	numBytes =0;	// Number of bytes read or written
	char tstr[MAX_LENGTH] = "\0";
	int i = 0;
	uint32_t strl;
	strl = (uint32_t)strlen(tempString);
	
	numBytes = write(fd, tempString,strl);
	if (numBytes == -1)
	{
		printf("Error writing to Serial port - %s(%d) at serialPortDescriptor = %d\n",
			   strerror(errno), errno, fd);
		return 0;
	}
	for (i=0; i<strl; i++){
		tstr[i] = tempString[i];
	}
	tstr[i] = '\0';

    return numBytes;
}





