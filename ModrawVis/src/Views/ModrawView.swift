import SwiftUI

struct ModrawView: View {
    @Environment(\.colorScheme) var colorScheme

    @State private var refreshView = false
    let refreshTimer = Timer.publish(every: 1.0/30, on: .main, in: .common).autoconnect()

    @StateObject var vm: ViewModel
    // TODO: find a less hacky way to size the Canvas to the content
    @State var newHeight = 0.0

    var body: some View {
        ScrollView {
            VStack {
                Canvas { context, size in
                    //let stopwatch = Stopwatch(label: "Render")
                    render(context: context, size: size)
                    //stopwatch.printElapsed()
                }
                .id(refreshView)
                .frame(minWidth: 300)
                .frame(height: newHeight)
                .navigationTitle($vm.model.title)
                .onAppear() {
                    newHeight = getRenderHeight()
                }
                .onReceive(refreshTimer) { _ in
                    Task {
                        //let stopwatch = Stopwatch(label: "Update")
                        if (vm.update()) {
                            newHeight = getRenderHeight()
                            //stopwatch.printElapsed()
                            refreshView.toggle()
                        }
                    }
                }
            }
        }/*.toolbar {
            ToolbarItem() {
                InfoWindowToggle(vm: vm)
            }
        }*/
    }
        
    let plotHeight = 100.0
    let timelineLabelsHeight = 10.0 + 40.0
    let vgap = 25.0

    func getRenderHeight() -> Double {
        var plotCount = 0
        for i in 0..<vm.graphs.count {
            if vm.graphs[i].visible {
                plotCount += 1
            }
        }
        return vgap + Double(plotCount) * (plotHeight + vgap) + timelineLabelsHeight
    }
    
    func render(context: GraphicsContext, size: CGSize) {
        let timeTickCount = Int(size.width / 200)
        var xAxis : [Double] = []
        for i in 0..<timeTickCount {
            xAxis.append(Double(i) / Double(timeTickCount - 1))
        }

        let gr = GraphRenderer(context: context, isDarkTheme: colorScheme == .dark, xAxis: xAxis)
        gr.rect = CGRect(x: 0.0, y: vgap, width: size.width, height: plotHeight)
        gr.rect = gr.rect.inset(gr.leftLabelsWidth, 0.0, gr.rightLabelsWidth, 0.0)

        var visibleGraphs = 0
        for graph in vm.graphs {
            if graph.visible {
                graph.renderer(gr)
                gr.drawMainLabel(graph.label)
                gr.advanceRectY(vgap)
                visibleGraphs += 1
            }
        }

        // Time labels
        guard visibleGraphs > 0 else { return }
        guard vm.time_window.0 != vm.time_window.1 else { return }

        let textHeight = context.resolve(Text("00:00:00").font(gr.font)).measure(in: CGSize(width: .max, height: .max)).height
        var y = gr.rect.minY - vgap/2

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        for i in 0..<xAxis.count {
            let s = xAxis[i]
            let time_s = (1 - s) * vm.time_window.0 + s * vm.time_window.1
            let date = Date(timeIntervalSince1970: time_s)
            let label = dateFormatter.string(from: date)
            
            context.draw(Text(label).font(gr.font),
                         at: CGPoint(x: gr.lerpToX(s), y: y),
                         anchor: .center)
        }
        if !xAxis.isEmpty {
            y += textHeight
        }
        if let pos = vm.model.d.mostRecentCoords {
            func drawPos(_ text: String) {
                context.draw(Text(text).font(gr.font).bold(),
                             at: CGPoint(x: gr.rect.maxX, y: y),
                             anchor: .topTrailing)
                y += textHeight
            }
            
            drawPos(pos.describe())
            drawPos(pos.describeSci())
        }
    }
}
