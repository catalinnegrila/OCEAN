import Foundation

class ModrawPacket {
    var timestamp = 0
    var signature = ""
    var packetStart = 0
    var payloadStart = 0
    var payloadEnd = 0
    var packetEnd = 0

    let parent: ModrawParser
    init(parent: ModrawParser) {
        self.parent = parent
    }
    func getDateFromTimestamp() -> NSDate {
        let timestampInSeconds = Double(timestamp) / 100.0
        return NSDate(timeIntervalSince1970: TimeInterval(Double(parent.currentYearOffsetInSeconds) + timestampInSeconds))
    }
    fileprivate func _parsePacket() -> Bool {
        packetStart = parent.cursor
        guard !parent.atEnd() else { return false }
        if (parent.peekByte() == ModrawUtils.ASCII_T)
        {
            parent.cursor += 1
            timestamp = 0
            while !parent.atEnd() && ModrawUtils.isDigit(parent.peekByte())
            {
                timestamp = timestamp * 10 + Int(parent.peekByte() - ModrawUtils.ASCII_0)
                parent.cursor += 1
            }
            guard !parent.atEnd() else { return false }
        }

        guard parent.peekByte() == ModrawUtils.ASCII_DOLLAR &&
              !parent.atEnd(offset: parent.PACKET_SIGNATURE_LEN) else { return false }

        signature = parent.peekString(at: parent.cursor, len: parent.PACKET_SIGNATURE_LEN)
        parent.cursor += parent.PACKET_SIGNATURE_LEN

        payloadStart = parent.cursor
        while !parent.atEnd()
        {
            // Does this look like a checksum and a new packet beginning?
            if parent.isPacketEndChecksum() {
                payloadEnd = parent.cursor
                parent.cursor += parent.PACKET_END_CHECKSUM_LEN
                if !parent.atEnd() && parent.peekByte() == ModrawUtils.ASCII_LF {
                    parent.cursor += 1
                }
                if parent.isPacketStart() ||
                    parent.foundEndMarker() {
                    packetEnd = parent.cursor
                    break
                }
            } else {
                parent.cursor += 1
            }
        }
        guard packetEnd != 0 else { return false }
        return true
    }
}

class ModrawHeader {
    var headerStart = 0
    var headerEnd = 0
    var lines = [String]()

    let parent: ModrawParser
    fileprivate init(parent: ModrawParser) {
        self.parent = parent
    }

    func getValueForKeyAsString(_ key: String) -> String? {
        var value:String?
        for line in lines {
            let comp = line.components(separatedBy: "=")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            if comp.count == 2 && comp[0] == key {
                value = comp[1]
                break
            }
        }
        if let value {
            return value
        } else {
            print("Key '\(key)' not found in header!")
            return nil
        }
    }
    func getValueForKeyAsDouble(_ key: String) -> Double? {
        if let str = getValueForKeyAsString(key) {
            if let v = Double(str) {
                return v
            } else {
                print("Invalid numeric value for \(key): \(str)")
            }
        }
        return nil
    }

    fileprivate func _parseIntFromKeyValue(line: String) -> Int {
        return Int(line.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
    }
    fileprivate func _parseHeader(header: ModrawHeader) -> Bool {
        var line = parent.parseLine()
        guard line != nil else { return false }
        guard line!.starts(with: "header_file_size_inbytes =") else { return false }
        header.lines.append(line!)
        
        line = parent.parseLine()
        guard line != nil else { return false }
        guard line!.starts(with: "TOTAL_HEADER_LINES =") else { return false }
        header.lines.append(line!)
        
        line = parent.parseLine()
        guard line != nil else { return false }
        guard line!.contains("****START_FCTD_HEADER_START_RUN****") else { return false }
        header.lines.append(line!)
        
        repeat {
            line = parent.parseLine()
            guard line != nil else { return false }
            if line!.starts(with: "OFFSET_TIME =") {
                parent.currentYearOffsetInSeconds = _parseIntFromKeyValue(line: line!)
            }
            header.lines.append(line!)
        } while !line!.contains("****END_FCTD_HEADER_START_RUN****")

        if !parent.atEnd() && parent.peekByte() == 0 {
            parent.cursor += 1
        }

        header.headerEnd = parent.cursor
        return true
    }
}

class ModrawUtils {
    static let ASCII_LF     = UInt8(0x0A) // '\n'
    static let ASCII_CR     = UInt8(0x0D) // '\r'
    static let ASCII_a      = UInt8(0x61) // 'a'
    static let ASCII_f      = UInt8(0x66) // 'f'
    static let ASCII_A      = UInt8(0x41) // 'A'
    static let ASCII_F      = UInt8(0x46) // 'F'
    static let ASCII_S      = UInt8(0x53) // 'S'
    static let ASCII_O      = UInt8(0x4F) // 'O'
    static let ASCII_M      = UInt8(0x4D) // 'M'
    static let ASCII_T      = UInt8(0x54) // 'T'
    static let ASCII_STAR   = UInt8(0x2A) // '*'
    static let ASCII_0      = UInt8(0x30) // '0'
    static let ASCII_9      = UInt8(0x39) // '9'
    static let ASCII_DOLLAR = UInt8(0x24) // '$'
    static func isDigit(_ c : UInt8) -> Bool {
        return c >= ASCII_0 && c <= ASCII_9
    }
    static func isHexDigit(_ c : UInt8) -> Bool {
        return isDigit(c) ||
                (c >= ASCII_a && c <= ASCII_f) ||
                (c >= ASCII_A && c <= ASCII_F)
    }
}

class ModrawParser {
    var data = [UInt8]()
    var cursor = 0
    var currentYearOffsetInSeconds = 0

