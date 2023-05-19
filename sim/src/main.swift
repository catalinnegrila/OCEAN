import Foundation

enum MyError: Error {
    case runtimeError(String)
}

func getCurrentTimeMs() -> Int {
    return Int(NSDate().timeIntervalSince1970 * 1000.0)
}

let options = SimOptions.parseOrExit()
print("Running at \(options.speed)x speed")

let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SS"
dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

let inputFileUrlList = try options.inputFileUrlList
for inputFileUrl in inputFileUrlList {
    let outputFileUrl = options.outputFileUrl(inputFileUrl)
    try deleteFile(fileURL: outputFileUrl)
}

var partialEndPacket : Data? = nil

let inputFileUrlListWithIndex = zip(inputFileUrlList.indices, inputFileUrlList)
for (index, inputFileUrl) in inputFileUrlListWithIndex {
    let outputFileUrl = options.outputFileUrl(inputFileUrl)

    print("\nFile \(index + 1) of \(inputFileUrlList.count):")
    print(" Reading '\(inputFileUrl.path)'")
    print(" Writing '\(outputFileUrl.path)'")

    let inputFileData = try Data(contentsOf: inputFileUrl)
    var inputFileParser = Parser(data: inputFileData)

    let header = inputFileParser.parseHeader()
    guard header != nil else {
        throw MyError.runtimeError("Invalid file format. Could not parse header.")
    }
    try header!.appendToURL(fileURL: outputFileUrl)

    let som = inputFileParser.parsePacket()
    guard som != nil &&
            som!.timeOffsetMs == nil &&
            som!.signature == "$SOM" else {
        throw MyError.runtimeError("Expected $SOM first packet.")
    }
    try som!.data.appendToURL(fileURL: outputFileUrl)

    if partialEndPacket != nil {
        print("Patching partial first packet with \(partialEndPacket!).")
        inputFileParser.insertPartialEndPacket(partialEndPacket!)
    }
    partialEndPacket = inputFileParser.extractPartialEndPacket()
    if partialEndPacket != nil {
        print("Extracted partial last packet of \(partialEndPacket!).")
    }

    let startTime = getCurrentTimeMs()
    var lastProgress = -1.0

    var packet = inputFileParser.parsePacket()
    while packet != nil {
        if packet!.timeOffsetMs == nil || packet!.date == nil {
            throw MyError.runtimeError("Expected timestamp on packet.")
        }

        let currentProgress = inputFileParser.progress()
        if lastProgress != currentProgress {
            if options.verbose {
                let date = dateFormatter.string(for: packet!.date!)
                print("\(currentProgress)% - T\(date!) \(packet!.signature)")
            } else {
                print(" Progress: \(currentProgress)% ", terminator: "\r")
                fflush(stdout)
            }
            lastProgress = currentProgress
        }

        let relativeTime = getCurrentTimeMs() - startTime
        if packet!.timeOffsetMs! > relativeTime {
            usleep(UInt32(Double(packet!.timeOffsetMs! - relativeTime) / options.speed))
        }

        try packet!.data.appendToURL(fileURL: outputFileUrl)
        packet = inputFileParser.parsePacket()
    }
}

print("Simulation completed.")

