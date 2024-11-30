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
    func toString(_ latlon: Double) -> String {
        guard !latlon.isNaN else { return "n/a" }
        return String(format: "%.2f", latlon)
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
                    Text(toString(vm.model.d.mostRecentLatitudeScientific)).bold()
                }
                GridRow {
                    Text("Longitude (scientific):")
                    Text(toString(vm.model.d.mostRecentLongitudeScientific)).bold()
                }
                Divider()
                GridRow {
                    Text("Latitude:")
                    Text(vm.model.d.mostRecentLatitude).bold()
                }
                GridRow {
                    Text("Longitude:")
                    Text(vm.model.d.mostRecentLongitude).bold()
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
/*
                GridRow {
                    Text("Model producer:")
                    Text(String(describing: vm.modelProducer!.self))
                }
 */
            }
            Spacer()
        }.frame(width: 350).frame(minHeight: 250)
    }
}

