# TODO:
# 8. Stream multiple modraw files
# 9. Mock the UDP and TCP clients
# 10. Where is PCode data coming from?
# 11. Diff input and output .modraw files to detect regressions
# 12. Diff the UDP and TCP outputs against reference recordings

import pty, os, re
import ModrawFilter

# Setup is one level below this test script, ../Setup
acq_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
Setup_path = os.path.join(acq_path, "Setup")
data_in_path = "/Users/Shared/FCTD_EPSI_DATA/acq_test"
data_out_path = "/Users/Shared/FCTD_EPSI_DATA/TESTMOTIVE2024"
print(f"Modraw input: {data_in_path}")
print(f"Modraw output: {data_out_path}")

for fname in os.listdir(data_out_path):
    os.unlink(os.path.join(data_out_path, fname))

def update_Setup(var_name,new_value):
    print(f"{var_name}={new_value}")
    with open(Setup_path, 'r') as file:
        content = file.read()

    pattern = r'(' + re.escape(var_name) + r'\s*=\s*)(.*)'
    replacement = r'\g<1>' + str(new_value)
    updated_content = re.sub(pattern, replacement, content)

    with open(Setup_path, 'w') as file:
        file.write(updated_content)
    
CTDPort_sim, CTDPort_acq = os.openpty()
update_Setup("CTD.CTDPortName", f"'{os.ttyname(CTDPort_acq)}'")

CTDCommandPort_sim, CTDCommandPort_acq = os.openpty()
update_Setup("CTD.CommandPortName", f"'{os.ttyname(CTDCommandPort_acq)}'")

print("Start the acquisition software...")

# Wait for 'som.start'
with os.fdopen(CTDCommandPort_sim, "rb") as fd:
    try:
        out = None
        while out != "som.start":
            out = fd.readline().decode('utf-8').strip()
            print(f"Received: {out}")
    except KeyboardInterrupt:
        print("Simulation interrupted.")
        exit()

def enumerate_all_files(dir):
    file_names = [os.path.join(dir, f) for f in os.listdir(dir) if os.path.isfile(os.path.join(dir, f)) and os.path.splitext(f)[1] == ".modraw"]
    file_names.sort()
    return file_names

file_names = enumerate_all_files(data_in_path)
current_file_idx = 0

# Start streaming
with os.fdopen(CTDPort_sim, "wb") as fd:
    modraw = ModrawFilter.ModrawParser(file_names[current_file_idx])
    print(f"Streaming {file_names[current_file_idx]}")
    header = modraw.parseHeader()
    packet = modraw.parsePacket()
    while packet != None:
        print(f"Packet: {packet.signature}")
        fd.write(modraw.data[packet.signatureCursor:packet.endCursor])
        fd.flush()
        packet = modraw.parsePacket()

