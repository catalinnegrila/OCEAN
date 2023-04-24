import SwiftUI


struct HeatMap: View {
    @State private var selection = ""
    private var pickerValues : [String]

    private static let rgbGradient : [[UInt8]] = [[0, 0, 255], [0, 255, 0], [0, 255, 255], [255, 166, 0], [255, 0, 0]]
    private static func interpolateValue(_ v : Double, _ ch : Int) -> UInt8
    {
        if (v.isNaN) {
            return 255
        }
        assert(v >= 0.0 && v <= 1.0)
        let maxIndex = Double(HeatMap.rgbGradient.count - 1)
        let elem = v * maxIndex
        let prevElem = floor(elem)
        let nextElem = ceil(elem)
        let s = (elem - prevElem)
        let prevValue = Double(HeatMap.rgbGradient[Int(prevElem)][ch])
        let nextValue = Double(HeatMap.rgbGradient[Int(nextElem)][ch])
        return UInt8((1.0 - s) * prevValue + s * nextValue)
    }

    var mat : MatData
    var xAxis : [Double]
    var yAxis : [Double]

    static func transpose(mat : [[Double]]) -> [[Double]]
    {
        let rows = mat.count
        assert(rows > 0)
        let cols = mat[0].count
        assert(cols > 0)

        var result = Array(repeating: Array<Double>(repeating: 0.0, count: rows), count: cols)
        for i in 0..<cols {
            for j in 0..<rows {
                result[i][j] = mat[j][i]
            }
        }
        return result
    }
    static func shorten(mat : [Double], newCount: Int) -> [Double]
    {
        assert(newCount < mat.count)
        var result = Array(repeating: 0.0, count: newCount)
        for i in 0..<newCount {
            let j = Int(Double(mat.count) * Double(i) / Double(newCount))
            result[i] = mat[j]
        }
        return result
    }

    func generateImage() -> (NSImage, Double, Double) {
        let colorField = selection.components(separatedBy: ".")[1]
        let colorData = mat.getMatrixDouble2(name: colorField)
        print("color: \(colorData.count)x\(colorData[0].count)")

        let width = colorData[0].count
        let height = colorData.count

        let bitmapImageRep = NSBitmapImageRep(
            bitmapDataPlanes:nil,
            pixelsWide:width,
            pixelsHigh:height,
            bitsPerSample:8,
            samplesPerPixel:4,
            hasAlpha:true,
            isPlanar:false,
            colorSpaceName:NSColorSpaceName.deviceRGB,
            bytesPerRow:width * 4,
            bitsPerPixel:32)!
        
        let context = NSGraphicsContext(bitmapImageRep: bitmapImageRep)!
        let data = context.cgContext.data!
        let pixelBuffer = data.assumingMemoryBound(to: UInt8.self)
        var offset = 0

        var minVal = colorData[0][0]
        var maxVal = minVal
        for rowIndex in 0..<height {
            for colIndex in 0..<width {
                let val = colorData[rowIndex][colIndex]
                minVal = fmin(minVal, val)
                maxVal = fmax(maxVal, val)
            }
        }
        print("MinVal: \(minVal), MaxVal: \(maxVal)")

        for rowIndex in 0..<height {
            for colIndex in 0..<width {
                let val = (colorData[rowIndex][colIndex] - minVal) / (maxVal - minVal)
                pixelBuffer[offset] = HeatMap.interpolateValue(val, 0)
                pixelBuffer[offset+1] = HeatMap.interpolateValue(val, 1)
                pixelBuffer[offset+2] = HeatMap.interpolateValue(val, 2)
                pixelBuffer[offset+3] = 255
                offset += 4
            }
        }

        let image = NSImage(size: NSSize(width: width, height: height))
        image.addRepresentation(bitmapImageRep)
        return (image, minVal, maxVal)
    }

