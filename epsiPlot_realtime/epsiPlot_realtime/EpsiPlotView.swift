import SwiftUI

struct EpsiPlotView: View {
    var dataModel : EpsiDataModel
/*
    func generateImage() -> (NSImage, Double, Double) {
        let fieldName = "t1_volt"
        let origData = mat.getMatrixDouble2(name: fieldName)
        print("\(fieldName): \(origData.count)x\(origData[0].count)")

        let width = 512
        let height = 256
        let displayData = EpsiDataModel.shortenMat1(mat: EpsiDataModel.mat2ToMat1(mat: origData), newCount: width)

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

        let (minVal, maxVal) = EpsiDataModel.getMinMaxMat1(mat: EpsiDataModel.mat2ToMat1(mat: origData))
        print("MinVal: \(minVal), MaxVal: \(maxVal)")

        for colIndex in 0..<width {
            let normVal = (displayData[colIndex] - minVal) / (maxVal - minVal)
            let rowIndex = Int(Double(height) * normVal)
            let offset = (colIndex + rowIndex * width) * 4
            pixelBuffer[offset] = 112
            pixelBuffer[offset+1] = 180
            pixelBuffer[offset+2] = 180
            pixelBuffer[offset+3] = 255
        }

        let image = NSImage(size: NSSize(width: width, height: height))
        image.addRepresentation(bitmapImageRep)
        return (image, minVal, maxVal)
    }
*/
    init() {
        self.dataModel = try! EpsiDataModelModraw()
        //self.dataModel = try! EpsiDataModelMat()
    }

