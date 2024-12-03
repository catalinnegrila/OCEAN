class VnavModelData : TimestampedData
{
    var compass_x : Channel { get { channels[0] }}
    var compass_y : Channel { get { channels[1] }}
    var compass_z : Channel { get { channels[2] }}

    var acceleration_x : Channel { get { channels[3] }}
    var acceleration_y : Channel { get { channels[4] }}
    var acceleration_z : Channel { get { channels[5] }}

    var gyro_x : Channel { get { channels[6] }}
    var gyro_y : Channel { get { channels[7] }}
    var gyro_z : Channel { get { channels[8] }}

    var yaw : Channel { get { channels[0] }}
    var pitch : Channel { get { channels[1] }}
    var roll : Channel { get { channels[2] }}

    required init() {
        super.init(numChannels: 9, capacity: 200, samples_per_sec: 16) // 100 blocks
    }
}

