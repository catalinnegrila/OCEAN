import os, sys, socket, time
from dataclasses import dataclass

source_dir = "/Users/catalin/Documents/OCEAN_data/out/"
dir_scan_freq = 0.025

@dataclass
class FileInfo:
    path: str
    size: int

def get_most_recent_file_from(dir_path):
    file_names = [os.path.join(dir_path, f) for f in os.listdir(dir_path) if os.path.isfile(os.path.join(dir_path, f))]
    file_names.sort()
    file_info = FileInfo(file_names[-1], os.path.getsize(file_names[-1]))
    return file_info

def format_bytesize(num, suffix="B"):
    if abs(num) < 1024.0:
        return f"{num} bytes"
    for unit in ("", "K", "M", "G", "T", "P", "E", "Z"):
        if abs(num) < 1024.0:
            return f"{num:3.1f} {unit}{suffix}"
        num /= 1024.0
    return f"{num:.1f} Y{suffix}"

def sync_file(src_file, connection, dst_file_size):
    src_file_name = os.path.basename(src_file.path)
    with open(src_file.path, 'rb') as src_f:
        src_f.seek(dst_file_size)
        block = src_f.read(src_file.size - dst_file_size)
        if dst_file_size == 0:
            connection.send(str.encode("!modraw") + block)
            print(f"{src_file_name}: new file, size {format_bytesize(len(block))}                          ")
        else:
            connection.send(block)
            print(f"{src_file_name}: size {format_bytesize(dst_file_size)} appending {len(block)}", end="\r")
    
def stream_dir(src_dir, connection, dir_scan_freq):
    print(f"Watching {src_dir} for changes... Press Ctrl+C to stop.")
    most_recent_file = get_most_recent_file_from(src_dir)
    sync_file(most_recent_file, connection, 0)
    while True:
        time.sleep(dir_scan_freq)
        new_most_recent_file = get_most_recent_file_from(src_dir)
        if new_most_recent_file.path == most_recent_file.path:
            # No new files, has the size changed?
            if new_most_recent_file.size > most_recent_file.size:
                sync_file(new_most_recent_file, connection, most_recent_file.size)
        else:
            # Finish uploading the previous file
            prev_file_size = most_recent_file.size
            most_recent_file.size = os.path.getsize(most_recent_file.path)
            if most_recent_file.size > prev_file_size:
                sync_file(most_recent_file, connection, prev_file_size)
            # Start uploading the new most recent file
            sync_file(new_most_recent_file, connection, 0)
        most_recent_file = new_most_recent_file

def accept_connection(sock):
    connection,address = sock.accept()  
    print(f"Connection started from address: {address}")
    buf = connection.recv(1024).decode("utf-8")
    if buf != "!modraw":
        print(f"Received invalid request: {buf}")
        connection.close()
        print("Connection rejected.")
    else:
        try:
            stream_dir(source_dir, connection, dir_scan_freq)
        finally:
            print()
        print("Connection completed by the client.")
        connection.close()
    connection.close()

def wait_on_socket():
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)  
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        port = 31415
        sock.bind(('127.0.0.1', port))
        sock.listen(5)  
        while True:  
            print(f"Waiting for client to connect on port {port}...")
            accept_connection(sock)

    except BrokenPipeError:
        print("Connection closed by the server.")

    finally:
        sock.close()
        print("Socket closed.")

try:
    while True:
        wait_on_socket()

except KeyboardInterrupt:
    print('Sync stopped.')
