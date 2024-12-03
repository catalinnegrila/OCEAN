class EpsiModelData : TimestampedData
{
    var t1_volt : Channel { get { channels[0] }}
    var t2_volt : Channel { get { channels[1] }}
    var s1_volt : Channel { get { channels[2] }}
    var s2_volt : Channel { get { channels[3] }}
    var a1_g : Channel { get { channels[4] }}
    var a2_g : Channel { get { channels[5] }}
    var a3_g : Channel { get { channels[6] }}

    required init() {
        super.init(numChannels: 7, capacity: 8000, samples_per_sec: 333) // 100 blocks
    }
}

