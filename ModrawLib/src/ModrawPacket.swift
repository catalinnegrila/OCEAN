import Foundation

public class ModrawPacket {
    public var packetStart: Int
    var timestampStart: Int?
    public var signatureStart: Int
    public var checksumStart: Int

    public static let PACKET_CHECKSUM_LEN = 3 // <*><HEX><HEX>
    fileprivate static let PACKET_END_CHECKSUM_LEN = 5 // <*><HEX><HEX><CR><LF>
    fileprivate static let PACKET_TIMESTAMP_LEN = 10

    public let parent: ModrawParser
    init?(parent: ModrawParser) {
        self.parent = parent

        packetStart = parent.cursor
        guard !parent.atEnd() else { return nil }
        if let timestampRange = ModrawPacket.getTimestampRange(parent) {
            timestampStart = timestampRange.0
            parent.cursor = timestampRange.1
        }

        guard parent.peekByte().toChar() == "$" else { return nil }
        signatureStart = parent.cursor

        checksumStart = 0
        while !parent.atEnd()
        {
            // Does this look like a checksum and a new packet beginning?
            if isPacketEndChecksum() {
                checksumStart = parent.cursor
                parent.cursor += ModrawPacket.PACKET_END_CHECKSUM_LEN
                if !parent.atEnd() && parent.peekByte().toChar() == "\n" {
                    parent.cursor += 1
                }
                if isPacketStart() ||
                    parent.foundEndMarker() {
                    break
                }
            } else {
                parent.cursor += 1
            }
        }
        guard checksumStart != 0 else { return nil }
    }
    public func checkSignature(_ signature: String) -> Bool {
        guard signatureStart + signature.count <= checksumStart else { return false }
        return parent.foundMarker(i: signatureStart, marker: signature)
    }
    public func getPayloadStart(signatureLen: Int) -> Int {
        return signatureStart + signatureLen
    }
    public func getTimestampInSeconds() -> Double? {
        guard let timestampStart else { return nil }
        let timestampStr = parent.peekString(at: timestampStart, len: signatureStart - timestampStart)
        guard let timestamp = Int(timestampStr, radix: 10) else { return nil }
        return Double(timestamp) / 100.0
    }
    public func getTimestampAsDate(_ currentYearOffsetInSeconds: Int) -> NSDate? {
        guard let timestampInSeconds = getTimestampInSeconds() else { return nil }
        return NSDate(timeIntervalSince1970: TimeInterval(Double(currentYearOffsetInSeconds) + timestampInSeconds))
    }
    fileprivate static func getTimestampRange(_ parent: ModrawParser) -> (Int, Int)? {
        var i = parent.cursor
        guard i < parent.data.count else { return nil }
        guard parent.data[i].toChar() == "T" else { return nil }
        i += 1
        guard i + ModrawPacket.PACKET_TIMESTAMP_LEN < parent.data.count else { return nil }
        for _ in 0..<ModrawPacket.PACKET_TIMESTAMP_LEN {
            guard parent.data[i].isNumber else { return nil }
            i += 1
        }
        guard parent.data[i].toChar() == "$" else { return nil }
        return (parent.cursor + 1, i)
    }
    fileprivate func isPacketStart() -> Bool {
        if parent.foundMarker(i: parent.cursor, marker: "$SOM3") {
            return true
        }
        if ModrawPacket.getTimestampRange(parent) != nil {
            return true
        }
        return false
    }
    public func isChecksum(_ i: Int) -> Bool {
        return i <= parent.data.count - 3 &&
            parent.data[i].toChar() == "*" &&
            parent.data[i+1].isHexDigit &&
            parent.data[i+2].isHexDigit
    }
    fileprivate func isPacketEndChecksum() -> Bool {
        return isChecksum(parent.cursor) &&
            parent.cursor <= parent.data.count - 5 &&
            parent.data[parent.cursor+3].toChar() == "\r" &&
            parent.data[parent.cursor+4].toChar() == "\n"
    }
}

