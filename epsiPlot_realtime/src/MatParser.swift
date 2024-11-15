import Foundation
import Compression

let VERBOSE = false

class MatHeader {
    var signature = "" // 116
    var offset = 0
    var version = 0
    var endian = "" // 2

    public func print() {
        Swift.print("Signature: '\(signature)'");
        Swift.print("Subsystem offset: 0x\(String(format:"%x", offset))")
        Swift.print("Version: 0x\(String(format:"%02X", version))")
        Swift.print("Endian: '\(endian)'")
    }
}

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
    switch (dataType)
    {
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

class MatDataElementHeader {
    var dataType = MatDataType.miINT8
    var numberOfBytes = 0

    func print(force : Bool = false) {
        if (VERBOSE || force) {
            Swift.print("\nData Element: \(String(describing: dataType)) (\(dataType.rawValue)) size \(numberOfBytes)")
        }
    }
}

enum MatMatrixClass : Int {
    case mxCELL_CLASS    = 1 // Cell array
    case mxSTRUCT_CLASS  = 2 // Structure
    case mxOBJECT_CLASS  = 3 // Object
    case mxCHAR_CLASS    = 4 // Character array
    case mxSPARSE_CLASS  = 5 // Sparse array
    case mxDOUBLE_CLASS  = 6 // Double precision array
    case mxSINGLE_CLASS  = 7 // Single precision array
    case mxINT8_CLASS    = 8 // 8-bit, signed integer
    case mxUINT8_CLASS   = 9 // 8-bit, unsigned integer
    case mxINT16_CLASS   = 10 // 16-bit, signed integer
    case mxUINT16_CLASS  = 11 // 16-bit, unsigned integer
    case mxINT32_CLASS   = 12 // 32-bit, signed integer
    case mxUINT32_CLASS  = 13 // 32-bit, unsigned integer
    case mxINT64_CLASS   = 14 // 64-bit, signed integer
    case mxUINT64_CLASS  = 15 // 64-bit, unsigned integer
}

class MatArrayFlagsSubelement {
    var matrixClass = MatMatrixClass.mxCELL_CLASS

    func print(force : Bool = false) {
        if (VERBOSE || force) {
            Swift.print("ArrayFlags: \(String(describing: matrixClass)) (\(matrixClass))")
        }
    }
}

class MatFile {
    private var data : [UInt8]
    private var cursor : Int
    private var cursor0 : Int

    public init(_ fileUrl : URL) {
        let fileData = try! Data(contentsOf: fileUrl)
        self.data = [UInt8](repeating: 0, count: fileData.count)
        fileData.copyBytes(to: &self.data, count: self.data.count)

        cursor = 0
        cursor0 = 0
        _ = readMatHeader()
        cursor0 = cursor

        print("File size: \(fileData.count)")
        var decompData = [UInt8]()
        while cursor < data.count {
            let dataElement = readDataElementHeader()
            print("DataType: \(dataElement.dataType)")
            print("NumberOfBytes: \(dataElement.numberOfBytes)")
            assert(data.count >= cursor + dataElement.numberOfBytes)
            assert(dataElement.dataType == MatDataType.miCOMPRESSED)
            let uncompressedLen = dataElement.numberOfBytes * 20
            let uncompressed = UnsafeMutablePointer<UInt8>.allocate(capacity: uncompressedLen)
            // 2 is a mysterious fudge factor
            let writtenLen = data[(cursor + 2)..<(cursor + dataElement.numberOfBytes)].withUnsafeBytes ({
                return compression_decode_buffer(
                    uncompressed, uncompressedLen,
                    $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1),
                    dataElement.numberOfBytes - 2, nil, COMPRESSION_ZLIB)
            })
            assert(writtenLen > 0)
            decompData.append(contentsOf: Array(UnsafeBufferPointer(start: uncompressed, count: writtenLen)))
            uncompressed.deallocate()
            cursor += dataElement.numberOfBytes
        }
        self.data = decompData
        cursor0 = 0
        seek(0)
    }

    public func endOfFile() -> Bool {
        assert(cursor <= data.count)
        return cursor == data.count
    }

    public func skip(_ numberOfBytes : Int) {
        assert(cursor + numberOfBytes <= data.count)
        cursor += numberOfBytes;
    }

    public func seek(_ pos : Int) {
        assert(cursor0 + pos >= 0 && cursor0 + pos < data.count)
        cursor = cursor0 + pos;
    }

    public func tell() -> Int {
        assert(cursor >= cursor0)
        return cursor - cursor0
    }
    public func seekToEnd() {
        cursor = data.count
    }
    public func readByte() -> UInt8 {
        assert(cursor < data.count)
        defer { cursor += 1 }
        return data[cursor]
    }

    public func readChar() -> Character {
        let byte = readByte()
        return Character(UnicodeScalar(byte))
    }

    public func readString(_ numChars: Int, _ encoding: MatDataType? = nil) -> String {
        var str = ""
        for _ in 0..<numChars {
            let byte = readByte()
            if (byte != 0) {
                str += String(Character(UnicodeScalar(byte)))
            }
        }

        if (encoding != nil) {
            switch (encoding!) {
            case .miUTF8:
                str = String(str.utf8)

            case .miUTF16:
                str = String(str.utf16)

            default:
                print("ERROR: Unsupported string encoding: \(String(describing: encoding!))")
                assert(false)
            }
        }

        return str
    }

    public func readLEDouble() -> Double
    {
        let expected = MemoryLayout<Double>.size
        assert(cursor + expected <= data.count)
        defer { cursor += expected }
        return data.withUnsafeBytes {
            return $0.load(fromByteOffset: cursor, as: Double.self)
        }
    }

    public func readLEUIntX<Result>(_: Result.Type) -> Result
            where Result: UnsignedInteger
    {
        let expected = MemoryLayout<Result>.size
        assert(cursor + expected <= data.count)
        defer { cursor += expected }
        let sub = data[cursor..<cursor + expected]
        return sub
            .reversed()
            .reduce(0, { soFar, new in
                    (soFar << 8) | Result(new)
            })
    }

    public func readLEIntX<Result>(_: Result.Type) -> Result
            where Result: SignedInteger
    {
        let expected = MemoryLayout<Result>.size
        assert(cursor + expected <= data.count)
        defer { cursor += expected }
        let sub = data[cursor..<cursor + expected]
        return sub
            .reversed()
            .reduce(0, { soFar, new in
                    (soFar << 8) | Result(new)
            })
    }

    public func readLEUInt8() -> Int {
        Int(readLEUIntX(UInt8.self))
    }

    public func readLEUInt16() -> Int {
        Int(readLEUIntX(UInt16.self))
    }

    public func readLEUInt32() -> Int {
        Int(readLEUIntX(UInt32.self))
    }

    public func readLEUInt64() -> Int {
        Int(readLEUIntX(UInt64.self))
    }

    public func readLEInt32() -> Int {
        Int(readLEIntX(Int32.self))
    }

    public func readMatHeader() -> MatHeader {
        assert(cursor == 0)
        let header = MatHeader()
        header.signature = readString(116)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        header.offset = readLEUInt64()
        header.version = readLEUInt16()
        header.endian = readString(2)
        assert(header.version == 0x100)
        assert(header.endian == "IM")
        header.print()
        return header
    }

    public func readDataElementHeader() -> MatDataElementHeader {
        let header = MatDataElementHeader()
        // Is it a small data element, packed into 4bytes?
        if (data[cursor + 2] != 0 || data[cursor + 3] != 0)
        {
            let dataType = readLEUInt16()
            let numberOfBytes = readLEUInt16()
            header.dataType = MatDataType(rawValue: dataType)!
            header.numberOfBytes = numberOfBytes
        }
        else // No, regular sized 8byte data element
        {
            let dataType = readLEUInt32()
            header.dataType = MatDataType(rawValue: dataType)!
            header.numberOfBytes = readLEUInt32()
        }
        header.print()
        return header
    }

    public func readArrayFlags() -> MatArrayFlagsSubelement {
        let arrayFlags = MatArrayFlagsSubelement()
        arrayFlags.matrixClass = MatMatrixClass(rawValue: readLEUInt8())!
        skip(7)
        arrayFlags.print()
        return arrayFlags
    }
}

