import Foundation

class StreamingFolderModelProducer: StreamingModelProducer {
    var fileUrl: URL?
    let folderUrl: URL

    init(folderUrl: URL) {
        self.folderUrl = folderUrl
    }
    func tryReadMoreData(model: Model) {
        guard let epsiModrawParser = epsiModrawParser else { return }
        let fileAttributes = try! FileManager.default.attributesOfItem(atPath: fileUrl!.path)
        let newModrawSize = fileAttributes[.size] as! Int
        let oldModrawSize = epsiModrawParser.modrawParser.data.count
        if (oldModrawSize < newModrawSize)
        {
            let blockSize = newModrawSize - oldModrawSize
            print("Updating \(fileUrl!.path) with \(blockSize)")
            let inputFileData = try! Data(contentsOf: fileUrl!)
            // TODO: does this read the entire file each time?
            var newData = [UInt8](repeating: 0, count: newModrawSize - oldModrawSize)
            inputFileData.copyBytes(to: &newData, from: oldModrawSize..<newModrawSize)
            epsiModrawParser.modrawParser.appendData(bytes: newData)
            epsiModrawParser.parse(model: model)
        }
    }
    func startParsing(model: Model, fileUrl: URL) {
        do {
            model.appendNewFileBoundary()
            self.fileUrl = fileUrl
            epsiModrawParser = try EpsiModrawParser(fileUrl: fileUrl)
            epsiModrawParser!.parse(model: model)
            model.status = "Streaming \(fileUrl.path) -- \(epsiModrawParser!.getHeaderInfo())"
        }
        catch {
            model.status = error.localizedDescription
        }
    }
    override func update(model: Model) -> Bool
    {
        // TODO: optimize this like in ModrawServer
        if let enumerator = FileManager.default.enumerator(at: folderUrl, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles, .skipsPackageDescendants]) {
            var allFiles = [String]()
            for case let fileUrl as URL in enumerator {
                do {
                    let fileAttributes = try fileUrl.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile! {
                        let filePath = fileUrl.path
                        if filePath.lowercased().hasSuffix(".modraw") {
                            allFiles.append(filePath)
                        }
                    }
                } catch {
                    model.status = error.localizedDescription
                    print(error, fileUrl)
                }
            }

            allFiles.sort()

            let secondMostRecentFile : String? = allFiles.count > 1 ? allFiles[allFiles.count - 2] : nil
            let mostRecentFile : String? = allFiles.count > 0 ? allFiles[allFiles.count - 1] : nil
            if (secondMostRecentFile != nil) {
                if (fileUrl != nil) {
                    if (mostRecentFile! == fileUrl!.path) {
                        // We are parsing the most recent file
                        tryReadMoreData(model: model)
                    } else if (secondMostRecentFile! == fileUrl!.path) {
                        // We are parsing the second most recent file
                        tryReadMoreData(model: model)
                        // Start parsing the most recent one
                        startParsing(model: model, fileUrl: URL(fileURLWithPath: mostRecentFile!))
                    }
                } else {
                    // Parse the second most recent file first, in case the most recent is partial
                    startParsing(model: model, fileUrl: URL(fileURLWithPath: secondMostRecentFile!))
                    // Start parsing the most recent file
                    startParsing(model: model, fileUrl: URL(fileURLWithPath: mostRecentFile!))
                }
            } else if (mostRecentFile != nil) {
                if (fileUrl != nil && mostRecentFile! == fileUrl!.path) {
                    // We only have one file and are already parsing it
                    tryReadMoreData(model: model)
                } else {
                    // We only have one file, start parsing it
                    startParsing(model: model, fileUrl: URL(fileURLWithPath: mostRecentFile!))
                }
            } // else no files to parse yet in the folder
        }

        return super.update(model: model)
    }
}
