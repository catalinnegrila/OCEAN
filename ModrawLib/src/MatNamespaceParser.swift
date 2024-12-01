let VERBOSE = false

class MatNamespaceEntry {
    var name = ""
    var offsetInFile = 0
    var dimensions: [Int] = [Int]()
}

class MatNamespace {
    var entries = [String : MatNamespaceEntry]()
}

class MatNamespaceParser {
    fileprivate var mat: MatFile
    fileprivate var ns = MatNamespace()
    fileprivate var missingNameCount = 0
    init(mat: MatFile) {
        self.mat = mat
    }
    func parse() -> MatNamespace {
        while !mat.endOfFile() {
            let element = MatDataElementTag(mat.reader)
            switch element.dataType {
            case MatDataType.miMATRIX:
                readMatrix(entry: nil)
            default:
                print("ERROR: Unsupported root data element!")
                element.print(force: true)
                assertionFailure()
                mat.reader.cursor += element.numberOfBytes
            }
        }
        return ns
    }
    fileprivate func readMatrixStruct(parentName: String) {
        let fieldNameLengthTag = MatDataElementTag(mat.reader)
        assert(fieldNameLengthTag.dataType == MatDataType.miINT32)
        assert(fieldNameLengthTag.numberOfBytes == MemoryLayout<Int32>.size)
        let fieldNameLength = mat.reader.readLEUInt32()
        
        let fieldNamesTag = MatDataElementTag(mat.reader)
        assert(fieldNamesTag.dataType == MatDataType.miINT8)
        assert(fieldNamesTag.numberOfBytes % fieldNameLength == 0);
        let fieldNameCount = fieldNamesTag.numberOfBytes / fieldNameLength
        print("STRUCT[\(fieldNameCount)]:")

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
            let field = MatDataElementTag(mat.reader)
            assert(field.dataType == MatDataType.miMATRIX)
            readMatrix(entry: entries[i])
        }
    }
    fileprivate func readMatrix(entry: MatNamespaceEntry?) {
        let arrayFlagsTag = MatDataElementTag(mat.reader)
        assert(arrayFlagsTag.dataType == MatDataType.miUINT32)
        assert(arrayFlagsTag.numberOfBytes == 2 * MemoryLayout<UInt32>.size)
        let arrayFlags = MatArrayFlagsSubelement(mat.reader)
        
        print()
        if (entry != nil) {
            print("\(entry!.name): ", terminator: "")
        }
        
        let dimensionTag = MatDataElementTag(mat.reader)
        assert(dimensionTag.dataType == MatDataType.miINT32)
        let dimensions = dimensionTag.numberOfBytes / MemoryLayout<UInt32>.size
        assert(dimensions > 0)
        for i in 0..<dimensions {
            let val = mat.reader.readLEUInt32()
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
        let arrayNameTag = MatDataElementTag(mat.reader)
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
            entry!.offsetInFile = mat.reader.cursor
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
    fileprivate func skipMatrixChar() {
        let tag = MatDataElementTag(mat.reader)
        let val = mat.readString(tag.numberOfBytes, tag.dataType)
        print("\(String(describing: tag.dataType))[\(tag.numberOfBytes)]: '\(val)'")
    }
    fileprivate func skipMatrixNumeric() {
        let tag = MatDataElementTag(mat.reader)
        let dataTypeSize = MatDataTypeToSize(tag.dataType)
        assert(dataTypeSize != 0)
        let n = tag.numberOfBytes / dataTypeSize
        print("\(String(describing: tag.dataType))[\(n)]")
        if VERBOSE {
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
        } else {
            mat.reader.cursor += tag.numberOfBytes
        }
    }
}