class MatData {
    struct FieldInfo {
        var name = ""
        var offsetInFile = 0
        var dimensions : [Int] = [Int]()
    }

    var mat : MatFile
    var arrayName = ""
    var fieldInfo = [FieldInfo]()

    init(fileUrl : URL) {
        mat = MatFile(fileUrl)
        while !mat.endOfFile() {
            let element = mat.readDataElementHeader();
            switch (element.dataType) {
            case MatDataType.miMATRIX:
                readMatrix()
                
            default:
                print("ERROR: Unknown data element!")
                element.print(force: true)
                assert(false)
                //mat.skip(element.numberOfBytes)
            }
        }
        mat.seek(0)
    }

    private func readMatrixStruct() {
        let fieldNameLengthHeader = mat.readDataElementHeader()
        assert(fieldNameLengthHeader.dataType == MatDataType.miINT32)
        assert(fieldNameLengthHeader.numberOfBytes == MemoryLayout<Int32>.size)
        let fieldNameLength = mat.readLEUInt32()
        print()
        
        let fieldNamesHeader = mat.readDataElementHeader();
        assert(fieldNamesHeader.dataType == MatDataType.miINT8)
        assert(fieldNamesHeader.numberOfBytes % fieldNameLength == 0);
        let fieldNameCount = fieldNamesHeader.numberOfBytes / fieldNameLength
        
        let firstField = fieldInfo.count
        for i in 0..<fieldNameCount {
            let fieldName = mat.readString(fieldNameLength)
            print("[\(String(format: "%02d", i))]: '\(fieldName)'")
            fieldInfo.append(FieldInfo(name: "\(arrayName).\(fieldName)"))
        }

        let aligner = (arrayName != "Meta_Data") ? 4 : 8
        let padding = (aligner - (fieldNamesHeader.numberOfBytes % aligner)) % aligner
        mat.skip(padding)

        for i in 0..<fieldNameCount {
            let field = mat.readDataElementHeader();
            assert(field.dataType == MatDataType.miMATRIX)
            readMatrix(currentField: firstField + i)
        }
    }
    
