import Foundation

extension URL {
    var isDirectory: Bool? {
        return (try? resourceValues(forKeys: [URLResourceKey.isDirectoryKey]).isDirectory)
    }
}

func appendToURL(fileURL: URL, data: Data) {
    do {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        } else {
            try data.write(to: fileURL)
        }
    } catch {
        print(error)
        exit(1)
    }
}

func deleteFile(fileURL: URL) throws {
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: fileURL.path) {
        try fileManager.removeItem(atPath: fileURL.path)
    }
}

func getCurrentTimeInSeconds() -> Double {
    return NSDate().timeIntervalSince1970
}

func roundTo(_ v: Double, _ m: Double) -> Double {
    return Double(round(m * v) / m)
}


