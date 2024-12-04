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

func rangeToYAxis(range: (Double, Double)) -> [Double]
{
    if (range.0 != range.1) {
        return [range.0, (range.1 + range.0) / 2, range.1]
    } else {
        return [Double]()
    }
}

class GraphRenderer {
    let context: GraphicsContext
    let isDarkTheme: Bool
    let xAxis: [Double]
    var rect = CGRect()
    init(context: GraphicsContext,
         isDarkTheme: Bool,
         xAxis: [Double]) {
        self.context = context
        self.isDarkTheme = isDarkTheme
        self.xAxis = xAxis
    }
    init(context: GraphicsContext, gr: GraphRenderer) {
        self.context = context
        self.isDarkTheme = gr.isDarkTheme
        self.xAxis = gr.xAxis
        self.rect = gr.rect
    }
    func offsetRectY(_ vgap: Double) {
        rect = rect.offsetBy(dx: 0.0, dy: rect.height + vgap)
    }
    func valueToY(_ v: Double, range: (Double, Double)) -> Double {
        let s = (v - range.0) / (range.1 - range.0)
        return rect.maxY - floor(s * rect.height)
    }
    func lerpToX(_ s: Double) -> Double {
        return floor(rect.minX + rect.width * s)
    }

    let font = Font.body
    let leftLabelsWidth = 70.0