    func skipMatrixChar() {
        let header = mat.readDataElementHeader()
        let val = mat.readString(header.numberOfBytes, header.dataType)
        print("\(String(describing: header.dataType)) '\(val)'")
    }
    
    func getMatrixChar(name: String) -> String {
        let field = fieldInfo.first { $0.name == name }
        assert(field != nil)

        let prevPos = mat.tell()
        defer { mat.seek(prevPos) }
        mat.seek(field!.offsetInFile)

        let header = mat.readDataElementHeader()
        return mat.readString(header.numberOfBytes, header.dataType)
    }

    func skipMatrixDouble() {
        let header = mat.readDataElementHeader()
        let dataTypeSize = MatDataTypeToSize(header.dataType)
        assert(dataTypeSize != 0)
        print(String(describing: header.dataType))
        if (header.dataType == MatDataType.miDOUBLE) {
            var minVal = mat.readLEDouble()
            var maxVal = minVal
            for _ in 1..<(header.numberOfBytes / dataTypeSize) {
                let val = mat.readLEDouble()
                minVal = fmin(minVal, val)
                maxVal = fmax(maxVal, val)
            }
            print("Min: \(minVal), Max: \(maxVal)")
        } else {
            mat.skip(header.numberOfBytes)
        }
    }
    
    func skipMatrixUInt32() {
        let header = mat.readDataElementHeader()
        let dataTypeSize = MatDataTypeToSize(header.dataType)
        assert(dataTypeSize != 0)
        print(String(describing: header.dataType))
        if (header.dataType == MatDataType.miUINT32) {
            var minVal = mat.readLEUInt32()
            var maxVal = minVal
            for _ in 1..<(header.numberOfBytes / dataTypeSize) {
                let val = mat.readLEUInt32()
                minVal = min(minVal, val)
                maxVal = max(maxVal, val)
            }
            print("Min: \(minVal), Max: \(maxVal)")
        } else {
            mat.skip(header.numberOfBytes)
        }
    }

