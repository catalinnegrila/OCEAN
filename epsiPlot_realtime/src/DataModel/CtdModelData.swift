class CtdModelData : TimestampedData
{
    var P : [Double] = []
    var T : [Double] = []
    var S : [Double] = []
    var z : [Double] = []

    init() {
        super.init(capacity: 200, samples_per_sec: 16) // 100 blocks
        reserveCapacity(capacity)
    }
    override func reserveCapacity(_ newCapacity: Int)
    {
        super.reserveCapacity(newCapacity)
        P.reserveCapacity(newCapacity)
        T.reserveCapacity(newCapacity)
        S.reserveCapacity(newCapacity)
        z.reserveCapacity(newCapacity)
    }
    override func removeAll() {
        super.removeAll()
        P.removeAll()
        T.removeAll()
        S.removeAll()
        z.removeAll()
    }
    func append(from: CtdModelData, first: Int, count: Int)
    {
        super.append(from: from, first: first, count: count)
        P.append(contentsOf: from.P[first..<first+count])
        T.append(contentsOf: from.T[first..<first+count])
        S.append(contentsOf: from.S[first..<first+count])
        z.append(contentsOf: from.z[first..<first+count])
    }
}
