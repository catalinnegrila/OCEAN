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

    let realWorldStartTime = getCurrentTimeInSeconds()
    var modrawStartTime: Double?
    var lastProgress = -1.0
    
    var packet = inputFileParser.parsePacket()
    while packet != nil {
        let currentProgress = roundTo(inputFileParser.getProgress(), 10.0)

        if lastProgress != currentProgress {
            print(" Progress: \(currentProgress)%  ", terminator: "\r")
            fflush(stdout)
            lastProgress = currentProgress
        }

        let modrawPacketTime = packet!.getTimestampInSeconds()
        if modrawPacketTime != nil {
            if modrawStartTime == nil {
                modrawStartTime = modrawPacketTime
            }
            let modrawTime = modrawPacketTime! - modrawStartTime!
            let realWorldTime = getCurrentTimeInSeconds() - realWorldStartTime
            if modrawTime > realWorldTime {
                let deltaMicroseconds = (modrawTime - realWorldTime) * 1_000_000.0
                usleep(UInt32(deltaMicroseconds / options.speed))
            }
        }

        let packetStart = packet!.packetStart
        packet = inputFileParser.parsePacket()
        let packetEnd = packet != nil ? packet!.packetStart : inputFileParser.data.count
        appendToURL(fileURL: outputFileUrl, data: Data(inputFileParser.data[packetStart..<packetEnd]))
    }
}

print("Simulation completed.")