    func getMatrixDouble2(name : String) -> [[Double]] {
        let field = fieldInfo.first { $0.name == name }
        assert(field != nil)

        let prevPos = mat.tell()
        defer { mat.seek(prevPos) }
        mat.seek(field!.offsetInFile)

        assert(field!.dimensions.count == 2)
        var result = Array(repeating: Array<Double>(repeating: 0.0, count: field!.dimensions[1]), count: field!.dimensions[0])

        let header = mat.readDataElementHeader()
        for i in 0..<result[0].count {
            for j in 0..<result.count {
                switch (header.dataType) {
                case .miDOUBLE:
                    result[j][i] = mat.readLEDouble()

                case .miUINT8:
                    result[j][i] = Double(mat.readLEUInt8())

                case .miUINT16:
                    result[j][i] = Double(mat.readLEUInt16())

                case .miUINT32:
                    result[j][i] = Double(mat.readLEUInt32())

                case .miINT32:
                    result[j][i] = Double(mat.readLEInt32())

                default:
                    print("Unsupported Matrix2D type: \(String(describing: header.dataType))")
                    assert(false)
                }
            }
        }

        return result
    }

    func readMatrix(currentField: Int? = nil) {
        let arrayFlagsHeader = mat.readDataElementHeader()
        assert(arrayFlagsHeader.dataType == MatDataType.miUINT32)
        assert(arrayFlagsHeader.numberOfBytes == 2 * MemoryLayout<UInt32>.size)
        let arrayFlags = mat.readArrayFlags()
        
        print()
        if (currentField != nil) {
            print("\(fieldInfo[currentField!].name): ", terminator: "")
        }
        
        let dimensionHeader = mat.readDataElementHeader()
        assert(dimensionHeader.dataType == MatDataType.miINT32)
        let dimensions = dimensionHeader.numberOfBytes / MemoryLayout<UInt32>.size
        for i in 0..<dimensions {
            let val = mat.readLEUInt32()
            if (currentField != nil) {
                fieldInfo[currentField!].dimensions.append(val)
            }
            print(val, terminator: "")
            if (i < dimensions - 1) {
                print("-by-", terminator: "")
            }
        }
        print(", ", terminator: "")
        
        let arrayNameHeader = mat.readDataElementHeader()
        assert(arrayNameHeader.dataType == MatDataType.miINT8)
        if (arrayNameHeader.numberOfBytes > 0) {
            arrayName = mat.readString(arrayNameHeader.numberOfBytes)
            print("'\(arrayName)' ", terminator: "")
            if (arrayName == "Meta_Data") {
                print("BUG: noping out!")
                mat.seekToEnd()
                return
            }
        }

        if (currentField != nil) {
            fieldInfo[currentField!].offsetInFile = mat.tell()
        }

        let aligner = (arrayName != "Meta_Data") ? 4 : 8
        let padding = (aligner - (arrayNameHeader.numberOfBytes % aligner)) % aligner
        mat.skip(padding)

        switch (arrayFlags.matrixClass) {
        case MatMatrixClass.mxSTRUCT_CLASS:
            readMatrixStruct()

        case MatMatrixClass.mxCHAR_CLASS:
            assert(currentField != nil)
            skipMatrixChar()
            
        case MatMatrixClass.mxDOUBLE_CLASS:
            skipMatrixDouble()
            
        case MatMatrixClass.mxUINT32_CLASS:
            assert(currentField != nil)
            skipMatrixUInt32()

        default:
            print("ERROR: Unsupported matrix type!")
            arrayFlags.print(force: true)
            assert(false)
        }
    }
}
