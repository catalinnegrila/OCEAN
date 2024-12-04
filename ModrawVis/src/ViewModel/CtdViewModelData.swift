import SwiftUI

class CtdViewModelData: CtdModelData {
    var z_range = (0.0, 0.0)

    var z_pos = TimestampedData.Channel()
    var z_neg = TimestampedData.Channel()

    // Keep as scratch to avoid re-allocating each time
    fileprivate var dzdt = [Double]()
    var dzdt_movmean = TimestampedData.Channel()
    var dzdt_range = (0.0, 0.0)

    override func removeAll()
    {
        super.removeAll()
        z_range = (0, 0)
        z_pos.data.removeAll()
        z_neg.data.removeAll()
        dzdt.removeAll()
        dzdt_movmean.data.removeAll()
        dzdt_range = (0, 0)
    }
    override func calculateDerivedData(time_window: (Double, Double))
    {
        super.calculateDerivedData(time_window: time_window)

        z_range = z.invRange()

        let time_s = self.time_s.data[...]
        let z = self.z.data[...]

        dzdt.reserveCapacity(z.count)
        dzdt.append(0.0)
        for i in 1..<z.count {
            dzdt.append((z[i] - z[i - 1]) / (time_s[i] - time_s[i - 1]))
        }
        if (dzdt.count > 1) {
            dzdt[0] = dzdt[1]
        }
        dzdt_movmean.data = movmean(mat: dzdt, window: 40)
        dzdt_range = dzdt_movmean.invRange()

        z_pos.data.reserveCapacity(z.count)
        z_neg.data.reserveCapacity(z.count)
        for i in 0..<z.count {
            z_pos.append(dzdt[i] > 0 ? z[i] : Double.nan)
            z_neg.append(dzdt[i] > 0 ? Double.nan : z[i])
        }
    }

    let T_color = Color(red: 212/255, green: 35/255, blue: 36/255)
    let S_color = Color(red: 82/255, green: 135/255, blue: 187/255)
    let dzdt_up_color = Color(red: 233/255, green: 145/255, blue: 195/255)
    let dzdt_down_color = Color(red: 82/255, green: 135/255, blue: 187/255)
    let P_color = Color(red: 24/255, green: 187/255, blue: 24/255)

    func renderT(gr: GraphRenderer) {
        gr.renderGenericTimeseries(td: self, channel: T, color: T_color)
    }
    func renderS(gr: GraphRenderer) {
        gr.renderGenericTimeseries(td: self, channel: S, color: S_color)
    }
    func getDzdtZeroY(gr: GraphRenderer) -> Double {
        let dzdt_min = dzdt_range.0
        let dzdt_max = dzdt_range.1
        let zero_s = (0.0 - dzdt_min) / (dzdt_max - dzdt_min)
        return zero_s * gr.rect.minY + (1.0 - zero_s) * gr.rect.maxY
    }
    func renderDzdt(gr: GraphRenderer) {
        var dzdt_yAxis: [Double]
        let dzdt_min = dzdt_range.0
        let dzdt_max = dzdt_range.1
        let zero_y = getDzdtZeroY(gr: gr)
        if (dzdt_min * dzdt_max < 0) {
            // Plot contains zero level, highlight that instead of middle
            dzdt_yAxis = [dzdt_min, 0.0, dzdt_max]
        } else {
            dzdt_yAxis = rangeToYAxis(range: dzdt_range)
        }
        gr.renderGrid(td: self, yAxis: dzdt_yAxis, leftLabels: true, format: "%.2f")
        if (zero_y > gr.rect.minY + 2) {
            gr.context.drawLayer { ctx in
                ctx.clip(to: Path(CGRect(x: gr.rect.minX, y: gr.rect.minY, width: gr.rect.width, height: zero_y - gr.rect.minY)))
                let rdUp = GraphRenderer(context: ctx, gr: gr)
                rdUp.renderTimeSeries(td: self, data: dzdt_movmean, range: dzdt_range, color: dzdt_up_color)
            }
        }
        if (zero_y < gr.rect.maxY - 2) {
            gr.context.drawLayer { ctx in
                ctx.clip(to: Path(CGRect(x: gr.rect.minX, y: zero_y, width: gr.rect.width, height: gr.rect.maxY - zero_y)))
                let rdDown = GraphRenderer(context: ctx, gr: gr)
                rdDown.renderTimeSeries(td: self, data: dzdt_movmean, range: dzdt_range, color: dzdt_down_color)
            }
        }
        if (dzdt_max == dzdt_min)
        {
            // Render the no data, if needed
            gr.renderTimeSeries(td: self, data: dzdt_movmean, range: dzdt_range, color: .black)
        }
        renderDzdtArrows(gr: gr)
    }
    func renderZ(gr: GraphRenderer) {
        gr.renderGenericTimeseries(td: self, channel: z, color: P_color)
    }
    func renderDzdtStyledZ(gr: GraphRenderer) {
        let z_yAxis = rangeToYAxis(range: z_range)
        gr.renderGrid(td: self, yAxis: z_yAxis, leftLabels: true, format: "%.1f")
        gr.renderTimeSeries(td: self, data: z_pos, range: z_range, color: dzdt_down_color)
        gr.renderTimeSeries(td: self, data: z_neg, range: z_range, color: dzdt_up_color)
        renderDzdtArrows(gr: gr)
    }
    func renderDzdtArrows(gr: GraphRenderer) {
        let zero_y = getDzdtZeroY(gr: gr)
        let arrow_x = gr.rect.maxX + 10.0
        let arrow_headLen = 15.0
        let arrow_len = 40.0
        let arrow_thick = 5.0
        if (zero_y > gr.rect.minY + 2) {
            let arrow_y = min(zero_y, gr.rect.maxY)
            gr.drawArrow(from: CGPoint(x: arrow_x, y: arrow_y - 1), to: CGPoint(x: arrow_x, y: arrow_y - arrow_len), thick: arrow_thick, head: arrow_headLen, color: dzdt_up_color)
        }
        if (zero_y < gr.rect.maxY - 2) {
            let arrow_y = max(zero_y, gr.rect.minY)
            gr.drawArrow(from: CGPoint(x: arrow_x, y: arrow_y + 1), to: CGPoint(x: arrow_x, y: arrow_y + arrow_len), thick: arrow_thick, head: arrow_headLen, color: dzdt_down_color)
        }
    }
}
