import SwiftUI

class EpsiViewModelData: EpsiModelData {
    var t1_volt_mean = 0.0
    var t2_volt_mean = 0.0
    var s1_volt_rms = 0.0
    var s2_volt_rms = 0.0

    override func removeAll()
    {
        super.removeAll()
        t1_volt_mean = 0
        t2_volt_mean = 0
        s1_volt_rms = 0
        s2_volt_rms = 0
    }
    override func calculateDerivedData(time_window: (Double, Double))
    {
        super.calculateDerivedData(time_window: time_window)

        t1_volt_mean = t1_volt.mean()
        t2_volt_mean = t2_volt.mean()
        s1_volt_rms = s1_volt.rms()
        s2_volt_rms = s2_volt.rms()
        
        for i in 0..<time_s.count {
            t1_volt.data[i] -= t1_volt_mean
            t2_volt.data[i] -= t2_volt_mean
            s1_volt.data[i] -= s1_volt_rms
            s2_volt.data[i] -= s2_volt_rms
        }
    }

    let t1_dark_color = Color(red: 182/255, green: 114/255, blue: 182/255)
    let t1_light_color = Color(red: 21/255, green: 53/255, blue: 136/255)
    let t2_color = Color(red: 114/255, green: 182/255, blue: 182/255, opacity: 0.75)
    let s1_color = Color(red: 88/255, green: 143/255, blue: 92/255)
    let s2_color = Color(red: 189/255, green: 219/255, blue: 154/255, opacity: 0.75)
    let a1_color = Color(red: 129/255, green: 39/255, blue: 120/255)
    let a2_color = Color(red: 220/255, green: 86/255, blue: 77/255)
    let a3_color = Color(red: 240/255, green: 207/255, blue: 140/255, opacity: 0.75)

    func renderT(gr: GraphRenderer) {
        let t1_color = gr.isDarkTheme ? t1_dark_color : t1_light_color
        let t_volt_range = rangeUnion(t1_volt.range(), t2_volt.range())
        let t_yAxis = rangeToYAxis3(range: t_volt_range)
        
        gr.renderGrid(td: self, yAxis: t_yAxis, leftLabels: true, format: "%.2f")
        gr.renderTimeSeries(td: self, data: t1_volt, range: t_volt_range, color: t1_color)
        gr.renderTimeSeries(td: self, data: t2_volt, range: t_volt_range, color: t2_color)
        if (time_s.count > 0) {
            gr.drawDataLabels(labels: [
                (t1_color, "t1 - \(String(format: "%.2g", t1_volt_mean))"),
                (t2_color, "t2 - \(String(format: "%.2g", t2_volt_mean))")])
        }
    }
    func renderS(gr: GraphRenderer) {
        let s_volt_range = rangeUnion(s1_volt.range(), s2_volt.range())
        let s_yAxis = rangeToYAxis3(range: s_volt_range)
        gr.renderGrid(td: self, yAxis: s_yAxis, leftLabels: true, format: "%.2f")
        gr.renderTimeSeries(td: self, data: s1_volt, range: s_volt_range, color: s1_color)
        gr.renderTimeSeries(td: self, data: s2_volt, range: s_volt_range, color: s2_color)
        if (time_s.count > 0) {
            gr.drawDataLabels(labels: [
                (s1_color, "s1 - rms \(String(format: "%.2g", s1_volt_rms))"),
                (s2_color, "s2 - rms \(String(format: "%.2g", s2_volt_rms))")])
        }
    }
    func renderS1(gr: GraphRenderer) {
        gr.renderGenericTimeseries(td: self, channel: s1_volt, color: s1_color)
        if (time_s.count > 0) {
            gr.drawDataLabels(labels: [
                (s1_color, "s1 - rms \(String(format: "%.2g", s1_volt_rms))")])
        }
    }
    func renderS2(gr: GraphRenderer) {
        gr.renderGenericTimeseries(td: self, channel: s2_volt, color: s2_color)
        if (time_s.count > 0) {
            gr.drawDataLabels(labels: [
                (s2_color, "s2 - rms \(String(format: "%.2g", s2_volt_rms))")])
        }
    }
    func renderA(gr: GraphRenderer) {
        let gr = GraphRenderer(context: gr.context, gr: gr)
        // EPSI a1
        gr.rect = gr.rect.inset(0.0, 0.0, 0.0, gr.rect.height / 2)
        
        let a1_g_range = a1_g.range()
        let a1_yAxis = rangeToYAxis3(range: a1_g_range)
        gr.renderGrid(td: self, yAxis: a1_yAxis, leftLabels: false, format: "%.1f")
        gr.renderTimeSeries(td: self, data: a1_g, range: a1_g_range, color: a1_color)
        if (time_s.count > 0) {
            gr.drawDataLabels(labels: [(a1_color, "z")])
        }

        // EPSI a2, a3
        gr.advanceRectY(0)
        let a23_g_range = rangeUnion(a2_g.range(), a3_g.range())
        
        let a23_yAxis = rangeToYAxis3(range: a23_g_range)
        gr.renderGrid(td: self, yAxis: a23_yAxis, leftLabels: true, format: "%.1f")
        gr.renderTimeSeries(td: self, data: a2_g, range: a23_g_range, color: a2_color)
        gr.renderTimeSeries(td: self, data: a3_g, range: a23_g_range, color: a3_color)
        if (time_s.count > 0) {
            gr.drawDataLabels(labels: [(a2_color, "x"), (a3_color, "y")])
        }
    }
}
