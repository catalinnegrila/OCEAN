import SwiftUI
import Network

struct OpenSocketView: View {
    struct ConnectionInfo {
        var label: String { get {endpoint.toString()}}
        var badge: String
        var endpoint: NWEndpoint
    }
    struct OpenSocketLabel: View {
        let label: String
        let badge: String
        let image = "rectangle.connected.to.line.below"
        var body: some View {
            Label(label, systemImage: badge == "Bonjour" ? "bonjour" : image)
                .id(label)
                .badge(badge)
                .listRowSeparator(.visible)
        }
    }
    @State private var connections = [ConnectionInfo]()
    @State private var unavailable = [ConnectionInfo]()
    @State private var selectedLabel: String?
    @State private var customIP = "tcp://"
    @State private var backgroundTasks = 0
    @FocusState private var isListFocused: Bool

    func checkConnection(_ ci: ConnectionInfo) {
        if let i = connections.firstIndex(where: { $0.label == ci.label }) {
            connections.remove(at: i)
        }
        if let i = unavailable.firstIndex(where: { $0.label == ci.label }) {
            unavailable.remove(at: i)
        }
        let connection = ClientConnection(ci.endpoint)
        connection.onStateUpdateCallback = { [weak connection](newState: NWConnection.State) -> Void in
            DispatchQueue.main.async {
                switch newState {
                case .ready:
                    self.connections.append(ci)
                    connection?.stop()
                case .waiting, .failed:
                    self.unavailable.append(ci)
                case .cancelled:
                    self.backgroundTasks -= 1
                default:
                    break
                }
            }
        }
        backgroundTasks += 1
        connection.start()
    }
    func checkBonjour() {
        let discoverService = BrowseBonjourService("ModrawServer")
        discoverService.onFound = { endpoint in
            DispatchQueue.main.async {
                self.connections.append(ConnectionInfo(badge: "Bonjour", endpoint: endpoint))
                discoverService.stop()
            }
        }
        discoverService.onStateUpdate = { newState in
            switch newState {
            case .failed(let error):
                print("NWBrowser: failed with error: \(error.localizedDescription)")
            case .cancelled:
                self.backgroundTasks -= 1
            default:
                break
            }
        }
        backgroundTasks += 1
        discoverService.start()
    }
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("IP:")
                TextField("Enter a custom address:", text: $customIP)
                    .tint(.black)
                Button("Check") {
                    if let url = URL(string: customIP) {
                        let endpoint = NWEndpoint.url(url)
                        print(endpoint)
                        checkConnection(ConnectionInfo(badge: "custom IP", endpoint: endpoint))
                    }
                }
            }
            List(selection: $selectedLabel) {
                Section(header: Text("Available services")) {
                    ForEach($connections, id: \.label) { $ci in
                        OpenSocketLabel(label: ci.label, badge: ci.badge)
                    }
                }
            }
            .border(.green)
            .onChange(of: selectedLabel) { _, newValue in
                if let newValue {
                    //customIP = newValue
                    print(newValue)
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
                        OpenSocketLabel(label: ci.label, badge: ci.badge)
                    }
                }
            }.border(.red)
            HStack {
                if backgroundTasks > 0 {
                    ProgressView()
                    Text("Scanning the local network for ModrawServer using Bonjour...")
                }
            }.frame(height: 40)
            //Spacer()
            HStack {
                Spacer()
                Button("Cancel") {
                    //ModalWindow.current.endModal(withCode: .cancel)
                }
                Button("Connect") {
                    print("Connect to \($selectedLabel)")
                    //ModalWindow.current.endModal(withCode: .OK)
                }
                .disabled($selectedLabel.wrappedValue == nil)
                .buttonStyle(BorderedProminentButtonStyle())
            }
        }
        .padding(16)
        .frame(width: 400, height: 400)
        .task {
            checkConnection(ConnectionInfo(badge: "DEV1", endpoint: NWEndpoint.hostPort(host: "192.168.1.168", port: 31415)))
            checkConnection(ConnectionInfo(badge: "localhost", endpoint: NWEndpoint.hostPort(host: "127.0.0.1", port: 31415)))
            if let ip = getWiFiAddress() {
                checkConnection(ConnectionInfo(badge: "local IP", endpoint: NWEndpoint.hostPort(host: .init(ip), port: 31415)))
            }
            checkBonjour()
        }
    }
}
