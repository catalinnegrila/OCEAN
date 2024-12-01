class CtdViewModelData: CtdModelData {
    var time_f = [Double]()

    var P_range = (0.0, 0.0)
    var T_range = (0.0, 0.0)
    var S_range = (0.0, 0.0)
    var z_range = (0.0, 0.0)

    var z_pos = [Double]()
    var z_neg = [Double]()

    var dzdt = [Double]()
    var dzdt_movmean = [Double]()
    var dzdt_range = (0.0, 0.0)

    override func removeAll()
    {
        super.removeAll()
        time_f.removeAll()
        P_range = (0, 0)
        T_range = (0, 0)
        S_range = (0, 0)
        z_range = (0, 0)
        z_pos.removeAll()
        z_neg.removeAll()
        dzdt.removeAll()
        dzdt_movmean.removeAll()
        dzdt_range = (0, 0)
        dzdt_range = (0, 0)
    }
    override func calculateDerivedData(time_window: (Double, Double))
    {
        if (time_s.count > 0)
        {
            calculateTimeF(time_window: time_window, time_f: &time_f)
            P_range = minmax(mat: P)
            T_range = minmax(mat: T)
            S_range = minmax(mat: S)
            z_range = minmax(mat: z)
            // Invert Z to show >0 going down
            z_range = (z_range.1, z_range.0)

            dzdt.removeAll()
            dzdt.reserveCapacity(z.count)
            dzdt.append(0.0)
            for i in 1..<z.count {
                dzdt.append((z[i] - z[i - 1]) / (time_s[i] - time_s[i - 1]))
            }
            if (dzdt.count > 1) {
                dzdt[0] = dzdt[1]
            }
            dzdt_movmean = movmean(mat: dzdt, window: 40)
            dzdt_range = minmax(mat: dzdt_movmean)
            // Invert dzdt same as z
            dzdt_range = (dzdt_range.1, dzdt_range.0)

            z_pos.removeAll()
            z_pos.reserveCapacity(z.count)
            z_neg.removeAll()
            z_neg.reserveCapacity(z.count)
            for i in 0..<z.count {
                z_pos.append(dzdt[i] > 0 ? z[i] : Double.nan)
                z_neg.append(dzdt[i] > 0 ? Double.nan : z[i])
            }
        }
    }
}