    init() {
        // For fctd_grid, FCTDgrid.time is the x-axis, FCTDgrid.depth is the y-axis, and any of the 2D variables are the color.
        // For epsi_grid, GRID.dnum is the x-axis, GRID.z is the y-axis, and any of the 2D variables are the color.

        self.mat = MatData(path: "epsi_grid_uncompressed.mat")
        let xAxisField = "dnum"
        let yAxisField = "z"
        let colorField = "s"
/*
        self.mat = MatData(path: "fctd_grid_uncompressed.mat")
        let colorField = "density"
        let xAxisField = "time"
        let yAxisField = "depth"
*/
        self.pickerValues = mat.getFieldNames(filter2D: true)
        self.selection = "\(mat.getArrayName()).\(colorField)"

        let xAxis = mat.getMatrixDouble2(name: xAxisField)
        let yAxis = mat.getMatrixDouble2(name: yAxisField)
        self.xAxis = HeatMap.shorten(mat: xAxis[0], newCount: 5)
        self.yAxis = HeatMap.shorten(mat: HeatMap.transpose(mat: yAxis)[0], newCount: 10)
        print("x: \(xAxis.count)x\(xAxis[0].count)")
        print("y: \(yAxis.count)x\(yAxis[0].count)")
    }

    var body: some View {
        VStack {
            Text("Epsi Grid Data Display")
                .font(.largeTitle)
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Picker("Variable:", selection: $selection) {
                    ForEach(pickerValues, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.menu)
                .frame(width:300, alignment: Alignment.leading)
                .padding()

                chart
                    .padding()
                    .frame(width: 500, alignment: .topLeading)
            }
            //.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .border(.black, width: 2)
            .padding()
        }
        .navigationTitle("Chart demo")
    }

    private func renderGrid(context: GraphicsContext, rc: CGRect, yAxis: [Double], leftLabels: Bool, formatter: (Double) -> String) {
        let nub = 7.0
        let thickLine = 1.5
        let textGap = 5.0
        
        var yOffset = [CGFloat](repeating: 0.0, count: yAxis.count)
        for i in 0..<yAxis.count {
            let s = Double(i) / Double(yAxis.count - 1)
            yOffset[i] = s * rc.minY + (1 - s) * rc.maxY
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

        // Nubs
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

        // Y-Axis labels
        for i in 0..<yAxis.count {
            let atX = leftLabels ? rc.minX - textGap : rc.maxX + textGap
            let anchorX = leftLabels ? 1.0 : 0.0
            context.draw(Text(formatter(yAxis[i]))
                    .font(.footnote),
                             at: CGPoint(x: atX, y: yOffset[i]),
                             anchor: UnitPoint(x: anchorX, y: 0.5))
        }

    }
    private var chart: some View {
        return Canvas{ context, size in
            let (image, minVal, maxVal) = generateImage()
            let imageRect = CGRect(x: 30, y: 20, width: image.size.width, height: image.size.height)
            context.draw(
                Image(nsImage: image)
                    .interpolation(.low)
                    .antialiased(false),
                in: imageRect)

            renderGrid(context: context, rc: imageRect, yAxis: self.yAxis, leftLabels: true,
                       formatter: { String(format: "%u", Int($0)) })

            var legendAxis = Array(repeating: 0.0, count: 10)
            for i in 0..<legendAxis.count {
                let s = Double(i) / Double(legendAxis.count - 1)
                legendAxis[i] = s * minVal + (1 - s) * maxVal
            }
            var legendGradient = [Color]()
            for rgb in HeatMap.rgbGradient {
                legendGradient.append(Color(red: Double(rgb[0]) / 255.0,
                                            green: Double(rgb[1]) / 255.0,
                                            blue: Double(rgb[2]) / 255.0))
            }
            let legendRect = CGRect(x: imageRect.maxX + 20, y: imageRect.minY, width: 20, height: imageRect.height)
            context.fill(Path(legendRect),
                         with: GraphicsContext.Shading.linearGradient(Gradient(colors: legendGradient),
                                                                      startPoint: CGPoint(x: legendRect.minX, y: legendRect.minY),
                                                                      endPoint: CGPoint(x: legendRect.minY, y: legendRect.maxY)))
            renderGrid(context: context, rc: legendRect, yAxis: legendAxis, leftLabels: false,
                       formatter: { String(format: "%.2f", $0) })
        }
    }
}
