import Foundation

enum MyError: Error {
    case runtimeError(String)
}

func getCurrentTimeMs() -> Int {
    return Int(NSDate().timeIntervalSince1970 * 1000.0)
}

// If you prefer writing in a "script" style, you can call `parseOrExit()` to
// parse a single `ParsableArguments` type from command-line arguments.
let options = SimulatorOptions.parseOrExit()

if (options.verbose) {
    print("Reading from '\(options.inputFileUrl.path)'")
    print("Writing to '\(options.outputFileUrl.path)'")
    print("Running at \(options.speed)x speed")
}

let inputFileData = try Data(contentsOf: options.inputFileUrl)
var inputFileParser = Parser(data: inputFileData)
let outputFileUrl = options.outputFileUrl
try deleteFile(fileURL: outputFileUrl)

let header = inputFileParser.parseHeader()
if header == nil {
    throw MyError.runtimeError("Invalid file format. Could not parse header.")
}
try header!.appendToURL(fileURL: outputFileUrl)

let som = inputFileParser.parsePacket()
if som == nil {
    throw MyError.runtimeError("Expected SOM first packet.")
}
try som!.data.appendToURL(fileURL: outputFileUrl)

let startTime = getCurrentTimeMs()

let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SS"
dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

var packet = inputFileParser.parsePacket()
while packet != nil {
    if packet!.timeOffsetMs == nil || packet!.date == nil {
        throw MyError.runtimeError("Expected timestamp on packet.")
    }
    if (options.verbose) {
        let date = dateFormatter.string(for: packet!.date!)
        print("\(inputFileParser.progress())% - T\(date!) \(packet!.signature)")
    } else {
        print(" Progress: \(inputFileParser.progress())% ", terminator: "\r")
        fflush(stdout)
    }
    let relativeTime = getCurrentTimeMs() - startTime
    if packet!.timeOffsetMs! > relativeTime {
        usleep(UInt32(Double(packet!.timeOffsetMs! - relativeTime) / options.speed))
    }
    try packet!.data.appendToURL(fileURL: outputFileUrl)
    packet = inputFileParser.parsePacket()
}
print("Simulation completed.")
