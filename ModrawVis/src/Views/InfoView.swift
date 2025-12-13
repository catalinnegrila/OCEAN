import Foundation
import SwiftUI

/* OS 15+
struct InfoWindowToggle: View {
    @StateObject var vm: ViewModel
    var body: some View {
        WindowVisibilityToggle(windowID: NSWindowUtils.InfoWindowId)
            .keyboardShortcut("i", modifiers: [.command])
            .disabled(vm.model.isEmpty)
    }
}
*/

struct InfoWindowButtonToggle: View {
    @StateObject var vm: ViewModel
    var body: some View {
        Button(action: {
            NSWindowUtils.toggleInfoWindow()
        }) {
            Label("Info", systemImage: "info.circle")
        }
    }
}

struct InfoWindowMenuToggle: View {
    @StateObject var vm: ViewModel
    var body: some View {
        Button("Show/Hide Info") {
                NSWindowUtils.toggleInfoWindow()
            }
            .keyboardShortcut("i", modifiers: [.command])
    }
}

struct InfoView: View {
    @StateObject public var vm: ViewModel

    func toColor(_ state: ViewModelBroadcaster.State) -> Color {
        switch vm.broadcaster.state {
            case .Starting, .Stopped: return .blue
            case .Sending: return .green
            case .Error: return .red
        }
    }
    func timeWindowToString() -> String {
        let dt = vm.time_window.1 - vm.time_window.0
        guard dt > 0.0 else { return "n/a" }
        return String(format: "%.2f seconds", dt)
    }
    func nowToString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = Date(timeIntervalSince1970: vm.time_window.1)
        return dateFormatter.string(from: date)
    }

    var body: some View {
        ScrollView {
            Grid {
                GridRow {
                    Text("Fishflag:").bold()
                    Text(vm.model.d.fishflag)
                }
                Divider()
                GridRow {
                    Text("")
                        .gridColumnAlignment(.trailing)
                        .frame(maxWidth: .infinity)
                    Text("")
                        .gridColumnAlignment(.leading)
                        .frame(maxWidth: .infinity)
                }
                GridRow {
                    Text("Latitude (scientific):").bold()
                    Text(vm.model.d.mostRecentCoords?.lat.describeSci() ?? "n/a")
                }
                GridRow {
                    Text("Longitude (scientific):").bold()
                    Text(vm.model.d.mostRecentCoords?.lon.describeSci() ?? "n/a")
                }
                Divider()
                GridRow {
                    Text("Latitude:").bold()
                    Text(vm.model.d.mostRecentCoords?.lat.describe() ?? "n/a")
                }
                GridRow {
                    Text("Longitude:").bold()
                    Text(vm.model.d.mostRecentCoords?.lon.describe() ?? "n/a")
                }
                Divider()
                GridRow {
                    Text("Current time:").bold()
                    Text(nowToString())
                }
                GridRow {
                    Text("Time window:").bold()
                    Text(timeWindowToString())
                }
                Divider()
                GridRow {
                    Text("Broadcast:").bold()
                    HStack {
                        Text(String(vm.broadcaster.state.rawValue))
                            .foregroundColor(toColor(vm.broadcaster.state))
                        switch vm.broadcaster.state {
                        case .Starting, .Sending, .Error:
                            Button("Stop") {
                                vm.broadcaster.state = .Stopped
                            }
                        case .Stopped:
                            Button("Start") {
                                vm.broadcaster.state = .Sending
                            }
                        }
                    }
                }
                Divider()
                GridRow {
                    Text("Visibility presets:").bold()
                    Picker("", selection: $vm.model.d.fishflag) {
                        Text("EPSI").tag("EPSI")
                        Text("FCTD").tag("FCTD")
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                GridRow {
                    Spacer()
                    Button {
                        for i in 0..<vm.graphs.count {
                            vm.graphs[i].resetToUserDefaultFor(preset: vm.model.d.fishflag)
                        }
                    } label: {
                        Text("Reset to defaults").frame(maxWidth: .infinity)
                    }.gridCellUnsizedAxes(.horizontal)
                }
                ForEach($vm.graphs, id: \.label) { $graph in
                    GridRow {
                        Text("\(graph.label):").bold()
                        HStack {
                            if graph.visible {
                                Text(String("Visible"))
                                    .foregroundColor(.green)
                                Button("Hide") {
                                    graph.setVisibleFor(preset: vm.model.d.fishflag, visible: false)
                                }
                            } else {
                                Text(String("Hidden"))
                                    .foregroundColor(.blue)
                                Button("Show") {
                                    graph.setVisibleFor(preset: vm.model.d.fishflag, visible: true)
                                }
                            }
                        }
                    }
                }
            }.padding(15.0)
        }.frame(width: 350).frame(minHeight: 500)
    }
}

