import Foundation

struct ModrawPacket {
    //public var data : Data
    public var data : [UInt8]
    public var timeOffsetMs : Int?
    public var date : NSDate?
    public var signature = ""
    public var payloadStart : Int = 0

    func parseString(start: Int, len: Int) -> String {
        assert(start + len <= data.count)
        var str = ""
        for i in start..<start+len {
            str += String(Character(UnicodeScalar(data[i])))
        }
        return str
    }

    func parseHex(start: Int, len: Int) -> Int {
        return Int(parseString(start: start, len: len), radix: 16)!
    }

    func parseBin(start: Int, len: Int) -> UInt64 {
        assert(len <= 8)
        var val = UInt64(0)
        var mult = UInt64(1)
        for i in 0..<len {
            //val += UInt64(data[i]) * UInt64(pow(256, Double(start+len-i-1)))
            val += UInt64(data[start + len - 1 - i]) * mult
            if (i < 7) {
                mult *= 256
            }
        }
        return val
    }
}

struct ModrawParser {
    private var data : [UInt8]
    private var cursor = 0
    private var firstTimestamp : Int?
    private var currentYearOffset = 0
    init(data: Data) {
        self.data = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &self.data, count: data.count)
    }
    private func peekByte() -> UInt8? {
        guard cursor < data.count else { return nil }
        return data[cursor]
    }
    mutating func parseByte() -> UInt8? {
        if let byte = peekByte() {
            cursor = cursor + 1
            return byte
        }
        return nil
    }
    mutating func parseChar() -> Character? {
        if let byte = parseByte() {
            return Character(UnicodeScalar(byte))
        }
        return nil
    }
    mutating func parseLine() -> String? {
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
    mutating func foundMarker(_ marker: String) -> Bool {
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
    mutating func parseHeader() -> String? {
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

        // skipToFirstPacket
        while (peekByte() != ModrawParser.ASCII_DOLLAR) {
            _ = parseByte()
        }

        return header
    }

    private let endMarker = "%*****START_FCTD_TAILER_END_RUN*****"

    mutating func extractPartialEndPacket() -> Data? {
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
                    data[cursor - 3] == ModrawParser.ASCII_CR) {
                    var partialPacketStart = cursor
                    while partialPacketStart > 2 {
                        if (data[partialPacketStart] == ModrawParser.ASCII_T &&
                            data[partialPacketStart - 1] == ModrawParser.ASCII_LF &&
                            data[partialPacketStart - 2] == ModrawParser.ASCII_CR) {
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
    mutating func insertPartialEndPacket(_ packet: Data) {
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
    public static func isUppercase(_ c : UInt8) -> Bool {
        return c >= ASCII_A && c <= ASCII_Z
    }
    mutating func parsePacket() -> ModrawPacket? {
        var packet = [UInt8]()
        var c = parseByte()
        while (c != nil) {
            packet.append(c!)
            if (c! == ModrawParser.ASCII_LF && packet.count > 5) {
                // Expected format is <STAR><HEX><HEX><CR><LF>
                if (packet[packet.count - 2] == ModrawParser.ASCII_CR &&
                    ModrawParser.isHexDigit(packet[packet.count - 3]) &&
                    ModrawParser.isHexDigit(packet[packet.count - 4]) &&
                    packet[packet.count - 5] == ModrawParser.ASCII_STAR) {
                    // Sometimes there's an extra <LF>
                    var nextChar = peekByte()
                    if (nextChar != nil && nextChar! == ModrawParser.ASCII_LF) {
                        nextChar = parseByte()
                        packet.append(nextChar!)
                        nextChar = peekByte()
                    }
                    // First $SOM packet ends abruptly with *cb<CR><LF>
                    if (packet[0] == ModrawParser.ASCII_DOLLAR &&
                        packet[1] == ModrawParser.ASCII_S &&
                        packet[2] == ModrawParser.ASCII_O &&
                        packet[3] == ModrawParser.ASCII_M &&
                        packet[packet.count - 3] == ModrawParser.ASCII_b &&
                        packet[packet.count - 4] == ModrawParser.ASCII_c) {
                        break
                    }
                    // All others are followed by another packet starting with <T>
                    if (nextChar == nil || nextChar! == ModrawParser.ASCII_T) {
                        break
                    }
                }
            }
            if foundMarker(endMarker) {
                // TODO: mark as incomplete packet
                return nil
            }
            c = parseByte()
        }
        guard packet.count > 5 else { return nil }
        var p = ModrawPacket(data: packet)
        var i = 0
        // Parse the timestamp immediately following the <T>
        if packet.count > 2 && packet[i] == ModrawParser.ASCII_T {
            var timestamp = 0
            i = i + 1
            var c = packet[i]
            while i < packet.count && ModrawParser.isDigit(c) {
                timestamp = timestamp * 10 + Int(c - ModrawParser.ASCII_0)
                i = i + 1
                c = packet[i]
            }
            if c == ModrawParser.ASCII_DOLLAR {
                if firstTimestamp == nil {
                    firstTimestamp = timestamp
                }
                let timestampSeconds = Double(timestamp) / 100.0
                p.date = NSDate(timeIntervalSince1970: TimeInterval(Double(currentYearOffset) + timestampSeconds))
                // Convert from hundreths of seconds to milliseconds
                p.timeOffsetMs = 10 * (timestamp - firstTimestamp!)
            }
        }
        // Parse the signature following the <DOLLAR>
        if i < packet.count - 1 && packet[i] == ModrawParser.ASCII_DOLLAR {
            p.signature = "$"
            i = i + 1
            var c = packet[i]
            for _ in 0..<4  {
                assert(i < packet.count)
                p.signature = p.signature + String(Character(UnicodeScalar(c)))
                i = i + 1
                c = packet[i]
            }
        }
        p.payloadStart = i
        return p
    }
    func progress() -> Double {
        let fullPercent = 100.0 * Double(cursor) / Double(data.count)
        return Double(round(10.0 * fullPercent) / 10.0)
    }
}
