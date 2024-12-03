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

    func renderCtd_T(gr: GraphRenderer) {
        let T_range = T.range()
        let T_yAxis = rangeToYAxis(range: T_range)
        gr.renderGrid(td: self, yAxis: T_yAxis, leftLabels: true, format: "%.1f")
        gr.renderTimeSeries(td: self, data: T, range: T_range, color: T_color)
        
        gr.drawMainLabel("T [\u{00B0}C]")
    }
    func renderCtd_S(gr: GraphRenderer) {
        let S_range = S.range()
        let S_yAxis = rangeToYAxis(range: S_range)
        gr.renderGrid(td: self, yAxis: S_yAxis, leftLabels: true, format: "%.1f")
        gr.renderTimeSeries(td: self, data: S, range: S_range, color: S_color)
        
        gr.drawMainLabel("S")
    }
    func getCtd_dzdt_zero_y(gr: GraphRenderer) -> Double {
        let dzdt_min = dzdt_range.0
        let dzdt_max = dzdt_range.1
        let zero_s = (0.0 - dzdt_min) / (dzdt_max - dzdt_min)
        return zero_s * gr.rect.minY + (1.0 - zero_s) * gr.rect.maxY
    }
    func renderCtd_dzdt(gr: GraphRenderer) {
        var dzdt_yAxis: [Double]
        let dzdt_min = dzdt_range.0
        let dzdt_max = dzdt_range.1
        let zero_y = getCtd_dzdt_zero_y(gr: gr)
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
        renderCtd_dzdt_arrows(gr: gr)

        gr.drawMainLabel("dzdt [m/s]")
    }
    func renderCtd_z(gr: GraphRenderer) {
        let z_yAxis = rangeToYAxis(range: z_range)
        gr.renderGrid(td: self, yAxis: z_yAxis, leftLabels: true, format: "%.1f")
        gr.renderTimeSeries(td: self, data: z, range: z_range, color: P_color)
        gr.drawMainLabel("z [m]")
    }
    func renderCtd_z_dzdt(gr: GraphRenderer) {
        let z_yAxis = rangeToYAxis(range: z_range)
        gr.renderGrid(td: self, yAxis: z_yAxis, leftLabels: true, format: "%.1f")
        gr.renderTimeSeries(td: self, data: z_pos, range: z_range, color: dzdt_down_color)
        gr.renderTimeSeries(td: self, data: z_neg, range: z_range, color: dzdt_up_color)
        gr.drawMainLabel("z [m]")
        renderCtd_dzdt_arrows(gr: gr)
    }
    func renderCtd_dzdt_arrows(gr: GraphRenderer) {
        let zero_y = getCtd_dzdt_zero_y(gr: gr)
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
