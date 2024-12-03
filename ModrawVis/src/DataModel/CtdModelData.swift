class CtdModelData : TimestampedData
{
    var P : Channel { get { channels[0] }}
    var T : Channel { get { channels[1] }}
    var S : Channel { get { channels[2] }}
    var z : Channel { get { channels[3] }}

    required init() {
        super.init(numChannels: 4, capacity: 200, samples_per_sec: 16) // 100 blocks
    }
}

