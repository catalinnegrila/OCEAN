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
            compass_x_range = minmax(mat: compass_x)
            compass_y_range = minmax(mat: compass_y)
            compass_z_range = minmax(mat: compass_z)

            acceleration_x_range = minmax(mat: acceleration_x)
            acceleration_y_range = minmax(mat: acceleration_y)
            acceleration_z_range = minmax(mat: acceleration_z)

            gyro_x_range = minmax(mat: gyro_x)
            gyro_y_range = minmax(mat: gyro_y)
            gyro_z_range = minmax(mat: gyro_z)
        }
    }
}
