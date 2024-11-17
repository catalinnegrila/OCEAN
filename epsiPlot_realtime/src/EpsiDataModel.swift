import Foundation
import RegexBuilder
import AppKit

class TimestampedData
{
    let capacity : Int
    let expected_sample_duration : Double
    var time_s = [Double]()
    var time_f = [Double]()
    var dataGaps = [(Double, Double)]()

    init(capacity: Int, samples_per_sec: Int) {
        self.capacity = capacity
        self.expected_sample_duration = 1.0 / Double(samples_per_sec)
    }
    func isFull() -> Bool {
        return time_s.count >= capacity
    }
    func reserveCapacity(_ newCapacity: Int)
    {
        time_s.reserveCapacity(newCapacity)
        time_f.reserveCapacity(newCapacity)
    }
    func removeAll()
    {
        time_s.removeAll()
        time_f.removeAll()
        dataGaps.removeAll()
    }
    func append(from: TimestampedData, first: Int, count: Int)
    {
        time_s.append(contentsOf: from.time_s[first..<first+count])
        for dataGap in from.dataGaps {
            if (dataGap.1 >= from.time_s[first] && dataGap.0 <= from.time_s[first+count - 1]) {
                dataGaps.append(dataGap)
            }
        }
    }
    func checkAndAppendGap(t0: Double, t1: Double)
    {
        if ((t1 - t0) > 2 * expected_sample_duration) {
            dataGaps.append((t0 + expected_sample_duration, t1 - expected_sample_duration))
        }
    }
    func checkAndAppendGap(prevBlock: TimestampedData)
    {
        if let dataGap = prevBlock.dataGaps.last {
            if (dataGap.1 > time_s.first!) {
                dataGaps.insert(dataGap, at: 0)
            }
        }
    }
    func getTimeSlice(t0: Double, t1: Double) -> (Int, Int)? {
        assert(t0 <= t1)
        if time_s.isEmpty || time_s.first! > t1 || time_s.last! < t0 {
            return nil
        }
        var slice = (0, time_s.count - 1)
        while time_s[slice.0] < t0 {
            slice.0 += 1
        }
        while time_s[slice.1] > t1 {
            slice.1 -= 1
        }
        return slice
    }
    func computeTimeF(t0: Double, dt: Double) {
        for i in 0..<time_s.count {
            time_f.append((time_s[i] - t0) / dt)
        }
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
    
    init() {
        super.init(capacity: 8000, samples_per_sec: 333) // 100 blocks
        reserveCapacity(capacity)
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
    var z : [Double] = []

    init() {
        super.init(capacity: 200, samples_per_sec: 16) // 100 blocks
        reserveCapacity(capacity)
    }
    override func reserveCapacity(_ newCapacity: Int)
    {
        super.reserveCapacity(newCapacity)
        P.reserveCapacity(newCapacity)
        T.reserveCapacity(newCapacity)
        S.reserveCapacity(newCapacity)
        z.reserveCapacity(newCapacity)
    }
    override func removeAll() {
        super.removeAll()
        P.removeAll()
        T.removeAll()
        S.removeAll()
        z.removeAll()
    }
    func append(from: CtdData, first: Int, count: Int)
    {
        super.append(from: from, first: first, count: count)
        P.append(contentsOf: from.P[first..<first+count])
        T.append(contentsOf: from.T[first..<first+count])
        S.append(contentsOf: from.S[first..<first+count])
        z.append(contentsOf: from.z[first..<first+count])
    }
}

class EpsiDataModel
{
    enum Mode : Int {
        case EPSI = 1, FCTD
    }

    var mode : Mode = .EPSI
    func setMode(_ mode: Mode) {
        self.mode = mode
    }
    var windowTitle : String = ""

    // Source data
    var epsi : EpsiData = EpsiData()
    var ctd : CtdData = CtdData()

    // View data
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
    var ctd_z_range : (Double, Double) = (0, 0)
    // Calculated from ctd.z
    var ctd_dzdt : [Double] = []
    var ctd_dzdt_movmean : [Double] = []
    var ctd_dzdt_range : (Double, Double) = (0, 0)

    var time_window_start = 0.0
    var time_window_length = 0.0

    var sourceDataChanged = false

    func updateSourceData() -> Bool
    {
        return false
    }
    func time(_ t: Double) -> Int {
        return Int(t * 1000) - 1730860000000
    }
    func updateViewData(pixel_width: Int)
    {
        if (epsi.time_s.count > 0)
        {
            epsi.computeTimeF(t0: time_window_start, dt: time_window_length)
            //print("time window: \(time(time_window_start))..\(time(time_window_start+time_window_length))")
            //print("EPSI time_s: \(time(epsi.time_s.first!))..\(time(epsi.time_s.last!))")
            //print("EPSI time_f: \(epsi.time_f.first!)..\(epsi.time_f.last!)")
            epsi_t1_volt_mean = EpsiDataModel.mean(mat: epsi.t1_volt)
            epsi_t2_volt_mean = EpsiDataModel.mean(mat: epsi.t2_volt)
            epsi_s1_volt_rms = EpsiDataModel.rms(mat: epsi.s1_volt)
            epsi_s2_volt_rms = EpsiDataModel.rms(mat: epsi.s2_volt)

            for i in 0..<epsi.time_s.count {
                epsi.t1_volt[i] -= epsi_t1_volt_mean
                epsi.t2_volt[i] -= epsi_t2_volt_mean
                epsi.s1_volt[i] -= epsi_s1_volt_rms
                epsi.s2_volt[i] -= epsi_s2_volt_rms
            }

            epsi_t1_volt_range = EpsiDataModel.minmax(mat: epsi.t1_volt)
            epsi_t2_volt_range = EpsiDataModel.minmax(mat: epsi.t2_volt)
            epsi_s1_volt_range = EpsiDataModel.minmax(mat: epsi.s1_volt)
            epsi_s2_volt_range = EpsiDataModel.minmax(mat: epsi.s2_volt)
            epsi_a1_g_range = EpsiDataModel.minmax(mat: epsi.a1_g)
            epsi_a2_g_range = EpsiDataModel.minmax(mat: epsi.a2_g)
            epsi_a3_g_range = EpsiDataModel.minmax(mat: epsi.a3_g)
        }
        else
        {
            epsi_t1_volt_mean = 0
            epsi_t2_volt_mean = 0
            epsi_s1_volt_rms = 0
            epsi_s2_volt_rms = 0
            epsi_t1_volt_range = (0, 0)
            epsi_t2_volt_range = (0, 0)
            epsi_s1_volt_range = (0, 0)
            epsi_s2_volt_range = (0, 0)
            epsi_a1_g_range = (0, 0)
            epsi_a2_g_range = (0, 0)
            epsi_a3_g_range = (0, 0)
        }
        if (ctd.time_s.count > 0)
        {
            ctd.computeTimeF(t0: time_window_start, dt: time_window_length)
            //print("time window: \(time(time_window_start))..\(time(time_window_start+time_window_length))")
            //print("CTD time_s: \(time(ctd.time_s.first!))..\(time(ctd.time_s.last!))")
            //print("CTD time_f: \(epsi.time_f.first!)..\(ctd.time_f.last!)")
            ctd_P_range = EpsiDataModel.minmax(mat: ctd.P)
            ctd_T_range = EpsiDataModel.minmax(mat: ctd.T)
            ctd_S_range = EpsiDataModel.minmax(mat: ctd.S)
            ctd_z_range = EpsiDataModel.minmax(mat: ctd.z)
            ctd_z_range = (ctd_z_range.1, ctd_z_range.0)

            ctd_dzdt.removeAll()
            ctd_dzdt.reserveCapacity(ctd.z.count)
            ctd_dzdt.append(0.0)
            for i in 1..<ctd.z.count {
                ctd_dzdt.append((ctd.z[i] - ctd.z[i - 1]) / (ctd.time_s[i] - ctd.time_s[i - 1]))
            }
            if (ctd_dzdt.count > 1) {
                ctd_dzdt[0] = ctd_dzdt[1]
            }
            ctd_dzdt_movmean = EpsiDataModel.movmean(mat: ctd_dzdt, window: 40)
            ctd_dzdt_range = EpsiDataModel.minmax(mat: ctd_dzdt_movmean)
            ctd_dzdt_range = (ctd_dzdt_range.1, ctd_dzdt_range.0)
        }
        else
        {
            ctd_P_range = (0, 0)
            ctd_T_range = (0, 0)
            ctd_S_range = (0, 0)
            ctd_z_range = (0, 0)
            ctd_dzdt.removeAll()
            ctd_dzdt_movmean.removeAll()
            ctd_dzdt_range = (0, 0)
            ctd_dzdt_range = (0, 0)
        }

        sourceDataChanged = false
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
    var currentFileUrl : URL?
    var currentFolderUrl : URL?
    func updateWindowTitle()
    {
        if (currentFolderUrl != nil) {
            let currentUrl = currentFileUrl != nil ? currentFileUrl : currentFolderUrl
            windowTitle = "Scanning \(currentUrl!.path) -- \(mode) mode"
        } else if (currentFileUrl != nil){
            windowTitle = "\(currentFileUrl!.path) -- \(mode) mode"
        } else {
            windowTitle = "No data source"
        }
        print(windowTitle)
    }
    func openFolder(_ folderUrl: URL)
    {
        currentFileUrl = nil
        currentFolderUrl = folderUrl
        updateWindowTitle()
        sourceDataChanged = true
    }
    func openFile(_ fileUrl: URL)
    {
        currentFileUrl = fileUrl
        currentFolderUrl = nil
        updateWindowTitle()
        sourceDataChanged = true
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

    static func minmax(v1: (Double, Double), v2: (Double, Double)) -> (Double, Double)
    {
        return (min(v1.0, v2.0), max(v1.1, v2.1))
    }

    static func createInstanceFromFile(_ fileUrl: URL) -> EpsiDataModel? {
        var dataModel : EpsiDataModel?
        switch fileUrl.pathExtension {
        case "mat":
            dataModel = EpsiDataModelMat()
            dataModel!.openFile(fileUrl)
        case "modraw":
            dataModel = EpsiDataModelModraw()
            dataModel!.openFile(fileUrl)
        default:
            print("Unknown file extension for \(fileUrl.path)")
        }
        return dataModel
    }
    static func createInstanceFromFolder(_ folderUrl: URL) -> EpsiDataModel? {
        let dataModel = EpsiDataModelModraw()
        dataModel.openFolder(folderUrl)
        return dataModel
    }
}
