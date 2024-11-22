/*
 *  UDPUtils.c
 *  FastCTD
 *
 *  Created by Mai on 1/27/05.
 *  Copyright 2005 __MyCompanyName__. All rights reserved.
 *
 */

#include "udp_utils.h"

int u_openudp(void) {
   int error;
   int one = 1;
//   struct sockaddr_in server;
   int sock;

   if ((sock = socket(AF_INET, SOCK_DGRAM, 0)) == -1)
      return -1;
   if (setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &one, sizeof(one)) == -1) {
      error = errno;
      close(sock);
      errno = error;
      return -1;
   }
//   if (port > 0) {
//      server.sin_family = AF_INET;
//      server.sin_addr.s_addr = htonl(INADDR_ANY);
//      server.sin_port = htons((short)port);
//      if (bind(sock, (struct sockaddr *)&server, sizeof(server)) == -1) {
//         error = errno;
//         close(sock);
//         errno = error;
//         return -1;
//      }
//   }
   return sock;
}

int InitUDP(struct sockaddr_in *sInfoPtr,int port)
{
	sInfoPtr->sin_len = sizeof (struct sockaddr_in);
	sInfoPtr->sin_family = AF_INET;
	sInfoPtr->sin_port = htons (port);
	sInfoPtr->sin_addr.s_addr = htonl(INADDR_BROADCAST);
	memset (sInfoPtr->sin_zero, 0, sizeof(sInfoPtr->sin_zero));
    return 0;
}

ssize_t u_sendto(int fd, void *buf, size_t nbytes, struct sockaddr_in *sInfoPtr) {
   int len;
   struct sockaddr *remotep;
   int retval;

   len = sizeof(struct sockaddr_in);
   remotep = (struct sockaddr *)sInfoPtr;
   while (((retval = (int32_t)sendto(fd, buf, nbytes, 0, remotep, len)) == -1) &&
           (errno == EINTR)) ;  
   return retval;
}


