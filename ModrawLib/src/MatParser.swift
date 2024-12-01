import Foundation

public class MatParser {
    fileprivate var mat: MatFile
    fileprivate var ns: MatNamespace

    public init(fileUrl : URL) throws {
        mat = try MatFile(fileUrl)
        let namespaceParser = MatNamespaceParser(mat: mat)
        ns = namespaceParser.parse()
    }

    fileprivate struct NumericMatrixReaderData {
        var cols: Int
        var rows: Int
        var reader: () -> Double
    }
    fileprivate func seekToNumericMatrixData(name: String) -> NumericMatrixReaderData {
        let entry = ns.entries[name]
        assert(entry != nil)
        assert(entry!.dimensions.count == 2)

        mat.reader.cursor = entry!.offsetInFile
        let tag = MatDataElementTag(mat.reader)

        return NumericMatrixReaderData(
            cols: entry!.dimensions[0],
            rows: entry!.dimensions[1],
            reader: mat.getNumericReader(dataType: tag.dataType))
    }
    public func getMatrixNumeric2(name : String) -> [[Double]] {
        let nmrd = seekToNumericMatrixData(name: name)

        var result = [[Double]]()
        result.reserveCapacity(nmrd.rows)
        for _ in 0..<nmrd.rows {
            result.append([Double](repeating: 0, count: nmrd.cols))
        }

        for col in 0..<nmrd.cols {
            for row in 0..<nmrd.rows {
                result[row][col] = nmrd.reader()
            }
        }

        return result
    }
    public func getMatrixNumeric1(name : String) -> [Double] {
        let nmrd = seekToNumericMatrixData(name: name)

        assert(nmrd.rows == 1 || nmrd.cols == 1)
        assert(nmrd.rows != 0 && nmrd.cols != 0)
        let n = nmrd.rows * nmrd.cols
        var result = [Double](repeating: 0.0, count: n)
        for i in 0..<n {
            result[i] = nmrd.reader()
        }

        return result
    }
    public func getMatrixNumericValue(name : String) -> Double {
        let nmrd = seekToNumericMatrixData(name: name)

        assert(nmrd.rows == 1 && nmrd.cols == 1)
        return nmrd.reader()
    }
}
