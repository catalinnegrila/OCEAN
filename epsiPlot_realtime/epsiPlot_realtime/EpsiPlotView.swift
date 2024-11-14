import SwiftUI

let PRINT_PERF = true
var epsiDataModel : EpsiDataModel? = EpsiDataModelModraw(mode: .EPSI)

struct EpsiPlotView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var refreshView = false
    @State private var windowTitle = ""
    let refreshTimer = Timer.publish(every: 1.0/30, on: .main, in: .common).autoconnect()

    var body: some View {
        chart
            .id(refreshView)
            .padding()
            .frame(alignment: .topLeading)
            .navigationTitle($windowTitle)
            .onReceive(refreshTimer) { _ in
                Task {
                    if (epsiDataModel != nil && !epsiDataModel!.windowTitle.isEmpty) {
                        windowTitle = epsiDataModel!.windowTitle
                    } else {
                        windowTitle = "No data source"
                    }
                    if (epsiDataModel != nil) {
                        let start_time = ProcessInfo.processInfo.systemUptime
                        if epsiDataModel!.updateSourceData() {
                            if PRINT_PERF {
                                let end_time = ProcessInfo.processInfo.systemUptime
                                let msec = Int((end_time - start_time) * 1000)
                                print("Update: \(msec) ms")
                            }
                            refreshView.toggle()
                        }
                    }
                }
        }
    }

    private func renderGrid(context: GraphicsContext, rc: CGRect, xAxis: [Double], yAxis: [Double], leftLabels: Bool, formatter: (Double) -> String) {
        let nub = 7.0
        let thickLine = 1.5
        let textGap = 5.0

        let yAxisMin = yAxis[0]
        let yAxisMax = yAxis[yAxis.count - 1]

        var yOffset = [CGFloat](repeating: 0.0, count: yAxis.count)
        for i in 0..<yAxis.count {
            let s = (yAxis[i] - yAxisMin) / (yAxisMax - yAxisMin)
            yOffset[i] = s * rc.minY + (1 - s) * rc.maxY
        }

        var xOffset = [CGFloat](repeating: 0.0, count: xAxis.count)
        for i in 0..<xAxis.count {
            let s = xAxis[i]
            xOffset[i] = (1 - s) * rc.minX + s * rc.maxX
        }

        // Framing rectangle
        context.stroke(
            Path(rc),
            with: .color(.gray),
            lineWidth: thickLine)

        // Dashed horizontal lines
        context.stroke(Path { path in
                for i in 0..<yAxis.count {
                    path.move(to: CGPoint(x: rc.minX, y: yOffset[i]))
                    path.addLine(to: CGPoint(x: rc.maxX, y: yOffset[i]))
                }
            },
            with: .color(.gray),
            style: StrokeStyle(lineWidth: 0.5, dash: [5]))

        // Horizontal nubs
        context.stroke(Path { path in
                for i in 0..<yAxis.count {
                    path.move(to: CGPoint(x: rc.minX, y: yOffset[i]))
                    path.addLine(to: CGPoint(x: rc.minX + nub, y: yOffset[i]))
                    path.move(to: CGPoint(x: rc.maxX - nub, y: yOffset[i]))
                    path.addLine(to: CGPoint(x: rc.maxX, y: yOffset[i]))
                }
            },
            with: .color(.gray),
            lineWidth: thickLine)

        // Dashed vertical lines
        context.stroke(Path { path in
                for i in 0..<xAxis.count {
                    path.move(to: CGPoint(x: xOffset[i], y: rc.minY))
                    path.addLine(to: CGPoint(x: xOffset[i], y: rc.maxY))
                }
            },
            with: .color(.gray),
            style: StrokeStyle(lineWidth: 0.5, dash: [5]))

        // Vertical nubs
        context.stroke(Path { path in
                for i in 0..<xAxis.count {
                    path.move(to: CGPoint(x: xOffset[i], y: rc.minY))
                    path.addLine(to: CGPoint(x: xOffset[i], y: rc.minY + nub))
                    path.move(to: CGPoint(x: xOffset[i], y: rc.maxY - nub))
                    path.addLine(to: CGPoint(x: xOffset[i], y: rc.maxY))
                }
            },
            with: .color(.gray),
            lineWidth: thickLine)

        // Y-Axis labels
        for i in 0..<yAxis.count {
            let atX = leftLabels ? rc.minX - textGap : rc.maxX + textGap
            let anchorX = leftLabels ? 1.0 : 0.0
            context.draw(Text(formatter(yAxis[i])).font(.footnote),
                             at: CGPoint(x: atX, y: yOffset[i]),
                             anchor: UnitPoint(x: anchorX, y: 0.5))
        }
    }

    static func valueToY(rc: CGRect, yAxis: (Double, Double), v: Double) -> Double {
        return lerpToY(rc: rc, s: valueToLerp(yAxis: yAxis, v: v))
    }

    static func lerpToY(rc: CGRect, s: Double) -> Double {
        return rc.maxY - floor(s * rc.height)
    }

    static func valueToLerp(yAxis: (Double, Double), v: Double) -> Double {
        return (v - yAxis.0) / (yAxis.1 - yAxis.0)
    }

    static func timeToLerp(t: Double) -> Double {
        return (t - epsiDataModel!.time_window_start) / epsiDataModel!.time_window_length
    }
    static func timeToX(rc: CGRect, t: Double) -> Double {
        return lerpToX(rc: rc, s: EpsiPlotView.timeToLerp(t: t))
    }
    static func lerpToX(rc: CGRect, s: Double) -> Double {
        return floor(rc.minX + rc.width * s)
    }
    private func render1D(context: GraphicsContext, rc: CGRect, yAxis: (Double, Double), data: inout [Double], time_f: inout [Double], color: Color) {
        let noDataColor = getNoDataColor()
        if (!data.isEmpty) {
            let minX = EpsiPlotView.lerpToX(rc: rc, s: time_f.first!)
            assert(minX >= rc.minX)
            if (minX - rc.minX > 2) {
                let rcEmpty = CGRect(x: rc.minX + 1, y: rc.minY + 1, width: minX - rc.minX - 1, height: rc.height - 2)
                context.fill(Path(rcEmpty), with: .color(noDataColor))
            }
            let maxX = EpsiPlotView.lerpToX(rc: rc, s: time_f.last!)
            if (rc.maxX - maxX > 2) {
                let rcEmpty = CGRect(x: maxX, y: rc.minY + 1, width: rc.maxX - maxX - 1, height: rc.height - 2)
                context.fill(Path(rcEmpty), with: .color(noDataColor))
            }

            context.stroke(Path { path in
                var sample_index = 0
                if (data.count <= Int(maxX - minX)) {
                    path.move(to: CGPoint(x: minX, y: EpsiPlotView.valueToY(rc: rc, yAxis: yAxis, v: data[0])))
                    for x in stride(from: minX + 1, to: maxX, by: 1.0) {
                        let s = min((x - rc.minX) / Double(rc.width), time_f.last!)
                        while (time_f[sample_index] < s) {
                            sample_index += 1
                        }
                        path.addLine(to: CGPoint(x: x, y: EpsiPlotView.valueToY(rc: rc, yAxis: yAxis, v: data[sample_index])))
                    }
                } else {
                    for x in stride(from: minX, to: maxX, by: 1.0) {
                        let s = (x - rc.minX) / Double(rc.width - 1)
                        let v = EpsiPlotView.valueToY(rc: rc, yAxis: yAxis, v: data[sample_index])
                        var minv = v
                        var maxv = v
                        while (time_f[sample_index] < s) {
                            sample_index += 1
                            let v = EpsiPlotView.valueToY(rc: rc, yAxis: yAxis, v: data[sample_index])
                            minv = min(minv, v)
                            maxv = max(maxv, v)
                        }
                        path.move(to: CGPoint(x: x, y: minv - 1))
                        path.addLine(to: CGPoint(x: x, y: maxv + 1))
                    }

                }
            }, with: .color(color),
               lineWidth: 2)
        } else {
            context.fill(Path(rc), with: .color(noDataColor))
            context.draw(Text("no data").foregroundColor(.gray),
                         at: CGPoint(x: (rc.minX + rc.maxX) / 2, y: (rc.minY + rc.maxY) / 2),
                         anchor: .center)
        }
    }
    func renderDataGaps(context: GraphicsContext, rc: CGRect, dataGaps: inout [(Double, Double)]) {
        let noDataColor = getNoDataColor()
        for dataGap in dataGaps {
            let x0 = max(rc.minX + 1, EpsiPlotView.timeToX(rc: rc, t: dataGap.0))
            let x1 = min(rc.maxX - 1, EpsiPlotView.timeToX(rc: rc, t: dataGap.1))
            if (x1 - x0 >= 1) {
                let rcGap = CGRect(x: x0, y: rc.minY + 1, width: x1 - x0, height: rc.height - 2)
                context.fill(Path(rcGap), with: .color(noDataColor))
            }
        }
    }

    func isDarkTheme() -> Bool {
        return (colorScheme == .dark)
    }
    func getNoDataColor() -> Color {
        let noDataGray = isDarkTheme() ? 0.15 : 0.85
        return Color(red: noDataGray, green: noDataGray, blue: noDataGray)
    }
    let s1_color = Color(red: 88/255, green: 143/255, blue: 92/255)
    let s2_color = Color(red: 189/255, green: 219/255, blue: 154/255)
    let a1_color = Color(red: 129/255, green: 39/255, blue: 120/255)
    let a2_color = Color(red: 220/255, green: 86/255, blue: 77/255)
    let a3_color = Color(red: 240/255, green: 207/255, blue: 140/255)
    let T_color = Color(red: 212/255, green: 35/255, blue: 36/255)
    let S_color = Color(red: 82/255, green: 135/255, blue: 187/255)
    let dzdt_color = Color(red: 233/255, green: 145/255, blue: 195/255)
    let P_color = Color(red: 24/255, green: 187/255, blue: 24/255)
    let leftLabelsWidth = CGFloat(30)
    let vgap = CGFloat(25)
    let hgap = CGFloat(30)

    func drawMainLabel(context: GraphicsContext, rc: CGRect, text: String) {
        context.drawLayer { ctx in
            ctx.translateBy(x: leftLabelsWidth/2, y: (rc.maxY + rc.minY) / 2)
            ctx.rotate(by: Angle(degrees: -90))
            ctx.draw(Text(text).bold(), at: CGPoint(x: 0, y: 0), anchor: .center)
        }
    }
    func drawSubLabels(context: GraphicsContext, rc: CGRect, labels: [(Color, String)]) {
        var textHeight = 0.0
        var textWidth = 0.0
        let inset = (5.0, 3.0)
        let gray = isDarkTheme() ? 0.4 : 0.9

        let textFont = Font.footnote
        for i in 0..<labels.count {
            let textSize = context.resolve(Text(labels[i].1).font(textFont)).measure(in: CGSize(width: .max, height: .max))
            textWidth = max(textWidth, textSize.width)
            textHeight = max(textHeight, textSize.height)
        }

        let dotSize = 5.0
        let width = inset.0 + dotSize + inset.0 + textWidth + inset.0
        let height = inset.1 + textHeight * Double(labels.count) + inset.1
        
        let rcLabels = CGRect(x: rc.minX + 10, y: rc.minY + 10, width: width, height: height)
        context.fill(Path(rcLabels), with: .color(Color(red: gray, green: gray, blue: gray)))
        context.stroke(Path(rcLabels), with: .color(.black))

        var rcDot = CGRect(x: rcLabels.minX + inset.0, y: rcLabels.minY + inset.1 + (textHeight - dotSize) / 2, width: dotSize, height: dotSize)
        var ptText = CGPoint(x: rcLabels.minX + inset.0 + dotSize + inset.0, y: rcLabels.minY + inset.1)
        for i in 0..<labels.count {
            context.fill(Circle().path(in: rcDot), with: .color(labels[i].0))
            context.draw(Text(labels[i].1).foregroundColor(.black).font(textFont), at: ptText, anchor: .topLeading)
            ptText.y += textHeight
            rcDot = rcDot.offsetBy(dx: 0, dy: textHeight)
        }
    }
    private var chart: some View {
        return Canvas{ context, size in
            if (epsiDataModel == nil) {
                context.draw(Text("Choose an option from the EPSI or FCTD menus..."),
                             at: CGPoint(x: size.width / 2, y: size.height / 2),
                             anchor: .center)
                return
            }

            let dataModel = epsiDataModel!
            var rect = CGRect(x: hgap + leftLabelsWidth, y: 10, width: size.width - 2 * hgap - leftLabelsWidth, height: 100)
            dataModel.updateViewData(pixel_width: Int(rect.width))

            let timeTickCount = 10
            var xAxis : [Double] = []
            for i in 0..<timeTickCount {
                xAxis.append(Double(i) / Double(timeTickCount - 1))
            }

            let start_time2 = ProcessInfo.processInfo.systemUptime
            switch dataModel.mode {
            case .EPSI:
                // EPSI t1, t2
                let t1_color = isDarkTheme() ? Color(red: 182/255, green: 114/255, blue: 182/255) : Color(red: 21/255, green: 53/255, blue: 136/255)
                let t2_color = Color(red: 114/255, green: 182/255, blue: 182/255)
                
                let epsi_t_volt_range = EpsiDataModel.minmax(v1: dataModel.epsi_t1_volt_range, v2: dataModel.epsi_t2_volt_range)
                
                let t_yAxis = EpsiDataModel.yAxis(range: epsi_t_volt_range)
                renderGrid(context: context, rc: rect, xAxis: xAxis, yAxis: t_yAxis, leftLabels: true, formatter: { String(format: "%.2f", Double($0)) })
                
                render1D(context: context, rc: rect, yAxis: epsi_t_volt_range, data: &dataModel.epsi.t1_volt, time_f: &dataModel.epsi.time_f, color: t1_color)
                render1D(context: context, rc: rect, yAxis: epsi_t_volt_range, data: &dataModel.epsi.t2_volt, time_f: &dataModel.epsi.time_f, color: t2_color)
                renderDataGaps(context: context, rc: rect, dataGaps: &dataModel.epsi.dataGaps)

                drawMainLabel(context: context, rc: rect, text: "FP07 [Volt]")
                if (dataModel.epsi.time_s.count > 0) {
                    drawSubLabels(context: context, rc: rect, labels: [
                        (t1_color, "t1 - \(String(format: "%.1f", dataModel.epsi_t1_volt_mean))"),
                        (t2_color, "t2 - \(String(format: "%.1f", dataModel.epsi_t2_volt_mean))")])
                }
                rect = rect.offsetBy(dx: 0, dy: rect.height + vgap)

                // EPSI s1, s2
                let epsi_s_volt_range = EpsiDataModel.minmax(v1: dataModel.epsi_s1_volt_range, v2: dataModel.epsi_s2_volt_range)
                
                let s_yAxis = EpsiDataModel.yAxis(range: epsi_s_volt_range)
                renderGrid(context: context, rc: rect, xAxis: xAxis, yAxis: s_yAxis, leftLabels: true, formatter: { String(format: "%.1f", Double($0)) })
                
                render1D(context: context, rc: rect, yAxis: epsi_s_volt_range, data: &dataModel.epsi.s1_volt, time_f: &dataModel.epsi.time_f, color: s1_color)
                render1D(context: context, rc: rect, yAxis: epsi_s_volt_range, data: &dataModel.epsi.s2_volt, time_f: &dataModel.epsi.time_f, color: s2_color)
                renderDataGaps(context: context, rc: rect, dataGaps: &dataModel.epsi.dataGaps)

                drawMainLabel(context: context, rc: rect, text: "Shear [Volt]")
                if (dataModel.epsi.time_s.count > 0) {
                    drawSubLabels(context: context, rc: rect, labels: [
                        (s1_color, "s1 - rms \(String(format: "%.1f", dataModel.epsi_s1_volt_rms))"),
                        (s2_color, "s2 - rms \(String(format: "%.1f", dataModel.epsi_s2_volt_rms))")])
                }
                rect = rect.offsetBy(dx: 0, dy: rect.height + vgap);

            case .FCTD:
                // EPSI s1
                let s1_yAxis = EpsiDataModel.yAxis(range: dataModel.epsi_s1_volt_range)
                renderGrid(context: context, rc: rect, xAxis: xAxis, yAxis: s1_yAxis, leftLabels: true, formatter: { String(format: "%.1f", Double($0)) })
                
                render1D(context: context, rc: rect, yAxis: dataModel.epsi_s1_volt_range, data: &dataModel.epsi.s1_volt, time_f: &dataModel.epsi.time_f, color: s1_color)
                renderDataGaps(context: context, rc: rect, dataGaps: &dataModel.epsi.dataGaps)

                drawMainLabel(context: context, rc: rect, text: "s1 [Volt]")
                rect = rect.offsetBy(dx: 0, dy: rect.height + vgap)

                // EPSI s2
                let s2_yAxis = EpsiDataModel.yAxis(range: dataModel.epsi_s2_volt_range)
                renderGrid(context: context, rc: rect, xAxis: xAxis, yAxis: s2_yAxis, leftLabels: true, formatter: { String(format: "%.1f", Double($0)) })
                
                render1D(context: context, rc: rect, yAxis: dataModel.epsi_s2_volt_range, data: &dataModel.epsi.s2_volt, time_f: &dataModel.epsi.time_f, color: s2_color)
                renderDataGaps(context: context, rc: rect, dataGaps: &dataModel.epsi.dataGaps)

                drawMainLabel(context: context, rc: rect, text: "s2 [Volt]")
                rect = rect.offsetBy(dx: 0, dy: rect.height + vgap);
            }

            // EPSI a1
            var halfRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height / 2)

            let a1_yAxis = EpsiDataModel.yAxis(range: dataModel.epsi_a1_g_range)
            renderGrid(context: context, rc: halfRect, xAxis: xAxis, yAxis: a1_yAxis, leftLabels: true, formatter: { String(format: "%.1f", Double($0)) })
            render1D(context: context, rc: halfRect, yAxis: dataModel.epsi_a1_g_range, data: &dataModel.epsi.a1_g, time_f: &dataModel.epsi.time_f, color: a1_color)
            renderDataGaps(context: context, rc: halfRect, dataGaps: &dataModel.epsi.dataGaps)
            if (dataModel.epsi.time_s.count > 0) {
                drawSubLabels(context: context, rc: halfRect, labels: [(a1_color, "a1")])
            }

            // EPSI a2, a3
            halfRect = halfRect.offsetBy(dx: 0, dy: halfRect.height)
            let epsi_a23_g_range = EpsiDataModel.minmax(v1: dataModel.epsi_a2_g_range, v2: dataModel.epsi_a3_g_range)

            let a23_yAxis = EpsiDataModel.yAxis(range: epsi_a23_g_range)
            renderGrid(context: context, rc: halfRect, xAxis: xAxis, yAxis: a23_yAxis, leftLabels: false, formatter: { String(format: "%.1f", Double($0)) })
            render1D(context: context, rc: halfRect, yAxis: epsi_a23_g_range, data: &dataModel.epsi.a2_g, time_f: &dataModel.epsi.time_f, color: a2_color)
            render1D(context: context, rc: halfRect, yAxis: epsi_a23_g_range, data: &dataModel.epsi.a3_g, time_f: &dataModel.epsi.time_f, color: a3_color)
            renderDataGaps(context: context, rc: halfRect, dataGaps: &dataModel.epsi.dataGaps)
            if (dataModel.epsi.time_s.count > 0) {
                drawSubLabels(context: context, rc: halfRect, labels: [(a2_color, "a2"), (a3_color, "a3")])
            }
            drawMainLabel(context: context, rc: rect, text: "Accel [g]")
            rect = rect.offsetBy(dx: 0, dy: rect.height + vgap);

            // CTD T
            let T_yAxis = EpsiDataModel.yAxis(range: dataModel.ctd_T_range)
            renderGrid(context: context, rc: rect, xAxis: xAxis, yAxis: T_yAxis, leftLabels: true, formatter: { String(format: "%.1f", Double($0)) })
            render1D(context: context, rc: rect, yAxis: dataModel.ctd_T_range, data: &dataModel.ctd.T, time_f: &dataModel.ctd.time_f, color: T_color)
            renderDataGaps(context: context, rc: rect, dataGaps: &dataModel.ctd.dataGaps)

            drawMainLabel(context: context, rc: rect, text: "T [\u{00B0}C]")
            rect = rect.offsetBy(dx: 0, dy: rect.height + vgap);

            // CTD S
            let S_yAxis = EpsiDataModel.yAxis(range: dataModel.ctd_S_range)
            renderGrid(context: context, rc: rect, xAxis: xAxis, yAxis: S_yAxis, leftLabels: true, formatter: { String(format: "%.1f", Double($0)) })
            render1D(context: context, rc: rect, yAxis: dataModel.ctd_S_range, data: &dataModel.ctd.S, time_f: &dataModel.ctd.time_f, color: S_color)
            renderDataGaps(context: context, rc: rect, dataGaps: &dataModel.ctd.dataGaps)

            drawMainLabel(context: context, rc: rect, text: "S")
            rect = rect.offsetBy(dx: 0, dy: rect.height + vgap);

            // CTD dzdt
            var dzdt_yAxis : [Double]
            if (dataModel.ctd_dzdt_range.0 < 0.0 && 0.0 < dataModel.ctd_dzdt_range.1) {
                dzdt_yAxis = [dataModel.ctd_dzdt_range.0, 0.0, dataModel.ctd_dzdt_range.1]
            } else {
                dzdt_yAxis = EpsiDataModel.yAxis(range: dataModel.ctd_dzdt_range)
            }
            renderGrid(context: context, rc: rect, xAxis: xAxis, yAxis: dzdt_yAxis, leftLabels: true, formatter: { String(format: "%.1f", Double($0)) })
            render1D(context: context, rc: rect, yAxis: dataModel.ctd_dzdt_range, data: &dataModel.ctd_dzdt_movmean, time_f: &dataModel.ctd.time_f, color: dzdt_color)
            renderDataGaps(context: context, rc: rect, dataGaps: &dataModel.ctd.dataGaps)

            drawMainLabel(context: context, rc: rect, text: "dzdt [m/s]")
            rect = rect.offsetBy(dx: 0, dy: rect.height + vgap);

            // CTD z
            let z_yAxis = EpsiDataModel.yAxis(range: dataModel.ctd_z_range)
            renderGrid(context: context, rc: rect, xAxis: xAxis, yAxis: z_yAxis, leftLabels: true, formatter: { String(format: "%.1f", Double($0)) })
            render1D(context: context, rc: rect, yAxis: dataModel.ctd_z_range, data: &dataModel.ctd.z, time_f: &dataModel.ctd.time_f, color: P_color)
            renderDataGaps(context: context, rc: rect, dataGaps: &dataModel.ctd.dataGaps)
            drawMainLabel(context: context, rc: rect, text: "z [m]")

            // Time labels
            if (!epsiDataModel!.epsi.time_s.isEmpty || !epsiDataModel!.ctd.time_s.isEmpty) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "mm:ss.S"
                for i in 0..<xAxis.count {
                    let s = xAxis[i]
                    let time_s = dataModel.time_window_start + s * dataModel.time_window_length
                    let date = Date(timeIntervalSince1970: time_s)
                    let label = dateFormatter.string(from: date)
                    
                    let x = (1 - s) * rect.minX + s * rect.maxX
                    context.draw(Text(label).font(.footnote),
                                 at: CGPoint(x: x, y: rect.maxY + vgap/2),
                                 anchor: .center)
                }
            }
            if PRINT_PERF {
                let end_time2 = ProcessInfo.processInfo.systemUptime
                let msec2 = Int((end_time2 - start_time2) * 1000)
                print("Render: \(msec2) ms")
            }
        }
    }
}
