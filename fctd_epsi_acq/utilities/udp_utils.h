/*
 *  UDPUtils.h
 *  FastCTD
 *
 *  Created by Mai on 1/27/05.
 *  Copyright 2005 __MyCompanyName__. All rights reserved.
 *
 */
#ifndef UDPUTILS_H
#define UDPUTILS_H

#import <sys/types.h>   // random types
#import <netinet/in.h>  // for sockaddr_in
#import <sys/socket.h>  // for socket(), AF_INET
#import <arpa/inet.h>   // for inet_ntoa
#import <errno.h>       // for errno
#import <string.h>      // for strerror
#import <stdlib.h>      // for EXIT_SUCCESS
#include <stdio.h>
#import <unistd.h>      // for close

#define PORT_NUMBER 2342

typedef struct UDPStruct
{
	int portnum;
	int udpfd;
	unsigned int sendBytes;
	struct sockaddr_in sockaddInfo;
}UDPStruct, *UDPStructPtr;

int u_openudp(void);
ssize_t u_sendto(int fd, void *buf, size_t nbytes, struct sockaddr_in *sInfoPtr);
int InitUDP(struct sockaddr_in *sInfoPtr, int port);

#endif


