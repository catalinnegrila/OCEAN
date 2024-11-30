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
                model.title = fileUrl.path
            case "modraw":
                let parser = try EpsiModrawParser(fileUrl: fileUrl)
                parser.parse(model: model)
                model.title = fileUrl.path
            default:
                model.title = "Unknown file extension for \(fileUrl.path)"
            }
        }
        catch {
            model.title = error.localizedDescription
        }
    }
    override func getTimeWindow(model: Model) -> (Double, Double)
    {
        return (model.getBeginTime(), model.getEndTime())
    }
}
