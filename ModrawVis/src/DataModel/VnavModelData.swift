class VnavModelData : TimestampedData
{
    var compass_x : [Double] = []
    var compass_y : [Double] = []
    var compass_z : [Double] = []

    var acceleration_x : [Double] = []
    var acceleration_y : [Double] = []
    var acceleration_z : [Double] = []

    var gyro_x : [Double] = []
    var gyro_y : [Double] = []
    var gyro_z : [Double] = []

    var yaw : [Double] {
        get { compass_x }
    }
    var pitch : [Double] {
        get { compass_y }
    }
    var roll : [Double] {
        get { compass_z }
    }

    required init() {
        super.init(capacity: 200, samples_per_sec: 16) // 100 blocks
        reserveCapacity(capacity)
    }
    override func reserveCapacity(_ newCapacity: Int)
    {
        super.reserveCapacity(newCapacity)
        compass_x.reserveCapacity(newCapacity)
        compass_y.reserveCapacity(newCapacity)
        compass_z.reserveCapacity(newCapacity)
        acceleration_x.reserveCapacity(newCapacity)
        acceleration_y.reserveCapacity(newCapacity)
        acceleration_z.reserveCapacity(newCapacity)
        gyro_x.reserveCapacity(newCapacity)
        gyro_y.reserveCapacity(newCapacity)
        gyro_z.reserveCapacity(newCapacity)
    }
    override func removeAll() {
        super.removeAll()
        compass_x.removeAll()
        compass_y.removeAll()
        compass_z.removeAll()
        acceleration_x.removeAll()
        acceleration_y.removeAll()
        acceleration_z.removeAll()
        gyro_x.removeAll()
        gyro_y.removeAll()
        gyro_z.removeAll()
    }
    override func append(from: TimestampedData, first: Int, count: Int)
    {
        super.append(from: from, first: first, count: count)
        if let from = from as? VnavModelData {
            compass_x.append(contentsOf: from.compass_x[first..<first+count])
            compass_y.append(contentsOf: from.compass_y[first..<first+count])
            compass_z.append(contentsOf: from.compass_z[first..<first+count])
            acceleration_x.append(contentsOf: from.acceleration_x[first..<first+count])
            acceleration_y.append(contentsOf: from.acceleration_y[first..<first+count])
            acceleration_z.append(contentsOf: from.acceleration_z[first..<first+count])
            gyro_x.append(contentsOf: from.gyro_x[first..<first+count])
            gyro_y.append(contentsOf: from.gyro_y[first..<first+count])
            gyro_z.append(contentsOf: from.gyro_z[first..<first+count])
        }
    }
}

