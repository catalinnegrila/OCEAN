import socket

client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client.connect(('moloz', 31415)) #10.5.0.53
client.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)

client.send(b"!modraw")
data = client.recv(512)
print(f"Received: {data}")
client.close()