import Foundation

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
}

/*@Observable */class ViewModel: ObservableObject
{
    @Published var model = Model()
    var epsi = EpsiViewModelData()
    var ctd = CtdViewModelData()
    var _modelProducer: ModelProducer?
    var modelProducer: ModelProducer? {
        get {
            return _modelProducer
        }
        set(newModelProducer) {
            if (_modelProducer != nil) {
                _modelProducer!.stop()
                _modelProducer = nil
            }
            model.reset()
            _modelProducer = newModelProducer
            if (_modelProducer != nil) {
                _modelProducer!.start(model: model)
            }
        }
    }
    var server = UdpBroadcastServer()
    func append<T>(value: T, data: inout [UInt8]) {
        var v = value
        withUnsafeBytes(of: &v) {
            data.append(contentsOf: Array($0))
        }
    }
    var lastBroadcast: TimeInterval = 0
    func broadcastEpsiData() {
        if !epsi.time_s.isEmpty {
            let currentBroadcast = ProcessInfo.processInfo.systemUptime
            if currentBroadcast - lastBroadcast < 0.1 /*1.0 */{
                return
            }
            lastBroadcast = currentBroadcast

            let duration = 5.0 // seconds
            let samples = 256
            let first_time_s = epsi.time_s.last! - duration
            var i = epsi.time_s.count - 1
            while i > 0 && epsi.time_s[i] > first_time_s {
                i -= 1
            }

            var minv = epsi.a1_g[i]
            var maxv = epsi.a1_g[i]
            var samples_f = [(Double, Double)]()
            samples_f.reserveCapacity(samples)
            for j in 0..<samples {
                var sample_minv = epsi.a1_g[i]
                var sample_maxv = epsi.a1_g[i]
                let last_time_s = first_time_s + duration * Double(j) / Double(samples - 1)
                while i < epsi.time_s.count && epsi.time_s[i] < last_time_s {
                    sample_minv = min(sample_minv, epsi.a1_g[i])
                    sample_maxv = max(sample_maxv, epsi.a1_g[i])
                    i += 1
                }
                samples_f.append((sample_minv, sample_maxv))
                minv = min(minv, sample_minv)
                maxv = max(maxv, sample_maxv)
            }

            func toByte(_ v: Double) -> UInt8 {
                return UInt8(255.0 * (v - minv) / (maxv - minv))
            }

            let header_size = 4 + 4 + 2
            var buf = Array<UInt8>()
            buf.reserveCapacity(header_size + 2 * samples)
            append(value: Float(minv), data: &buf)
            append(value: Float(maxv), data: &buf)
            append(value: UInt16(samples), data: &buf)
            for j in 0..<samples {
                buf.append(toByte(samples_f[j].0))
                buf.append(toByte(samples_f[j].1))
            }
            
            server.broadcast(&buf)
        }
    }
    func update() -> Bool {
        if let modelProducer = modelProducer {
            if (modelProducer.update(model: model)) {
                let time_window = modelProducer.getTimeWindow(model: model)
                epsi.mergeBlocks(time_window: time_window, blocks: &model.epsi_blocks)
                ctd.mergeBlocks(time_window: time_window, blocks: &model.ctd_blocks)
#if DEBUG
                broadcastEpsiData()
#endif
                return true
            }
        }

        return false
    }
}
