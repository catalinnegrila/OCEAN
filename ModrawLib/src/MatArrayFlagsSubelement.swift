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
    case mxUnknown16_CLASS = 16
}

class MatArrayFlagsSubelement {
    var matrixClass = MatMatrixClass.mxCELL_CLASS
    init(_ reader: ByteArrayReader) {
        let matrixClass = reader.readLEUInt8()
        self.matrixClass = MatMatrixClass(rawValue: matrixClass)!
        reader.cursor += 7
        print()
    }
    func print(force : Bool = false) {
        if (VERBOSE || force) {
            Swift.print("ArrayFlags: \(String(describing: matrixClass)) (\(matrixClass))")
        }
    }
}

