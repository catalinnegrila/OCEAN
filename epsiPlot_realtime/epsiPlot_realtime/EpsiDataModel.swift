import Foundation
import RegexBuilder

class TimestampedData
{
    var capacity : Int = 0
    var time_s : [Double] = []

    func isFull() -> Bool {
        return time_s.count >= capacity
    }
    func reserveCapacity(_ newCapacity: Int)
    {
        time_s.reserveCapacity(newCapacity)
    }
    func removeAll()
    {
        time_s.removeAll()
    }
    func append(from: TimestampedData, first: Int, count: Int)
    {
        time_s.append(contentsOf: from.time_s[first..<first+count])
    }
    func getFirstEntryIndex(_ time_cursor : Double) -> Int
    {
        for i in 0..<time_s.count {
            if (time_s[i] >= time_cursor) {
                return i
            }
        }
        assert(false)
    }
    func getSampleDuration() -> Double
    {
        return time_s[1] - time_s[0]
    }
}

class EpsiData : TimestampedData
{
    var t1_volt : [Double] = []
    var t2_volt : [Double] = []
    var s1_volt : [Double] = []
    var s2_volt : [Double] = []
    var a1_g : [Double] = []
    var a2_g : [Double] = []
    var a3_g : [Double] = []
    
    override init() {
        super.init()
        capacity = 8000
    }
    override func reserveCapacity(_ newCapacity: Int)
    {
        super.reserveCapacity(newCapacity)
        t1_volt.reserveCapacity(newCapacity)
        t2_volt.reserveCapacity(newCapacity)
        s1_volt.reserveCapacity(newCapacity)
        s2_volt.reserveCapacity(newCapacity)
        a1_g.reserveCapacity(newCapacity)
        a2_g.reserveCapacity(newCapacity)
        a3_g.reserveCapacity(newCapacity)
    }
    override func removeAll()
    {
        super.removeAll()
        t1_volt.removeAll()
        t2_volt.removeAll()
        s1_volt.removeAll()
        s2_volt.removeAll()
        a1_g.removeAll()
        a2_g.removeAll()
        a3_g.removeAll()
    }
    func append(from: EpsiData, first: Int, count: Int)
    {
        super.append(from: from, first: first, count: count)
        t1_volt.append(contentsOf: from.t1_volt[first..<first+count])
        t2_volt.append(contentsOf: from.t2_volt[first..<first+count])
        s1_volt.append(contentsOf: from.s1_volt[first..<first+count])
        s2_volt.append(contentsOf: from.s2_volt[first..<first+count])
        a1_g.append(contentsOf: from.a1_g[first..<first+count])
        a2_g.append(contentsOf: from.a2_g[first..<first+count])
        a3_g.append(contentsOf: from.a3_g[first..<first+count])
    }
}

class CtdData : TimestampedData
{
    var P : [Double] = []
    var T : [Double] = []
    var S : [Double] = []
    var C : [Double] = []
    var dPdt : [Double] = []
    
    override init() {
        super.init()
        capacity = 1000
    }
    override func reserveCapacity(_ newCapacity: Int)
    {
        super.reserveCapacity(newCapacity)
        P.reserveCapacity(newCapacity)
        T.reserveCapacity(newCapacity)
        S.reserveCapacity(newCapacity)
        C.reserveCapacity(newCapacity)
        dPdt.reserveCapacity(newCapacity)
    }
    override func removeAll() {
        super.removeAll()
        P.removeAll()
        T.removeAll()
        S.removeAll()
        C.removeAll()
        dPdt.removeAll()
    }
    func append(from: CtdData, first: Int, count: Int)
    {
        super.append(from: from, first: first, count: count)
        P.append(contentsOf: from.P[first..<first+count])
        T.append(contentsOf: from.T[first..<first+count])
        S.append(contentsOf: from.S[first..<first+count])
        C.append(contentsOf: from.C[first..<first+count])
        dPdt.append(contentsOf: from.dPdt[first..<first+count])
    }
}

class EpsiDataModel
{
    var windowTitle : String = ""
    var epsi : EpsiData = EpsiData()
    var ctd : CtdData = CtdData()

    var ctd_dPdt_movmean : [Double] = []

    var epsi_t1_volt_mean : Double = 0
    var epsi_t2_volt_mean : Double = 0
    var epsi_s1_volt_rms : Double = 0
    var epsi_s2_volt_rms : Double = 0

    var epsi_t1_volt_range : (Double, Double) = (0, 0)
    var epsi_t2_volt_range : (Double, Double) = (0, 0)
    var epsi_s1_volt_range : (Double, Double) = (0, 0)
    var epsi_s2_volt_range : (Double, Double) = (0, 0)
    var epsi_a1_g_range : (Double, Double) = (0, 0)
    var epsi_a2_g_range : (Double, Double) = (0, 0)
    var epsi_a3_g_range : (Double, Double) = (0, 0)
    var ctd_P_range : (Double, Double) = (0, 0)
    var ctd_T_range : (Double, Double) = (0, 0)
    var ctd_S_range : (Double, Double) = (0, 0)
    var ctd_C_range : (Double, Double) = (0, 0)
    var ctd_dPdt_range : (Double, Double) = (0, 0)

