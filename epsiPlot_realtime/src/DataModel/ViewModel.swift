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
    var time_window = (0.0, 0.0)
    var epsi = EpsiViewModelData()
    var ctd = CtdViewModelData()
    var broadcaster = ViewModelBroadcaster()
    var lastResetCounter = 0

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
    func update() -> Bool {
        if let modelProducer = modelProducer {
            if modelProducer.update(model: model) {
                time_window = modelProducer.getTimeWindow(model: model)
                epsi.mergeBlocks(time_window: time_window, blocks: &model.epsi_blocks)
                ctd.mergeBlocks(time_window: time_window, blocks: &model.ctd_blocks)
                broadcaster.broadcast(vm: self)
                return true
            }
        }

        return false
    }
}
