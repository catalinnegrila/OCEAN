import SwiftUI

struct InfoView: View {
    @StateObject public var vm: ViewModel
    func toColor(_ state: ViewModelBroadcaster.State) -> Color {
       switch vm.broadcaster.state {
           case .Starting, .Stopped: return .yellow
           case .Sending: return .green
           case .Error: return .red
       }
    }
    func timeWindowToString() -> String {
        let dt = vm.time_window.1 - vm.time_window.0
        guard dt > 0.0 else { return "n/a" }
        return String(format: "%.2f seconds", dt)
    }
    var body: some View {
        ScrollView {
            Grid {
                GridRow {
                    Text("")
                        .gridColumnAlignment(.trailing)
                        .frame(maxWidth: .infinity)
                    Text("")
                        .gridColumnAlignment(.leading)
                        .frame(maxWidth: .infinity)
                }
                GridRow {
                    Text("Latitude (scientific):")
                    Text(vm.model.d.mostRecentCoords?.lat.describeSci() ?? "n/a").bold()
                }
                GridRow {
                    Text("Longitude (scientific):")
                    Text(vm.model.d.mostRecentCoords?.lon.describeSci() ?? "n/a").bold()
                }
                Divider()
                GridRow {
                    Text("Latitude:")
                    Text(vm.model.d.mostRecentCoords?.lat.describe() ?? "n/a").bold()
                }
                GridRow {
                    Text("Longitude:")
                    Text(vm.model.d.mostRecentCoords?.lon.describe() ?? "n/a").bold()
                }
                Divider()
                GridRow {
                    Text(Model.fishflagFieldName)
                    Text(vm.model.d.fishflag).bold()
                }
                GridRow {
                    Text("Time window:")
                    Text(timeWindowToString()).bold()
                }
                Divider()
                GridRow {
                    Text("Broadcast:")
                    HStack {
                        Text(String(vm.broadcaster.state.rawValue)).bold()
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
                ForEach($vm.graphs, id: \.id) { $graph in
                    GridRow {
                        Text(graph.id)
                        HStack {
                            if graph.visible {
                                Text(String("Visible")).bold()
                                    .foregroundColor(.green)
                                Button("Hide") {
                                    graph.setVisible(fishflag: vm.model.d.fishflag, visible: false)
                                }
                            } else {
                                Text(String("Hidden")).bold()
                                    .foregroundColor(.blue)
                                Button("Show") {
                                    graph.setVisible(fishflag: vm.model.d.fishflag, visible: true)
                                }
                            }
                        }
                    }
                }
            }
            Spacer()
        }.frame(width: 350).frame(minHeight: 250)
    }
}

