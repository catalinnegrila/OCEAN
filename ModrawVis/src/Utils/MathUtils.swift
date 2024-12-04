import Foundation

func movmean(mat : [Double], window: Int) -> [Double]
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

func rangeUnion(_ r1: (Double, Double), _ r2: (Double, Double)) -> (Double, Double)
{
    return (min(r1.0, r2.0), max(r1.1, r2.1))
}

func rangeUnion(_ r1: (Double, Double), _ r2: (Double, Double), _ r3: (Double, Double)) -> (Double, Double)
{
    return (min(r1.0, r2.0, r3.0), max(r1.1, r2.1, r3.1))
}
