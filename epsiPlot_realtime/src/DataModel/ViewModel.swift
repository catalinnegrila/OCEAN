import Foundation
import RegexBuilder
import AppKit

@Observable class ViewModel
{
    var model = Model()
    var epsi = EpsiViewModelData()
    var ctd = CtdViewModelData()

    func getWindowTitle() -> String
    {
        var windowTitle : String
        if (model.currentFolderUrl != nil) {
            let currentUrl = model.currentFileUrl != nil ? model.currentFileUrl : model.currentFolderUrl
            windowTitle = "Scanning \(currentUrl!.path)" // -- \(mode) mode"
        } else if (model.currentFileUrl != nil){
            windowTitle = "\(model.currentFileUrl!.path)" // -- \(mode) mode"
        } else {
            windowTitle = "No data source"
        }
        print(windowTitle)
        return windowTitle
    }
    func getTimeWindow() -> (Double, Double)
    {
        var time_window: (Double, Double)
        if (model.currentFolderUrl != nil) {
            /*let epsi_time_end = epsi_blocks.isEmpty ? 0.0 : epsi_blocks.last!.time_s.last!
            let ctd_time_end = ctd_blocks.isEmpty ? 0.0 : ctd_blocks.last!.time_s.last!
            time_window.0 = max(epsi_time_end, ctd_time_end) - time_window_length
            // Round time to pixel increments for consistent sampling
            if (pixel_width > 0) {
                let time_per_pixel = time_window_length / Double(pixel_width)
                time_window.0 = floor(model.time_window.0 / time_per_pixel) * time_per_pixel
            }
            time_window.1 = model.time_window.0 + time_window_length*/
            time_window = (0.0, 0.0)
        } else {
            let epsi_time_begin = model.epsi_blocks.isEmpty ? Double.greatestFiniteMagnitude : model.epsi_blocks.first!.time_s.first!
            let ctd_time_begin = model.ctd_blocks.first!.time_s.isEmpty ? Double.greatestFiniteMagnitude : model.ctd_blocks.first!.time_s.first!
            let epsi_time_end = model.epsi_blocks.last!.time_s.isEmpty ? 0.0 : model.epsi_blocks.last!.time_s.last!
            let ctd_time_end = model.ctd_blocks.last!.time_s.isEmpty ? 0.0 : model.ctd_blocks.last!.time_s.last!
            time_window.0 = min(epsi_time_begin, ctd_time_begin)
            time_window.1 = max(epsi_time_end, ctd_time_end)
        }
        return time_window
    }
    func update() {
        epsi.removeAll()
        ctd.removeAll()
        
        let time_window = getTimeWindow()
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
    }
}
