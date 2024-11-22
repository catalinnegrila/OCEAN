import os
import string

modraw_file_path = "/Users/catalin/Documents/OCEAN_data/epsiPlot/EPSI24_11_06_054202.modraw"
time_window = 20 # seconds

class ModrawPacket:
    def __init__(self):
        self.startCursor = None
        self.endCursor = None
        self.timestamp = None
        self.signature = None

class ModrawParser:
    def __init__(self, file_path):
        with open(file_path, 'rb') as f:
            self.data = f.read(os.path.getsize(file_path))
            self.count = len(self.data)
        self.cursor = 0
        self.PACKET_TIMESTAMP_LEN = 16
        self.PACKET_SIZE_LEN = 8
        self.PACKET_END_CHECKSUM_LEN = 5 # <*><HEX><HEX><CR><LF>
        self.PACKET_SIGNATURE_LEN = 5 # <$>4*(<sig>)
        self.PACKET_START_LEN = 1 + 10 + 5 # <T>10*<dec><$>4*<alphanum>
        self.PACKET_CHECKSUM_LEN = 3
        self.ASCII_CR = 13
        self.ASCII_LF = 10

    def peekString(self, len):
        if self.cursor + len >= self.count:
            return None
        s = ""
        for i in range(0, len):
            s += chr(self.data[self.cursor + i])
        return s

    def parseLine(self):
        line = ""
        while self.cursor < self.count:
            c = self.data[self.cursor]
            line += chr(c)
            self.cursor += 1
            if c == self.ASCII_LF:
                break
        return line

    def parseHeader(self):
        header = ""
        line = self.parseLine()
        assert(line.startswith("header_file_size_inbytes ="))
        header += line

        line = self.parseLine()
        assert(line.startswith("TOTAL_HEADER_LINES ="))
        header += line

        line = self.parseLine()
        assert("****START_FCTD_HEADER_START_RUN****" in line)
        header += line

        while "****END_FCTD_HEADER_START_RUN****" not in line:
            header += line
            line = self.parseLine()
        header += line
        return header

    def isPacketStart(self, i):
        if self.peekString(4) == "$SOM":
            return True
        if i >= self.count:
            return False
        if self.data[i] != ord('T'):
            return False
        i += 1
        while i < self.count and chr(self.data[i]).isdigit():
            i += 1
        return i < self.count and self.data[i] == ord('$')

    def isPacketEndChecksum(self, i):
        return i <= self.count - self.PACKET_END_CHECKSUM_LEN and \
                self.data[i] == ord('*') and \
                chr(self.data[i+1]) in string.hexdigits and \
                chr(self.data[i+2]) in string.hexdigits and \
                self.data[i+3] == self.ASCII_CR and \
                self.data[i+4] == self.ASCII_LF

    def isPacketEnd(self, i):
        return self.isPacketEndChecksum(i - self.PACKET_END_CHECKSUM_LEN) or \
                (i <= self.count and \
                 self.data[i - 1] == self.ASCII_LF and \
                 self.isPacketEndChecksum(i - 1 - self.PACKET_END_CHECKSUM_LEN))

    def parsePacket(self):
        while self.cursor + self.PACKET_START_LEN < self.count and not self.isPacketStart(self.cursor):
            self.cursor += 1

        if self.cursor >= self.count:
            return None

        packet = ModrawPacket()
        packet.startCursor = self.cursor
        if self.data[self.cursor] == ord('T'):
            self.cursor += 1
            while self.cursor < self.count and chr(self.data[self.cursor]).isdigit():
                self.cursor += 1

            if self.cursor == self.count:
                self.cursor = packet.startCursor
                return None

        if self.data[self.cursor] != ord('$') or self.cursor + self.PACKET_SIGNATURE_LEN > self.count:
            self.cursor = packet.startCursor
            return None

        packet.signature = self.peekString(self.PACKET_SIGNATURE_LEN)
        self.cursor += self.PACKET_SIGNATURE_LEN
        if packet.signature in ["$SOM4", "$EFE4", "$SB49", ]:
            packet.timestamp = int(self.peekString(self.PACKET_TIMESTAMP_LEN), 16)
            self.cursor += self.PACKET_TIMESTAMP_LEN

            blocksize = int(self.peekString(self.PACKET_SIZE_LEN), 16)
            self.cursor += self.PACKET_SIZE_LEN

            #print(f"{packet.signature}: {packet.timestamp}, size: {blocksize}")
            self.cursor += self.PACKET_CHECKSUM_LEN

            self.cursor += blocksize
            if not self.isPacketEndChecksum(self.cursor):
                self.cursor = packet.startCursor
                return None
        else:
            #print(f"{packet.signature}")
            while self.cursor < self.count:
                if self.isPacketEndChecksum(self.cursor):
                    self.cursor += self.PACKET_END_CHECKSUM_LEN
                    packet.endCursor = self.cursor
                    break
                else:
                    self.cursor += 1

        self.cursor += self.PACKET_END_CHECKSUM_LEN
        packet.endCursor = self.cursor

        if packet.endCursor == None:
            self.cursor = packet.startCursor
            return None
        return packet

def getLastTimestamp(modraw):
    cursor = modraw.cursor
    for i in range(modraw.count - modraw.PACKET_START_LEN - 1, cursor, -1):
        modraw.cursor = i
        packet = modraw.parsePacket()
        if packet != None and packet.timestamp != None:
            modraw.cursor = cursor
            return packet.timestamp
    modraw.cursor = cursor
    return None

time_window = 20

modraw = ModrawParser(modraw_file_path)
header = modraw.parseHeader()

lastTimestamp = getLastTimestamp(modraw)
print(f"LastTimeStamp: {lastTimestamp}")

window_started = False
while True:
    packet = modraw.parsePacket()
    if packet == None:
        break
    if not window_started:
        print(f"{lastTimestamp} ")
        print(f"{packet.timestamp} ")
        if packet.timestamp != None and (lastTimestamp - packet.timestamp) > time_window * 1000:
            window_started = True
    if packet.signature == "$SOM3" or window_started:
        print(f"{packet.signature} KEEP ")
    else:
        print(f"{packet.signature} DROP ")

