import Foundation
import ArgumentParser

extension URL {
    var isDirectory: Bool? {
        do {
            return (try resourceValues(forKeys: [URLResourceKey.isDirectoryKey]).isDirectory)
        }
        catch {
            return nil
        }
    }
}

struct SimOptions: ParsableArguments {
    @Option(name: .shortAndLong, help: ArgumentHelp("Input .modraw file path, or @listOfFiles.txt, or folder to scan for .modraw files."))
    var inputFilePath : String
    
    @Option(name: .shortAndLong, help: ArgumentHelp("Output .modraw file path, or folder to write to."))
    var outputFilePath : String
    
    @Option(name: .shortAndLong, help: ArgumentHelp("Time multiplier.", valueName: "multiplier"))
    var speed = 1.0
    
    @Flag(name: .shortAndLong, help: "Show extra information.")
    var verbose = false

    mutating func validate() throws {
        guard speed > 0 else {
            throw ValidationError("The time multiplier needs to be a strictly positive number.")
        }

        if inputFilePath.hasPrefix("@") {
            let inputPath = String(inputFilePath.dropFirst(1))
            let inputUrl = URL(fileURLWithPath: inputPath)
            let inputIsDir = inputUrl.isDirectory
            guard inputIsDir != nil else {
                throw ValidationError("Input list file doesn't exist: '\(inputUrl.path)'")
            }
            guard !inputIsDir! else {
                throw ValidationError("Input list file can't be a folder: '\(inputUrl.path)'")
            }
        }

        let outputUrl = URL(fileURLWithPath: outputFilePath)
        let outputIsDir = outputUrl.isDirectory
        if batchMode {
            guard outputIsDir != nil else {
                throw ValidationError("Output folder for batch mode doesn't exist: `\(outputUrl.path)`.")
            }
            guard outputIsDir! else {
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
                if inputFilePath.hasPrefix("@") {
                    let inputPath = String(inputFilePath.dropFirst(1))
                    let fileContents = try String(contentsOfFile: inputPath)
                    files = fileContents.components(separatedBy: "\n")
                    files = files.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    files = files.filter { !$0.hasPrefix("#") } // ignore comments
                    files = files.filter { !$0.isEmpty } // ignore empty lines

                    let inputBasePath = URL(fileURLWithPath: inputPath).deletingLastPathComponent().path
                    files = files.map { $0.hasPrefix("/") ? $0 : "\(inputBasePath)/\($0)" }
                } else {
                    let fm = FileManager.default
                    files = try fm.contentsOfDirectory(atPath: inputFilePath)
                    files = files.filter { $0.lowercased().hasSuffix(".modraw") }
                    files = files.sorted()

                    let inputBasePath = URL(fileURLWithPath: inputFilePath).path
                    files = files.map { $0.hasPrefix("/") ? $0 : "\(inputBasePath)/\($0)" }
                }
            } else {
                files = [inputFilePath]
            }

            return files.map { URL(fileURLWithPath: $0) }
        }
    }

    func outputFileUrl(_ path : URL)  -> URL {
        if batchMode {
            // Output is a folder, so append the filename
            return URL(fileURLWithPath: "\(outputFilePath)/\(path.lastPathComponent)")
        } else {
            assert(path == URL(fileURLWithPath: inputFilePath))
            let outUrl = URL(fileURLWithPath: outputFilePath)
            let outIsDir = outUrl.isDirectory
            if outIsDir != nil && outIsDir! {
                return URL(fileURLWithPath: "\(outputFilePath)/\(path.lastPathComponent)")
            } else {
                return URL(fileURLWithPath: outputFilePath)
            }
        }
    }

    var batchMode : Bool {
        let inputIsDir = URL(fileURLWithPath: inputFilePath).isDirectory
        return inputFilePath.hasPrefix("@") || (inputIsDir != nil && inputIsDir!)
    }
}
