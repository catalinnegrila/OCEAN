import socket

IPAddr = '10.5.0.151'
#IPAddr = '127.0.0.1'
port = 31415

try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.connect((IPAddr, port))
    sock.send("!modraw".encode())
    buf = sock.recv(1024)
    print(buf)

finally:
    sock.close()