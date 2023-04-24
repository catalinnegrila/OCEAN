//
// Copyright © 2022 Swift Charts Examples.
// Open Source - MIT License

import SwiftUI
import Charts

struct HeatMap: View {
    @State private var numRows = 20
    @State private var numCols = 20
    
    var gradientColors: [Color] = [.blue, .green, .yellow, .orange, .red]

    var image : NSImage

    private static let rgbGradient : [[UInt8]] = [[0, 0, 255], [0, 255, 0], [0, 255, 255], [255, 166, 0], [255, 0, 0]]
    private static func interpolateValue(_ v : Double, _ ch : Int) -> UInt8
    {
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

    init() {
        // For fctd_grid, FCTDgrid.time is the x-axis, FCTDgrid.depth is the y-axis, and any of the 2D variables are the color.
        // For epsi_grid, GRID.dnum is the x-axis, GRID.z is the y-axis, and any of the 2D variables are the color.
/*
        let mat = MatData(path: "epsi_grid_uncompressed.mat")
        let xAxis = mat.getMatrixDouble2(name: "dnum")
        let yAxis = mat.getMatrixDouble2(name: "z")
        let colorData = mat.getMatrixDouble2(name: "w")
*/
        let mat = MatData(path: "fctd_grid_uncompressed.mat")
        let xAxis = mat.getMatrixDouble2(name: "time")
        let yAxis = mat.getMatrixDouble2(name: "depth")
        let colorData = mat.getMatrixDouble2(name: "density")

        print("x: \(xAxis.count)x\(xAxis[0].count)")
        print("y: \(yAxis.count)x\(yAxis[0].count)")
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
                assert(!val.isNaN)
                minVal = fmin(minVal, val)
                maxVal = fmax(maxVal, val)
            }
        }
        print("MinVal: \(minVal), MaxVal: \(maxVal)")

        for rowIndex in 0..<height {
            for colIndex in 0..<width {
                /*
                let maxValue = height - 1
                let variance = Double.random(in: 0..<0.25) - 0.125
                var value = Double(rowIndex) / Double(maxValue) + variance
                value = min(max(value, 0.0), 1.0)
                 */
                //let val = (colorData[rowIndex][colIndex] - minVal) / (maxVal - minVal)
                let val = colorData[rowIndex][colIndex]
                pixelBuffer[offset] = HeatMap.interpolateValue(val, 0)
                pixelBuffer[offset+1] = HeatMap.interpolateValue(val, 1)
                pixelBuffer[offset+2] = HeatMap.interpolateValue(val, 2)
                pixelBuffer[offset+3] = 255
                offset += 4
            }
        }
        
        self.image = NSImage(size: NSSize(width: width, height: height))
        self.image.addRepresentation(bitmapImageRep)
/*
        let frame = NSRect(x: 0, y: 0, width: width, height: height)
        self.image = NSImage(size: NSSize(width: width, height: height), flipped: false, drawingHandler: { (_) -> Bool in
            return bitmapImageRep.draw(in: frame)
        })
        self.image.cacheMode = NSImage.CacheMode.never
*/
    }

    var body: some View {
        chart
            .navigationTitle("Heatmap")
	}

    private var chart: some View {
        return Chart {
            RectangleMark(
                xStart: PlottableValue.value("xStart", 0),
                xEnd: PlottableValue.value("xEnd", 100),
                yStart: PlottableValue.value("yStart", 0),
                yEnd: PlottableValue.value("yEnd", 100)
            )
            .alignsMarkStylesWithPlotArea(true)
            .foregroundStyle( .image(Image(nsImage: self.image)))
        }
        .aspectRatio(image.size.width / image.size.height, contentMode: .fit)
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: Int(image.size.height / 100),
                                         roundLowerBound: false,
                                         roundUpperBound: false)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(centered: true)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: Int(image.size.width / 100),
                                         roundLowerBound: false,
                                         roundUpperBound: false)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(centered: true)
            }
        }
        .chartYAxis(.automatic)
        .chartXAxis(.automatic)
    }
}
