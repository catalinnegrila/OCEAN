class FluorModelData : TimestampedData
{
    var bb : [Double] = []
    var chla : [Double] = []
    var fDOM : [Double] = []

    required init() {
        super.init(capacity: 200, samples_per_sec: 16) // 100 blocks
        reserveCapacity(capacity)
    }
    override func reserveCapacity(_ newCapacity: Int)
    {
        super.reserveCapacity(newCapacity)
        bb.reserveCapacity(newCapacity)
        chla.reserveCapacity(newCapacity)
        fDOM.reserveCapacity(newCapacity)
    }
    override func removeAll() {
        super.removeAll()
        bb.removeAll()
        chla.removeAll()
        fDOM.removeAll()
    }
    override func append(from: TimestampedData, first: Int, count: Int)
    {
        super.append(from: from, first: first, count: count)
        if let from = from as? FluorModelData {
            bb.append(contentsOf: from.bb[first..<first+count])
            chla.append(contentsOf: from.chla[first..<first+count])
            fDOM.append(contentsOf: from.fDOM[first..<first+count])
        }
    }
}
