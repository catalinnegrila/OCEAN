import os
import time

def scan_dir(dir_path):
    # Only sync the 2 most recent files for realtime rendering
    file_names = [os.path.join(dir_path, f) for f in os.listdir(dir_path) if os.path.isfile(os.path.join(dir_path, f))]
    file_names.sort()
    files = {}
    for f in file_names[-2:]:
        files[f] = os.path.getsize(f)
    return files

def sizeof_fmt(num, suffix="B"):
    if abs(num) < 1024.0:
        return f"{num} bytes"
    for unit in ("", "K", "M", "G", "T", "P", "E", "Z"):
        if abs(num) < 1024.0:
            return f"{num:3.1f} {unit}{suffix}"
        num /= 1024.0
    return f"{num:.1f} Y{suffix}"

def sync_file(src_file, src_file_size, dst_dir, dst_file_size):
    src_file_name = os.path.basename(src_file)
    dst_file = os.path.join(dst_dir, src_file_name)
    if src_file_size > dst_file_size:
        with open(src_file, 'rb') as src_f:
            src_f.seek(dst_file_size)
            block = src_f.read(src_file_size - dst_file_size)
            with open(dst_file, 'a+b') as dst_f:
                dst_f.seek(dst_file_size)
                dst_f.write(block)
                if dst_file_size == 0:
                    print(f"{src_file_name}: created with size {sizeof_fmt(len(block))}")
                else:
                    print(f"{src_file_name}: appended {sizeof_fmt(len(block))}")
    else:
        print(f"{src_file_name}: unchanged")

def sync_dir(src_dir, current_files, dst_dir, last_scanned_files):
    for f in current_files:
        src_file_size = current_files[f]
        if f in last_scanned_files:
            dst_file_size = last_scanned_files[f]
        else:
            dst_file_size = 0
        if (not f in last_scanned_files) or (src_file_size != dst_file_size):
            sync_file(f, src_file_size, dst_dir, dst_file_size)
    
def watch_and_sync_dir(src_dir, dst_dir, dir_scan_freq):
    print(f"Sync source: {src_dir}")
    print(f"Sync destination: {dst_dir}")

    if not os.path.exists(dst_dir):
        os.mkdir(dst_dir)

    last_scanned_files = scan_dir(src_dir)
    for src_file in last_scanned_files:
        src_file_name = os.path.basename(src_file)
        dst_file = os.path.join(dst_dir, src_file_name)
        if os.path.exists(dst_file):
            dst_file_size = os.path.getsize(dst_file)
        else:
            dst_file_size = 0
        sync_file(src_file, last_scanned_files[src_file], dst_dir, dst_file_size)

    print(f"Initial sync of {len(last_scanned_files)} file(s) complete.\n")
    print(f"Watching {src_dir} for changes... Press Ctrl+C to stop.")

    while True:
        time.sleep(dir_scan_freq)
        current_files = scan_dir(src_dir)
        sync_dir(src_dir, current_files, dst_dir, last_scanned_files)
        last_scanned_files = current_files

source_dir = "/Users/catalin/Documents/OCEAN_data/out/"
dest_dir = "/Users/catalin/Documents/OCEAN_data/out2/"
dir_scan_freq = 0.25

try:
    watch_and_sync_dir(source_dir, dest_dir, dir_scan_freq)
except KeyboardInterrupt:
    print('\nSync stopped.')
