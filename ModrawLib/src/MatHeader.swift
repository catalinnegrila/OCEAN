class MatHeader {
    var signature: String
    var offset: Int
    var version: Int
    var endian: String

    init(_ reader: ByteArrayReader) {
        assert(reader.cursor == 0)
        signature = reader.readString(116)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        offset = reader.readLEUInt64()
        version = reader.readLEUInt16()
        endian = reader.readString(2)
        assert(version == 0x100)
        assert(endian == "IM")
        print()
    }
    public func print() {
        Swift.print("Signature: '\(signature)'");
        Swift.print("Subsystem offset: 0x\(String(format:"%x", offset))")
        Swift.print("Version: 0x\(String(format:"%02X", version))")
        Swift.print("Endian: '\(endian)'")
    }
}
