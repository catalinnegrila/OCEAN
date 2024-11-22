import Foundation
import Compression

let VERBOSE = false

fileprivate class MatHeader {
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

fileprivate enum MatDataType : Int {
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

fileprivate func MatDataTypeToSize(_ dataType: MatDataType) -> Int {
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

fileprivate class MatDataElementTag {
    var dataType = MatDataType.miINT8
    var numberOfBytes = 0

    func print(force : Bool = false) {
        if (VERBOSE || force) {
            Swift.print("\nData Element: \(String(describing: dataType)) (\(dataType.rawValue)) size \(numberOfBytes)")
        }
    }
}

fileprivate enum MatMatrixClass : Int {
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
    case mxUnknown16_CLASS = 16
}

fileprivate class MatArrayFlagsSubelement {
    var matrixClass = MatMatrixClass.mxCELL_CLASS

    func print(force : Bool = false) {
        if (VERBOSE || force) {
            Swift.print("ArrayFlags: \(String(describing: matrixClass)) (\(matrixClass))")
        }
    }
}

fileprivate class MatFile {
    var data : [UInt8]
    var cursor : Int
    var cursor0 : Int

    func align64bit(_ x: Int) -> Int {
        return (x + 7) & ~7
    }
    func decompress(_ compBuffer: ArraySlice<UInt8>) -> Array<UInt8> {
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
    init(_ fileUrl : URL) {
        let fileData = try! Data(contentsOf: fileUrl)
        self.data = newByteArrayFrom(data: fileData)
        
        cursor = 0
        cursor0 = 0
        _ = readMatHeader()
        cursor0 = cursor

        print("File size: \(fileData.count)")
        var decompData = [UInt8]()
        while cursor < data.count {
            // compressed data element tags are 8bytes unaligned
            let dataTypeRaw = readLEUInt32()
            let dataType = MatDataType(rawValue: dataTypeRaw)!
            if (dataType != MatDataType.miCOMPRESSED) {
                // Mixed compressed/uncompressed data elements not supported
                assert(decompData.isEmpty)
                break
            }
            print("\nDataType: \(dataType)")
            let numberOfBytes = readLEUInt32()
            print("CompressedBytes: \(numberOfBytes)")
            assert(cursor + numberOfBytes <= data.count)
            // 2 is a mysterious fudge factor
            let decompBuffer = decompress(data[(cursor + 2)..<(cursor + numberOfBytes)])
            print("UncompressedBytes: \(decompBuffer.count)")
            decompData.append(contentsOf: decompBuffer)
            cursor += numberOfBytes
            assert(align64bit(decompData.count) == decompData.count)
        }
        if (!decompData.isEmpty) {
            self.data = decompData
            cursor0 = 0
        }
        seek(0)
    }

    func endOfFile() -> Bool {
        assert(cursor <= data.count)
        return cursor == data.count
    }
    func skip(_ numberOfBytes : Int) {
        assert(cursor + numberOfBytes <= data.count)
        cursor += numberOfBytes;
    }
    func seek(_ pos : Int) {
        assert(cursor0 + pos >= 0 && cursor0 + pos < data.count)
        cursor = cursor0 + pos;
    }
    func tell() -> Int {
        assert(cursor >= cursor0)
        return cursor - cursor0
    }
    func seekToEnd() {
        cursor = data.count
    }
    func readByte() -> UInt8 {
        assert(cursor < data.count)
        defer { cursor += 1 }
        return data[cursor]
    }
    func readString(_ numChars: Int, _ encoding: MatDataType = .miUINT8) -> String {
        var str = ""
        for _ in 0..<numChars {
            let byte = readByte()
            if (byte != 0) {
                str += String(Character(UnicodeScalar(byte)))
            }
        }

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
            assert(false)
        }
        return str
    }

    func readLEFloatX<Result>(_: Result.Type) -> Result
    {
        let expected = MemoryLayout<Result>.size
        assert(cursor + expected <= data.count)
        defer { cursor += expected }
        return data.withUnsafeBytes {
            return $0.load(fromByteOffset: cursor, as: Result.self)
        }
    }
    func readLESingle() -> Float {
        return readLEFloatX(Float.self)
    }
    func readLEDouble() -> Double {
        return readLEFloatX(Double.self)
    }
    func readLEUIntX<Result>(_: Result.Type) -> Result
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
    func readLEIntX<Result>(_: Result.Type) -> Result
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
    func readLEUInt8() -> Int {
        Int(readLEUIntX(UInt8.self))
    }
    func readLEUInt16() -> Int {
        Int(readLEUIntX(UInt16.self))
    }
    func readLEUInt32() -> Int {
        Int(readLEUIntX(UInt32.self))
    }
    func readLEUInt64() -> Int {
        Int(readLEUIntX(UInt64.self))
    }
    func readLEInt64() -> Int {
        Int(readLEIntX(Int64.self))
    }
    func readLEInt32() -> Int {
        Int(readLEIntX(Int32.self))
    }
    func getNumericReader(dataType: MatDataType) -> (() -> Double) {
        switch (dataType) {
        case .miSINGLE:
            return { Double(self.readLESingle()) }
            
        case .miDOUBLE:
            return { self.readLEDouble() }
            
        case .miUINT8:
            return { Double(self.readLEUInt8()) }
            
        case .miUINT16:
            return { Double(self.readLEUInt16()) }
            
        case .miUINT32:
            return { Double(self.readLEUInt32()) }
            
        case .miINT32:
            return { Double(self.readLEInt32()) }
            
        case .miUINT64:
            return { Double(self.readLEUInt64()) }
            
        case .miINT64:
            return {  Double(self.readLEInt64()) }
            
        default:
            print("Unsupported type: \(String(describing: dataType))")
            assert(false)
            return { 0.0 }
        }
    }
    func readMatHeader() -> MatHeader {
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
    func readDataElementTag() -> MatDataElementTag {
        cursor = align64bit(cursor)
        //assert(cursor < data.count)
        let tag = MatDataElementTag()
        // Is it a small data element, packed into 4bytes?
        if (data[cursor + 2] != 0 || data[cursor + 3] != 0)
        {
            let dataType = readLEUInt16()
            tag.dataType = MatDataType(rawValue: dataType)!
            tag.numberOfBytes = readLEUInt16()
        }
        else // No, regular sized 8byte data element
        {
            let dataType = readLEUInt32()
            tag.dataType = MatDataType(rawValue: dataType)!
            tag.numberOfBytes = readLEUInt32()
        }
        tag.print()
        return tag
    }
    func readArrayFlags() -> MatArrayFlagsSubelement {
        let arrayFlags = MatArrayFlagsSubelement()
        let matrixClass = readLEUInt8()
        arrayFlags.matrixClass = MatMatrixClass(rawValue: matrixClass)!
        skip(7)
        arrayFlags.print()
        return arrayFlags
    }
}

fileprivate class MatNamespaceEntry {
    var name = ""
    var offsetInFile = 0
    var dimensions: [Int] = [Int]()
}

fileprivate class MatNamespace {
    var entries = [String : MatNamespaceEntry]()
}

fileprivate class MatNamespaceParser {
    var mat: MatFile
    var ns = MatNamespace()
    var missingNameCount = 0
    init(mat: MatFile) {
        self.mat = mat
    }
    func readNamespace() -> MatNamespace {
        while !mat.endOfFile() {
            let element = mat.readDataElementTag();
            switch element.dataType {
            case MatDataType.miMATRIX:
                readMatrix(entry: nil)
                
            default:
                print("ERROR: Unsupported root data element!")
                element.print(force: true)
                assert(false)
                //mat.skip(element.numberOfBytes)
            }
        }
        return ns
    }
    func readMatrixStruct(parentName: String) {
        let fieldNameLengthTag = mat.readDataElementTag()
        assert(fieldNameLengthTag.dataType == MatDataType.miINT32)
        assert(fieldNameLengthTag.numberOfBytes == MemoryLayout<Int32>.size)
        let fieldNameLength = mat.readLEUInt32()
        print()
        
        let fieldNamesTag = mat.readDataElementTag();
        assert(fieldNamesTag.dataType == MatDataType.miINT8)
        assert(fieldNamesTag.numberOfBytes % fieldNameLength == 0);
        let fieldNameCount = fieldNamesTag.numberOfBytes / fieldNameLength
        
        var entries = [MatNamespaceEntry]()
        for i in 0..<fieldNameCount {
            let fieldName = mat.readString(fieldNameLength)
            let entryName = "\(parentName).\(fieldName)"
            print("[\(String(format: "%02d", i))]: '\(entryName)'")
            let entry = MatNamespaceEntry()
            entry.name = entryName
            ns.entries[entryName] = entry
            entries.append(entry)
        }

        for i in 0..<fieldNameCount {
            let field = mat.readDataElementTag();
            assert(field.dataType == MatDataType.miMATRIX)
            readMatrix(entry: entries[i])
        }
    }
    func readMatrix(entry: MatNamespaceEntry?) {
        let arrayFlagsTag = mat.readDataElementTag()
        assert(arrayFlagsTag.dataType == MatDataType.miUINT32)
        assert(arrayFlagsTag.numberOfBytes == 2 * MemoryLayout<UInt32>.size)
        let arrayFlags = mat.readArrayFlags()
        
        print()
        if (entry != nil) {
            print("\(entry!.name): ", terminator: "")
        }
        
        let dimensionTag = mat.readDataElementTag()
        assert(dimensionTag.dataType == MatDataType.miINT32)
        let dimensions = dimensionTag.numberOfBytes / MemoryLayout<UInt32>.size
        for i in 0..<dimensions {
            let val = mat.readLEUInt32()
            if (entry != nil) {
                entry!.dimensions.append(val)
            }
            print(val, terminator: "")
            if (i < dimensions - 1) {
                print("-by-", terminator: "")
            }
        }
        print(", ", terminator: "")
    
        var parentName : String
        let arrayNameTag = mat.readDataElementTag()
        assert(arrayNameTag.dataType == MatDataType.miINT8)
        if (arrayNameTag.numberOfBytes > 0) {
            let arrayName = mat.readString(arrayNameTag.numberOfBytes)
            assert(entry == nil)
            parentName = arrayName
            print("'\(parentName)' ", terminator: "")
        } else if (entry != nil) {
            parentName = entry!.name
        } else {
            parentName = "UNNAMED_\(missingNameCount)"
            print("'\(parentName)' ", terminator: "")
            missingNameCount += 1
        }

        if (entry != nil) {
            entry!.offsetInFile = mat.tell()
        }

        switch (arrayFlags.matrixClass) {
        case MatMatrixClass.mxSTRUCT_CLASS:
            readMatrixStruct(parentName: parentName)

        case MatMatrixClass.mxCHAR_CLASS:
            skipMatrixChar()
            
        case MatMatrixClass.mxCELL_CLASS:
            skipMatrixChar() // ?

        case MatMatrixClass.mxSINGLE_CLASS: fallthrough
        case MatMatrixClass.mxDOUBLE_CLASS: fallthrough
        case MatMatrixClass.mxINT8_CLASS: fallthrough
        case MatMatrixClass.mxUINT8_CLASS: fallthrough
        case MatMatrixClass.mxINT16_CLASS: fallthrough
        case MatMatrixClass.mxUINT16_CLASS: fallthrough
        case MatMatrixClass.mxINT32_CLASS: fallthrough
        case MatMatrixClass.mxUINT32_CLASS: fallthrough
        case MatMatrixClass.mxINT64_CLASS: fallthrough
        case MatMatrixClass.mxUINT64_CLASS:
            skipMatrixNumeric()

        default:
            print("ERROR: Unsupported matrix type!")
            arrayFlags.print(force: true)
            skipMatrixChar()
        }
    }
    func skipMatrixChar() {
        let tag = mat.readDataElementTag()
        let val = mat.readString(tag.numberOfBytes, tag.dataType)
        print("\(String(describing: tag.dataType)) '\(val)'")
    }
    func skipMatrixNumeric() {
        let tag = mat.readDataElementTag()
        let dataTypeSize = MatDataTypeToSize(tag.dataType)
        let n = tag.numberOfBytes / dataTypeSize
        assert(dataTypeSize != 0)
        print(String(describing: tag.dataType))
        let reader = mat.getNumericReader(dataType: tag.dataType)
        if (n > 0) {
            var minVal = reader()
            var maxVal = minVal
            for _ in 1..<n {
                let val = reader()
                minVal = min(minVal, val)
                maxVal = max(maxVal, val)
            }
            print("Min: \(minVal), Max: \(maxVal)")
        } else {
            print("<empty>")
        }
    }
}

class MatParser {
    fileprivate var mat: MatFile
    fileprivate var ns: MatNamespace

    init(fileUrl : URL) {
        mat = MatFile(fileUrl)
        let namespaceParser = MatNamespaceParser(mat: mat)
        ns = namespaceParser.readNamespace()
    }

    fileprivate struct NumericMatrixReaderData {
        var cols: Int
        var rows: Int
        var reader: () -> Double
    }
    fileprivate func seekToNumericMatrixData(name: String) -> NumericMatrixReaderData {
        let entry = ns.entries[name]
        assert(entry != nil)
        assert(entry!.dimensions.count == 2)

        mat.seek(entry!.offsetInFile)
        let tag = mat.readDataElementTag()

        return NumericMatrixReaderData(
            cols: entry!.dimensions[0],
            rows: entry!.dimensions[1],
            reader: mat.getNumericReader(dataType: tag.dataType))
    }
    public func getMatrixNumeric2(name : String) -> [[Double]] {
        let nmrd = seekToNumericMatrixData(name: name)

        var result = [[Double]]()
        result.reserveCapacity(nmrd.rows)
        for _ in 0..<nmrd.rows {
            result.append([Double](repeating: 0, count: nmrd.cols))
        }

        for col in 0..<nmrd.cols {
            for row in 0..<nmrd.rows {
                result[row][col] = nmrd.reader()
            }
        }

        return result
    }
    public func getMatrixNumeric1(name : String) -> [Double] {
        let nmrd = seekToNumericMatrixData(name: name)

        assert(nmrd.rows == 1 || nmrd.cols == 1)
        assert(nmrd.rows != 0 && nmrd.cols != 0)
        let n = nmrd.rows * nmrd.cols
        var result = [Double](repeating: 0.0, count: n)
        for i in 0..<n {
            result[i] = nmrd.reader()
        }

        return result
    }
    public func getMatrixNumericValue(name : String) -> Double {
        let nmrd = seekToNumericMatrixData(name: name)

        assert(nmrd.rows == 1 && nmrd.cols == 1)
        return nmrd.reader()
    }
}
