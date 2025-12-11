# *STW (kts) speed through water [$VDVBW]
# *SOG speed over ground (kts) [$GPVTG]
# *COG course over ground (deg) [$GPVTG]
# *Heading direction ship is pointed (deg) [$GPRMC,PSXN20,PSXN23 head]
# Surface Current (kts)
# Surface Current Heading (deg)
# *Ocean Depth Multibeam (m) [$EMDBS]

# GPGGA, GPGLL - lat/lon
# GPHDT - heading from true North
# GPRMC - lat, lon, track angle in degrees, SOG in knots
# GPVTG - track degrees from true north, speed in knots or km
# GPZDA - time and date
# Magellan GPS proprietary format: $MGHCR, $MGHDT, $MGROT, $MGTHS, $MGVER
# $PSXN - position, velocity, roll, pitch, yaw
# $VDDPT - water depth
# $VDVBW - water speed only
# $WIMWV - wind speed
# $WIXDR - wind temperature

ports = [55006, 55004, 55005, 53135]
#ports = [52119,53135,53113,53139,53121,53120,53122,53123,53119,53118,53133,53132,53126,53127,53125,53128,53130,53131]
#ports = [54000,54135,54134,54113,55006,54129,54116,54139,54138,54121,54120,54122,54123,54118,54133,54132,54109,54104,54136,54137,54102,54126,54127,54125,54105,54147,54106,54107,54111,54110,54114,55007,54124,54130,54131,54145]
#53145,53149,53138,53111,53110,53116,53105,53104,53134,53124,53137,53107,53106,53129,53136,53147,53114,53102,

import socket
import select
import sys
import time
import threading

tagSet = set()
tagSetLock = threading.Lock()

def print_messages(port):
    sys.stdout.flush()
    start_time = time.time()
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(('', port))
    sock.setblocking(0)
    msg_timeout = 30
    message = None    
    try:
        while message == None:
            ready = select.select([sock], [], [], msg_timeout + 1)
            if ready[0]:
                data, addr = sock.recvfrom(1024)
                for line in data.decode("utf-8").splitlines():
                    start_index = line.find('$')
                    if start_index != -1:
                        line = line[start_index:]
                    print(f"{port}: {line}")
                    x = line.replace('\n', '').split(',')
                    with tagSetLock:
                        tagSet.add(x[0])
            if time.time() - start_time > msg_timeout:
                break 
    except KeyboardInterrupt:
        print()
    sock.close()

def worker_function(index, port):
    print_messages(port)
    #invtg = wait_for_message(port, '$INVTG')
    #inhdt = wait_for_message(port, '$INHDT')
    #if invbw or invtg or inhdt:
    #    print(f"Found on port {port}!")
    #    exit(1)

threads = []
for index, port in enumerate(ports):
    thread_name = f"Thread-{index}"
    thread = threading.Thread(target=worker_function, args=(index, port), name=thread_name)
    threads.append(thread)
    thread.start()
for thread in threads:
    thread.join()
print("All threads have finished their execution:")
for index, tag in enumerate(sorted(tagSet)):
    print(f"  {tag}")
print(f"{len(tagSet)} unique tag(s) found.")
exit(1)
