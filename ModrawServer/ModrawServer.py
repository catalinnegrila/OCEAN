import os, sys, socket, subprocess, time
from dataclasses import dataclass

source_dir = "/Users/Shared/FCTD_EPSI_DATA/Current_Cruise/"
dir_scan_freq = 0.025

try:
    import zeroconf

    def get_MODraw_service_info(hostname, IPAddr, port):
        return zeroconf.ServiceInfo(
                "_http._tcp.local.",
                "MODraw Server._http._tcp.local.",
                addresses=[socket.inet_aton(IPAddr)],
                port=port,
                properties={'description': 'MODraw streaming for realtime EPSI/FCTD visualization.'},
                server=hostname
            )

    def register_MODraw_service(info):
        zc = zeroconf.Zeroconf()
        zc.register_service(info)
        print('Server registered with mDNS.')
        return zc

    def unregister_MODraw_service(zc, info):
        zc.unregister_service(info)
        zc.close()
        print('Server unregistered from mDNS.')

except ImportError:
    def get_MODraw_service_info(hostname, IPAddr, port):
        print(f"zeroconf not installed. Automatic service discovery not available!")
        return None

    def register_MODraw_service(info):
        return None

    def unregister_MODraw_service(zeroconf, info):
        print("zeroconf not installed. Nothing to unregister.")
        pass

@dataclass
class FileInfo:
    path: str
    size: int
    def __init__(self, path):
        self.path = path
        self.size = os.path.getsize(path)

def get_most_recent_file_from(dir_path):
    file_names = [os.path.join(dir_path, f) for f in os.listdir(dir_path) if os.path.isfile(os.path.join(dir_path, f)) and os.path.splitext(f)[1] == ".modraw"]
    if len(file_names) > 0:
        file_names.sort()
        return FileInfo(file_names[-1])
    return None

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
            print(f"  {src_file_name}: new file, initial size {format_bytesize(len(block))}                          ")
        else:
            connection.send(block)
            print(f"  {src_file_name}: current size {format_bytesize(dst_file_size)} appending {len(block)}", end="\r")

def is_connection_closed(connection) -> bool:
    try:
        # this will try to read bytes without blocking and also without removing them from buffer (peek only)
        data = connection.recv(16, socket.MSG_DONTWAIT | socket.MSG_PEEK)
        if len(data) == 0:
            return True
    except BlockingIOError:
        return False  # socket is open and reading from it would block
    except ConnectionResetError:
        return True  # socket was closed for some other reason
    except Exception as e:
        print(f"Unexpected exception: {e}")
        return False
    return False

def stream_dir(src_dir, connection, dir_scan_freq):
    print(f"Watching {src_dir} for changes... Press Ctrl+C to stop.")
    most_recent_file = get_most_recent_file_from(src_dir)
    if most_recent_file != None:
        sync_file(most_recent_file, connection, 0)
    while not is_connection_closed(connection):
        time.sleep(dir_scan_freq)
        most_recent_file_changed = False
        # If we have a file syncing, check if its size has changed
        if most_recent_file != None:
            new_most_recent_file = FileInfo(most_recent_file.path)
            if new_most_recent_file.size > most_recent_file.size:
                sync_file(new_most_recent_file, connection, most_recent_file.size)
                most_recent_file = new_most_recent_file
                most_recent_file_changed = True
        # If we don't have any files syncing,
        # or the currently syncing file hasn't changed
        if not most_recent_file_changed:
            # Has a newer file been created?
            new_most_recent_file = get_most_recent_file_from(src_dir)
            if new_most_recent_file != None and \
                (most_recent_file == None or new_most_recent_file.path != most_recent_file.path):
                sync_file(new_most_recent_file, connection, 0)
                most_recent_file = new_most_recent_file

def accept_connection(sock):
    connection,address = sock.accept()  
    print(f"Connection started from {address[0]}:{address[1]}")
    buf = connection.recv(100).decode("utf-8")
    if buf != "!modraw":
        print(f"Received invalid request: {buf}")
        print("Connection rejected by the server.")
    else:
        stream_dir(source_dir, connection, dir_scan_freq)
        print("Connection completed by the client.                       ")
    connection.close()

def wait_on_socket(IPAddr, port):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)  
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind((IPAddr, port))
        sock.listen(5)
        while True:
            print(f"Waiting for client to connect to tcp://{IPAddr}:{port}...")
            accept_connection(sock)
    except KeyboardInterrupt:
        raise # Pipe down the Ctrl+C
    except Exception as e:
        print(f"Exception: {e}")
    finally:
        sock.close()
        print("Socket closed.")

def get_my_ip(hostname):
    #ip_addresses = socket.gethostbyname_ex(hostname)[2]
    #filtered_ips = [ip for ip in ip_addresses if not ip.startswith("127.")]
    #if len(filtered_ips) > 0:
    #    return filtered_ips[0]
    result = subprocess.run(["ifconfig"], capture_output=True, text=True)
    for line in result.stdout.splitlines():
        x = line.strip()
        if x.startswith("inet "):
            ip = x.split(" ")[1]
            if not ip.startswith("127."):
                return ip
    return "127.0.0.1"

hostname = socket.gethostname()
IPAddr = get_my_ip(hostname)
port = 31415

try:
    info = get_MODraw_service_info(hostname, IPAddr, port)
    zc = register_MODraw_service(info)
    while True:
        wait_on_socket(IPAddr, port)

except KeyboardInterrupt:
    print('Sync stopped.')

finally:
    #unregister_MODraw_service(zc, info)
    pass