import Foundation

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

    func print() {
        if (VERBOSE) {
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

    func print() {
        if (VERBOSE) {
            Swift.print("ArrayFlags: \(String(describing: matrixClass)) (\(matrixClass))")
        }
    }
}

class MatFile {
    private var data : [UInt8]
    private var cursor : Int

    public init(_ path : String) {
        print("Reading file: \(path)")

        let fileData = try! Data(contentsOf: URL(fileURLWithPath: path))
        self.data = [UInt8](repeating: 0, count: fileData.count)
        fileData.copyBytes(to: &self.data, count: self.data.count)
        cursor = 0

        _ = readMatHeader()
    }

    public func endOfFile() -> Bool {
        assert(cursor <= data.count)
        return cursor == data.count
    }

    public func skip(_ numberOfBytes : Int) {
        assert(cursor + numberOfBytes <= data.count)
        cursor += numberOfBytes;
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

    public func readString(_ numChars : Int) -> String {
        var str = ""
        for _ in 0..<numChars {
            let byte = readByte()
            if (byte != 0) {
                str += String(Character(UnicodeScalar(byte)))
            }
        }
        return str
    }
 
    public func readLEUIntX<Result>(_: Result.Type) -> Result
            where Result: UnsignedInteger
    {
        let expected = MemoryLayout<Result>.size
        assert(cursor + expected <= data.count)
        defer { cursor += expected }
        let sub = data[cursor...cursor + expected - 1]
        assert(sub.count == expected)
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

    public func readMatHeader() -> MatHeader {
        assert(cursor == 0)
        let header = MatHeader()
        header.signature = readString(116)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        header.offset = readLEUInt64()
        header.version = readLEUInt16()
        header.endian = readString(2)
        header.print()
        return header
    }

    public func readDataElementHeader() -> MatDataElementHeader {
        let header = MatDataElementHeader()
        cursor = ((cursor + 7) & ~7)
        assert((cursor % 8) == 0)
        if (data[cursor + 2] != 0 || data[cursor + 3] != 0)
        {
            header.dataType = MatDataType(rawValue: readLEUInt16())!
            header.numberOfBytes = readLEUInt16()
        }
        else
        {
            header.dataType = MatDataType(rawValue: readLEUInt32())!
            header.numberOfBytes = readLEUInt32()
        }
        header.print()

        assert(header.dataType != MatDataType.miCOMPRESSED)
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

var g_currentField = -1
var g_arrayName = ""
var g_fieldNames = [String]()

func readMatrixStruct(_ mat : MatFile) {
    let fieldNameLengthHeader = mat.readDataElementHeader()
    assert(fieldNameLengthHeader.dataType == MatDataType.miINT32)
    assert(fieldNameLengthHeader.numberOfBytes == MemoryLayout<Int32>.size)
    let fieldNameLength = mat.readLEUInt32()
    print()

    let fieldNamesHeader = mat.readDataElementHeader();
    assert(fieldNamesHeader.dataType == MatDataType.miINT8)
    assert(fieldNamesHeader.numberOfBytes % fieldNameLength == 0);
    let fieldNameCount = fieldNamesHeader.numberOfBytes / fieldNameLength

    g_fieldNames = [String](repeating: "", count: fieldNameCount)
    for i in 0..<fieldNameCount {
        let fieldName = mat.readString(fieldNameLength)
        print("[\(String(format: "%02d", i))]: '\(fieldName)'")
        g_fieldNames[i] = fieldName
    }
    g_currentField = 0
}

func readMatrixChar(_ mat : MatFile) {
    let header = mat.readDataElementHeader()
    assert(header.dataType == MatDataType.miUTF8)

    let charName = mat.readString(header.numberOfBytes)
    print("\(String(describing: header.dataType)) '\(charName)'")
}

func readMatrixDouble(_ mat : MatFile) {
    let header = mat.readDataElementHeader()
    let dataTypeSize = MatDataTypeToSize(header.dataType)
    assert(dataTypeSize != 0)
    print(String(describing: header.dataType))
    mat.skip(header.numberOfBytes);
}

func readMatrix(_ mat : MatFile) {
    let arrayFlagsHeader = mat.readDataElementHeader()
    assert(arrayFlagsHeader.dataType == MatDataType.miUINT32)
    assert(arrayFlagsHeader.numberOfBytes == 2 * MemoryLayout<UInt32>.size)
    let arrayFlags = mat.readArrayFlags()

    print()
    if (g_fieldNames.count > 0)
    {
        assert(g_currentField < g_fieldNames.count)
        print("\(g_arrayName).\(g_fieldNames[g_currentField]): ", terminator: "")
        g_currentField += 1
    }

    let dimensionHeader = mat.readDataElementHeader()
    assert(dimensionHeader.dataType == MatDataType.miINT32)
    let dimensions = dimensionHeader.numberOfBytes / MemoryLayout<UInt32>.size
    for i in 0..<dimensions {
        print(mat.readLEUInt32(), terminator: "")
        if (i < dimensions - 1) {
            print("-by-", terminator: "")
        }
    }
    print(", ", terminator: "")

    let arrayNameHeader = mat.readDataElementHeader()
    assert(arrayNameHeader.dataType == MatDataType.miINT8)
    if (arrayNameHeader.numberOfBytes > 0) {
        g_arrayName = mat.readString(arrayNameHeader.numberOfBytes)
        print("'\(g_arrayName)' ", terminator: "")
    }

    switch (arrayFlags.matrixClass) {
    case MatMatrixClass.mxSTRUCT_CLASS:
        readMatrixStruct(mat)
        break

    case MatMatrixClass.mxCHAR_CLASS:
        readMatrixChar(mat)
        break

    case MatMatrixClass.mxDOUBLE_CLASS:
        readMatrixDouble(mat)
        break

    default:
        print("Unsupported matrix type!")
        assert(false)
    }
}

//var mat = MatFile("fctd_grid_uncompressed.mat")
var mat = MatFile("epsi_grid_uncompressed.mat")

while (!mat.endOfFile())
{
    let element = mat.readDataElementHeader();
    if (element.dataType == MatDataType.miMATRIX)
    {
        readMatrix(mat);
    }
    else
    {
        mat.skip(element.numberOfBytes);
    }
}