    var body: some View {
        VStack {
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                chart
                    .padding()
                    .frame(width: 700, alignment: .topLeading)
            }
            //.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            //.border(.black, width: 2)
            //.padding()
        }
        .navigationTitle("Realtime EPSI")
    }

    private func renderGrid(context: GraphicsContext, rc: CGRect, yAxis: [Double], leftLabels: Bool, formatter: (Double) -> String) {
        let nub = 7.0
        let thickLine = 1.5
        let textGap = 5.0

        let yAxisMin = yAxis[0]
        let yAxisMax = yAxis[yAxis.count - 1]

        var yOffset = [CGFloat](repeating: 0.0, count: yAxis.count)
        for i in 0..<yAxis.count {
            //let s = Double(i) / Double(yAxis.count - 1)
            let s = (yAxis[i] - yAxisMin) / (yAxisMax - yAxisMin)
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
    private func render1D(context: GraphicsContext, rc: CGRect, yAxisTop: Double, yAxisBottom: Double, data: [Double], color: Color) {

        var displayData = EpsiDataModel.shortenMat1(mat: data, newCount: Int(rc.maxX - rc.minX))
        for i in 0..<displayData.count {
            displayData[i] = rc.maxY - Double(rc.maxY - rc.minY) * (displayData[i] - yAxisBottom) / (yAxisTop - yAxisBottom)
        }

        context.stroke(Path { path in
            path.move(to: CGPoint(x: rc.minX, y: displayData[0]))
            for i in 1..<displayData.count {
                    path.addLine(to: CGPoint(x: rc.minX + CGFloat(i), y: displayData[i]))
                }
            },
            with: .color(color),
            lineWidth: 2)
    }

    private var chart: some View {
        return Canvas{ context, size in
            print("W: \(size.width) H: \(size.height)")
            //let (image, minVal, maxVal) = generateImage()
            //let imageRect = CGRect(x: 30, y: 20, width: image.size.width, height: image.size.height)
            let gap = CGFloat(20);
            let height = CGFloat(100)
            var rect = CGRect(x: 30, y: gap/2, width: 545, height: height)
            /*context.draw(
                Image(nsImage: image)
                    .interpolation(.low)
                    .antialiased(false),
                in: imageRect)
            print("minVal: \(minVal) maxVal: \(maxVal)")*/

            // EPSI t1, t2
            let t1_data2 = dataModel.getChannel(name: "epsi.t1_volt")
            let t1_mean = EpsiDataModel.mean(mat: t1_data2)
            let t1_data = EpsiDataModel.offsetMat1(mat: t1_data2, offset: -t1_mean)
            let (t1_minVal, t1_maxVal) = EpsiDataModel.getMinMaxMat1(mat: t1_data)
            let t1_color = Color(red: 114/255, green: 182/255, blue: 182/255)

            let t2_data2 = dataModel.getChannel(name: "epsi.t2_volt")
            let t2_mean = EpsiDataModel.mean(mat: t2_data2)
            let t2_data = EpsiDataModel.offsetMat1(mat: t2_data2, offset: -t2_mean)
            let (t2_minVal, t2_maxVal) = EpsiDataModel.getMinMaxMat1(mat: t2_data)
            let t2_color = Color(red: 21/255, green: 53/255, blue: 136/255)

            let t_minVal = min(t1_minVal, t2_minVal)
            let t_maxVal = max(t1_maxVal, t2_maxVal)

            renderGrid(context: context, rc: rect, yAxis: [t_minVal, (t_minVal + t_maxVal) / 2, t_maxVal], leftLabels: true,
                       formatter: { String(format: "%.2f", Double($0)) })

            render1D(context: context, rc: rect, yAxisTop: t_maxVal, yAxisBottom: t_minVal, data: t1_data, color: t1_color)
            render1D(context: context, rc: rect, yAxisTop: t_maxVal, yAxisBottom: t_minVal, data: t2_data, color: t2_color)

            // EPSI s1, s2
            rect = rect.offsetBy(dx: 0, dy: rect.height + gap);
            let s1_data2 = dataModel.getChannel(name: "epsi.s1_volt")
            let s1_rms = EpsiDataModel.rms(mat: s1_data2)
            let s1_data = EpsiDataModel.offsetMat1(mat: s1_data2, offset: -s1_rms)
            let (s1_minVal, s1_maxVal) = EpsiDataModel.getMinMaxMat1(mat: s1_data)
            let s1_color = Color(red: 88/255, green: 143/255, blue: 92/255)

            let s2_data2 = dataModel.getChannel(name: "epsi.s2_volt")
            let s2_rms = EpsiDataModel.rms(mat: s2_data2)
            let s2_data = EpsiDataModel.offsetMat1(mat: s2_data2, offset: -s2_rms)
            let (s2_minVal, s2_maxVal) = EpsiDataModel.getMinMaxMat1(mat: s2_data)
            let s2_color = Color(red: 189/255, green: 219/255, blue: 154/255)

            let s_minVal = min(s1_minVal, s2_minVal)
            let s_maxVal = max(s1_maxVal, s2_maxVal)

            renderGrid(context: context, rc: rect, yAxis: [s_minVal, (s_minVal + s_maxVal) / 2, s_maxVal], leftLabels: true,
                       formatter: { String(format: "%.1f", Double($0)) })

            render1D(context: context, rc: rect, yAxisTop: s_maxVal, yAxisBottom: s_minVal, data: s1_data, color: s1_color)
            render1D(context: context, rc: rect, yAxisTop: s_maxVal, yAxisBottom: s_minVal, data: s2_data, color: s2_color)

            // EPSI a1
            rect = rect.offsetBy(dx: 0, dy: rect.height + gap);
            var halfRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height / 2)
            
            let a1_data = dataModel.getChannel(name: "epsi.a1_g")
            let (a1_minVal, a1_maxVal) = EpsiDataModel.getMinMaxMat1(mat: a1_data)
            let a1_color = Color(red: 129/255, green: 39/255, blue: 120/255)

            renderGrid(context: context, rc: halfRect, yAxis: [a1_minVal, (a1_minVal + a1_maxVal) / 2, a1_maxVal], leftLabels: true,
                       formatter: { String(format: "%.1f", Double($0)) })
            render1D(context: context, rc: halfRect, yAxisTop: a1_maxVal, yAxisBottom: a1_minVal, data: a1_data, color: a1_color)

            // EPSI a2, a3
            halfRect = halfRect.offsetBy(dx: 0, dy: halfRect.height)

            let a2_data = dataModel.getChannel(name: "epsi.a2_g")
            let (a2_minVal, a2_maxVal) = EpsiDataModel.getMinMaxMat1(mat: a2_data)
            let a2_color = Color(red: 220/255, green: 86/255, blue: 77/255)

            let a3_data = dataModel.getChannel(name: "epsi.a3_g")
            let (a3_minVal, a3_maxVal) = EpsiDataModel.getMinMaxMat1(mat: a3_data)
            let a3_color = Color(red: 240/255, green: 207/255, blue: 140/255)

            let a_minVal = min(a2_minVal, a3_minVal)
            let a_maxVal = max(a2_maxVal, a3_maxVal)

            renderGrid(context: context, rc: halfRect, yAxis: [a_minVal, (a_minVal + a_maxVal) / 2, a_maxVal], leftLabels: false,
                       formatter: { String(format: "%.1f", Double($0)) })
            render1D(context: context, rc: halfRect, yAxisTop: a_maxVal, yAxisBottom: a_minVal, data: a2_data, color: a2_color)
            render1D(context: context, rc: halfRect, yAxisTop: a_maxVal, yAxisBottom: a_minVal, data: a3_data, color: a3_color)

            // CTD T
            rect = rect.offsetBy(dx: 0, dy: rect.height + gap);
            
            let T_data = dataModel.getChannel(name: "ctd.T")
            let (T_minVal, T_maxVal) = EpsiDataModel.getMinMaxMat1(mat: T_data)
            let T_color = Color(red: 212/255, green: 35/255, blue: 36/255)

            renderGrid(context: context, rc: rect, yAxis: [T_minVal, (T_minVal + T_maxVal) / 2, T_maxVal], leftLabels: true,
                       formatter: { String(format: "%.1f", Double($0)) })
            render1D(context: context, rc: rect, yAxisTop: T_maxVal, yAxisBottom: T_minVal, data: T_data, color: T_color)

            // CTD S
            rect = rect.offsetBy(dx: 0, dy: rect.height + gap);
            
            let S_data = dataModel.getChannel(name: "ctd.S")
            let (S_minVal, S_maxVal) = EpsiDataModel.getMinMaxMat1(mat: S_data)
            let S_color = Color(red: 82/255, green: 135/255, blue: 187/255)

            renderGrid(context: context, rc: rect, yAxis: [S_minVal, (S_minVal + S_maxVal) / 2, S_maxVal], leftLabels: true,
                       formatter: { String(format: "%.1f", Double($0)) })
            render1D(context: context, rc: rect, yAxisTop: S_maxVal, yAxisBottom: S_minVal, data: S_data, color: S_color)

            // CTD dPdt
            rect = rect.offsetBy(dx: 0, dy: rect.height + gap);
            
            let dPdt_data2 = dataModel.getChannel(name: "ctd.dPdt")
            let dPdt_data = EpsiDataModel.movmean(mat: dPdt_data2, window: 100)
            let (dPdt_minVal, dPdt_maxVal) = EpsiDataModel.getMinMaxMat1(mat: dPdt_data)
            let dPdt_color = Color(red: 233/255, green: 145/255, blue: 195/255)

            renderGrid(context: context, rc: rect, yAxis: [dPdt_maxVal, 0.0, /*(dPdt_minVal + dPdt_maxVal) / 2,*/ dPdt_minVal], leftLabels: true,
                       formatter: { String(format: "%.1f", Double($0)) })
            render1D(context: context, rc: rect, yAxisTop: dPdt_minVal, yAxisBottom: dPdt_maxVal, data: dPdt_data, color: dPdt_color)

            // CTD P
            rect = rect.offsetBy(dx: 0, dy: rect.height + gap);
            
            let P_data = dataModel.getChannel(name: "ctd.P")
            let (P_minVal, P_maxVal) = EpsiDataModel.getMinMaxMat1(mat: P_data)
            let P_color = Color(red: 24/255, green: 200/255, blue: 24/255)

            renderGrid(context: context, rc: rect, yAxis: [P_minVal, (P_minVal + P_maxVal) / 2, P_maxVal], leftLabels: true,
                       formatter: { String(format: "%.1f", Double($0)) })
            render1D(context: context, rc: rect, yAxisTop: P_maxVal, yAxisBottom: P_minVal, data: P_data, color: P_color)

            // TODO: add labels to the left for each graph
            // TODO: add labels inside about lines and offsets
            // TODO: render time
        }
    }
}
