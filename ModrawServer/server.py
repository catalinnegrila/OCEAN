import socket
import time

server = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
server.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
server.settimeout(0.2)
counter = 0
while True:
    counter += 1
    message = str.encode(f"your very important message ({counter})")
    server.sendto(message, ('<broadcast>', 37020))
    #server.sendto(message, ('255.255.255.255', 37020))
    print(f"sending: '{message}'")
    time.sleep(1)