import os, sys, socket, subprocess, time
from dataclasses import dataclass

hostname = socket.gethostname()
port = 31415

current_cruise_path = "/Users/Shared/FCTD_EPSI_DATA/Current_Cruise/"
if os.path.exists(current_cruise_path):
    source_dir = current_cruise_path
    sim_mode = False
else:
    source_dir = "/Users/catalin/Documents/OCEAN_data/Freeze/"
    sim_mode = (hostname == "Catalins-MacBook-Pro.local")

dir_scan_freq = 0.025
sim_block_size = 512

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
        print("Server registered with mDNS.")
        return zc

    def unregister_MODraw_service(zc, info):
        zc.unregister_service(info)
        zc.close()
        print("Server unregistered from mDNS.")

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
    sim_size: int
    def __init__(self, path):
        self.path = path
        if sim_mode:
            self.size = 0
            self.sim_size = os.path.getsize(path)
        else:
            self.size = os.path.getsize(path)
            self.sim_size = 0

sim_all_files = []
sim_current_file = None

def get_all_files():
    file_names = [os.path.join(source_dir, f) for f in os.listdir(source_dir) if os.path.isfile(os.path.join(source_dir, f)) and os.path.splitext(f)[1] == ".modraw"]
    file_names.sort()
    return file_names

def restart_simulation():
    if sim_mode:
        print("!!!Running in simulator mode!!!")
        global sim_all_files, sim_current_file_idx, sim_current_file
        sim_all_files = get_all_files()
        if len(sim_all_files) == 0:
            print(f"{source_dir} is empty. Nothing to do.")
            exit(1)
        sim_current_file_idx = 0
        sim_current_file = FileInfo(sim_all_files[sim_current_file_idx])
        #sim_current_file.size = current_file.sim_size - 250 * 1024

def refresh_most_recent_file(file_path):
    if sim_mode:
        global sim_current_file
        assert(sim_current_file.path == file_path)
        if sim_current_file.size < sim_current_file.sim_size:
            new_size = min(sim_current_file.sim_size, sim_current_file.size + sim_block_size)
            sim_current_file = FileInfo(file_path)
            sim_current_file.size = new_size
        return sim_current_file
    else:
        return FileInfo(file_path)

def get_most_recent_file_from(dir_path):
    if sim_mode:
        global sim_all_files, sim_current_file_idx, sim_current_file
        if sim_current_file != None and sim_current_file.size == sim_current_file.sim_size:
            if sim_current_file_idx < len(sim_all_files) - 1:
                sim_current_file_idx += 1
                sim_current_file = FileInfo(sim_all_files[sim_current_file_idx])
            else:
                sim_current_file = None
        return sim_current_file
    else:
        all_files = get_all_files()
        if len(all_files) > 0:
            return FileInfo(all_files[-1])
        return None

def format_bytesize(num, suffix="B"):
    if abs(num) < 1024.0:
        return f"{num} bytes"
    for unit in ("", "K", "M", "G", "T", "P", "E", "Z"):
        if abs(num) < 1024.0:
            return f"{num:3.1f} {unit}{suffix}"
        num /= 1024.0
    return f"{num:.1f} Y{suffix}"

def erase_line():
    columns, _ = os.get_terminal_size()
    print(" "*columns, end="\r")

def sync_file(src_file, connection, dst_file_size):
    if src_file.size > dst_file_size:
        with open(src_file.path, 'rb') as src_f:
            src_f.seek(dst_file_size)
            block = src_f.read(src_file.size - dst_file_size)
            src_file_name = os.path.basename(src_file.path)
            status = f"  {src_file_name}: size {format_bytesize(dst_file_size)}, last append {len(block)}"
            if dst_file_size == 0:
                connection.send(str.encode("!modraw") + block)
                print(status)
            else:
                connection.send(block)
                columns, _ = os.get_terminal_size()
                print("\033[1F" + status + " "*(columns - len(status)))
            return True
    return False

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
    return False

def stream_dir(src_dir, connection, dir_scan_freq):
    print(f"Watching {src_dir} for changes... Press Ctrl+C to stop.")
    most_recent_file = None
    while not is_connection_closed(connection):
        time.sleep(dir_scan_freq)
        most_recent_file_changed = False
        # If we have a file syncing, check if its size has changed
        if most_recent_file != None:
            new_most_recent_file = refresh_most_recent_file(most_recent_file.path)
            if sync_file(new_most_recent_file, connection, most_recent_file.size):
                most_recent_file.size = new_most_recent_file.size
                most_recent_file_changed = True
        # If we don't have a file already syncing,
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
        connection.send(str.encode("!reset"))
        stream_dir(source_dir, connection, dir_scan_freq)
    connection.close()

def wait_on_socket(IPAddr, port):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)  
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind((IPAddr, port))
        sock.listen(5)
        while True:
            print()
            restart_simulation()
            print(f"Waiting for client to connect to tcp://{IPAddr}:{port}...")
            accept_connection(sock)
    except BrokenPipeError as e:
        print(f"Connection closed. {e}")
    except ConnectionResetError as e:
        print(f"Connection closed. {e}")
    except KeyboardInterrupt:
        print("\r  ")
        raise
    finally:
        sock.close()

def get_my_ip(hostname):
    result = subprocess.run(["ifconfig"], capture_output=True, text=True)
    for line in result.stdout.splitlines():
        x = line.strip()
        if x.startswith("inet "):
            ip = x.split(" ")[1]
            if not ip.startswith("127."):
                return ip
    return "127.0.0.1"

try:
    IPAddr = get_my_ip(hostname)
    info = get_MODraw_service_info(hostname, IPAddr, port)
    zc = register_MODraw_service(info)
    while True:
        wait_on_socket(IPAddr, port)

except KeyboardInterrupt:
    print("Sync stopped.")

finally:
    unregister_MODraw_service(zc, info)
