import Foundation

class ScanningFolderModel: Model{
    let folderUrl: URL
    var epsiModrawParser: EpsiModrawParser?
    let time_window_length = 20.0 // seconds

    init(folderUrl: URL) {
        self.folderUrl = folderUrl
        super.init()
    }
    override func getTimeWindow() -> (Double, Double)
    {
        let epsi_time_end = epsi_blocks.isEmpty ? 0.0 : epsi_blocks.last!.time_s.last!
        let ctd_time_end = ctd_blocks.isEmpty ? 0.0 : ctd_blocks.last!.time_s.last!
        let time_window_start = max(epsi_time_end, ctd_time_end) - time_window_length
        // Round time to pixel increments for consistent sampling
        //if (pixel_width > 0) {
        //    let time_per_pixel = time_window_length / Double(pixel_width)
        //    time_window.0 = floor(model.time_window.0 / time_per_pixel) * time_per_pixel
        //}
        return (time_window_start, time_window_start + time_window_length)
    }
    func tryReadMoreData()
    {
        let fileAttributes = try! FileManager.default.attributesOfItem(atPath: fileUrl!.path)
        let newModrawSize = fileAttributes[.size] as! Int
        let oldModrawSize = epsiModrawParser!.modrawParser.data.count
        if (oldModrawSize < newModrawSize)
        {
            let inputFileData = try! Data(contentsOf: fileUrl!)
            var newData = [UInt8](repeating: 0, count: newModrawSize - oldModrawSize)
            inputFileData.copyBytes(to: &newData, from: oldModrawSize..<newModrawSize)
            epsiModrawParser!.modrawParser.appendData(data: newData)
            epsiModrawParser!.parsePackets(model: self)
        }
    }
    func startParsing(fileUrl: URL) {
        do {
            self.fileUrl = fileUrl
            epsiModrawParser = try EpsiModrawParser(model: self)
            status = fileUrl.path
        }
        catch {
            status = error.localizedDescription
        }
    }
    override func update() -> Bool
    {
        if let enumerator = FileManager.default.enumerator(at: folderUrl, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
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
                    status = error.localizedDescription
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
                        tryReadMoreData()
                    } else if (secondMostRecentFile! == fileUrl!.path) {
                        // We are parsing the second most recent file
                        tryReadMoreData()
                        // Start parsing the most recent one
                        startParsing(fileUrl: URL(fileURLWithPath: mostRecentFile!))
                    }
                } else {
                    // Parse the second most recent file first, in case the most recent is partial
                    startParsing(fileUrl: URL(fileURLWithPath: secondMostRecentFile!))
                    // Start parsing the most recent file
                    startParsing(fileUrl: URL(fileURLWithPath: mostRecentFile!))
                }
            } else if (mostRecentFile != nil) {
                if (fileUrl != nil && mostRecentFile! == fileUrl!.path) {
                    // We only have one file and are already parsing it
                    tryReadMoreData()
                } else {
                    // We only have one file, start parsing it
                    startParsing(fileUrl: URL(fileURLWithPath: mostRecentFile!))
                }
            } // else no files to parse yet in the folder
        }

        return super.update()
    }
}


