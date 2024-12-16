import select
import socket
import sys
import time

def wait_for_message(port, name):
    print(f"Waiting for {name} on UDP port {port}...", end="")
    sys.stdout.flush()
    start_time = time.time()
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(('', port))
    sock.setblocking(0)
    msg_timeout = 10
    message = None    
    try:
        while message == None:
            ready = select.select([sock], [], [], msg_timeout + 1)
            if ready[0]:
                data, addr = sock.recvfrom(1024)
                for line in data.decode("utf-8").splitlines():
                    x = line.replace('\n', '').split(',')
                    if x[0] == name:
                        message = x
                        print(" \033[1;32mOk.\033[0m")
                        break
            if time.time() - start_time > msg_timeout:
                print(" \033[1;31mTimeout!\033[0m")
                break 
    except KeyboardInterrupt:
        print()
    sock.close()
    return message