    func renderGrid(td: TimestampedData, yAxis: [Double], leftLabels: Bool, format: String) {
        let nub = 7.0
        let thickLine = 1.5
        let textGap = 5.0
        let gray = isDarkTheme ? 0.15 : 0.85
        let color = Color(red: gray, green: gray, blue: gray, opacity: 0.5)

        // Framing rectangle
        context.stroke(
            Path(rect),
            with: .color(.gray),
            lineWidth: thickLine)

        // No data representation
        if yAxis.isEmpty {
            context.fill(Path(rect), with: .color(color))
            context.draw(Text("no data").foregroundColor(.gray),
                         at: CGPoint(x: (rect.minX + rect.maxX) / 2, y: (rect.minY + rect.maxY) / 2),
                         anchor: .center)
            return
        }

        if (!xAxis.isEmpty) {
            var xOffset = [CGFloat](repeating: 0.0, count: xAxis.count)
            for i in 0..<xAxis.count {
                let s = xAxis[i]
                xOffset[i] = (1 - s) * rect.minX + s * rect.maxX
            }
            
            // Dashed vertical lines
            context.stroke(Path { path in
                for i in 0..<xAxis.count {
                    path.addVLine(x: xOffset[i], y0: rect.minY, y1: rect.maxY)
                }
            }, with: .color(.gray), style: StrokeStyle(lineWidth: 0.5, dash: [5]))
            
            // Vertical nubs
            context.stroke(Path { path in
                for i in 0..<xAxis.count {
                    path.addVLine(x: xOffset[i], y0: rect.minY, y1: rect.minY + nub)
                    path.addVLine(x: xOffset[i], y0: rect.maxY - nub, y1: rect.maxY)
                }
            }, with: .color(.gray), lineWidth: thickLine)
        }
        
        if (!yAxis.isEmpty) {
            let yAxisMin = yAxis[0]
            let yAxisMax = yAxis[yAxis.count - 1]
            
            var yOffset = [CGFloat](repeating: 0.0, count: yAxis.count)
            for i in 0..<yAxis.count {
                let s = (yAxis[i] - yAxisMin) / (yAxisMax - yAxisMin)
                yOffset[i] = s * rect.minY + (1 - s) * rect.maxY
            }
            
            // Dashed horizontal lines
            context.stroke(Path { path in
                for i in 0..<yAxis.count {
                    path.addHLine(y: yOffset[i], x0: rect.minX, x1: rect.maxX)
                }
            }, with: .color(.gray), style: StrokeStyle(lineWidth: 0.5, dash: [5]))
            
            // Horizontal nubs
            context.stroke(Path { path in
                for i in 0..<yAxis.count {
                    path.addHLine(y: yOffset[i], x0: rect.minX, x1: rect.minX + nub)
                    path.addHLine(y: yOffset[i], x0: rect.maxX - nub, x1: rect.maxX)
                }
            }, with: .color(.gray), lineWidth: thickLine)
            
            // Y-Axis labels
            for i in 0..<yAxis.count {
                let atX = leftLabels ? rect.minX - textGap : rect.maxX + textGap
                context.draw(Text(String(format: format, yAxis[i])).font(font),
                             at: CGPoint(x: atX, y: yOffset[i]),
                             anchor: leftLabels ? .trailing : .leading)
            }
        }

        // Missing data gaps
        for dataGap in td.dataGaps {
#if !DEBUG
            if dataGap.type == .NEW_FILE_BOUNDARY { continue }
#endif
            let x0 = max(rect.minX + 1, lerpToX(dataGap.t0_f))
            let x1 = min(rect.maxX - 1, lerpToX(dataGap.t1_f))
            if (x1 - x0 >= 1) {
                let rcGap = CGRect(x: x0, y: rect.minY + 1, width: x1 - x0, height: rect.height - 2)
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

        // Missing at the beginning/end of the current time window
        if (!td.time_f.isEmpty) {
            let time_f = td.time_f.data[...]
            let minX = lerpToX(time_f.first!)
            assert(minX >= rect.minX)
            if (minX - rect.minX > 2) {
                let rcEmpty = CGRect(x: rect.minX + 1, y: rect.minY + 1, width: minX - rect.minX - 1, height: rect.height - 2)
                context.fill(Path(rcEmpty), with: .color(color))
            }
            let maxX = lerpToX(time_f.last!)
            if (rect.maxX - maxX > 2) {
                let rcEmpty = CGRect(x: maxX, y: rect.minY + 1, width: rect.maxX - maxX - 1, height: rect.height - 2)
                context.fill(Path(rcEmpty), with: .color(color))
            }
        }
    }
    func renderTimeSeries(td: TimestampedData, data: TimestampedData.Channel, range: (Double, Double), color: Color) {
        guard !data.isEmpty && !td.time_f.isEmpty else { return }
        let time_f = td.time_f.data[...]
        let data = data.data[...]
        let minX = lerpToX(time_f.first!)
        let maxX = lerpToX(time_f.last!)
        
        var emptyX = 0.0
        for dataGap in td.dataGaps {
            let x0 = max(rect.minX + 1, lerpToX(dataGap.t0_f))
            let x1 = min(rect.maxX - 1, lerpToX(dataGap.t1_f))
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
                        let x = lerpToX(time_f[i])
                        let y = valueToY(data[i], range: range)
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
                        let x = lerpToX(time_f[i])
                        let y = valueToY(data[i], range: range)
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
                    while i < time_f.count {
                        let sampleX = lerpToX(time_f[i])
                        if (sampleX > x) {
                            break
                        }
                        let y = valueToY(data[i], range: range)
                        minY = (minY == nil ? y : min(minY!, y))
                        maxY = (maxY == nil ? y : max(maxY!, y))
                        i += 1
                    }
                    if (minY != nil && maxY != nil) {
                        path.addVLine(x: x, y0: minY! - 1, y1: maxY! + 1)
                    }
                    if i >= time_f.count {
                        break
                    }
                }
            }, with: .color(color), lineWidth: 2)
        }
    }
    func drawMainLabel(_ text: String) {
        context.drawLayer { ctx in
            ctx.translateBy(x: 0.35 * leftLabelsWidth, y: (rect.maxY + rect.minY) / 2)
            ctx.rotate(by: Angle(degrees: -90))
            ctx.draw(Text(text).font(font).bold(), at: CGPoint(x: 0, y: -5), anchor: .center)
        }
    }
    func drawDataLabels(labels: [(Color, String)]) {
        var textHeight = 0.0
        var textWidth = 0.0
        let inset = (5.0, 3.0)
        let gray = isDarkTheme ? 0.4 : 0.9
        
        for i in 0..<labels.count {
            let textSize = context.resolve(Text(labels[i].1).font(font)).measure(in: CGSize(width: .max, height: .max))
            textWidth = max(textWidth, textSize.width)
            textHeight = max(textHeight, textSize.height)
        }
        
        let dotSize = 5.0
        let width = inset.0 + dotSize + inset.0 + textWidth + inset.0
        let height = inset.1 + textHeight * Double(labels.count) + inset.1
        
        let rcLabels = CGRect(x: rect.minX + 10, y: rect.minY + 10, width: width, height: height)
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
    func drawArrow(from: CGPoint, to: CGPoint, thick: Double, head: Double, color: Color) {
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
    func renderGenericTimeseries(td: TimestampedData, channel: TimestampedData.Channel, color: Color) {
        let range = channel.range()
        let yAxis = rangeToYAxis(range: range)
        renderGrid(td: td, yAxis: yAxis, leftLabels: true, format: "%.1f")
        renderTimeSeries(td: td, data: channel, range: range, color: color)
    }

}
