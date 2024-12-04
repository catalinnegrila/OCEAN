class TtvViewModelData: TtvModelData {
    func render_tof(gr: GraphRenderer) {
        let range = rangeUnion(tof_up.range(), tof_down.range())
        let yAxis = rangeToYAxis3(range: range)
        
        gr.renderGrid(td: self, yAxis: yAxis, leftLabels: true, format: "%.2f")
        gr.renderTimeSeries(td: self, data: tof_up, range: range, color: .red)
        gr.renderTimeSeries(td: self, data: tof_down, range: range, color: .green)
        if (time_s.count > 0) {
            gr.drawDataLabels(labels: [(.red, "up"), (.green, "down")])
        }
    }
    func render_dtof(gr: GraphRenderer) {
        gr.renderGenericTimeseries(td: self, channel: dtof, color: .blue)
    }
    func render_vfr(gr: GraphRenderer) {
        gr.renderGenericTimeseries(td: self, channel: vfr, color: .cyan)
    }
}
