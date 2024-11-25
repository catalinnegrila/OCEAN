import Foundation

class SingleFileModelProducer: ModelProducer {
    var fileUrl: URL

    init(fileUrl: URL) {
        self.fileUrl = fileUrl
    }
    override func start(model: Model)
    {
        do {
            switch fileUrl.pathExtension {
            case "mat":
                let _ = try EpsiMatParser(model: model, fileUrl: fileUrl)
                model.status = fileUrl.path
            case "modraw":
                let parser = try EpsiModrawParser(fileUrl: fileUrl)
                parser.parse(model: model)
                model.status = "\(fileUrl.path) -- \(parser.getHeaderInfo())"
            default:
                model.status = "Unknown file extension for \(fileUrl.path)"
            }
        }
        catch {
            model.status = error.localizedDescription
        }
    }
    override func getTimeWindow(model: Model) -> (Double, Double)
    {
        var time_window: (Double, Double)
        let epsi_time_begin = model.epsi_blocks.getBeginTime()
        let ctd_time_begin = model.ctd_blocks.getBeginTime()
        let epsi_time_end = model.epsi_blocks.getEndTime()
        let ctd_time_end = model.ctd_blocks.getEndTime()
        time_window.0 = min(epsi_time_begin, ctd_time_begin)
        time_window.1 = max(epsi_time_end, ctd_time_end)
        return time_window
    }
}
