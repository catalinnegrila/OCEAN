import Foundation

class StreamingFolderModelProducer: StreamingModelProducer {
    var fileUrl: URL?
    let folderUrl: URL

    init(folderUrl: URL) {
        self.folderUrl = folderUrl
    }
    func tryReadMoreData(model: Model) -> Bool {
        guard let epsiModrawParser = epsiModrawParser else { return false }
        let fileAttributes = try! FileManager.default.attributesOfItem(atPath: fileUrl!.path)
        let newModrawSize = fileAttributes[.size] as! Int
        let oldModrawSize = epsiModrawParser.modrawParser.data.count
        guard oldModrawSize != newModrawSize else { return false }

        let inputFileData = try! Data(contentsOf: fileUrl!)
        // TODO: does this read the entire file each time?
        var newData = [UInt8](repeating: 0, count: newModrawSize - oldModrawSize)
        inputFileData.copyBytes(to: &newData, from: oldModrawSize..<newModrawSize)
        epsiModrawParser.modrawParser.appendData(bytes: newData)
        epsiModrawParser.parse(model: model)
        return true
    }
    func startParsing(model: Model, fileUrl: URL) {
        do {
            model.appendNewFileBoundary()
            self.fileUrl = fileUrl
            epsiModrawParser = try EpsiModrawParser(fileUrl: fileUrl)
            epsiModrawParser!.parse(model: model)
            model.title = "Streaming \(fileUrl.path)"
        }
        catch {
            model.title = error.localizedDescription
        }
    }
    fileprivate func getMostRecentFilePath(model: Model) -> String? {
        guard let enumerator = FileManager.default.enumerator(at: folderUrl, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles, .skipsPackageDescendants]) else { return nil }
        
        var mostRecentFilePath: String?
        for case let fileUrl as URL in enumerator {
            do {
                let fileAttributes = try fileUrl.resourceValues(forKeys:[.isRegularFileKey])
                if fileAttributes.isRegularFile! {
                    let filePath = fileUrl.path
                    if filePath.lowercased().hasSuffix(".modraw") {
                        if mostRecentFilePath == nil {
                            mostRecentFilePath = filePath
                        } else if mostRecentFilePath! < filePath {
                            mostRecentFilePath = filePath
                        }
                    }
                }
            } catch {
                model.title = "\(error.localizedDescription), \(fileUrl)"
            }
        }
        return mostRecentFilePath
    }
    override func update(model: Model) -> Bool
    {
        var currentFileUpdated = false
        if fileUrl != nil {
            currentFileUpdated = tryReadMoreData(model: model)
        }
        if !currentFileUpdated {
            if let mostRecentFile = getMostRecentFilePath(model: model) {
                if fileUrl == nil || mostRecentFile != fileUrl!.path {
                    startParsing(model: model, fileUrl: URL(fileURLWithPath: mostRecentFile))
                }
            }
        }
        return super.update(model: model)
    }
}
