class FluorModelData : TimestampedData
{
    var bb : Channel { get { channels[0] }}
    var chla : Channel { get { channels[1] }}
    var fDOM : Channel { get { channels[2] }}

    required init() {
        super.init(numChannels: 3, capacity: 200, samples_per_sec: 16) // 100 blocks
    }

    func render_bb(gr: GraphRenderer) {
        gr.renderGenericTimeseries(td: self, channel: bb, color: .red)
    }
    func render_chla(gr: GraphRenderer) {
        gr.renderGenericTimeseries(td: self, channel: chla, color: .green)
    }
    func render_fDOM(gr: GraphRenderer) {
        gr.renderGenericTimeseries(td: self, channel: fDOM, color: .blue)
    }
}
