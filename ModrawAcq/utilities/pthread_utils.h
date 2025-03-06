#ifndef PTHREADUTILS_H
#define PTHREADUTILS_H

#include <mach/mach_init.h>
/*#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <pthread.h>

#include <time.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <paths.h>
#include <termios.h>
#include <sysexits.h>
#include <sys/param.h>

#include <CoreFoundation/CoreFoundation.h>

#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#include <mach/thread_policy.h>
#include <err.h>
*/
#include "globals.h"
#include "file_utils.h"
#include "serial_port_utils.h"
#include "fctd_epsi.h"

#define WARN_TIME 2
#define NUM_THREADS 8   // 8 threads for now: ReadFishCTDdataFromPort(),ReadPCodeDataFromPort(), ReadWinchControl(),
						//						WriteCTDdataIntoFile(), WriteCTDdataViaSerialPort(), CheckDataIsBlocked(), StopFastCTD()
						//                      TCPIPSocketServer();
void fctd_epsi_create_threads_f(pthread_t*, fctd_epsi_ptr_t);
void fctd_epsi_join_threads_f(pthread_t thread_list[]);
void *write_ctd_data_to_file_f(void *arg);
void *check_if_data_is_blocked_f(void *arg);
void *stop_ftcd_epsi_f(void *arg);
void *tcp_ip_server_f(void *arg);
// copy from /usrs/include/mach/thread_policy.h since it's commented out in that file
kern_return_t   set_thread_policy_f(thread_act_t thread,thread_policy_flavor_t flavor, thread_policy_t policy_info, mach_msg_type_number_t count);
int set_realtime_f(int period, int computation, int constraint);  // MNB Aug 14, 2012

#endif
