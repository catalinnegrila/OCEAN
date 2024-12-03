class EpsiModelData : TimestampedData
{
    var t1_volt : [Double] = []
    var t2_volt : [Double] = []
    var s1_volt : [Double] = []
    var s2_volt : [Double] = []
    var a1_g : [Double] = []
    var a2_g : [Double] = []
    var a3_g : [Double] = []

    required init() {
        super.init(capacity: 8000, samples_per_sec: 333) // 100 blocks
        reserveCapacity(capacity)
    }
    override func reserveCapacity(_ newCapacity: Int)
    {
        super.reserveCapacity(newCapacity)
        t1_volt.reserveCapacity(newCapacity)
        t2_volt.reserveCapacity(newCapacity)
        s1_volt.reserveCapacity(newCapacity)
        s2_volt.reserveCapacity(newCapacity)
        a1_g.reserveCapacity(newCapacity)
        a2_g.reserveCapacity(newCapacity)
        a3_g.reserveCapacity(newCapacity)
    }
    override func removeAll()
    {
        super.removeAll()
        t1_volt.removeAll()
        t2_volt.removeAll()
        s1_volt.removeAll()
        s2_volt.removeAll()
        a1_g.removeAll()
        a2_g.removeAll()
        a3_g.removeAll()
    }
    override func append(from: TimestampedData, first: Int, count: Int)
    {
        super.append(from: from, first: first, count: count)
        if let from = from as? EpsiModelData {
            t1_volt.append(contentsOf: from.t1_volt[first..<first+count])
            t2_volt.append(contentsOf: from.t2_volt[first..<first+count])
            s1_volt.append(contentsOf: from.s1_volt[first..<first+count])
            s2_volt.append(contentsOf: from.s2_volt[first..<first+count])
            a1_g.append(contentsOf: from.a1_g[first..<first+count])
            a2_g.append(contentsOf: from.a2_g[first..<first+count])
            a3_g.append(contentsOf: from.a3_g[first..<first+count])
        }
    }
}

