import Foundation
import ModrawLib

let options = SimOptions.parseOrExit()
print("Running at \(options.speed)x speed")

let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SS"
dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

if options.batchMode {
    let fm = FileManager.default
    let outputFileUrl = URL(fileURLWithPath: options.outputFilePath)
    if outputFileUrl.isDirectory == nil {
        try fm.createDirectory(atPath: options.outputFilePath, withIntermediateDirectories: true)
    }
    let filePaths = try fm.contentsOfDirectory(atPath: options.outputFilePath)
    for filePath in filePaths {
        try fm.removeItem(atPath: "\(options.outputFilePath)/\(filePath)")
    }
}

let inputFileUrlList = try options.inputFileUrlList
for inputFileUrl in inputFileUrlList {
    let outputFileUrl = options.outputFileUrl(inputFileUrl)
    try deleteFile(fileURL: outputFileUrl)
}

for i in 0..<inputFileUrlList.count {
    let inputFileUrl = inputFileUrlList[i]
    let outputFileUrl = options.outputFileUrl(inputFileUrl)

    print("\nFile \(i + 1) of \(inputFileUrlList.count):")
    print(" Reading '\(inputFileUrl.path)'")
    print(" Writing '\(outputFileUrl.path)'")

    let inputFileParser = try? ModrawParser(fileUrl: inputFileUrl)
    guard let inputFileParser else {
        print("Failed to read input file from disk. Skipping...")
        continue
    }
    guard let header = inputFileParser.parseHeader() else {
        print("Invalid file header format. Skipping....")
        continue
    }
    appendToURL(fileURL: outputFileUrl, data: Data(inputFileParser.data[0..<header.headerEnd]))

    let realWorldStartTime = getCurrentTimeMs()
    var modrawStartTime: Int?
    var lastProgress = -1.0
    
    var packet = inputFileParser.parsePacket()
    while packet != nil {
        let currentProgress = Double(round(10.0 * inputFileParser.getProgress()) / 10.0)

        if lastProgress != currentProgress {
            //print(" Progress: \(currentProgress)%  ", terminator: "\r")
            //fflush(stdout)
            lastProgress = currentProgress
        }
            
        let modrawPacketTime = packet!.getTimestamp()
        if modrawPacketTime != nil {
            if modrawStartTime == nil {
                modrawStartTime = modrawPacketTime
            }
            let modrawTime = modrawPacketTime! - modrawStartTime!
            let realWorldTime = getCurrentTimeMs() - realWorldStartTime
            if modrawTime > realWorldTime {
                //print("Sleep: \(modrawTime - realWorldTime)")
                //usleep(UInt32(Double(modrawTime - realWorldTime) / options.speed))
            }
        }

        let packetStart = packet!.packetStart
        packet = inputFileParser.parsePacket()
        let packetEnd = packet != nil ? packet!.packetStart : inputFileParser.data.count
        appendToURL(fileURL: outputFileUrl, data: Data(inputFileParser.data[packetStart..<packetEnd]))
        if packet == nil {
            print("File duration: \(modrawPacketTime! - modrawStartTime!)")
        }
    }
}

print("Simulation completed.")

