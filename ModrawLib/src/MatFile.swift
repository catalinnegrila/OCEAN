import Foundation
import Compression

fileprivate func decompress(_ compBuffer: ArraySlice<UInt8>) -> Array<UInt8> {
    let compBufferLen = compBuffer.count
    let decompBufferLen = compBufferLen * 20 // Is there a better estimation?
    let decompBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: decompBufferLen)
    defer { decompBuffer.deallocate() }
    let decompSize = compBuffer.withUnsafeBytes ({
        return compression_decode_buffer(
            decompBuffer, decompBufferLen,
            $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1),
            compBufferLen, nil, COMPRESSION_ZLIB)
    })
    return Array<UInt8>(UnsafeBufferPointer(start: decompBuffer, count: decompSize))
}

class MatFile {
    fileprivate var data : [UInt8]
    var reader: ByteArrayReader

    init(_ fileUrl : URL) throws {
        let data = try Data(contentsOf: fileUrl)
        self.data = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &self.data, count: data.count)
        reader = ByteArrayReader(data: self.data[...])
        _ = MatHeader(reader)
        let dataStart = reader.cursor

        print("FileSize: \(self.data.count)")
        var decompData = [UInt8]()
        while !reader.atTheEnd() {
            // compressed data element tags are 8bytes unaligned
            let dataTypeRaw = reader.readLEUInt32()
            let dataType = MatDataType(rawValue: dataTypeRaw)!
            if (dataType != MatDataType.miCOMPRESSED) {
                // Mixed compressed/uncompressed data elements not supported
                assert(decompData.isEmpty)
                break
            }
            let numberOfBytes = reader.readLEUInt32()
            assert(reader.canRead(numberOfBytes))
            // 2 is a mysterious fudge factor
            let compBuffer = reader.getRelativeSlice(2..<numberOfBytes)
            let decompBuffer = decompress(compBuffer)
            print("DataType: \(dataType), \(numberOfBytes) -> \(decompBuffer.count)")
            decompData.append(contentsOf: decompBuffer)
            reader.cursor += numberOfBytes
            assert(align64bit(decompData.count) == decompData.count)
        }
        if (!decompData.isEmpty) {
            self.data = decompData
            reader = ByteArrayReader(data: self.data[...])
        } else {
            reader.cursor = dataStart
        }
    }

    func endOfFile() -> Bool {
        return reader.atTheEnd()
    }
    func readString(_ numChars: Int, _ encoding: MatDataType = .miUINT8) -> String {
        var str = reader.readString(numChars)
        switch encoding {
        case .miUINT8:
            // Binary blob, treat as ASCII
            break

        case .miMATRIX:
            // Binary blob, treat as ASCII
            break

        case .miUTF8:
            str = String(str.utf8)

        case .miUTF16:
            str = String(str.utf16)

        default:
            print("ERROR: Unsupported string encoding: \(String(describing: encoding)) value '\(str)'")
            assertionFailure()
        }
        return str
    }
    func getNumericReader(dataType: MatDataType) -> (() -> Double) {
        switch (dataType) {
        case .miSINGLE:
            return { Double(self.reader.readLESingle()) }
            
        case .miDOUBLE:
            return { self.reader.readLEDouble() }
            
        case .miUINT8:
            return { Double(self.reader.readLEUInt8()) }

        case .miINT8:
            return { Double(self.reader.readLEUInt8()) }
            
        case .miUINT16:
            return { Double(self.reader.readLEUInt16()) }
            
        case .miINT16:
            return { Double(self.reader.readLEInt16()) }
            
        case .miUINT32:
            return { Double(self.reader.readLEUInt32()) }
            
        case .miINT32:
            return { Double(self.reader.readLEInt32()) }
            
        case .miUINT64:
            return { Double(self.reader.readLEUInt64()) }
            
        case .miINT64:
            return { Double(self.reader.readLEInt64()) }
            
        default:
            print("Unsupported type: \(String(describing: dataType))")
            assertionFailure()
            return { 0.0 }
        }
    }
}

