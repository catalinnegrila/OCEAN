import Foundation

public extension UInt8 {
    func toChar() -> Character {
        return Character(UnicodeScalar(self))
    }
    var isHexDigit: Bool { get { toChar().isHexDigit }}
    var isNumber: Bool { get { toChar().isNumber }}
}

public class ModrawParser {
    public var data = [UInt8]()
    var cursor = 0

    public convenience init(fileUrl: URL) throws {
        let fileData = try Data(contentsOf: fileUrl)
        self.init(data: fileData)
    }
    public init(bytes: ArraySlice<UInt8>) {
        self.data.append(contentsOf: bytes)
    }
    init(data: Data) {
        self.data = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &self.data, count: data.count)
    }
    public func appendData(bytes: [UInt8]) {
        self.data.append(contentsOf: bytes) //[0..<bytes.count])
    }
    public func appendData(bytes: ArraySlice<UInt8>) {
        self.data.append(contentsOf: bytes)
    }
    public func atBeginning() -> Bool {
        return cursor == 0
    }
    func atEnd(offset: Int = 0) -> Bool {
        return cursor + offset >= data.count
    }
    func peekByte() -> UInt8 {
        return data[cursor]
    }
    func parseLine() -> String? {
        var line = ""
        while true {
            guard !atEnd() else { return nil }
            let c = data[cursor].toChar()
            cursor += 1
            if c == "\r" { continue }
            if c == "\n" { break }
            line += String(c)
        }
        return line
    }
    func foundMarker(i: Int, marker: String) -> Bool {
        var j = i
        for mc in marker {
            if j >= data.count { return false }
            if data[j].toChar() != mc { return false }
            j += 1
        }
        return true
    }
    public func foundEndMarker() -> Bool {
        let MODRAW_END_MARKER = "%*****START_FCTD_TAILER_END_RUN*****"
        return foundMarker(i: cursor, marker: MODRAW_END_MARKER)
    }
    public func parseHeader() -> ModrawHeader? {
        let savedCursor = cursor
        if let header = ModrawHeader(parent: self) {
            return header
        } else {
            cursor = savedCursor
            return nil
        }
    }
    public func peekString(at: Int, len: Int) -> String {
        var str = ""
        for b in data[at..<at+len] {
            if (b == 0) {
                str += "<0>"
            } else {
                str += String(b.toChar())
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
    public func parsePacket() -> ModrawPacket? {
        let savedCursor = cursor
        if let p = ModrawPacket(parent: self) {
            return p
        } else {
            cursor = savedCursor
            return nil
        }
    }
    public func getProgress() -> Double {
        return 100.0 * Double(cursor) / Double(data.count)
    }
}
