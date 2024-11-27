import SwiftUI

extension Path {
    mutating func addHLine(y: Double, x0: Double, x1: Double) {
        move(to: CGPoint(x: x0, y: y))
        addLine(to: CGPoint(x: x1, y: y))
    }
    mutating func addVLine(x: Double, y0: Double, y1: Double) {
        move(to: CGPoint(x: x, y: y0))
        addLine(to: CGPoint(x: x, y: y1))
    }
}

struct RealtimePlotView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var refreshView = false
    let refreshTimer = Timer.publish(every: 1.0/30, on: .main, in: .common).autoconnect()
    @State/*Object*/ var vm: ViewModel
    
    var body: some View {
        VStack {
            chart
                .id(refreshView)
                .frame(alignment: .topLeading)
                .navigationTitle(vm.model.status)
                .onReceive(refreshTimer) { _ in
                    Task {
                        //let stopwatch = Stopwatch(label: "Update")
                        if (vm.update()) {
                            //stopwatch.printElapsed()
                            refreshView.toggle()
                        }
                    }
                }
        }
    }
    
    private var chart: some View {
        return Canvas{ context, size in
            //let stopwatch = Stopwatch(label: "Render")
            render(context: context, size: size)
            //stopwatch.printElapsed()
        }
    }
    
    func renderGrid(rd: RenderData, yAxis: [Double], leftLabels: Bool, format: String) {
        let rc = rd.rect
        let context = rd.context
        
        let nub = 7.0
        let thickLine = 1.5
        let textGap = 5.0
        
        // Framing rectangle
        context.stroke(
            Path(rc),
            with: .color(.gray),
            lineWidth: thickLine)
        
        if (!rd.xAxis.isEmpty) {
            var xOffset = [CGFloat](repeating: 0.0, count: rd.xAxis.count)
            for i in 0..<rd.xAxis.count {
                let s = rd.xAxis[i]
                xOffset[i] = (1 - s) * rc.minX + s * rc.maxX
            }
            
            // Dashed vertical lines
            context.stroke(Path { path in
                for i in 0..<rd.xAxis.count {
                    path.addVLine(x: xOffset[i], y0: rc.minY, y1: rc.maxY)
                }
            }, with: .color(.gray), style: StrokeStyle(lineWidth: 0.5, dash: [5]))
            
            // Vertical nubs
            context.stroke(Path { path in
                for i in 0..<rd.xAxis.count {
                    path.addVLine(x: xOffset[i], y0: rc.minY, y1: rc.minY + nub)
                    path.addVLine(x: xOffset[i], y0: rc.maxY - nub, y1: rc.maxY)
                }
            }, with: .color(.gray), lineWidth: thickLine)
        }
        
        if (!yAxis.isEmpty) {
            let yAxisMin = yAxis[0]
            let yAxisMax = yAxis[yAxis.count - 1]
            
            var yOffset = [CGFloat](repeating: 0.0, count: yAxis.count)
            for i in 0..<yAxis.count {
                let s = (yAxis[i] - yAxisMin) / (yAxisMax - yAxisMin)
                yOffset[i] = s * rc.minY + (1 - s) * rc.maxY
            }
            
            // Dashed horizontal lines
            context.stroke(Path { path in
                for i in 0..<yAxis.count {
                    path.addHLine(y: yOffset[i], x0: rc.minX, x1: rc.maxX)
                }
            }, with: .color(.gray), style: StrokeStyle(lineWidth: 0.5, dash: [5]))
            
            // Horizontal nubs
            context.stroke(Path { path in
                for i in 0..<yAxis.count {
                    path.addHLine(y: yOffset[i], x0: rc.minX, x1: rc.minX + nub)
                    path.addHLine(y: yOffset[i], x0: rc.maxX - nub, x1: rc.maxX)
                }
            }, with: .color(.gray), lineWidth: thickLine)
            
            // Y-Axis labels
            for i in 0..<yAxis.count {
                let atX = leftLabels ? rc.minX - textGap : rc.maxX + textGap
                context.draw(Text(String(format: format, yAxis[i])).font(font),
                             at: CGPoint(x: atX, y: yOffset[i]),
                             anchor: leftLabels ? .trailing : .leading)
            }
        }
        
        renderNoData(rd: rd)
    }
    func isDarkTheme() -> Bool {
        return colorScheme == .dark
    }
    func renderNoData(rd: RenderData) {
        let rc = rd.rect
        let context = rd.context
        let gray = isDarkTheme() ? 0.15 : 0.85
        let color = Color(red: gray, green: gray, blue: gray, opacity: 0.5)
        
        for dataGap in rd.dataGaps {
#if !DEBUG
            if dataGap.type == .NEW_FILE_BOUNDARY { continue }
#endif
            let x0 = max(rc.minX + 1, timeToX(rc: rc, t: dataGap.t0, t0: rd.time_window.0, t1: rd.time_window.1))
            let x1 = min(rc.maxX - 1, timeToX(rc: rc, t: dataGap.t1, t0: rd.time_window.0, t1: rd.time_window.1))
            if (x1 - x0 >= 1) {
                let rcGap = CGRect(x: x0, y: rc.minY + 1, width: x1 - x0, height: rc.height - 2)
                var gapColor: Color
                switch dataGap.type {
                case .MISSING_DATA:
                    gapColor = color
                case .NEW_FILE_BOUNDARY:
                    gapColor = .blue
                }
                context.fill(Path(rcGap), with: .color(gapColor))
            }
        }
        if (!rd.time_f.isEmpty) {
            let minX = lerpToX(rc: rc, s: rd.time_f.first!)
            assert(minX >= rc.minX)
            if (minX - rc.minX > 2) {
                let rcEmpty = CGRect(x: rc.minX + 1, y: rc.minY + 1, width: minX - rc.minX - 1, height: rc.height - 2)
                context.fill(Path(rcEmpty), with: .color(color))
            }
            let maxX = lerpToX(rc: rc, s: rd.time_f.last!)
            if (rc.maxX - maxX > 2) {
                let rcEmpty = CGRect(x: maxX, y: rc.minY + 1, width: rc.maxX - maxX - 1, height: rc.height - 2)
                context.fill(Path(rcEmpty), with: .color(color))
            }
        } else {
            context.fill(Path(rc), with: .color(color))
            context.draw(Text("no data").foregroundColor(.gray),
                         at: CGPoint(x: (rc.minX + rc.maxX) / 2, y: (rc.minY + rc.maxY) / 2),
                         anchor: .center)
        }
    }
    
    func valueToY(rc: CGRect, yAxis: (Double, Double), v: Double) -> Double {
        return lerpToY(rc: rc, s: valueToLerp(yAxis: yAxis, v: v))
    }
    func lerpToY(rc: CGRect, s: Double) -> Double {
        return rc.maxY - floor(s * rc.height)
    }
    func valueToLerp(yAxis: (Double, Double), v: Double) -> Double {
        return (v - yAxis.0) / (yAxis.1 - yAxis.0)
    }
    func timeToLerp(t: Double, t0: Double, t1: Double) -> Double {
        return (t - t0) / (t1 - t0)
    }
    func timeToX(rc: CGRect, t: Double, t0: Double, t1: Double) -> Double {
        return lerpToX(rc: rc, s: timeToLerp(t: t, t0: t0, t1: t1))
    }
    func lerpToX(rc: CGRect, s: Double) -> Double {
        return floor(rc.minX + rc.width * s)
    }
    func rangeToYAxis(range: (Double, Double)) -> [Double]
    {
        if (range.0 != range.1) {
            return [range.0, (range.1 + range.0) / 2, range.1]
        } else {
            return [Double]()
        }
    }
    func render1D(rd: RenderData, yAxis: (Double, Double), data: inout [Double], color: Color) {
        assert(data.count == rd.time_f.count)
        if (!data.isEmpty && !rd.time_f.isEmpty) {
            let rc = rd.rect
            let context = rd.context
            let minX = lerpToX(rc: rc, s: rd.time_f.first!)
            let maxX = lerpToX(rc: rc, s: rd.time_f.last!)
            
            var emptyX = 0.0
            for dataGap in rd.dataGaps {
                let x0 = max(rc.minX + 1, timeToX(rc: rc, t: dataGap.t0, t0: rd.time_window.0, t1: rd.time_window.1))
                let x1 = min(rc.maxX - 1, timeToX(rc: rc, t: dataGap.t1, t0: rd.time_window.0, t1: rd.time_window.1))
                if (x1 - x0 >= 1) {
                    emptyX += x1 - x0
                }
            }
            
            let pixelCount = Int(maxX - minX - emptyX)
            if (data.count <= 20 * pixelCount) {
                var prevWasNaN = false
                context.stroke(Path { path in
                    for i in 0..<data.count {
                        if data[i].isNaN {
                            prevWasNaN = true
                        } else {
                            let x = lerpToX(rc: rc, s: rd.time_f[i])
                            let y = valueToY(rc: rc, yAxis: yAxis, v: data[i])
                            if (i == 0 || prevWasNaN) { //} || (time_f[i] - time_f[i - 1]) > 2*(time_f[1] - time_f[0])) {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                            prevWasNaN = false
                        }
                    }
                }, with: .color(color.opacity(0.2)),
                               lineWidth: 1)
                context.stroke(Path { path in
                    for i in 0..<data.count {
                        if !data[i].isNaN {
                            let x = lerpToX(rc: rc, s: rd.time_f[i])
                            let y = valueToY(rc: rc, yAxis: yAxis, v: data[i])
                            path.addHLine(y: y, x0: x-1, x1: x+1)
                            path.addVLine(x: x, y0: y-1, y1: y+1)
                        }
                    }
                }, with: .color(color), lineWidth: 2)
            } else {
                context.stroke(Path { path in
                    var i = 0
                    for x in stride(from: minX, to: maxX, by: 1.0) {
                        var minY: Double?
                        var maxY: Double?
                        while i < rd.time_f.count {
                            let sampleX = lerpToX(rc: rc, s: rd.time_f[i])
                            if (sampleX > x) {
                                break
                            }
                            let y = valueToY(rc: rc, yAxis: yAxis, v: data[i])
                            minY = (minY == nil ? y : min(minY!, y))
                            maxY = (maxY == nil ? y : max(maxY!, y))
                            i += 1
                        }
                        if (minY != nil && maxY != nil) {
                            path.addVLine(x: x, y0: minY! - 1, y1: maxY! + 1)
                        }
                        if i >= rd.time_f.count {
                            break
                        }
                    }
                }, with: .color(color), lineWidth: 2)
            }
        }
    }
    
    let s1_color = Color(red: 88/255, green: 143/255, blue: 92/255)
    let s2_color = Color(red: 189/255, green: 219/255, blue: 154/255, opacity: 0.75)
    let a1_color = Color(red: 129/255, green: 39/255, blue: 120/255)
    let a2_color = Color(red: 220/255, green: 86/255, blue: 77/255)
    let a3_color = Color(red: 240/255, green: 207/255, blue: 140/255, opacity: 0.75)
    let T_color = Color(red: 212/255, green: 35/255, blue: 36/255)
    let S_color = Color(red: 82/255, green: 135/255, blue: 187/255)
    let dzdt_up_color = Color(red: 233/255, green: 145/255, blue: 195/255)
    let dzdt_down_color = Color(red: 82/255, green: 135/255, blue: 187/255)
    let P_color = Color(red: 24/255, green: 187/255, blue: 24/255)
    let leftLabelsWidth = 50.0
    let vgap = 25.0
    let hgap = 30.0
    let font = Font.body
    
    func drawMainLabel(context: GraphicsContext, rc: CGRect, text: String) {
        context.drawLayer { ctx in
            ctx.translateBy(x: leftLabelsWidth/2, y: (rc.maxY + rc.minY) / 2)
            ctx.rotate(by: Angle(degrees: -90))
            ctx.draw(Text(text).font(font).bold(), at: CGPoint(x: 0, y: -5), anchor: .center)
        }
    }
    func drawSubLabels(context: GraphicsContext, rc: CGRect, labels: [(Color, String)]) {
        var textHeight = 0.0
        var textWidth = 0.0
        let inset = (5.0, 3.0)
        let gray = (colorScheme == .dark) ? 0.4 : 0.9
        
        for i in 0..<labels.count {
            let textSize = context.resolve(Text(labels[i].1).font(font)).measure(in: CGSize(width: .max, height: .max))
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
            context.draw(Text(labels[i].1).foregroundColor(.black).font(font), at: ptText, anchor: .topLeading)
            ptText.y += textHeight
            rcDot = rcDot.offsetBy(dx: 0, dy: textHeight)
        }
    }
    
    func drawArrow(context: GraphicsContext, from: CGPoint, to: CGPoint, thick: Double, head: Double, color: Color) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let len = sqrt(dx * dx + dy * dy)
        let dir = atan2(dy, dx)
        context.drawLayer { ctx in
            ctx.translateBy(x: from.x, y: from.y)
            ctx.rotate(by: Angle(radians: dir))
            ctx.stroke(Path { path in
                path.addHLine(y: 0, x0: 0, x1: len - head)
            }, with: .color(color), lineWidth: thick)
            ctx.fill(Path { path in
                path.move(to: CGPoint(x: len, y: 0))
                path.addLine(to: CGPoint(x: len - head, y: head / 2))
                path.addLine(to: CGPoint(x: len - head, y: -head / 2))
            }, with: .color(color))
        }
    }
    func minmax(v1: (Double, Double), v2: (Double, Double)) -> (Double, Double)
    {
        return (min(v1.0, v2.0), max(v1.1, v2.1))
    }
    class RenderDataEnv {
        let context: GraphicsContext
        let time_window: (Double, Double)
        let xAxis: [Double]
        var rect = CGRect()
        init(context: GraphicsContext,
             time_window: (Double, Double),
             xAxis: [Double]) {
            self.context = context
            self.time_window = time_window
            self.xAxis = xAxis
        }
        init(context: GraphicsContext, rd: RenderDataEnv) {
            self.context = context
            self.time_window = rd.time_window
            self.xAxis = rd.xAxis
            self.rect = rd.rect
        }
        func offsetRectY(vgap: Double) {
            rect = rect.offsetBy(dx: 0.0, dy: rect.height + vgap)
        }
    }
    class RenderData: RenderDataEnv {
        let time_s: ArraySlice<Double>
        let time_f: ArraySlice<Double>
        let dataGaps: ArraySlice<DataGapInfo>
        init(context: GraphicsContext, rd: RenderData) {
            self.time_s = rd.time_s
            self.time_f = rd.time_f
            self.dataGaps = rd.dataGaps
            super.init(context: context, rd: rd)
        }
        init(epsi: EpsiViewModelData, rd: RenderDataEnv) {
            self.time_s = epsi.time_s[...]
            self.time_f = epsi.time_f[...]
            self.dataGaps = epsi.dataGaps[...]
            super.init(context: rd.context, rd: rd)
        }
        init(ctd: CtdViewModelData, rd: RenderDataEnv) {
            self.time_s = ctd.time_s[...]
            self.time_f = ctd.time_f[...]
            self.dataGaps = ctd.dataGaps[...]
            super.init(context: rd.context, rd: rd)
        }
    }
    
    func renderEpsi_t(rd: RenderDataEnv) {
        let epsi_rd = RenderData(epsi: vm.epsi, rd: rd)
        let t1_color = isDarkTheme() ? Color(red: 182/255, green: 114/255, blue: 182/255) : Color(red: 21/255, green: 53/255, blue: 136/255)
        let t2_color = Color(red: 114/255, green: 182/255, blue: 182/255, opacity: 0.75)
        
        let epsi_t_volt_range = minmax(v1: vm.epsi.t1_volt_range, v2: vm.epsi.t2_volt_range)
        
        let t_yAxis = rangeToYAxis(range: epsi_t_volt_range)
        
        renderGrid(rd: epsi_rd, yAxis: t_yAxis, leftLabels: true, format: "%.2f")
        
        render1D(rd: epsi_rd, yAxis: epsi_t_volt_range, data: &vm.epsi.t1_volt, color: t1_color)
        render1D(rd: epsi_rd, yAxis: epsi_t_volt_range, data: &vm.epsi.t2_volt, color: t2_color)
        
        drawMainLabel(context: rd.context, rc: rd.rect, text: "FP07 [Volt]")
        if (vm.epsi.time_s.count > 0) {
            drawSubLabels(context: rd.context, rc: rd.rect, labels: [
                (t1_color, "t1 - \(String(format: "%.2g", vm.epsi.t1_volt_mean))"),
                (t2_color, "t2 - \(String(format: "%.2g", vm.epsi.t2_volt_mean))")])
        }
        rd.offsetRectY(vgap: vgap)
    }
    func renderEpsi_s(rd: RenderDataEnv) {
        let epsi_rd = RenderData(epsi: vm.epsi, rd: rd)
        let epsi_s_volt_range = minmax(v1: vm.epsi.s1_volt_range, v2: vm.epsi.s2_volt_range)
        
        let s_yAxis = rangeToYAxis(range: epsi_s_volt_range)
        renderGrid(rd: epsi_rd, yAxis: s_yAxis, leftLabels: true, format: "%.2f")
        render1D(rd: epsi_rd, yAxis: epsi_s_volt_range, data: &vm.epsi.s1_volt, color: s1_color)
        render1D(rd: epsi_rd, yAxis: epsi_s_volt_range, data: &vm.epsi.s2_volt, color: s2_color)
        
        drawMainLabel(context: rd.context, rc: rd.rect, text: "Shear [Volt]")
        if (vm.epsi.time_s.count > 0) {
            drawSubLabels(context: rd.context, rc: rd.rect, labels: [
                (s1_color, "s1 - rms \(String(format: "%.2g", vm.epsi.s1_volt_rms))"),
                (s2_color, "s2 - rms \(String(format: "%.2g", vm.epsi.s2_volt_rms))")])
        }
        rd.offsetRectY(vgap: vgap)
    }
    func renderEpsi_s1(rd: RenderDataEnv) {
        let epsi_rd = RenderData(epsi: vm.epsi, rd: rd)
        let s1_yAxis = rangeToYAxis(range: vm.epsi.s1_volt_range)
        renderGrid(rd: epsi_rd, yAxis: s1_yAxis, leftLabels: true, format: "%.2f")
        render1D(rd: epsi_rd, yAxis: vm.epsi.s1_volt_range, data: &vm.epsi.s1_volt, color: s1_color)
        
        drawMainLabel(context: rd.context, rc: rd.rect, text: "s1 [Volt]")
        if (vm.epsi.time_s.count > 0) {
            drawSubLabels(context: rd.context, rc: rd.rect, labels: [
                (s1_color, "s1 - rms \(String(format: "%.2g", vm.epsi.s1_volt_rms))")])
        }
        rd.offsetRectY(vgap: vgap)
    }
    func renderEpsi_s2(rd: RenderDataEnv) {
        let epsi_rd = RenderData(epsi: vm.epsi, rd: rd)
        let s2_yAxis = rangeToYAxis(range: vm.epsi.s2_volt_range)
        renderGrid(rd: epsi_rd, yAxis: s2_yAxis, leftLabels: true, format: "%.2f")
        render1D(rd: epsi_rd, yAxis: vm.epsi.s2_volt_range, data: &vm.epsi.s2_volt, color: s2_color)
        
        drawMainLabel(context: rd.context, rc: rd.rect, text: "s2 [Volt]")
        if (vm.epsi.time_s.count > 0) {
            drawSubLabels(context: rd.context, rc: rd.rect, labels: [
                (s2_color, "s2 - rms \(String(format: "%.2g", vm.epsi.s2_volt_rms))")])
        }
        rd.offsetRectY(vgap: vgap)
    }
    func renderEpsi_a(rd: RenderDataEnv) {
        let epsi_rd = RenderData(epsi: vm.epsi, rd: rd)
        // EPSI a1
        epsi_rd.rect = CGRect(x: rd.rect.minX, y: rd.rect.minY, width: rd.rect.width, height: rd.rect.height / 2)
        
        let a1_yAxis = rangeToYAxis(range: vm.epsi.a1_g_range)
        renderGrid(rd: epsi_rd, yAxis: a1_yAxis, leftLabels: true, format: "%.1f")
        render1D(rd: epsi_rd, yAxis: vm.epsi.a1_g_range, data: &vm.epsi.a1_g, color: a1_color)
        if (vm.epsi.time_s.count > 0) {
            drawSubLabels(context: rd.context, rc: epsi_rd.rect, labels: [(a1_color, "z")])
        }

        // EPSI a2, a3
        epsi_rd.offsetRectY(vgap: 0)
        let epsi_a23_g_range = minmax(v1: vm.epsi.a2_g_range, v2: vm.epsi.a3_g_range)
        
        let a23_yAxis = rangeToYAxis(range: epsi_a23_g_range)
        renderGrid(rd: epsi_rd, yAxis: a23_yAxis, leftLabels: false, format: "%.1f")
        render1D(rd: epsi_rd, yAxis: epsi_a23_g_range, data: &vm.epsi.a2_g, color: a2_color)
        render1D(rd: epsi_rd, yAxis: epsi_a23_g_range, data: &vm.epsi.a3_g, color: a3_color)
        if (vm.epsi.time_s.count > 0) {
            drawSubLabels(context: rd.context, rc: epsi_rd.rect, labels: [(a2_color, "x"), (a3_color, "y")])
        }
        drawMainLabel(context: rd.context, rc: rd.rect, text: "Accel [g]")
        rd.offsetRectY(vgap: vgap)
    }
    func renderCtd_T(rd: RenderDataEnv) {
        let ctd_rd = RenderData(ctd: vm.ctd, rd: rd)
        let T_yAxis = rangeToYAxis(range: vm.ctd.T_range)
        renderGrid(rd: ctd_rd, yAxis: T_yAxis, leftLabels: true, format: "%.1f")
        render1D(rd: ctd_rd, yAxis: vm.ctd.T_range, data: &vm.ctd.T, color: T_color)
        
        drawMainLabel(context: rd.context, rc: rd.rect, text: "T [\u{00B0}C]")
        rd.offsetRectY(vgap: vgap)
    }
    func renderCtd_S(rd: RenderDataEnv) {
        let ctd_rd = RenderData(ctd: vm.ctd, rd: rd)
        let S_yAxis = rangeToYAxis(range: vm.ctd.S_range)
        renderGrid(rd: ctd_rd, yAxis: S_yAxis, leftLabels: true, format: "%.1f")
        render1D(rd: ctd_rd, yAxis: vm.ctd.S_range, data: &vm.ctd.S, color: S_color)
        
        drawMainLabel(context: rd.context, rc: rd.rect, text: "S")
        rd.offsetRectY(vgap: vgap);
    }
    func getCtd_dzdt_zero_y(rd: RenderDataEnv) -> Double {
        let dzdt_min = vm.ctd.dzdt_range.0
        let dzdt_max = vm.ctd.dzdt_range.1
        let zero_s = (0.0 - dzdt_min) / (dzdt_max - dzdt_min)
        return zero_s * rd.rect.minY + (1.0 - zero_s) * rd.rect.maxY
    }
    func renderCtd_dzdt(rd: RenderDataEnv) {
        let ctd_rd = RenderData(ctd: vm.ctd, rd: rd)

        var dzdt_yAxis: [Double]
        let dzdt_min = vm.ctd.dzdt_range.0
        let dzdt_max = vm.ctd.dzdt_range.1
        let zero_y = getCtd_dzdt_zero_y(rd: rd)
        if (dzdt_min * dzdt_max < 0) {
            // Plot contains zero level, highlight that instead of middle
            dzdt_yAxis = [dzdt_min, 0.0, dzdt_max]
        } else {
            dzdt_yAxis = rangeToYAxis(range: vm.ctd.dzdt_range)
        }
        renderGrid(rd: ctd_rd, yAxis: dzdt_yAxis, leftLabels: true, format: "%.2f")
        if (zero_y > rd.rect.minY + 2) {
            rd.context.drawLayer { ctx in
                ctx.clip(to: Path(CGRect(x: rd.rect.minX, y: rd.rect.minY, width: rd.rect.width, height: zero_y - rd.rect.minY)))
                let rdUp = RenderData(context: ctx, rd: ctd_rd)
                render1D(rd: rdUp, yAxis: vm.ctd.dzdt_range, data: &vm.ctd.dzdt_movmean, color: dzdt_up_color)
            }
        }
        if (zero_y < rd.rect.maxY - 2) {
            rd.context.drawLayer { ctx in
                ctx.clip(to: Path(CGRect(x: rd.rect.minX, y: zero_y, width: rd.rect.width, height: rd.rect.maxY - zero_y)))
                let rdDown = RenderData(context: ctx, rd: ctd_rd)
                render1D(rd: rdDown, yAxis: vm.ctd.dzdt_range, data: &vm.ctd.dzdt_movmean, color: dzdt_down_color)
            }
        }
        if (dzdt_max == dzdt_min)
        {
            // Render the no data, if needed
            render1D(rd: ctd_rd, yAxis: vm.ctd.dzdt_range, data: &vm.ctd.dzdt_movmean, color: .black)
        }
        renderCtd_dzdt_arrows(rd: rd)

        drawMainLabel(context: rd.context, rc: rd.rect, text: "dzdt [m/s]")
        rd.offsetRectY(vgap: vgap)
    }
    func renderCtd_z(rd: RenderDataEnv) {
        let ctd_rd = RenderData(ctd: vm.ctd, rd: rd)
        let z_yAxis = rangeToYAxis(range: vm.ctd.z_range)
        renderGrid(rd: ctd_rd, yAxis: z_yAxis, leftLabels: true, format: "%.1f")
        render1D(rd: ctd_rd, yAxis: vm.ctd.z_range, data: &vm.ctd.z, color: P_color)
        drawMainLabel(context: rd.context, rc: rd.rect, text: "z [m]")
        rd.offsetRectY(vgap: vgap)
    }
    func renderCtd_z_dzdt(rd: RenderDataEnv) {
        let ctd_rd = RenderData(ctd: vm.ctd, rd: rd)
        let z_yAxis = rangeToYAxis(range: vm.ctd.z_range)
        renderGrid(rd: ctd_rd, yAxis: z_yAxis, leftLabels: true, format: "%.1f")
        render1D(rd: ctd_rd, yAxis: vm.ctd.z_range, data: &vm.ctd.z_pos, color: dzdt_down_color)
        render1D(rd: ctd_rd, yAxis: vm.ctd.z_range, data: &vm.ctd.z_neg, color: dzdt_up_color)
        drawMainLabel(context: rd.context, rc: rd.rect, text: "z [m]")
        renderCtd_dzdt_arrows(rd: rd)
        rd.offsetRectY(vgap: vgap)
    }
    func renderCtd_dzdt_arrows(rd: RenderDataEnv) {
        let zero_y = getCtd_dzdt_zero_y(rd: rd)
        let arrow_x = rd.rect.maxX + 10.0
        let arrow_headLen = 15.0
        let arrow_len = 40.0
        let arrow_thick = 5.0
        if (zero_y > rd.rect.minY + 2) {
            let arrow_y = min(zero_y, rd.rect.maxY)
            drawArrow(context: rd.context, from: CGPoint(x: arrow_x, y: arrow_y - 1), to: CGPoint(x: arrow_x, y: arrow_y - arrow_len), thick: arrow_thick, head: arrow_headLen, color: dzdt_up_color)
        }
        if (zero_y < rd.rect.maxY - 2) {
            let arrow_y = max(zero_y, rd.rect.minY)
            drawArrow(context: rd.context, from: CGPoint(x: arrow_x, y: arrow_y + 1), to: CGPoint(x: arrow_x, y: arrow_y + arrow_len), thick: arrow_thick, head: arrow_headLen, color: dzdt_down_color)
        }
    }
    func render(context: GraphicsContext, size: CGSize) {
        let timeTickCount = Int(size.width / 200)
        var xAxis : [Double] = []
        for i in 0..<timeTickCount {
            xAxis.append(Double(i) / Double(timeTickCount - 1))
        }

        let rd = RenderDataEnv(
            context: context,
            time_window: vm.time_window,
            xAxis: xAxis)
        rd.rect = CGRect(x: hgap + leftLabelsWidth, y: vgap, width: max(size.width - 2 * hgap - leftLabelsWidth, 5), height: 100)

        switch vm.model.deploymentType {
        case .EPSI:
            renderEpsi_t(rd: rd)
            renderEpsi_s(rd: rd)
            renderEpsi_a(rd: rd)
            renderCtd_T(rd: rd)
            renderCtd_S(rd: rd)
            renderCtd_dzdt(rd: rd)
            renderCtd_z(rd: rd)

        case .FCTD:
            renderCtd_T(rd: rd)
            renderCtd_S(rd: rd)
            renderEpsi_s2(rd: rd)
            renderEpsi_a(rd: rd)
            renderCtd_z_dzdt(rd: rd)
        }

        let textHeight = context.resolve(Text("00:00:00").font(font)).measure(in: CGSize(width: .max, height: .max)).height
        var y = rd.rect.minY - vgap/2
        // Time labels
        if (!vm.epsi.time_s.isEmpty || !vm.ctd.time_s.isEmpty) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss" // .S for sub-second
            for i in 0..<xAxis.count {
                let s = xAxis[i]
                let time_s = (1 - s) * vm.time_window.0 + s * vm.time_window.1
                let date = Date(timeIntervalSince1970: time_s)
                let label = dateFormatter.string(from: date)
                
                let x = (1 - s) * rd.rect.minX + s * rd.rect.maxX
                context.draw(Text(label).font(font),
                             at: CGPoint(x: x, y: y),
                             anchor: .center)
            }
            if !xAxis.isEmpty {
                y += textHeight
            }
        }
