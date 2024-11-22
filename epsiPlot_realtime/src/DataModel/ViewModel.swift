import Foundation

/*@Observable */class ViewModel: ObservableObject
{
    @Published var model = Model()
    var epsi = EpsiViewModelData()
    var ctd = CtdViewModelData()

    func update() -> Bool {
        model.semaphore.wait()
        defer { model.semaphore.signal() }

        if (!model.update()) {
            return false
        }

        epsi.removeAll()
        ctd.removeAll()
        
        let time_window = model.getTimeWindow()
        let t0 = time_window.0
        let t1 = time_window.1
        
        while !model.epsi_blocks.isEmpty && model.epsi_blocks.first!.time_s.last! < t0 {
            if (model.epsi_blocks.count > 1) {
                model.epsi_blocks[1].checkAndAppendGap(prevBlock: model.epsi_blocks[0])
            }
            model.epsi_blocks.remove(at: 0)
        }
        if (!model.epsi_blocks.isEmpty) {
            epsi.reserveCapacity(model.epsi_blocks.reduce(0) { $0 + $1.time_s.count })
            for block in model.epsi_blocks {
                let slice = block.getTimeSlice(t0: t0, t1: t1)
                assert(slice != nil)
                if (slice != nil) {
                    epsi.append(from: block, first: slice!.0, count: slice!.1 - slice!.0 + 1)
                }
            }
        }
        while !model.ctd_blocks.isEmpty && model.ctd_blocks.first!.time_s.last! < t0 {
            if (model.ctd_blocks.count > 1) {
                model.ctd_blocks[1].checkAndAppendGap(prevBlock: model.ctd_blocks[0])
            }
            model.ctd_blocks.remove(at: 0)
        }
        if (!model.ctd_blocks.isEmpty) {
            ctd.reserveCapacity(model.ctd_blocks.reduce(0) { $0 + $1.time_s.count })
            for block in model.ctd_blocks {
                let slice = block.getTimeSlice(t0: t0, t1: t1)
                assert(slice != nil)
                if (slice != nil) {
                    ctd.append(from: block, first: slice!.0, count: slice!.1 - slice!.0 + 1)
                }
            }
        }
        epsi.calculateDerivedData(time_window: time_window)
        ctd.calculateDerivedData(time_window: time_window)
        return true
    }
}
