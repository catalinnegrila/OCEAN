import Foundation

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
    class Channel {
        var data = [Double]()

        subscript (i: Int) -> Double {
            get { data[i] }
            set { data[i] = newValue }
        }
        var isEmpty: Bool {
            get { data.isEmpty }
        }
        var count: Int {
            get { data.count }
        }
        func append(_ v: Double) {
            data.append(v)
        }
        func range() -> (Double, Double)
        {
            return data.isEmpty ? (0.0, 0.0) : (data.min()!, data.max()!)
        }
        func invRange() -> (Double, Double)
        {
            return data.isEmpty ? (0.0, 0.0) : (data.max()!, data.min()!)
        }
        func mean() -> Double
        {
            return data.reduce(0.0, +) / Double(data.count)
        }
        func rms() -> Double
        {
            let sumOfSquares = data.reduce(0.0, { (result, next) in
                return result + next * next
            })
            return sqrt(sumOfSquares / Double(data.count * data.count))
        }
    }

    let capacity: Int
    let expected_sample_duration: Double
    var dataGaps = [DataGapInfo]()
    var channels = [Channel]()
    var time_s: Channel { get { channels[channels.count-2] }}
    var time_f: Channel { get { channels[channels.count-1] }}

    required init() {
        self.capacity = 0
        self.expected_sample_duration = 0.0
        assertionFailure()
    }
    init(numChannels: Int, capacity: Int, samples_per_sec: Int) {
        self.capacity = capacity
        self.expected_sample_duration = 1.0 / Double(samples_per_sec)
        for _ in 0..<numChannels + 2 {
            self.channels.append(Channel())
        }
        reserveCapacity(capacity)
    }
    func isFull() -> Bool {
        return time_s.count >= capacity
    }
    func reserveCapacity(_ newCapacity: Int)
    {
        for i in 0..<channels.count {
            channels[i].data.reserveCapacity(newCapacity)
        }
    }
    func removeAll()
    {
        dataGaps.removeAll()
        for i in 0..<channels.count {
            channels[i].data.removeAll()
        }
    }
    func append(from: TimestampedData, first: Int, count: Int)
    {
        assert(channels.count == from.channels.count)
        for i in 0..<channels.count - 1 { // skip the time_f channel
            if !from.channels[i].isEmpty { // some channels are optional
                channels[i].data.append(contentsOf: from.channels[i].data[first..<first+count])
            }
        }
        for dataGap in from.dataGaps {
            if (dataGap.t1 >= from.time_s[first] && dataGap.t0 <= from.time_s[first + count - 1]) {
                dataGaps.append(dataGap)
            }
        }
    }
    func getFirstTimestamp() -> Double {
        return time_s.data.first!
    }
    func getLastTimestamp() -> Double {
        return time_s.data.last!
    }
    func appendNewFileBoundary()
    {
        let boundary_size = 0.025
        dataGaps.append(DataGapInfo(type: .NEW_FILE_BOUNDARY,
                                    t0: getLastTimestamp() - boundary_size,
                                    t1: getLastTimestamp() + boundary_size))
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
            if dataGap.t1 > getFirstTimestamp() {
                dataGaps.insert(dataGap, at: 0)
            }
        }
    }
    func getTimeSlice(t0: Double, t1: Double) -> (Int, Int)? {
        guard !time_s.data.isEmpty && t1 >= getFirstTimestamp() && t0 <= getLastTimestamp() else { return nil }
        var slice = (0, time_s.count - 1)
        while time_s[slice.0] < t0 {
            slice.0 += 1
        }
        while time_s[slice.1] > t1 {
            slice.1 -= 1
        }
        return slice
    }
    func calculateDerivedData(time_window: (Double, Double)) {
        assert(time_f.isEmpty)
        time_f.data.reserveCapacity(time_s.count)
        for i in 0..<time_s.count {
            time_f.append((time_s[i] - time_window.0) / (time_window.1 - time_window.0))
        }
    }
    func mergeBlocks<T: TimestampedData>(time_window: (Double, Double), blocks: inout [T]) {
        removeAll()
        blocks.removeBlocksOlderThan(t0: time_window.0)
        blocks.appendSamplesBetween(t0: time_window.0, t1: time_window.1, data: self)
        if !time_s.isEmpty {
            calculateDerivedData(time_window: time_window)
        }
    }
}

extension Array where Element: TimestampedData {
    mutating func removeBlocksOlderThan(t0: Double) {
        while !isEmpty && first!.getLastTimestamp() < t0 {
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
        return isEmpty ? Double.greatestFiniteMagnitude : first!.getFirstTimestamp()
    }
    func getEndTime() -> Double {
        return isEmpty ? 0.0 : last!.getLastTimestamp()
    }
    mutating func removeLastBlockIfEmpty() {
        if !isEmpty {
            if last!.time_s.isEmpty {
                removeLast()
            }
        }
    }
    mutating func getLastTwoBlocks() -> (Element?, Element) {
        let prev_block = last
        let this_block: Element
        if (prev_block == nil || prev_block!.isFull()) {
            this_block = Element()
            append(this_block)
        } else {
            this_block = prev_block!
        }
        return (prev_block, this_block)
    }
}

