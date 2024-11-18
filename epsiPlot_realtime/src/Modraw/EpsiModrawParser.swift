import Foundation

class EpsiModrawParser {
    var modraw_parser: ModrawParser?
    var packet_parsers : [EpsiModrawPacketParser] =
        [ EpsiModrawPacketParser_EFE4(), EpsiModrawPacketParser_SB49() ]

    var data = ProgressiveEpsiData()

    func readFile(model: Model)
    {
        startParsing(fileUrl: model.currentFileUrl!)
        model.time_window = data.resetTimeWindow()
        data.updateModel(model: model)
        model.calculateDerivedData()
    }
    func startParsing(fileUrl: URL)
    {
        do {
            modraw_parser = try ModrawParser(fileUrl: fileUrl)
            if let header = modraw_parser!.parseHeader() {
                for packet_parser in packet_parsers {
                    packet_parser.parse(header: header)
                }
            }
            parsePackets()
        } catch {
            //windowTitle = error.localizedDescription
            print(error)
        }
    }
    func getParserFor(packet: ModrawPacket) -> EpsiModrawPacketParser? {
        for packet_parser in packet_parsers {
            if packet.signature == packet_parser.signature {
                return packet_parser
            }
        }
        return nil
    }
    func parsePackets() {
        while true {
            if let packet = modraw_parser!.parsePacket() {
                if let packet_parser = getParserFor(packet: packet) {
                    if (packet_parser.isValid(packet: packet)) {
                        packet_parser.parse(packet: packet, data: &data)
                    } else {
                        modraw_parser!.rewindPacket(packet: packet)
                        break
                    }
                }
            } else {
                break
            }
        }
    }

/*
    func tryReadMoreData()
    {
        let fileAttributes = try! FileManager.default.attributesOfItem(atPath: currentFileUrl!.path)
        let newModrawSize = fileAttributes[.size] as! Int
        let oldModrawSize = currentModraw!.getSize()
        if (oldModrawSize < newModrawSize)
        {
            let inputFileData = try! Data(contentsOf: currentFileUrl!)
            var newData = [UInt8](repeating: 0, count: newModrawSize - oldModrawSize)
            inputFileData.copyBytes(to: &newData, from: oldModrawSize..<newModrawSize)
            currentModraw!.appendData(data: newData)
            parsePacketsLoop()
        }
    }
 */
}
/*
class ModrawFolderParser {
    override func openFolder(_ folderUrl: URL)
    {
        super.openFolder(folderUrl)
        time_window_start = 0.0
        time_window_length = 20.0 // seconds
    }
    func updateFromFolder()
    {
        if let enumerator = FileManager.default.enumerator(at: currentFolderUrl!, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            var allFiles = [String]()
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile! {
                        let fileURLString = fileURL.path
                        if fileURLString.lowercased().hasSuffix(".modraw") {
                            allFiles.append(fileURLString)
                        }
                    }
                } catch {
                    windowTitle = error.localizedDescription
                    print(error, fileURL)
                }
            }
            
            allFiles.sort()
            
            let secondMostRecentFile : String? = allFiles.count > 1 ? allFiles[allFiles.count - 2] : nil
            let mostRecentFile : String? = allFiles.count > 0 ? allFiles[allFiles.count - 1] : nil
            if (secondMostRecentFile != nil) {
                if (currentFileUrl != nil) {
                    if (mostRecentFile! == currentFileUrl!.path) {
                        // We are parsing the most recent file
                        tryReadMoreData()
                    } else if (secondMostRecentFile! == currentFileUrl!.path) {
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
                if (currentFileUrl != nil && mostRecentFile! == currentFileUrl!.path) {
                    // We only have one file and are already parsing it
                    tryReadMoreData()
                } else {
                    // We only have one file, start parsing it
                    startParsing(fileUrl: URL(fileURLWithPath: mostRecentFile!))
                }
            } // else no files to parse yet in the folder
        }
    }
}
*/
                                
