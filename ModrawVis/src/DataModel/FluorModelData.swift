class FluorModelData : TimestampedData
{
    var bb : Channel { get { channels[0] }}
    var chla : Channel { get { channels[1] }}
    var fDOM : Channel { get { channels[2] }}

    required init() {
        super.init(numChannels: 3, capacity: 200, samples_per_sec: 16) // 100 blocks
    }
}
