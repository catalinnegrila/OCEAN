import Foundation

class ModrawPacket {
    var timestamp = 0
    var signature = ""
    var payloadStart = 0
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
}

class ModrawHeader {
    var content = ""

    func getKeyValueString(key: String) -> String {
        let indexOfKey = content.index(of: key)
        if (indexOfKey == nil) {
            print("Key '\(key)' not found in header!")
            assert(false)
            return ""
        }
        let indexAfterKey = content.index(indexOfKey!, offsetBy: key.count)
        let valueOnwards = content[indexAfterKey...]
        var indexOfCrlf = valueOnwards.index(of: "\r\n")
        if (indexOfCrlf == nil || indexOfCrlf! > valueOnwards.index(indexAfterKey, offsetBy: 32)) {
            indexOfCrlf = valueOnwards.index(of: "\n")
        }
        if (indexOfCrlf == nil) {
            print("Unterminated key '\(key)' value '\(valueOnwards)'")
            assert(false)
            return ""
        }
        return valueOnwards[..<indexOfCrlf!].trimmingCharacters(in: .whitespaces)
    }
    func getKeyValueDouble(key: String) -> Double {
        let str = getKeyValueString(key: key)
        if let v = Double(str) {
            return v
        }
        print("Invalid numeric value for \(key): \(str)")
        assert(false)
        return 0
    }
}

class ModrawParser {
    var data : [UInt8]
    var cursor = 0
    var currentYearOffsetInSeconds = 0

    init(fileUrl: URL) throws {
        let fileData = try Data(contentsOf: fileUrl)
        data = [UInt8](repeating: 0, count: fileData.count)
        fileData.copyBytes(to: &data, count: data.count)
    }
    func appendData(data: [UInt8]) {
        self.data.append(contentsOf: data[0..<data.count])
    }
    func peekByte() -> UInt8? {
        guard cursor < data.count else { return nil }
        return data[cursor]
    }
    func parseByte() -> UInt8? {
        if let byte = peekByte() {
            cursor = cursor + 1
            return byte
        }
        return nil
    }
    func parseChar() -> Character? {
        if let byte = parseByte() {
            return Character(UnicodeScalar(byte))
        }
        return nil
    }
    func parseLine() -> String? {
        var line = ""
        var c : Character?
        repeat {
            c = parseChar()
            guard c != nil else { break }
            line = line + String(c!)
        } while !(c!.isNewline)
        guard line.count > 0 else { return nil }
        return line
    }
    func foundMarker(_ marker: String) -> Bool {
        let oldCursor = cursor
        defer { cursor = oldCursor }
        for mc in marker {
            let c = parseChar()
            if c == nil || c! != mc {
                return false
            }
        }
        return true
    }
    private let endMarker = "%*****START_FCTD_TAILER_END_RUN*****"
    func parseHeader() -> ModrawHeader {
        let header = ModrawHeader()
        var line = parseLine()
        assert(line != nil)
        assert(line!.starts(with: "header_file_size_inbytes ="))
        header.content += line!

        line = parseLine()
        assert(line != nil)
        assert(line!.starts(with: "TOTAL_HEADER_LINES ="))
        header.content += line!

        line = parseLine()
        assert(line != nil)
        assert(line!.contains("****START_FCTD_HEADER_START_RUN****"))
        header.content += line!

        repeat {
            line = parseLine()
            assert(line != nil)
            if line!.starts(with: "OFFSET_TIME =") {
                currentYearOffsetInSeconds = Int(line!.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
            }
            header.content += line!
        } while !line!.contains("****END_FCTD_HEADER_START_RUN****")

        return header
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
    public func parseString(start: Int, len: Int) -> String {
        assert(start + len <= data.count)
        var str = ""
        for i in start..<start+len {
            str += String(Character(UnicodeScalar(data[i])))
        }
        return str
    }
    public func parseHex(start: Int, len: Int) -> UInt64? {
        let str = parseString(start: start, len: len)
        return UInt64(str, radix: 16)
    }
    public func parseBin(start: Int, len: Int) -> UInt64 {
        assert(len <= 8)
        var val = UInt64(0)
        var p256 = UInt64(1)
        for i in stride(from: start+len, to: start,  by: -1) {
            val += UInt64(data[i-1]) * p256
            if (i > start + 1) {
                p256 *= 256
            }
        }
        return val
    }
    public func parseBinBE(start: Int, len: Int) -> UInt64 {
        assert(len <= 8)
        var val = UInt64(0)
        var p256 = UInt64(1)
        for i in start..<start+len {
            val += UInt64(data[i]) * p256
            if (i < start + len - 1) {
                p256 *= 256
            }
        }
        return val
    }
    func parsePacket() -> ModrawPacket? {
        while cursor + PACKET_HEADER_LEN < data.count && !isPacketStart(cursor) {
            cursor += 1
        }
        if (cursor >= data.count) {
            return nil
        }
        let p = ModrawPacket(parent: self)
        p.packetStart = cursor
        if (data[cursor] == ModrawParser.ASCII_T)
        {
            cursor += 1
            p.timestamp = 0
            while cursor < data.count && ModrawParser.isDigit(data[cursor])
            {
                p.timestamp = p.timestamp * 10 + Int(data[cursor] - ModrawParser.ASCII_0)
                cursor += 1
            }
            if (cursor == data.count)
            {
                cursor = p.packetStart
                return nil
            }
        }

        if (data[cursor] != ModrawParser.ASCII_DOLLAR ||
            cursor + PACKET_SIGNATURE_LEN > data.count)
        {
            cursor = p.packetStart
            return nil
        }

        p.signature = parseString(start: cursor, len: PACKET_SIGNATURE_LEN)
        cursor += PACKET_SIGNATURE_LEN

        p.payloadStart = cursor
        while (cursor < data.count)
        {
            // Does this look like a checksum?
            if isPacketEndChecksum(cursor)
            {
                cursor += PACKET_END_CHECKSUM_LEN
                p.packetEnd = cursor
                break
            }
            else
            {
                cursor += 1
            }
        }
        if (p.packetEnd == 0)
        {
            cursor = p.packetStart
            return nil
        }
        return p
    }
    func rewindPacket(packet: ModrawPacket) {
        cursor = packet.packetStart
    }
}
