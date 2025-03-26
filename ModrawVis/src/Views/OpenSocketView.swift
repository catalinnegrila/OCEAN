import SwiftUI
import Network

/* OS 15+
struct CustomAddressView: View {
    @Binding var customAddress: String
    @State private var showInvalidAddress = false
    var checkConnection: (NWEndpoint)->Void
    func isValid() -> Bool {
        let pattern = "(25[0-5]|2[0-4]\\d|1\\d{2}|\\d{1,2})\\.(25[0-5]|2[0-4]\\d|1\\d{2}|\\d{1,2})\\.(25[0-5]|2[0-4]\\d|1\\d{2}|\\d{1,2})\\.(25[0-5]|2[0-4]\\d|1\\d{2}|\\d{1,2})(\\:(\\d{1,5}))?"
        let regexText = NSPredicate(format: "SELF MATCHES %@", pattern)
        return regexText.evaluate(with: customAddress)
    }
    func submit() {
        if isValid() {
            let comp = customAddress.components(separatedBy: ":")
            let host = comp[0]
            let port = NWEndpoint.Port(comp.count == 2 ? comp[1] : OpenSocketView.ModrawServerDefaultPort)
            let endpoint = NWEndpoint.hostPort(host: .init(host), port: port!)
            checkConnection(endpoint)
            customAddress = ""
        } else {
            showInvalidAddress = true
        }
    }

    var body: some View {
        HStack {
            Text("IP:")
            TextField("Server IP address", text: $customAddress)
                .tint(.black)
                .onSubmit {
                    submit()
                }
            Button("+") {
                submit()
            }
            .disabled(customAddress.isEmpty)
        }
        .alert(isPresented: $showInvalidAddress) {
            Alert(
                title: Text("Invalid Server Address"),
                message: Text("'\(customAddress)' is not a valid IP address,\ne.g. 192.168.1.168")
            )
        }
    }
}

class ConnectionInfo {
    var label: String { get {endpoint.toString()}}
    var badge: String
    var endpoint: NWEndpoint
    var remoteEndpoint: NWEndpoint

    init(badge: String, endpoint: NWEndpoint) {
        self.badge = badge
        self.endpoint = endpoint
        self.remoteEndpoint = endpoint
    }
    init(badge: String, host: String) {
        self.badge = badge
        let host = NWEndpoint.Host(host)
        let port = NWEndpoint.Port(OpenSocketView.ModrawServerDefaultPort)
        self.endpoint = NWEndpoint.hostPort(host: host, port: port!)
        self.remoteEndpoint = self.endpoint
    }
}

extension Array<ConnectionInfo> {
    public mutating func remove(label: String) {
        if let i = firstIndex(where: { $0.remoteEndpoint.toString() == label }) {
            remove(at: i)
        }
    }
}

struct OpenSocketLabel: View {
    var ci: ConnectionInfo
    init(_ ci: ConnectionInfo) {
        self.ci = ci
    }
    func image() -> String {
        return (ci.badge == "Bonjour") ? "bonjour" : "rectangle.connected.to.line.below"
    }
    var body: some View {
        Label(ci.label, systemImage: image())
            .id(ci.label)
            .badge(ci.badge)
            .listRowSeparator(.visible)
    }
}

struct OpenSocketView: View {
    @Environment(\.dismiss) var dismiss
    @State private var connections = [ConnectionInfo]()
    @State private var unavailable = [ConnectionInfo]()
    @State private var checkConnectionTasks = [String: (ConnectionInfo, ClientConnection)]()
    @State private var selectedLabel: String?
    @State private var customAddress = ""
    @State private var showCheckConnectionTasksProgress = false
    @FocusState private var isListFocused: Bool
    static let ModrawServerDefaultPort = "31415"
    let browseBonjourService = BrowseBonjourService("ModrawServer")

    func removeConnection(label: String) {
        connections.remove(label: label)
        unavailable.remove(label: label)
    }
    func checkConnection(_ ci: ConnectionInfo) {
        let connection = ClientConnection(ci.endpoint)
        removeConnection(label: ci.label)
        connection.onStateUpdateCallback = { [weak connection](newState: NWConnection.State) -> Void in
            DispatchQueue.main.async {
                switch newState {
                case .ready:
                    if let endpoint = connection?.nwConnection.currentPath?.remoteEndpoint {
                        removeConnection(label: endpoint.toString())
                    }
                    connections.append(ci)
                    connection?.stop()
                case .waiting, .failed:
                    unavailable.append(ci)
                case .cancelled:
                    checkConnectionTasks.removeValue(forKey: ci.label)
                    showCheckConnectionTasksProgress = !checkConnectionTasks.isEmpty
                default:
                    break
                }
            }
        }
        checkConnectionTasks[ci.label] = (ci, connection)
        showCheckConnectionTasksProgress = true
        connection.start()
        if checkConnectionTasks.count == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                for checkConnectionTask in checkConnectionTasks.values {
                    let ci = checkConnectionTask.0
                    ci.badge += ", timeout"
                    unavailable.append(ci)
                    let connection = checkConnectionTask.1
                    connection.stop()
                }
            }
        }
    }
    func checkBonjour() {
        browseBonjourService.onFound = { endpoint in
            DispatchQueue.main.async {
                //self.connections.append(ConnectionInfo(badge: "Bonjour", endpoint: endpoint))
                checkConnection(ConnectionInfo(badge: "Bonjour", endpoint: endpoint))
            }
        }
        browseBonjourService.onStateUpdate = { newState in
            switch newState {
            case .failed(let error):
                print("NWBrowser: failed with error: \(error.localizedDescription)")
            //case .cancelled:
                //self.decBackgroundTasks()
            default:
                break
            }
        }
        //incBackgroundTasks()
        browseBonjourService.start()
    }

    var body: some View {
        VStack(spacing: 8) {
            CustomAddressView(customAddress: $customAddress, checkConnection: { endpoint in
                checkConnection(ConnectionInfo(badge: "custom IP", endpoint: endpoint))
            })
            List(selection: $selectedLabel) {
                Section(header: Text("Available services")) {
                    ForEach($connections, id: \.label) { $ci in
                        OpenSocketLabel(ci)
                    }
                }
            }
            .focused($isListFocused)
            .onChange(of: isListFocused) { _, isFocused in
                if !isFocused {
                    selectedLabel = nil
                }
            }
            List() {
                Section(header: Text("Not responding")) {
                    ForEach($unavailable, id: \.label) { $ci in
                        OpenSocketLabel(ci)
                    }
                }
            }
            HStack {
                Spacer()
                Button("Cancel") {
                    browseBonjourService.stop()
                    dismiss()
                    //ModalWindow.current.endModal(withCode: .cancel)
                }
                Button("Connect") {
                    print("Connect to \($selectedLabel)")
                    browseBonjourService.stop()
                    dismiss()
                    //ModalWindow.current.endModal(withCode: .OK)
                }
                .disabled($selectedLabel.wrappedValue == nil)
                .buttonStyle(BorderedProminentButtonStyle())
            }
        }
        .padding(16)
        .frame(width: 400, height: 400)
        .task {
            checkBonjour()
            checkConnection(ConnectionInfo(badge: "DEV1", host: "192.168.1.168"))
            checkConnection(ConnectionInfo(badge: "localhost", host: "127.0.0.1"))
            if let ip = getWiFiAddress() {
                checkConnection(ConnectionInfo(badge: "local IP", host: ip))
            }
        }
        .sheet(isPresented: $showCheckConnectionTasksProgress) {
            VStack(spacing: 8) {
                HStack {
                    ProgressView().scaleEffect(0.75)
                    Text("Searching for ModrawServer on the network...")
                }
                Button("Cancel") {
                    for checkConnectionTask in checkConnectionTasks.values {
                        let ci = checkConnectionTask.0
                        ci.badge += ", cancelled"
                        unavailable.append(ci)
                        let connection = checkConnectionTask.1
                        connection.stop()
                    }
                }
            }.padding(16)
        }
    }
}
*/
