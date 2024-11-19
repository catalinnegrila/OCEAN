import Foundation

class Model {
    var epsi_blocks = [EpsiModelData]()
    var ctd_blocks = [CtdModelData]()

    var currentFileUrl: URL?
    var currentFolderUrl: URL?

    func openFolder(_ folderUrl: URL)
    {
        currentFileUrl = nil
        currentFolderUrl = folderUrl
    }
    func openFile(_ fileUrl: URL)
    {
        currentFileUrl = fileUrl
        currentFolderUrl = nil

        switch fileUrl.pathExtension {
        case "mat":
            let parser = EpsiMatParser()
            parser.readFile(model: self)
        case "modraw":
            let parser = EpsiModrawParser()
            parser.readFile(model: self)
        default:
            print("Unknown file extension for \(fileUrl.path)")
        }
    }
}
