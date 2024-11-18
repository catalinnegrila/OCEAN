import Foundation

class ProgressiveEpsiData {
    var epsi_blocks = [EpsiData]()
    var ctd_blocks = [CtdData]()

    func resetTimeWindow() -> (Double, Double) {
        let epsi_time_begin = epsi_blocks.isEmpty ? Double.greatestFiniteMagnitude : epsi_blocks.first!.time_s.first!
        let ctd_time_begin = ctd_blocks.isEmpty ? Double.greatestFiniteMagnitude : ctd_blocks.first!.time_s.first!
        let epsi_time_end = epsi_blocks.isEmpty ? 0.0 : epsi_blocks.last!.time_s.last!
        let ctd_time_end = ctd_blocks.isEmpty ? 0.0 : ctd_blocks.last!.time_s.last!

        return (min(epsi_time_begin, ctd_time_begin),
                max(epsi_time_end, ctd_time_end))
    }
    /*
    func updateModelTimeWindow(pixel_width: Int, time_window_length: Double, model: Model) {
        if (model.currentFolderUrl != nil) {
            let epsi_time_end = epsi_blocks.isEmpty ? 0.0 : epsi_blocks.last!.time_s.last!
            let ctd_time_end = ctd_blocks.isEmpty ? 0.0 : ctd_blocks.last!.time_s.last!
            model.time_window.0 = max(epsi_time_end, ctd_time_end) - time_window_length
            // Round time to pixel increments for consistent sampling
            if (pixel_width > 0) {
                let time_per_pixel = time_window_length / Double(pixel_width)
                model.time_window.0 = floor(model.time_window.0 / time_per_pixel) * time_per_pixel
            }
            model.time_window.1 = model.time_window.0 + time_window_length
        }
    }*/
    func updateModel(model: Model) {
        model.epsi.removeAll()
        model.ctd.removeAll()
        
        let t0 = model.time_window.0
        let t1 = model.time_window.1
        
        while !epsi_blocks.isEmpty && epsi_blocks.first!.time_s.last! < t0 {
            if (epsi_blocks.count > 1) {
                epsi_blocks[1].checkAndAppendGap(prevBlock: epsi_blocks[0])
            }
            epsi_blocks.remove(at: 0)
        }
        if (!epsi_blocks.isEmpty) {
            model.epsi.reserveCapacity(epsi_blocks.reduce(0) { $0 + $1.time_s.count })
            for block in epsi_blocks {
                let slice = block.getTimeSlice(t0: t0, t1: t1)
                assert(slice != nil)
                if (slice != nil) {
                    model.epsi.append(from: block, first: slice!.0, count: slice!.1 - slice!.0 + 1)
                }
            }
        }
        while !ctd_blocks.isEmpty && ctd_blocks.first!.time_s.last! < t0 {
            if (ctd_blocks.count > 1) {
                ctd_blocks[1].checkAndAppendGap(prevBlock: ctd_blocks[0])
            }
            ctd_blocks.remove(at: 0)
        }
        if (!ctd_blocks.isEmpty) {
            model.ctd.reserveCapacity(ctd_blocks.reduce(0) { $0 + $1.time_s.count })
            for block in ctd_blocks {
                let slice = block.getTimeSlice(t0: t0, t1: t1)
                assert(slice != nil)
                if (slice != nil) {
                    model.ctd.append(from: block, first: slice!.0, count: slice!.1 - slice!.0 + 1)
                }
            }
        }
    }
}
