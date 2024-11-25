import socket, time

server_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
server_socket.settimeout(0.2)

#server_address = ('255.255.255.255', 12345)
#server_address = ('127.0.0.1', 12345)
server_address = ('<broadcast>', 37020)

while True:
    message = "!a1_g"
    server_socket.sendto(message.encode(), server_address)
    print(f"Sending: {message}")
    time.sleep(1.0)
