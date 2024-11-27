import Foundation

class ModrawPacket {
    var timestamp = 0
    var signature = ""
    var payloadStart = 0
    var payloadEnd = 0
    var packetStart = 0
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
        while !parent.atEnd(offset: parent.PACKET_HEADER_LEN) && !parent.isPacketStart(parent.cursor) {
            parent.cursor += 1
        }
        guard !parent.atEnd() else { return false }
        packetStart = parent.cursor
        if (parent.peekByte() == ModrawParser.ASCII_T)
        {
            parent.cursor += 1
            timestamp = 0
            while !parent.atEnd() && ModrawParser.isDigit(parent.peekByte())
            {
                timestamp = timestamp * 10 + Int(parent.peekByte() - ModrawParser.ASCII_0)
                parent.cursor += 1
            }
            guard !parent.atEnd() else { return false }
        }

        guard parent.peekByte() == ModrawParser.ASCII_DOLLAR &&
              !parent.atEnd(offset: parent.PACKET_SIGNATURE_LEN) else { return false }

        signature = parent.peekString(at: parent.cursor, len: parent.PACKET_SIGNATURE_LEN)
        parent.cursor += parent.PACKET_SIGNATURE_LEN

        payloadStart = parent.cursor
        while !parent.atEnd()
        {
            // Does this look like a checksum?
            if parent.isPacketEndChecksum(parent.cursor)
            {
                payloadEnd = parent.cursor
                parent.cursor += parent.PACKET_END_CHECKSUM_LEN
                packetEnd = parent.cursor
                break
            }
            else
            {
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

    private let endMarker = "%*****START_FCTD_TAILER_END_RUN*****"
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

        header.headerEnd = parent.cursor
        return true
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
            if b == ModrawParser.ASCII_CR { continue }
            if b == ModrawParser.ASCII_LF { break }
            line += String(Character(UnicodeScalar(b)))
            if atEnd() { return nil }
        }
        return line
    }
    func foundMarker(_ marker: String) -> Bool {
        var i = cursor
        for mc in marker {
            if i >= data.count { return false }
            if Character(UnicodeScalar(data[i])) != mc { return false }
            i += 1
        }
        return true
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

    func isPacketStart(_ i: Int) -> Bool {
        if (i + 4 <= data.count &&
            data[i] == ModrawParser.ASCII_DOLLAR &&
            data[i + 1] == ModrawParser.ASCII_S &&
            data[i + 2] == ModrawParser.ASCII_O &&
            data[i + 3] == ModrawParser.ASCII_M) {
            return true
        }
        if (i >= data.count) {
            return false
        }
        if (data[i] != ModrawParser.ASCII_T) {
            return false
        }
        var j = i + 1
        while j < data.count && ModrawParser.isDigit(data[j]) {
            j += 1
        }
        return j < data.count && data[j] == ModrawParser.ASCII_DOLLAR

    }
    let PACKET_CHECKSUM_LEN = 3 // <*><HEX><HEX>
    let PACKET_END_CHECKSUM_LEN = 5 // <*><HEX><HEX><CR><LF>
    let PACKET_SIGNATURE_LEN = 5 // <$>4*(<alphanum>)
    let PACKET_HEADER_LEN = 1 + 10 + 5 // <T>10*<dec><$>4*<alphanum>
    func isChecksum(_ i: Int) -> Bool {
        return i <= data.count - 3 &&
                data[i] == ModrawParser.ASCII_STAR &&
                ModrawParser.isHexDigit(data[i+1]) &&
                ModrawParser.isHexDigit(data[i+2])
    }
    func isPacketEndChecksum(_ i: Int) -> Bool {
        return isChecksum(i) &&
                i <= data.count - PACKET_END_CHECKSUM_LEN &&
                data[i+3] == ModrawParser.ASCII_CR &&
                data[i+4] == ModrawParser.ASCII_LF
    }
    func isPacketEnd(_ i: Int) -> Bool {
        return isPacketEndChecksum(i - PACKET_END_CHECKSUM_LEN) ||
                (i <= data.count &&
                 data[i - 1] == ModrawParser.ASCII_LF &&
                 isPacketEndChecksum(i - 1 - PACKET_END_CHECKSUM_LEN))
    }

    public static let ASCII_LF     = UInt8(0x0A) // '\n'
    public static let ASCII_CR     = UInt8(0x0D) // '\r'
    public static let ASCII_a      = UInt8(0x61) // 'a'
    public static let ASCII_f      = UInt8(0x66) // 'f'
    public static let ASCII_A      = UInt8(0x41) // 'A'
    public static let ASCII_F      = UInt8(0x46) // 'F'
    public static let ASCII_S      = UInt8(0x53) // 'S'
    public static let ASCII_O      = UInt8(0x4F) // 'O'
    public static let ASCII_M      = UInt8(0x4D) // 'M'
    public static let ASCII_T      = UInt8(0x54) // 'T'
    public static let ASCII_STAR   = UInt8(0x2A) // '*'
    public static let ASCII_0      = UInt8(0x30) // '0'
    public static let ASCII_9      = UInt8(0x39) // '9'
    public static let ASCII_DOLLAR = UInt8(0x24) // '$'
    public static func isDigit(_ c : UInt8) -> Bool {
        return c >= ASCII_0 && c <= ASCII_9
    }
    public static func isHexDigit(_ c : UInt8) -> Bool {
        return isDigit(c) ||
                (c >= ASCII_a && c <= ASCII_f) ||
                (c >= ASCII_A && c <= ASCII_F)
    }
    public func peekString(at: Int, len: Int) -> String {
        assert(at + len <= data.count)
        var str = ""
        for i in at..<at+len {
            str += String(Character(UnicodeScalar(data[i])))
        }
        return str
    }
    public func peekHex(at: Int, len: Int) -> UInt64? {
        let str = peekString(at: at, len: len)
        return UInt64(str, radix: 16)
    }
    public func peekBinLE(at: Int, len: Int) -> UInt64 {
        assert(len <= 8)
        var val = UInt64(0)
        var p256 = UInt64(1)
        for i in stride(from: at+len, to: at,  by: -1) {
            val += UInt64(data[i-1]) * p256
            if (i > at + 1) {
                p256 *= 256
            }
        }
        return val
    }
    public func peekBinBE(at: Int, len: Int) -> UInt64 {
        assert(len <= 8)
        var val = UInt64(0)
        var p256 = UInt64(1)
        for i in at..<at+len {
            val += UInt64(data[i]) * p256
            if (i < at + len - 1) {
                p256 *= 256
            }
        }
        return val
    }
    func parsePacket() -> ModrawPacket? {
        let originalCursor = cursor
        let p = ModrawPacket(parent: self)
        if p._parsePacket() {
            return p
        } else {
            cursor = originalCursor
            return nil
        }
    }
    func rewindPacket(packet: ModrawPacket) {
        cursor = packet.packetStart
    }
}
