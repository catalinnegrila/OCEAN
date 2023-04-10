import Foundation

extension String {

    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}

struct Packet {
    public var data : Data
    public var timestamp : Int?
    public var signature = ""
}

struct Parser {
    private var data : [UInt8]
    private var cursor = 0
    private var firstTimestamp : Int?
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
    mutating func parseHeader() -> String? {
        var header = ""
        var line = parseLine()
        guard line != nil else { return nil }
        guard line!.starts(with: "header_file_size_inbytes =") else { return nil }
        header = header + line!

        line = parseLine()
        guard line != nil else { return nil }
        guard line!.starts(with: "TOTAL_HEADER_LINES = 71") else { return nil }
        header = header + line!

        line = parseLine()
        guard line != nil else { return nil }
        guard line!.starts(with: "*****START_FCTD_HEADER_START_RUN*****") else { return nil }
        header = header + line!

        repeat {
            line = parseLine()
            guard line != nil else { return nil }
            header = header + line!
        } while !line!.starts(with: "%*****END_FCTD_HEADER_START_RUN*****")

        return header
    }
    private static let ASCII_LF     = UInt8(0x0A) // '\n'
    private static let ASCII_CR     = UInt8(0x0D) // '\r'
    private static let ASCII_a      = UInt8(0x61) // 'a'
    private static let ASCII_f      = UInt8(0x66) // 'f'
    private static let ASCII_z      = UInt8(0x7A) // 'z'
    private static let ASCII_A      = UInt8(0x41) // 'A'
    private static let ASCII_F      = UInt8(0x46) // 'F'
    private static let ASCII_T      = UInt8(0x54) // 'T'
    private static let ASCII_Z      = UInt8(0x5A) // 'Z'
    private static let ASCII_STAR   = UInt8(0x2A) // '*'
    private static let ASCII_0      = UInt8(0x30) // '0'
    private static let ASCII_9      = UInt8(0x39) // '9'
    private static let ASCII_DOLLAR = UInt8(0x24) // '$'
    private static func isDigit(_ c : UInt8) -> Bool {
        return c >= ASCII_0 && c <= ASCII_9
    }
    private static func isHexDigit(_ c : UInt8) -> Bool {
        return isDigit(c) ||
                (c >= ASCII_a && c <= ASCII_f) ||
                (c >= ASCII_A && c <= ASCII_F)
    }
    private static func isUppercase(_ c : UInt8) -> Bool {
        return c >= ASCII_A && c <= ASCII_Z
    }
    mutating func parsePacket() -> Packet? {
        var packet = [UInt8]()
        var c = parseByte()
        while (c != nil) {
            packet.append(c!)
            if (c! == Parser.ASCII_LF && packet.count > 5) {
                // Expected format is <STAR><HEX><HEX><CR><LF>
                if (packet[packet.count - 2] == Parser.ASCII_CR &&
                    Parser.isHexDigit(packet[packet.count - 3]) &&
                    Parser.isHexDigit(packet[packet.count - 4]) &&
                    packet[packet.count - 5] == Parser.ASCII_STAR) {
                    // Followed by another packet starting with <T>
                    let nextChar = peekByte()
                    if (nextChar == nil || nextChar! == Parser.ASCII_T) {
                        break
                    }
                }
            }
            c = parseByte()
        }
        guard packet.count > 5 else { return nil }
        var p = Packet(data: Data(packet))
        var i = 0
        // Parse the timestamp immediately following the <T>
        if packet.count > 2 && packet[i] == Parser.ASCII_T {
            p.timestamp = 0
            i = i + 1
            var c = packet[i]
            while i < packet.count && Parser.isDigit(c) {
                p.timestamp = p.timestamp! * 10 + Int(c - Parser.ASCII_0)
                i = i + 1
                c = packet[i]
            }
            if c != Parser.ASCII_DOLLAR {
                p.timestamp = nil
            } else {
                if firstTimestamp == nil {
                    firstTimestamp = p.timestamp
                }
                // Convert from hundreths of seconds to milliseconds
                p.timestamp = 10 * (p.timestamp! - firstTimestamp!)
            }
        }
        // Parse the signature following the <DOLLAR>
        if i < packet.count - 1 && packet[i] == Parser.ASCII_DOLLAR {
            p.signature = "$"
            i = i + 1
            var c = packet[i]
            while i < packet.count && Parser.isUppercase(c) {
                p.signature = p.signature + String(Character(UnicodeScalar(c)))
                i = i + 1
                c = packet[i]
            }
        }
        return p
    }
    func progress() -> Double {
        let fullPercent = 100.0 * Double(cursor) / Double(data.count)
        return Double(round(10.0 * fullPercent) / 10.0)
    }
}
