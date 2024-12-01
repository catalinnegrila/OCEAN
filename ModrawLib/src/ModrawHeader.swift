import Foundation

public class ModrawHeader {
    public let headerEnd: Int
    var lines = [String]()

    let parent: ModrawParser
    init?(parent: ModrawParser) {
        self.parent = parent

        assert(parent.cursor == 0)
        var line = parent.parseLine()
        guard line != nil else { return nil }
        guard line!.starts(with: "header_file_size_inbytes =") else { return nil }
        lines.append(line!)
        
        line = parent.parseLine()
        guard line != nil else { return nil }
        guard line!.starts(with: "TOTAL_HEADER_LINES =") else { return nil }
        lines.append(line!)
        
        line = parent.parseLine()
        guard line != nil else { return nil }
        guard line!.contains("****START_FCTD_HEADER_START_RUN****") else { return nil }
        lines.append(line!)
        
        repeat {
            line = parent.parseLine()
            guard line != nil else { return nil }
            lines.append(line!)
        } while !line!.contains("****END_FCTD_HEADER_START_RUN****")

        if !parent.atEnd() && parent.peekByte() == 0 {
            parent.cursor += 1
        }

        headerEnd = parent.cursor
    }

    public func getValueForKeyAsString(_ key: String) -> String? {
        var value:String?
        for line in lines {
            let comp = line.components(separatedBy: "=")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            if comp.count == 2 && comp[0] == key {
                value = comp[1]
                break
            }
        }
        if let value {
            return value
        } else {
            print("Key '\(key)' not found in header!")
            return nil
        }
    }
    public func getValueForKeyAsDouble(_ key: String) -> Double? {
        if let str = getValueForKeyAsString(key) {
            if let v = Double(str) {
                return v
            } else {
                print("Invalid numeric value for \(key): \(str)")
            }
        }
        return nil
    }
    fileprivate func parseIntFromKeyValue(line: String) -> Int {
        return Int(line.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
    }
}

