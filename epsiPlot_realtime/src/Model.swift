import Foundation
import RegexBuilder
import AppKit

class TimestampedData
{
    let capacity: Int
    let expected_sample_duration: Double
    var time_s = [Double]()
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
    }
    func removeAll()
    {
        time_s.removeAll()
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
    func computeTimeF(time_window: (Double, Double), time_f: inout [Double]) {
        time_f.removeAll()
        time_f.reserveCapacity(time_s.count)
        for i in 0..<time_s.count {
            time_f.append((time_s[i] - time_window.0) / (time_window.1 - time_window.0))
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

@Observable class Model
{
    var currentFileUrl: URL?
    var currentFolderUrl: URL?

    var epsi = EpsiData()
    var ctd = CtdData()

    var epsi_t1_volt_mean = 0.0
    var epsi_t2_volt_mean = 0.0
    var epsi_s1_volt_rms = 0.0
    var epsi_s2_volt_rms = 0.0

    var epsi_t1_volt_range = (0.0, 0.0)
    var epsi_t2_volt_range = (0.0, 0.0)
    var epsi_s1_volt_range = (0.0, 0.0)
    var epsi_s2_volt_range = (0.0, 0.0)
    var epsi_a1_g_range = (0.0, 0.0)
    var epsi_a2_g_range = (0.0, 0.0)
    var epsi_a3_g_range = (0.0, 0.0)
    var ctd_P_range = (0.0, 0.0)
    var ctd_T_range = (0.0, 0.0)
    var ctd_S_range = (0.0, 0.0)
    var ctd_z_range = (0.0, 0.0)

    // Calculated from ctd.z
    var ctd_dzdt = [Double]()
    var ctd_dzdt_movmean = [Double]()
    var ctd_dzdt_range = (0.0, 0.0)

    // Calculated from time_s
    var epsi_time_f = [Double]()
    var ctd_time_f = [Double]()

    var time_window = (0.0, 0.0)

    func getWindowTitle() -> String
    {
        var windowTitle : String
        /*
        if (currentFolderUrl != nil) {
            let currentUrl = currentFileUrl != nil ? currentFileUrl : currentFolderUrl
            windowTitle = "Scanning \(currentUrl!.path) -- \(mode) mode"
        } else if (currentFileUrl != nil){
            windowTitle = "\(currentFileUrl!.path) -- \(mode) mode"
        } else {
            windowTitle = "No data source"
        }*/
        if (currentFileUrl != nil){
            windowTitle = currentFileUrl!.path
        } else {
            windowTitle = "No data source"
        }
        print(windowTitle)
        return windowTitle
    }
    func openFolder(_ folderUrl: URL)
    {
        currentFileUrl = nil
        currentFolderUrl = folderUrl
    }
    func openFile(_ fileUrl: URL)
    {
        currentFileUrl = fileUrl
        currentFolderUrl = nil
    }

    func calculateDerivedData()
    {
        if (epsi.time_s.count > 0)
        {
            epsi.computeTimeF(time_window: time_window, time_f: &epsi_time_f)
            epsi_t1_volt_mean = mean(mat: epsi.t1_volt)
            epsi_t2_volt_mean = mean(mat: epsi.t2_volt)
            epsi_s1_volt_rms = rms(mat: epsi.s1_volt)
            epsi_s2_volt_rms = rms(mat: epsi.s2_volt)

            for i in 0..<epsi.time_s.count {
                epsi.t1_volt[i] -= epsi_t1_volt_mean
                epsi.t2_volt[i] -= epsi_t2_volt_mean
                epsi.s1_volt[i] -= epsi_s1_volt_rms
                epsi.s2_volt[i] -= epsi_s2_volt_rms
            }

            epsi_t1_volt_range = minmax(mat: epsi.t1_volt)
            epsi_t2_volt_range = minmax(mat: epsi.t2_volt)
            epsi_s1_volt_range = minmax(mat: epsi.s1_volt)
            epsi_s2_volt_range = minmax(mat: epsi.s2_volt)
            epsi_a1_g_range = minmax(mat: epsi.a1_g)
            epsi_a2_g_range = minmax(mat: epsi.a2_g)
            epsi_a3_g_range = minmax(mat: epsi.a3_g)
        }
        else
        {
            epsi_time_f.removeAll()
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
            ctd.computeTimeF(time_window: time_window, time_f: &ctd_time_f)
            ctd_P_range = minmax(mat: ctd.P)
            ctd_T_range = minmax(mat: ctd.T)
            ctd_S_range = minmax(mat: ctd.S)
            ctd_z_range = minmax(mat: ctd.z)
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
            ctd_dzdt_movmean = movmean(mat: ctd_dzdt, window: 40)
            ctd_dzdt_range = minmax(mat: ctd_dzdt_movmean)
            ctd_dzdt_range = (ctd_dzdt_range.1, ctd_dzdt_range.0)
        }
        else
        {
            ctd_time_f.removeAll()
            ctd_P_range = (0, 0)
            ctd_T_range = (0, 0)
            ctd_S_range = (0, 0)
            ctd_z_range = (0, 0)
            ctd_dzdt.removeAll()
            ctd_dzdt_movmean.removeAll()
            ctd_dzdt_range = (0, 0)
            ctd_dzdt_range = (0, 0)
        }
    }
    func resetTimeWindow() {
        let epsi_time_begin = epsi.time_s.isEmpty ? Double.greatestFiniteMagnitude : epsi.time_s.first!
        let ctd_time_begin = ctd.time_s.isEmpty ? Double.greatestFiniteMagnitude : ctd.time_s.first!
        let epsi_time_end = epsi.time_s.isEmpty ? 0.0 : epsi.time_s.last!
        let ctd_time_end = ctd.time_s.isEmpty ? 0.0 : ctd.time_s.last!

        time_window.0 = min(epsi_time_begin, ctd_time_begin)
        time_window.1 = max(epsi_time_end, ctd_time_end)
    }
}
