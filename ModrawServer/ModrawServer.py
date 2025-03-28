from abc import ABC, abstractmethod
import os, sys, socket, subprocess, time
from dataclasses import dataclass

# Sources:
#  Folder: set source_dir, and sim_mode = False
#  Simulator: set source_dir, and sim_mode = True
# Destinations:
#  Folder: set destination_dir
#  Socket: do not set destination_dir

port = 31415
dir_scan_freq = 0.025 # Seconds between scanning for changes to the source folder
sim_block_size = 512 * 2

source_dir = "/Users/Shared/FCTD_EPSI_DATA/Current_Cruise/"
if os.path.exists(source_dir):
    # Lab machine automatic configuration
    sim_mode = False
    destination_dir = None
else:
    # Local development configuration
    print(f"\033[1;31m!!! Running in simulator mode !!!\033[0m\n")
    source_dir = "/Users/catalin/Projects/OCEAN_data/epsi_data/"
    sim_mode = (socket.gethostname() == "Catalins-MacBook-Pro.local")
    #destination_dir = "/Users/catalin/Projects/OCEAN_data/out/"
    destination_dir = None

print(f"Source directory: {source_dir}\n") 

try:
    import zeroconf

    def get_MODraw_service_info(hostname, IPAddr, port):
        return zeroconf.ServiceInfo(
                "_http._tcp.local.",
                "ModrawServer._http._tcp.local.",
                addresses=[socket.inet_aton(IPAddr)],
                port=port,
                properties={'description': 'Modraw streaming for realtime EPSI/FCTD visualization.'},
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

def enumerate_all_files(dir):
    file_names = [os.path.join(dir, f) for f in os.listdir(dir) if os.path.isfile(os.path.join(dir, f)) and os.path.splitext(f)[1] == ".modraw"]
    file_names.sort()
    return file_names

@dataclass
class FileInfo:
    path: str
    size: int
    def __init__(self, path):
        self.path = path
        self.size = os.path.getsize(path)

class SimulatorFileInfo(FileInfo):
    real_size: int
    def __init__(self, path):
        FileInfo.__init__(self, path)
        self.real_size = self.size
        self.size = 0

class ModrawFileSource(ABC):
    def __init__(self, source_dir):
        self.source_dir = source_dir

    @abstractmethod
    def updateMostRecentFileSize(self, file_path):
        pass
    @abstractmethod
    def getMostRecentFile(self):
        pass

class ModrawFilesFromUpdatingFolderSource(ModrawFileSource):
    def updateMostRecentFileSize(self, file_path):
        return FileInfo(file_path)

    def getMostRecentFile(self):
        all_files = enumerate_all_files(source_dir)
        if len(all_files) > 0:
            return FileInfo(all_files[-1])
        return None

class ModrawFilesFromSimulatedFolderSource(ModrawFileSource):
    def __init__(self, source_dir):
        ModrawFileSource.__init__(self, source_dir)
        self.all_files = enumerate_all_files(source_dir)
        print(f"Starting simulation with {len(self.all_files)} file(s)")
        if len(self.all_files) == 0:
            print(f"{source_dir} is empty. Nothing to do.")
            exit(1)
        self.current_file_idx = 0
        self.current_file = SimulatorFileInfo(self.all_files[self.current_file_idx])

    def updateMostRecentFileSize(self, file_path):
        assert(self.current_file.path == file_path)
        if self.current_file.size < self.current_file.real_size:
            new_size = min(self.current_file.real_size, self.current_file.size + sim_block_size)
            self.current_file = SimulatorFileInfo(file_path)
            self.current_file.size = new_size
        return self.current_file

    def getMostRecentFile(self):
        if self.current_file != None and self.current_file.size == self.current_file.real_size:
            if self.current_file_idx < len(self.all_files) - 1:
                self.current_file_idx += 1
                self.current_file = SimulatorFileInfo(self.all_files[self.current_file_idx])
            else:
                print("Simulation ended.")
        return self.current_file

class ModrawDestination(ABC):
    @abstractmethod
    def isStopped(self):
        pass

    @abstractmethod
    def appendBlock(self, src_file_path, dst_file_size, block):
        pass

class ModrawSocketDestination(ModrawDestination):
    def __init__(self, connection):
        self.connection = connection

    def isStopped(self):
        try:
            # this will try to read bytes without blocking and also without removing them from buffer (peek only)
            data = self.connection.recv(16, socket.MSG_DONTWAIT | socket.MSG_PEEK)
            if len(data) == 0:
                return True
        except BlockingIOError:
            return False  # socket is open and reading from it would block
        #except ConnectionResetError:
        #    return True  # socket was closed for some other reason
        return False

    def appendBlock(self, src_file_path, dst_file_size, block):
        if dst_file_size == 0:
            self.connection.send(str.encode("!modraw") + block)
        else:
            self.connection.send(block)

class ModrawFolderDestination(ModrawDestination):
    def __init__(self, destination_dir):
        self.destination_dir = destination_dir
        print(f"Sync destination: {destination_dir}")
        if not os.path.exists(destination_dir):
            os.mkdir(destination_dir)

    def isStopped(self):
        return False

    def appendBlock(self, src_file_path, dst_file_size, block):
        src_file_name = os.path.basename(src_file_path)
        dst_file_path = os.path.join(self.destination_dir, src_file_name)
        with open(dst_file_path, 'a+b') as dst_f:
            dst_f.seek(dst_file_size)
            dst_f.write(block)

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

def sync_file(src_file, modraw_destination, dst_file_size):
    if src_file.size > dst_file_size:
        with open(src_file.path, 'rb') as src_f:
            src_f.seek(dst_file_size)
            block = src_f.read(src_file.size - dst_file_size)
            modraw_destination.appendBlock(src_file.path, dst_file_size, block)
            src_file_name = os.path.basename(src_file.path)
            status = f"  {src_file_name}: size {format_bytesize(dst_file_size)}, last append {len(block)}"
            if dst_file_size == 0:
                print(status)
            else:
                columns, _ = os.get_terminal_size()
                print("\033[1F" + status + " "*(columns - len(status)))
            return True
    return False

def stream_from_dir(modraw_destination, dir_scan_freq):
    modraw_source = createModrawSource()
    print(f"Watching {modraw_source.source_dir} for changes... Press Ctrl+C to stop.")
    most_recent_file = None
    while not modraw_destination.isStopped():
        time.sleep(dir_scan_freq)
        most_recent_file_changed = False
        # If we have a file syncing, check if its size has changed
        if most_recent_file != None:
            new_most_recent_file = modraw_source.updateMostRecentFileSize(most_recent_file.path)
            if sync_file(new_most_recent_file, modraw_destination, most_recent_file.size):
                most_recent_file.size = new_most_recent_file.size
                most_recent_file_changed = True
        # If we don't have a file already syncing,
        # or the currently syncing file hasn't changed
        if not most_recent_file_changed:
            # Has a newer file been created?
            new_most_recent_file = modraw_source.getMostRecentFile()
            if new_most_recent_file != None and \
                (most_recent_file == None or new_most_recent_file.path != most_recent_file.path):
                sync_file(new_most_recent_file, modraw_destination, 0)
                most_recent_file = new_most_recent_file

def wait_on_socket(IPAddr, port):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)  
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind((IPAddr, port))
        sock.listen(5)
        while True:
            print()
            print(f"Waiting for client to connect to {IPAddr}:{port}...")
            connection,address = sock.accept()
            print(f"Connection started from {address[0]}:{address[1]}")
            buf = connection.recv(100).decode("utf-8")
            if buf != "!modraw":
                print(f"Received invalid request: {buf}")
                print("Connection rejected by the server.")
            else:
                connection.send(str.encode("!reset"))
                modraw_destination = ModrawSocketDestination(connection)
                stream_from_dir(modraw_destination, dir_scan_freq)
            connection.close()

    except BrokenPipeError as e:
        print(f"Connection closed. {e}")
    except ConnectionResetError as e:
        print(f"Connection closed. {e}")
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

def stream_to_socket():
    hostname = socket.gethostname()
    IPAddr = get_my_ip(hostname)
    info = get_MODraw_service_info(hostname, IPAddr, port)
    zc = register_MODraw_service(info)
    try:
        while True:
            wait_on_socket(IPAddr, port)
    finally:
        unregister_MODraw_service(zc, info)

def createModrawSource():
    if sim_mode:
        return ModrawFilesFromSimulatedFolderSource(source_dir)
    else:
        return ModrawFilesFromUpdatingFolderSource(source_dir)

def stream_to_dir():
    modraw_destination = ModrawFolderDestination(destination_dir)
    stream_from_dir(modraw_destination, dir_scan_freq)

try:
    if not os.path.exists(source_dir):
        print(f"Source directory {source_dir} does not exist! Nothing to do.")
        exit(1)

    if destination_dir == None:
        stream_to_socket()
    else:
        stream_to_dir()
except KeyboardInterrupt:
    pass
