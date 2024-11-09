import Foundation
import RegexBuilder

class EpsiDataModel
{
    // Time window
    // How many elements in the window to render
    // On a timer go look at files on disk, read delta, render into view data
    // Source data in 2 buffers, sampled into view data based on window
    
    // Timer on the UI thread
    //  call dataModel.Update()
    //  getChannel()
    //  render

    init() throws
    {}
    
    func getChannel(name : String) -> [Double]
    {
        preconditionFailure("This method must be overridden")
    }
 
    static func mean(mat : [Double]) -> Double
    {
        var sum = 0.0
        for i in 0..<mat.count
        {
            sum += mat[i]
        }
        return sum / Double(mat.count)
    }

    static func rms(mat : [Double]) -> Double
    {
        var sum = 0.0
        for i in 0..<mat.count
        {
            sum += mat[i] * mat[i]
        }
        return sqrt(sum) / Double(mat.count)
    }

    static func movmean(mat : [Double], window: Int) -> [Double]
    {
        var result = Array(repeating: 0.0, count: mat.count)
        for i in 0..<mat.count {
            let window_start = max(0, i - window/2)
            let window_end = min(i + window/2, mat.count)
            var sum = 0.0
            for j in window_start..<window_end {
                sum += mat[j]
            }
            result[i] = sum / Double(window_end - window_start)
        }
        return result
    }

    static func shortenMat1(mat : [Double], newCount: Int) -> [Double]
    {
        assert(newCount < mat.count)
        var result = Array(repeating: 0.0, count: newCount)
        let slice = Double(mat.count) / Double(newCount)
        for i in 0..<newCount {
            result[i] = mat[Int(slice * Double(i))]
        }
        return result
    }
    
    static func offsetMat1(mat : [Double], offset: Double) -> [Double]
    {
        var result = Array(repeating: 0.0, count: mat.count)
        for i in 0..<mat.count {
            result[i] = mat[i] + offset
        }
        return result
    }

    static func mat2ToMat1(mat : [[Double]]) -> [Double]
    {
        assert(mat[0].count == 1)
        var result = Array(repeating: 0.0, count: mat.count)
        for i in 0..<mat.count {
            result[i] = mat[i][0]
        }
        return result
    }

    static func getMinMaxMat1<T:Comparable>(mat : [T]) -> (T, T)
    {
        var minVal = mat[0]
        var maxVal = minVal
        for i in 0..<mat.count {
            let val = mat[i]
            minVal = min(minVal, val)
            maxVal = max(maxVal, val)
        }
        return (minVal, maxVal)
    }
}
