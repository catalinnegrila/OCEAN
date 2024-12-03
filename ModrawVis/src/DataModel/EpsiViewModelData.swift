class EpsiViewModelData: EpsiModelData {
    var t1_volt_mean = 0.0
    var t2_volt_mean = 0.0
    var s1_volt_rms = 0.0
    var s2_volt_rms = 0.0

    override func removeAll()
    {
        super.removeAll()
        t1_volt_mean = 0
        t2_volt_mean = 0
        s1_volt_rms = 0
        s2_volt_rms = 0
    }
    override func calculateDerivedData(time_window: (Double, Double))
    {
        super.calculateDerivedData(time_window: time_window)

        t1_volt_mean = t1_volt.mean()
        t2_volt_mean = t2_volt.mean()
        s1_volt_rms = s1_volt.rms()
        s2_volt_rms = s2_volt.rms()
        
        for i in 0..<time_s.count {
            t1_volt[i] -= t1_volt_mean
            t2_volt[i] -= t2_volt_mean
            s1_volt[i] -= s1_volt_rms
            s2_volt[i] -= s2_volt_rms
        }
    }
}
