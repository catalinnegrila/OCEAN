import Foundation

class ModrawPacket {
    public var timeOffsetMs : Int?
    public var date : NSDate?
    public var signature = ""
    public var payloadStart = 0
    public var packetStart = 0
    public var packetEnd = 0
}

class ModrawParser {
    public var data : [UInt8]
    private var cursor = 0
    private var firstTimestamp : Int?
    private var currentYearOffset = 0
    init(fileUrl: URL) {
        let fileData = try! Data(contentsOf: fileUrl)
        data = [UInt8](repeating: 0, count: fileData.count)
        fileData.copyBytes(to: &data, count: data.count)
    }
    func getSize() -> Int {
        return data.count
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
    func parseHeader() -> String? {
        var header = ""
        var line = parseLine()
        //guard line != nil else { return nil }
        //guard line!.starts(with: "header_file_size_inbytes =") else { return nil }
        assert(line != nil)
        assert(line!.starts(with: "header_file_size_inbytes ="))
        header = header + line!

        line = parseLine()
        //guard line != nil else { return nil }
        //guard line!.starts(with: "TOTAL_HEADER_LINES =") else { return nil }
        assert(line != nil)
        assert(line!.starts(with: "TOTAL_HEADER_LINES ="))
        header = header + line!

        line = parseLine()
        //guard line != nil else { return nil }
        //guard line!.contains("****START_FCTD_HEADER_START_RUN****") else { return nil }
        assert(line != nil)
        assert(line!.contains("****START_FCTD_HEADER_START_RUN****"))
        header = header + line!

        repeat {
            line = parseLine()
            guard line != nil else { return nil }
            if line!.starts(with: "OFFSET_TIME =") {
                currentYearOffset = Int(line!.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
            }
            header = header + line!
        } while !line!.contains("****END_FCTD_HEADER_START_RUN****")

        return header
    }

    func skipToFirstPacket() {
        while (cursor < data.count && data[cursor] != ModrawParser.ASCII_DOLLAR)
        {
            cursor += 1
        }
    }

    private let endMarker = "%*****START_FCTD_TAILER_END_RUN*****"
    func extractPartialEndPacket() -> Data? {
        let oldCursor = cursor
        defer { cursor = oldCursor }
        cursor = data.count - endMarker.count
        var partialPacket : Data? = nil
        while cursor > 2 {
            if foundMarker(endMarker) {
                if !(data[cursor - 1] == ModrawParser.ASCII_LF &&
                    data[cursor - 2] == ModrawParser.ASCII_CR) &&
                    // Sometimes there's an extra <LF>
                    !(data[cursor - 1] == ModrawParser.ASCII_LF &&
                    data[cursor - 2] == ModrawParser.ASCII_LF &&
                    data[cursor - 3] == ModrawParser.ASCII_CR)
                {
                    var partialPacketStart = cursor
                    while partialPacketStart > 2
                    {
                        if (data[partialPacketStart] == ModrawParser.ASCII_T &&
                            data[partialPacketStart - 1] == ModrawParser.ASCII_LF &&
                            data[partialPacketStart - 2] == ModrawParser.ASCII_CR)
                        {
                            partialPacket = Data(data[partialPacketStart..<cursor])
                            data.removeSubrange(partialPacketStart..<cursor)
                            break
                        }
                        partialPacketStart -= 1
                    }
                }
                break
            }
            cursor -= 1
        }
        return partialPacket
    }
    func insertPartialEndPacket(_ packet: Data) {
        data.insert(contentsOf: packet, at: cursor)
    }

    public static let ASCII_LF     = UInt8(0x0A) // '\n'
    public static let ASCII_CR     = UInt8(0x0D) // '\r'
    public static let ASCII_a      = UInt8(0x61) // 'a'
    public static let ASCII_f      = UInt8(0x66) // 'f'
    public static let ASCII_z      = UInt8(0x7A) // 'z'
    public static let ASCII_A      = UInt8(0x41) // 'A'
    public static let ASCII_F      = UInt8(0x46) // 'F'
    public static let ASCII_S      = UInt8(0x53) // 'S'
    public static let ASCII_O      = UInt8(0x4F) // 'O'
    public static let ASCII_M      = UInt8(0x4D) // 'M'
    public static let ASCII_c      = UInt8(0x63) // 'c'
    public static let ASCII_b      = UInt8(0x62) // 'b'
    public static let ASCII_T      = UInt8(0x54) // 'T'
    public static let ASCII_Z      = UInt8(0x5A) // 'Z'
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
    public static func hexDigitToInt(_ c : UInt8) -> Int {
        if isDigit(c) { return Int(c - ASCII_0) }
        if (c >= ASCII_a && c <= ASCII_f) { return Int(c - ASCII_a + 10) }
        if (c >= ASCII_A && c <= ASCII_F) { return Int(c - ASCII_A + 10) }
        assert(false)
        return 0
    }
    public static func isUppercase(_ c : UInt8) -> Bool {
        return c >= ASCII_A && c <= ASCII_Z
    }
    public func parseString(start: Int, len: Int) -> String {
        assert(start + len <= data.count)
        var str = ""
        for i in start..<start+len {
            str += String(Character(UnicodeScalar(data[i])))
        }
        return str
    }
    public func parseHex(start: Int, len: Int) -> UInt64 {
        assert(len <= 16)
        var value = UInt64(0)
        var p16 = UInt64(1)
        for i in stride(from: start+len, to: start,  by: -1) {
            value += UInt64(ModrawParser.hexDigitToInt(data[i-1])) * p16
            if (i > start + 1) {
                p16 *= 16
            }
        }
        return value
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
        let p = ModrawPacket()
        p.packetStart = cursor
        if (data[cursor] == ModrawParser.ASCII_T)
        {
            var timestamp = 0
            cursor += 1
            while cursor < data.count && ModrawParser.isDigit(data[cursor])
            {
                timestamp = timestamp * 10 + Int(data[cursor] - ModrawParser.ASCII_0)
                cursor += 1
            }
            if (cursor == data.count)
            {
                cursor = p.packetStart
                return nil
            }
            if timestamp > 0
            {
                if firstTimestamp == nil
                {
                    firstTimestamp = timestamp
                }
                let timestampSeconds = Double(timestamp) / 100.0
                p.date = NSDate(timeIntervalSince1970: TimeInterval(Double(currentYearOffset) + timestampSeconds))
                // Convert from hundreths of seconds to milliseconds
                p.timeOffsetMs = 10 * (timestamp - firstTimestamp!)
            }
        }

        let sigLen = 5
        if (data[cursor] != ModrawParser.ASCII_DOLLAR ||
            cursor + sigLen > data.count)
        {
            cursor = p.packetStart
            return nil
        }

        for _ in 0..<sigLen
        {
            p.signature += String(Character(UnicodeScalar(data[cursor])))
            cursor += 1
        }

        if (p.signature == "$SOM3" && p.timeOffsetMs != nil)
        {
            cursor = p.packetStart
            return nil
        }
        p.payloadStart = cursor
        let checksumLen = 5 // <*><HEX><HEX><CR><LF>
        while (cursor + checksumLen + 1 < data.count)
        {
            if (data[cursor] == ModrawParser.ASCII_STAR &&
                ModrawParser.isHexDigit(data[cursor+1]) &&
                ModrawParser.isHexDigit(data[cursor+2]) &&
                data[cursor+3] == ModrawParser.ASCII_CR &&
                data[cursor+4] == ModrawParser.ASCII_LF)
            {
                cursor += checksumLen
                if (cursor < data.count &&
                    (data[cursor] == ModrawParser.ASCII_T || foundMarker(endMarker)))
                {
                    p.packetEnd = cursor
                    // Sometimes there's an extra <LF>
                    if (cursor < data.count && data[cursor] == ModrawParser.ASCII_LF)
                    {
                        cursor += 1
                    }
                    break
                }
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
    func progress() -> Double {
        let fullPercent = 100.0 * Double(cursor) / Double(data.count)
        return Double(round(10.0 * fullPercent) / 10.0)
    }
}
