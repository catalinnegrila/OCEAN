class ByteArrayReader {
    var data: ArraySlice<UInt8>
    var cursor: Int = 0
    var count: Int {
        get { data.count }
    }
    init(data: ArraySlice<UInt8>) {
        self.data = data
    }
    func getRelativeSlice(_ range: Range<Int>) -> ArraySlice<UInt8> {
        return data[(cursor + range.startIndex)..<(cursor + range.endIndex)]
    }
    func canRead(_ count: Int) -> Bool {
        return cursor + count <= self.count
    }
    func atTheEnd() -> Bool {
        return !canRead(1)
    }
    func readString(_ count: Int) -> String {
        assert(canRead(count))

        var str = ""
        for _ in 0..<count {
            let byte = data[cursor]
            if (byte != 0) {
                str += String(byte.toChar())
            }
            cursor += 1
        }
        return str
    }
    func readLEAligned<Result>(_: Result.Type) -> Result
    {
        let size = MemoryLayout<Result>.size
        assert(canRead(size))
        defer { cursor += size }
        return data.withUnsafeBytes {
            return $0.load(fromByteOffset: cursor, as: Result.self)
        }
    }
    func readLEBinaryIntegerX<Result>(_: Result.Type) -> Result
            where Result: BinaryInteger
    {
        let size = MemoryLayout<Result>.size
        assert(canRead(size))
        defer { cursor += size }
        return data[cursor..<cursor + size]
            .reversed()
            .reduce(0, { soFar, new in
                    (soFar << 8) | Result(new)
            })
    }
    func readLEUInt8() -> Int {
        Int(readLEAligned(UInt8.self))
    }
    func readLEInt8() -> Int {
        Int(readLEAligned(Int8.self))
    }
    func readLEUInt16() -> Int {
        Int(readLEAligned(UInt16.self))
    }
    func readLEInt16() -> Int {
        Int(readLEAligned(Int16.self))
    }
    func readLEUInt32() -> Int {
        Int(readLEBinaryIntegerX(UInt32.self))
    }
    func readLEInt32() -> Int {
        Int(readLEBinaryIntegerX(Int32.self))
    }
    func readLEUInt64() -> Int {
        Int(readLEBinaryIntegerX(UInt64.self))
    }
    func readLEInt64() -> Int {
        Int(readLEBinaryIntegerX(Int64.self))
    }
    func readLESingle() -> Float {
        return readLEAligned(Float.self)
    }
    func readLEDouble() -> Double {
        return readLEAligned(Double.self)
    }
    func alignCursorTo64bit() {
        cursor = align64bit(cursor)
    }
}

func align64bit(_ x: Int) -> Int {
    return (x + 7) & ~7
}
