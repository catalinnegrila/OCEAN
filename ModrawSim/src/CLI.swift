import Foundation
import ArgumentParser

struct SimOptions: ParsableArguments {
    @Option(name: .shortAndLong, help: ArgumentHelp("Input .modraw file path, or folder to scan for .modraw files."))
    var inputFilePath : String
    
    @Option(name: .shortAndLong, help: ArgumentHelp("Output .modraw file path, or folder to write to."))
    var outputFilePath : String
    
    @Option(name: .shortAndLong, help: ArgumentHelp("Time multiplier.", valueName: "multiplier"))
    var speed = 1.0
    
    mutating func validate() throws {
        guard speed > 0 else {
            throw ValidationError("The time multiplier needs to be a strictly positive number.")
        }

        let outputUrl = URL(fileURLWithPath: outputFilePath)
        let outputIsDir = outputUrl.isDirectory
        if batchMode {
            guard !(outputIsDir != nil && !outputIsDir!) else {
                throw ValidationError("Output in batch mode needs to be a folder not a file: `\(outputUrl.path)`")
            }
        } else {
            guard (outputIsDir != nil && outputIsDir!) ||
                    outputFilePath.lowercased().hasSuffix(".modraw") else {
                throw ValidationError("Output needs to be a folder or a .modraw file: `\(outputUrl.path)`")
            }
        }

        let inputFileUrlList = try inputFileUrlList
        guard inputFileUrlList.count > 0 else {
            if inputFilePath.hasPrefix("@") {
                let inputUrl = URL(fileURLWithPath: String(inputFilePath.dropFirst(1)))
                throw ValidationError("Input list file needs to contain at least one element: '\(inputUrl.path)'")
            } else {
                let inputUrl = URL(fileURLWithPath: inputFilePath)
                throw ValidationError("Input folder needs to contain at least one .modraw file: '\(inputUrl.path)'")
            }
        }

        for inputFileUrl in inputFileUrlList {
            let inputIsDir = inputFileUrl.isDirectory
            guard inputIsDir != nil else {
                throw ValidationError("Input file doesn't exist: `\(inputFileUrl.path)`")
            }
        }
    }

    // Helpers
    var inputFileUrlList : [URL] {
        get throws {
            var files : [String]
            if batchMode {
                let fm = FileManager.default
                files = try fm.contentsOfDirectory(atPath: inputFilePath)
                files = files.filter { $0.lowercased().hasSuffix(".modraw") }
                files = files.sorted()

                let inputBasePath = URL(fileURLWithPath: inputFilePath).path
                files = files.map { $0.hasPrefix("/") ? $0 : "\(inputBasePath)/\($0)" }
            } else {
                files = [inputFilePath]
            }

            return files.map { URL(fileURLWithPath: $0) }
        }
    }

    func outputFileUrl(_ path : URL)  -> URL {
        var outPath: String
        if batchMode {
            // Output is a folder, so append the filename
            outPath = "\(outputFilePath)/\(path.lastPathComponent)"
        } else {
            assert(path == URL(fileURLWithPath: inputFilePath))
            let outUrl = URL(fileURLWithPath: outputFilePath)
            let outIsDir = outUrl.isDirectory
            if outIsDir != nil && outIsDir! {
                outPath = "\(outputFilePath)/\(path.lastPathComponent)"
            } else {
                outPath = outputFilePath
            }
        }
        outPath = outPath.replacingOccurrences(of: "//", with: "/")
        return URL(fileURLWithPath: outPath)
    }

    var batchMode : Bool {
        let inputIsDir = URL(fileURLWithPath: inputFilePath).isDirectory
        return inputIsDir != nil && inputIsDir!
    }
}