/*
        context.draw(Text("Status: \(vm.model.status)").font(font).bold(),
                     at: CGPoint(x: 0, y: 0),
                     anchor: .topLeading)
*/

        if let server = vm.broadcaster.server {
            if server.state == .Failed {
                context.draw(Text("Broadcasting A1[g] to the winch app failed!")
                                .font(font).bold().foregroundColor(.red),
                             at: CGPoint(x: rd.rect.minX, y: y), anchor: .topLeading)
            }
        }

        if vm.model.mostRecentLatitude != "" {
            context.draw(Text("\(vm.model.mostRecentLatitude), \(vm.model.mostRecentLongitude)").font(font).bold(),
                         at: CGPoint(x: rd.rect.maxX, y: y),
                         anchor: .topTrailing)
            y += textHeight
        }
        
        if vm.model.mostRecentLatitudeScientific * vm.model.mostRecentLongitudeScientific != 0.0 {
            let lat = String(format: "%.2f", vm.model.mostRecentLatitudeScientific)
            let lon = String(format: "%.2f", vm.model.mostRecentLongitudeScientific)
            context.draw(Text("lat: \(lat), lon: \(lon)").font(font).bold(),
                         at: CGPoint(x: rd.rect.maxX, y: y),
                         anchor: .topTrailing)
            y += textHeight
        }
    }
}
