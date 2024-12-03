class VnavViewModelData: VnavModelData {
    var time_f = [Double]()

    var compass_x_range = (0.0, 0.0)
    var compass_y_range = (0.0, 0.0)
    var compass_z_range = (0.0, 0.0)

    var acceleration_x_range = (0.0, 0.0)
    var acceleration_y_range = (0.0, 0.0)
    var acceleration_z_range = (0.0, 0.0)

    var gyro_x_range = (0.0, 0.0)
    var gyro_y_range = (0.0, 0.0)
    var gyro_z_range = (0.0, 0.0)

    override func removeAll()
    {
        super.removeAll()
        time_f.removeAll()
        compass_x_range = (0.0, 0.0)
        compass_y_range = (0.0, 0.0)
        compass_z_range = (0.0, 0.0)

        acceleration_x_range = (0.0, 0.0)
        acceleration_y_range = (0.0, 0.0)
        acceleration_z_range = (0.0, 0.0)

        gyro_x_range = (0.0, 0.0)
        gyro_y_range = (0.0, 0.0)
        gyro_z_range = (0.0, 0.0)
    }
    override func calculateDerivedData(time_window: (Double, Double))
    {
        if (time_s.count > 0)
        {
            calculateTimeF(time_window: time_window, time_f: &time_f)
            compass_x_range = compass_x.range()
            compass_y_range = compass_y.range()
            compass_z_range = compass_z.range()

            acceleration_x_range = acceleration_x.range()
            acceleration_y_range = acceleration_y.range()
            acceleration_z_range = acceleration_z.range()

            gyro_x_range = gyro_x.range()
            gyro_y_range = gyro_y.range()
            gyro_z_range = gyro_z.range()
        }
    }
}
