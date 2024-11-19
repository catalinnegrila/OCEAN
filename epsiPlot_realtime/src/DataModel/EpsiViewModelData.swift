class EpsiViewModelData: EpsiModelData {
    var time_f = [Double]()

    var t1_volt_mean = 0.0
    var t2_volt_mean = 0.0
    var s1_volt_rms = 0.0
    var s2_volt_rms = 0.0

    var t1_volt_range = (0.0, 0.0)
    var t2_volt_range = (0.0, 0.0)
    var s1_volt_range = (0.0, 0.0)
    var s2_volt_range = (0.0, 0.0)
    var a1_g_range = (0.0, 0.0)
    var a2_g_range = (0.0, 0.0)
    var a3_g_range = (0.0, 0.0)

    override func removeAll()
    {
        super.removeAll()
        time_f.removeAll()
        t1_volt_mean = 0
        t2_volt_mean = 0
        s1_volt_rms = 0
        s2_volt_rms = 0
        t1_volt_range = (0, 0)
        t2_volt_range = (0, 0)
        s1_volt_range = (0, 0)
        s2_volt_range = (0, 0)
        a1_g_range = (0, 0)
        a2_g_range = (0, 0)
        a3_g_range = (0, 0)
    }
    func calculateDerivedData(time_window: (Double, Double))
    {
        if (time_s.count > 0)
        {
            calculateTimeF(time_window: time_window, time_f: &time_f)
            t1_volt_mean = mean(mat: t1_volt)
            t2_volt_mean = mean(mat: t2_volt)
            s1_volt_rms = rms(mat: s1_volt)
            s2_volt_rms = rms(mat: s2_volt)
            
            for i in 0..<time_s.count {
                t1_volt[i] -= t1_volt_mean
                t2_volt[i] -= t2_volt_mean
                s1_volt[i] -= s1_volt_rms
                s2_volt[i] -= s2_volt_rms
            }
            
            t1_volt_range = minmax(mat: t1_volt)
            t2_volt_range = minmax(mat: t2_volt)
            s1_volt_range = minmax(mat: s1_volt)
            s2_volt_range = minmax(mat: s2_volt)
            a1_g_range = minmax(mat: a1_g)
            a2_g_range = minmax(mat: a2_g)
            a3_g_range = minmax(mat: a3_g)
        }
    }
}
