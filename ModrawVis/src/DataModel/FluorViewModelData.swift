class FluorViewModelData: FluorModelData {
    var time_f = [Double]()

    var chla_range = (0.0, 0.0)
    var bb_range = (0.0, 0.0)
    var fDOM_range = (0.0, 0.0)

    override func removeAll()
    {
        super.removeAll()
        time_f.removeAll()
        chla_range = (0.0, 0.0)
        bb_range = (0.0, 0.0)
        fDOM_range = (0.0, 0.0)
    }
    override func calculateDerivedData(time_window: (Double, Double))
    {
        if (time_s.count > 0)
        {
            calculateTimeF(time_window: time_window, time_f: &time_f)
            chla_range = chla.range()
            bb_range = bb.range()
            fDOM_range = fDOM.range()
        }
    }
}
