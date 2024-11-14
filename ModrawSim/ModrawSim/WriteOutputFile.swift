import Foundation

extension String {
    func appendLineToURL(fileURL: URL) throws {
         try (self + "\n").appendToURL(fileURL: fileURL)
     }

     func appendToURL(fileURL: URL) throws {
         let data = self.data(using: String.Encoding.utf8)!
         try data.appendToURL(fileURL: fileURL)
     }
 }

 extension Data {
     func appendToURL(fileURL: URL) throws {
         if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
             defer {
                 fileHandle.closeFile()
             }
             fileHandle.seekToEndOfFile()
             fileHandle.write(self)
         }
         else {
             try write(to: fileURL, options: .atomic)
         }
     }
}

func deleteFile(fileURL: URL) throws {
    let fileManager = FileManager.default
    
    // Check if file exists
    if fileManager.fileExists(atPath: fileURL.path) {
        // Delete file
        try fileManager.removeItem(atPath: fileURL.path)
    }
}
