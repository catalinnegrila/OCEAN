import Foundation
import Network

extension NWEndpoint {
    func toString() -> String {
        switch self {
        case let .service(name: name, type: _, domain: domain, interface: _):
            return "\(domain)\(name)"
        case let .hostPort(host: host, port: port):
            return "tcp://\(host):\(port)"
        case let .url(url):
            return url.absoluteString
        default:
            assertionFailure()
            return debugDescription
        }
    }
}

extension NWConnection {
    func toString() -> String {
        // con.currentPath.remoteEndpoint
        return self.debugDescription
    }
}

class ClientConnection {
    let nwConnection: NWConnection
    let queue = DispatchQueue(label: "ClientConnectionQ")

    init(_ endpoint: NWEndpoint) {
        self.nwConnection = NWConnection(to: endpoint, using: .tcp)
        print(nwConnection.state)
    }
    deinit {
        print("[\(nwConnection.endpoint.toString())]: deinit")
    }

    var onStateUpdateCallback: ((NWConnection.State) -> Void)?
    var onReceiveCallback: ((Data?) -> Void)?

    func start() {
        nwConnection.stateUpdateHandler = { (newState) in
            let endpoint = self.nwConnection.endpoint
            print("[\(endpoint.toString())]: state '\(newState)'")
            switch newState {
            case .waiting, .failed:
                self.nwConnection.cancel()
            default:
                break
            }
            if let onStateUpdateCallback = self.onStateUpdateCallback {
                onStateUpdateCallback(newState)
            }
        }
        setupReceive()
        nwConnection.start(queue: queue)
    }

    private func setupReceive() {
        nwConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
            if let data, !data.isEmpty {
                if let onReceiveCallback = self.onReceiveCallback {
                    onReceiveCallback(data)
                }
            } else if !isComplete {
                self.setupReceive()
            } else if let error {
                print("[\(self.nwConnection.endpoint.toString())]: receive failed with error: \(error)")
            }
        }
    }

    func send(data: Data) {
        nwConnection.send(content: data, completion: .contentProcessed({ error in
            if let error {
                print("[\(self.nwConnection.endpoint.toString())]: send failed with error: \(error)")
            }
        }))
    }

    func stop() {
        nwConnection.cancel()
    }
}
