class DataGapInfo
{
    enum DataGapType : Int {
        case MISSING_DATA = 1, NEW_FILE_BOUNDARY
    }
    var type: DataGapType
    var t0: Double
    var t1: Double
    init(type: DataGapType, t0: Double, t1: Double) {
        self.type = type
        self.t0 = t0
        self.t1 = t1
    }
}

class TimestampedData
{
    let capacity: Int
    let expected_sample_duration: Double
    var time_s = [Double]()
    var dataGaps = [DataGapInfo]()

    init(capacity: Int, samples_per_sec: Int) {
        self.capacity = capacity
        self.expected_sample_duration = 1.0 / Double(samples_per_sec)
    }
    func isFull() -> Bool {
        return time_s.count >= capacity
    }
    func reserveCapacity(_ newCapacity: Int)
    {
        time_s.reserveCapacity(newCapacity)
    }
    func removeAll()
    {
        time_s.removeAll()
        dataGaps.removeAll()
    }
    func append(from: TimestampedData, first: Int, count: Int)
    {
        time_s.append(contentsOf: from.time_s[first..<first+count])
        for dataGap in from.dataGaps {
            if (dataGap.t1 >= from.time_s[first] && dataGap.t0 <= from.time_s[first + count - 1]) {
                dataGaps.append(dataGap)
            }
        }
    }
    func appendNewFileBoundary()
    {
        let boundary_size = 0.025
        dataGaps.append(DataGapInfo(type: .NEW_FILE_BOUNDARY,
                                    t0: time_s.last! - boundary_size,
                                    t1: time_s.last! + boundary_size))
    }
    func checkAndAppendMissingData(t0: Double, t1: Double)
    {
        if ((t1 - t0) > 2 * expected_sample_duration) {
            dataGaps.append(DataGapInfo(type: .MISSING_DATA,
                                        t0: t0 + expected_sample_duration,
                                        t1: t1 - expected_sample_duration))
        }
    }
    func transferOverlappingGapsFrom(prevBlock: TimestampedData)
    {
        if let dataGap = prevBlock.dataGaps.last {
            if (dataGap.t1 > time_s.first!) {
                dataGaps.insert(dataGap, at: 0)
            }
        }
    }
    func getTimeSlice(t0: Double, t1: Double) -> (Int, Int)? {
        guard !time_s.isEmpty && t1 >= time_s.first! && t0 <= time_s.last! else { return nil }
        var slice = (0, time_s.count - 1)
        while time_s[slice.0] < t0 {
            slice.0 += 1
        }
        while time_s[slice.1] > t1 {
            slice.1 -= 1
        }
        return slice
    }
    func calculateTimeF(time_window: (Double, Double), time_f: inout [Double]) {
        time_f.removeAll()
        time_f.reserveCapacity(time_s.count)
        for i in 0..<time_s.count {
            time_f.append((time_s[i] - time_window.0) / (time_window.1 - time_window.0))
        }
    }
    func calculateDerivedData(time_window: (Double, Double)) {
    }
    func mergeBlocks<T: TimestampedData>(time_window: (Double, Double), blocks: inout [T]) {
        removeAll()
        blocks.removeBlocksOlderThan(t0: time_window.0)
        blocks.appendSamplesBetween(t0: time_window.0, t1: time_window.1, data: self)
        calculateDerivedData(time_window: time_window)
    }
}

extension Array where Element: TimestampedData {
    mutating func removeBlocksOlderThan(t0: Double) {
        while !isEmpty && first!.time_s.last! < t0 {
            if (count > 1) {
                self[1].transferOverlappingGapsFrom(prevBlock: self[0])
            }
            remove(at: 0)
        }
    }
    func appendSamplesBetween<T: TimestampedData>(t0: Double, t1: Double, data: T) {
        if (!isEmpty) {
            data.reserveCapacity(reduce(0) { $0 + $1.time_s.count })
            for block in self {
                let slice = block.getTimeSlice(t0: t0, t1: t1)
                assert(slice != nil)
                if (slice != nil) {
                    data.append(from: block, first: slice!.0, count: slice!.1 - slice!.0 + 1)
                }
            }
        }
    }
    func getBeginTime() -> Double {
        return isEmpty ? Double.greatestFiniteMagnitude : first!.time_s.first!
    }
    func getEndTime() -> Double {
        return isEmpty ? 0.0 : last!.time_s.last!
    }
    mutating func removeLastBlockIfEmpty() {
        if !isEmpty {
            if last!.time_s.isEmpty {
                removeLast()
            }
        }
    }
}

