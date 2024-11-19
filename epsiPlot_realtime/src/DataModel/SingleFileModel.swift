import Foundation

class SingleFileModel: Model{
    init(fileUrl: URL) {
        super.init()
        self.fileUrl = fileUrl

        switch fileUrl.pathExtension {
        case "mat":
            let _ = EpsiMatParser(model: self)
            status = fileUrl.path
        case "modraw":
            do {
                let _ = try EpsiModrawParser(model: self)
            }
            catch {
                status = error.localizedDescription
            }
        default:
            status = "Unknown file extension for \(fileUrl.path)"
        }
    }
    override func getTimeWindow() -> (Double, Double)
    {
        var time_window: (Double, Double)
        let epsi_time_begin = epsi_blocks.isEmpty ? Double.greatestFiniteMagnitude : epsi_blocks.first!.time_s.first!
        let ctd_time_begin = ctd_blocks.first!.time_s.isEmpty ? Double.greatestFiniteMagnitude : ctd_blocks.first!.time_s.first!
        let epsi_time_end = epsi_blocks.last!.time_s.isEmpty ? 0.0 : epsi_blocks.last!.time_s.last!
        let ctd_time_end = ctd_blocks.last!.time_s.isEmpty ? 0.0 : ctd_blocks.last!.time_s.last!
        time_window.0 = min(epsi_time_begin, ctd_time_begin)
        time_window.1 = max(epsi_time_end, ctd_time_end)
        return time_window
    }
}

