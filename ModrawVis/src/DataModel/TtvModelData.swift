class TtvModelData : TimestampedData
{
    var tof_up : Channel { get { channels[0] }}
    var tof_down : Channel { get { channels[1] }}
    var dtof : Channel { get { channels[2] }}
    var vfr : Channel { get { channels[3] }}

    required init() {
        super.init(numChannels: 4, capacity: 200, samples_per_sec: 16) // 20 blocks
    }
}


