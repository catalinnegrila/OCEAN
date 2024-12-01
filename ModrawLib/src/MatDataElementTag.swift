enum MatDataType : Int {
    case miINT8      = 1 // 8 bit, signed
    case miUINT8     = 2 // 8 bit, unsigned
    case miINT16     = 3 // 16-bit, signed
    case miUINT16    = 4 // 16-bit, unsigned
    case miINT32     = 5 // 32-bit, signed
    case miUINT32    = 6 // 32-bit, unsigned
    case miSINGLE    = 7 // IEEE 754 single format
    // 8 -- Reserved
    case miDOUBLE    = 9 // IEEE 754 double format
    // 10 -- Reserved
    // 11 -- Reserved
    case miINT64     = 12 // 64-bit, signed
    case miUINT64    = 13 // 64-bit, unsigned
    case miMATRIX    = 14 // MATLAB array
    case miCOMPRESSED = 15 // Compressed Data
    case miUTF8      = 16 // Unicode UTF-8 Encoded Character Data
    case miUTF16     = 17 // Unicode UTF-16 Encoded Character Data
    case miUTF32     = 18 // Unicode UTF-32 Encoded Character Data
}

func MatDataTypeToSize(_ dataType: MatDataType) -> Int {
    switch dataType {
    case MatDataType.miINT8:   return 1
    case MatDataType.miUINT8:  return 1
    case MatDataType.miINT16:  return 2
    case MatDataType.miUINT16: return 2

    case MatDataType.miINT32:  return 4
    case MatDataType.miUINT32: return 4

    case MatDataType.miSINGLE: return 4
    case MatDataType.miDOUBLE: return 8

    case MatDataType.miINT64:  return 8
    case MatDataType.miUINT64: return 8

    default:
        return 0
    }
}

class MatDataElementTag {
    var dataType: MatDataType
    var numberOfBytes: Int
    init(_ reader: ByteArrayReader) {
        reader.alignCursorTo64bit()
        assert(reader.canRead(4))
        // Is it a small data element, packed into 4bytes?
        if (reader.data[reader.cursor + 2] != 0 || reader.data[reader.cursor + 3] != 0)
        {
            let dataType = reader.readLEUInt16()
            self.dataType = MatDataType(rawValue: dataType)!
            self.numberOfBytes = reader.readLEUInt16()
        }
        else // No, regular sized 8byte data element
        {
            assert(reader.canRead(8))
            let dataType = reader.readLEUInt32()
            self.dataType = MatDataType(rawValue: dataType)!
            self.numberOfBytes = reader.readLEUInt32()
        }
        print()
    }
    func print(force : Bool = false) {
        if (VERBOSE || force) {
            Swift.print("\nData Element: \(String(describing: dataType)) (\(dataType.rawValue)) size \(numberOfBytes)")
        }
    }
}
