class CtdViewModelData: CtdModelData {
    var time_f = [Double]()

    var P_range = (0.0, 0.0)
    var T_range = (0.0, 0.0)
    var S_range = (0.0, 0.0)
    var z_range = (0.0, 0.0)

    var z_pos = TimestampedData.Channel()
    var z_neg = TimestampedData.Channel()

    var dzdt = [Double]()
    var dzdt_movmean = TimestampedData.Channel()
    var dzdt_range = (0.0, 0.0)

    override func removeAll()
    {
        super.removeAll()
        time_f.removeAll()
        P_range = (0, 0)
        T_range = (0, 0)
        S_range = (0, 0)
        z_range = (0, 0)
        z_pos.data.removeAll()
        z_neg.data.removeAll()
        dzdt.removeAll()
        dzdt_movmean.data.removeAll()
        dzdt_range = (0, 0)
        dzdt_range = (0, 0)
    }
    override func calculateDerivedData(time_window: (Double, Double))
    {
        if (time_s.count > 0)
        {
            calculateTimeF(time_window: time_window, time_f: &time_f)
            P_range = P.range()
            T_range = T.range()
            S_range = S.range()
            z_range = z.range()
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
            dzdt_movmean.data = movmean(mat: dzdt, window: 40)
            dzdt_range = dzdt_movmean.range()
            // Invert dzdt same as z
            dzdt_range = (dzdt_range.1, dzdt_range.0)

            z_pos.data.removeAll()
            z_pos.data.reserveCapacity(z.count)
            z_neg.data.removeAll()
            z_neg.data.reserveCapacity(z.count)
            for i in 0..<z.count {
                z_pos.append(dzdt[i] > 0 ? z[i] : Double.nan)
                z_neg.append(dzdt[i] > 0 ? Double.nan : z[i])
            }
        }
    }
}