    var time_window_start = 0.0
    var time_window_length = 0.0

    func update()
    {
        if (epsi.time_s.count > 0)
        {
            epsi_t1_volt_mean = EpsiDataModel.mean(mat: epsi.t1_volt)
            epsi_t2_volt_mean = EpsiDataModel.mean(mat: epsi.t2_volt)
            epsi_s1_volt_rms = EpsiDataModel.rms(mat: epsi.s1_volt)
            epsi_s2_volt_rms = EpsiDataModel.rms(mat: epsi.s2_volt)
            
            epsi_t1_volt_range = EpsiDataModel.minmax(mat: epsi.t1_volt)
            epsi_t2_volt_range = EpsiDataModel.minmax(mat: epsi.t2_volt)
            epsi_s1_volt_range = EpsiDataModel.minmax(mat: epsi.s1_volt)
            epsi_s2_volt_range = EpsiDataModel.minmax(mat: epsi.s2_volt)
            epsi_a1_g_range = EpsiDataModel.minmax(mat: epsi.a1_g)
            epsi_a2_g_range = EpsiDataModel.minmax(mat: epsi.a2_g)
            epsi_a3_g_range = EpsiDataModel.minmax(mat: epsi.a3_g)
        }
        if (ctd.time_s.count > 0)
        {
            ctd_P_range = EpsiDataModel.minmax(mat: ctd.P)
            ctd_T_range = EpsiDataModel.minmax(mat: ctd.T)
            ctd_S_range = EpsiDataModel.minmax(mat: ctd.S)
            ctd_C_range = EpsiDataModel.minmax(mat: ctd.C)
            ctd_dPdt_movmean = EpsiDataModel.movmean(mat: ctd.dPdt, window: 100)
            ctd_dPdt_range = EpsiDataModel.minmax(mat: ctd.dPdt)
            ctd_dPdt_range = (ctd_dPdt_range.1, ctd_dPdt_range.0)
        }
    }
    func printValues()
    {
        /*print("------- \(epsi_t1_volt.count)")
        print("t1_volt: \(epsi_t1_volt[0])")
        print("t2_volt: \(epsi_t2_volt[0])")
        print("s1_volt: \(epsi_s1_volt[0])")
        print("s2_volt: \(epsi_s2_volt[0])")
        print("a1_g: \(epsi_a1_g[0])")
        print("a2_g: \(epsi_a2_g[0])")
        print("a3_g: \(epsi_a3_g[0])")*/
        /*print("------- \(ctd_T_raw.count)")
        print("T_raw: \(ctd_T_raw[0])")
        print("C_raw: \(ctd_C_raw[0])")
        print("P_raw: \(ctd_P_raw[0])")
        print("PT_raw: \(ctd_PT_raw[0])")*/
        /*print("------- \(ctd_P.count)")
        let (P_min, P_max) = EpsiDataModel.getMinMaxMat1(mat: ctd_P)
        print("P: \(ctd_P[0]) (\(P_min),\(P_max))")
        let (T_min, T_max) = EpsiDataModel.getMinMaxMat1(mat: ctd_T)
        print("T: \(ctd_T[0]) (\(T_min),\(T_max))")
        let (S_min, S_max) = EpsiDataModel.getMinMaxMat1(mat: ctd_S)
        print("S: \(ctd_S[0]) (\(S_min),\(S_max))")
        let (C_min, C_max) = EpsiDataModel.getMinMaxMat1(mat: ctd_C)
        print("C: \(ctd_C[0]) (\(C_min),\(C_max))")
        let (dPdt_min, dPdt_max) = EpsiDataModel.getMinMaxMat1(mat: ctd_dPdt)
        print("dPdt: \(ctd_dPdt[0]) (\(dPdt_min),\(dPdt_max))")
        print("-------")*/
    }

    func openFolder(_ folderUrl: URL)
    {
        windowTitle = "Scanning \(folderUrl.path)..."
        print("Reading folder: \(windowTitle)")
    }
    
    func openFile(_ fileUrl: URL)
    {
        windowTitle = fileUrl.path
        print("Reading file: \(windowTitle)")
    }

    static func yAxis(range: (Double, Double)) -> [Double]
    {
        return [range.0, (range.1 + range.0) / 2, range.1]
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
        return sqrt(sum / Double(mat.count))
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
    
    static func mat2ToMat1(mat : [[Double]]) -> [Double]
    {
        assert(mat[0].count == 1)
        var result = Array(repeating: 0.0, count: mat.count)
        for i in 0..<mat.count {
            result[i] = mat[i][0]
        }
        return result
    }

    static func minmax<T:Comparable>(mat : [T]) -> (T, T)
    {
        return (mat.min()!, mat.max()!)
    }

    static func minmaxoff(v1: (Double, Double), off1: Double, v2: (Double, Double), off2: Double) -> (Double, Double)
    {
        return (min(v1.0 + off1, v2.0 + off2), max(v1.1 + off1, v2.1 + off2))

    }
}
