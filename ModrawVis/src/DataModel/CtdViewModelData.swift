class CtdViewModelData: CtdModelData {
    var z_range = (0.0, 0.0)

    var z_pos = TimestampedData.Channel()
    var z_neg = TimestampedData.Channel()

    // Keep as scratch to avoid re-allocating each time
    fileprivate var dzdt = [Double]()
    var dzdt_movmean = TimestampedData.Channel()
    var dzdt_range = (0.0, 0.0)

    override func removeAll()
    {
        super.removeAll()
        z_range = (0, 0)
        z_pos.data.removeAll()
        z_neg.data.removeAll()
        dzdt.removeAll()
        dzdt_movmean.data.removeAll()
        dzdt_range = (0, 0)
    }
    override func calculateDerivedData(time_window: (Double, Double))
    {
        super.calculateDerivedData(time_window: time_window)

        z_range = z.invRange()

        dzdt.reserveCapacity(z.count)
        dzdt.append(0.0)
        for i in 1..<z.count {
            dzdt.append((z[i] - z[i - 1]) / (time_s[i] - time_s[i - 1]))
        }
        if (dzdt.count > 1) {
            dzdt[0] = dzdt[1]
        }
        dzdt_movmean.data = movmean(mat: dzdt, window: 40)
        dzdt_range = dzdt_movmean.invRange()

        z_pos.data.reserveCapacity(z.count)
        z_neg.data.reserveCapacity(z.count)
        for i in 0..<z.count {
            z_pos.append(dzdt[i] > 0 ? z[i] : Double.nan)
            z_neg.append(dzdt[i] > 0 ? Double.nan : z[i])
        }
    }
}
