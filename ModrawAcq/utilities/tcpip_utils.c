/*
 *  TCPIPUtils.c
 *  FastCTD
 *
 *  Created by Mai on 2/4/05.
 *  Copyright 2005 __MyCompanyName__. All rights reserved.
 *
 */

#include "tcpip_utils.h"
#define PORT_NUMBER 2342

int writeString (int fd, const void *buffer, size_t length)
{
    int result;
    unsigned char byte;

    if (length > 4095) {
        fprintf (stderr, "truncating message to 255 bytes\n");
        length = 4095;
    }
    byte = (unsigned char)length;

    result = (int32_t)write (fd, &byte, 1);
    if (result <= 0) {
        goto bailout;
    }

    do {
        result = (int32_t)write (fd, buffer, length);
        if (result <= 0) {
            goto bailout;
        }
        length -= result;
        buffer += result;
        
    } while (length > 0);

bailout:
    return (result);

} // writeString

// opentcpClient: open TCP connection for client to input hostname:
// open socket, connect (no binding and listenning)
int opentcpClient(char hname[])
{
    int result, fd = -1;
    struct sockaddr_in serverAddress;
    struct hostent *hostInfo;
	
	hostInfo = gethostbyname(hname);
    if (hostInfo == NULL) {
        fprintf (stderr, "could not gethostbyname for '%s'\n", hname);
        fprintf (stderr, " error: %d / %s\n", h_errno, hstrerror(h_errno));
		return -1;
    }
    serverAddress.sin_len = sizeof (struct sockaddr_in);
    serverAddress.sin_family = AF_INET;
    serverAddress.sin_port = htons (PORT_NUMBER);
    serverAddress.sin_addr = *((struct in_addr *)(hostInfo->h_addr));
    memset (&(serverAddress.sin_zero), 0, sizeof(serverAddress.sin_zero));

    result = socket (AF_INET, SOCK_STREAM, 0);

    if (result == -1) {
        fprintf (stderr, "could not make a socket.  error: %d / %s\n",
                 errno, strerror(errno));
		close (fd);
		return -1;
    }
    fd = result;

    // no need to bind() or listen()
    result = connect (fd, (struct sockaddr *)&serverAddress, 
                      sizeof(serverAddress));
    if (result == -1) {
        fprintf (stderr, "could not connect.  error: %d / %s\n",
                 errno, strerror(errno));
		close (fd);
		return -1;
    }
    result = fd;

    return (result);
}

// opentcp: for server(TCP socket)
// create socket, setoptions for socket and binding
int opentcpServer(int port) {
   int error;
   int one = 1;
   struct sockaddr_in server;
   int sock;

   if ((sock = socket(AF_INET, SOCK_STREAM, 0)) == -1)
   {
        fprintf (stderr, "could not make a socket.  error: %d / %s\n",
                 errno, strerror(errno));
		return -1;
   }
   if (setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one)) == -1) {
		fprintf (stderr, "couldn't setsockopt to reuseaddr. %d / %s\n",
				 errno, strerror(errno));
       close(sock);
       return -1;
   }
   if (port > 0) {
      server.sin_family = AF_INET;
      server.sin_addr.s_addr = htonl(INADDR_ANY);
      server.sin_port = htons((short)port);
      if (bind(sock, (struct sockaddr *)&server, sizeof(server)) == -1) {
		 fprintf (stderr, "could not bind socket.  error: %d / %s\n",
                     errno, strerror(errno));
         error = errno;
         close(sock);
         errno = error;
         return -1;
      }  
   }   
   return sock;
}

// startListening: for server (TCP socket)
// create socket, setoptions for socket, binding and listenning
int ServerStartListening (int port)	// for server
{
    struct sockaddr_in address;
    int fd = -1, success = 0;
    int result;

    result = socket (AF_INET, SOCK_STREAM, 0);
    
    if (result == -1) {
        fprintf (stderr, "could not make a socket.  error: %d / %s\n",
                 errno, strerror(errno));
        goto bailout;
    }
    fd = result;


    // bind to an address and port
    
    memset (&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl (INADDR_ANY);
    address.sin_port = htons ((short)port);
    address.sin_len = sizeof (struct sockaddr_in);

    result = bind (fd, (struct sockaddr *)&address, sizeof(address));
    if (result == -1) {
        fprintf (stderr, "could not bind socket.  error: %d / %s\n",
                 errno, strerror(errno));
        goto bailout;
    }
    
	// allow 1024 queue
    result = listen (fd, 1024);

    if (result == -1) {
        fprintf (stderr, "listen failed.  error: %d /  %s\n",
                 errno, strerror(errno));
        goto bailout;
    }

    success = 1;

bailout:
    if (!success) {
        close (fd);
        fd = -1;
    }

    return (fd);

} // SererStartListening