    convenience init(fileUrl: URL) throws {
        let fileData = try Data(contentsOf: fileUrl)
        self.init(data: fileData)
    }
    init(bytes: ArraySlice<UInt8>) {
        self.data.append(contentsOf: bytes)
    }
    init(data: Data) {
        self.data = newByteArrayFrom(data: data)
    }
    func appendData(bytes: [UInt8]) {
        self.data.append(contentsOf: bytes) //[0..<bytes.count])
    }
    func appendData(bytes: ArraySlice<UInt8>) {
        self.data.append(contentsOf: bytes)
    }
    func atEnd(offset: Int = 0) -> Bool {
        return cursor + offset >= data.count
    }
    func peekByte() -> UInt8 {
        return data[cursor]
    }
    func parseLine() -> String? {
        guard !atEnd() else { return nil }
        var line = ""
        while true {
            let b = peekByte()
            cursor += 1
            if b == ModrawUtils.ASCII_CR { continue }
            if b == ModrawUtils.ASCII_LF { break }
            line += String(Character(UnicodeScalar(b)))
            if atEnd() { return nil }
        }
        return line
    }
    fileprivate let MODRAW_END_MARKER = "%*****START_FCTD_TAILER_END_RUN*****"
    fileprivate func foundMarker(i: Int, marker: String) -> Bool {
        var j = i
        for mc in marker {
            if j >= data.count { return false }
            if Character(UnicodeScalar(data[j])) != mc { return false }
            j += 1
        }
        return true
    }
    func foundEndMarker(offset: Int = 0) -> Bool {
        return foundMarker(i: cursor + offset, marker: MODRAW_END_MARKER)
    }
    func parseHeader() -> ModrawHeader? {
        let header = ModrawHeader(parent: self)
        header.headerStart = cursor
        if header._parseHeader(header: header) {
            cursor = header.headerEnd
            return header
        } else {
            cursor = header.headerStart
            return nil
        }
    }

    func isPacketStart() -> Bool {
        var i = cursor
        if (i + 4 <= data.count &&
            data[i] == ModrawUtils.ASCII_DOLLAR &&
            data[i + 1] == ModrawUtils.ASCII_S &&
            data[i + 2] == ModrawUtils.ASCII_O &&
            data[i + 3] == ModrawUtils.ASCII_M) {
            return true
        }
        if (i >= data.count) {
            return false
        }
        if (data[i] != ModrawUtils.ASCII_T) {
            return false
        }
        i += 1
        while i < data.count && ModrawUtils.isDigit(data[i]) {
            i += 1
        }
        return i < data.count && data[i] == ModrawUtils.ASCII_DOLLAR
    }
    let PACKET_CHECKSUM_LEN = 3 // <*><HEX><HEX>
    let PACKET_END_CHECKSUM_LEN = 5 // <*><HEX><HEX><CR><LF>
    let PACKET_SIGNATURE_LEN = 5 // <$>4*(<alphanum>)
    let PACKET_HEADER_LEN = 1 + 10 + 5 // <T>10*<dec><$>4*<alphanum>
    func isChecksum(_ i: Int) -> Bool {
        return i <= data.count - 3 &&
                data[i] == ModrawUtils.ASCII_STAR &&
                ModrawUtils.isHexDigit(data[i+1]) &&
                ModrawUtils.isHexDigit(data[i+2])
    }
    fileprivate func isPacketEndChecksum() -> Bool {
        return isChecksum(cursor) &&
                cursor <= data.count - PACKET_END_CHECKSUM_LEN &&
                data[cursor+3] == ModrawUtils.ASCII_CR &&
                data[cursor+4] == ModrawUtils.ASCII_LF
    }

    public func peekString(at: Int, len: Int) -> String {
        var str = ""
        for b in data[at..<at+len] {
            if (b == 0) {
                str += "<0>"
            } else {
                str += String(Character(UnicodeScalar(b)))
            }
        }
        return str
    }
    public func peekHex(at: Int, len: Int) -> UInt64? {
        let str = peekString(at: at, len: len)
        return UInt64(str, radix: 16)
    }
    public func peekBinLE(at: Int, len: Int) -> UInt64 {
        assert(len <= MemoryLayout<UInt64>.size)
        return data[at..<at + len]
            .reduce(0, { soFar, new in
                    (soFar << 8) | UInt64(new)
            })
    }
    public func peekBinBE(at: Int, len: Int) -> UInt64 {
        assert(len <= MemoryLayout<UInt64>.size)
        return data[at..<at + len]
            .reversed()
            .reduce(0, { soFar, new in
                    (soFar << 8) | UInt64(new)
            })
    }
    func parsePacket() -> ModrawPacket? {
        let p = ModrawPacket(parent: self)
        if p._parsePacket() {
            return p
        } else {
            cursor = p.packetStart
            return nil
        }
    }
    func rewindPacket(packet: ModrawPacket) {
        cursor = packet.packetStart
    }
}
