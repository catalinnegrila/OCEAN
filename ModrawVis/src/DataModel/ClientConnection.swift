import Foundation
import Network

@available(macOS 10.14, *)
class ClientConnection {
    let nwConnection: NWConnection
    let queue = DispatchQueue(label: "Client connection Q")

    init(nwConnection: NWConnection) {
        self.nwConnection = nwConnection
    }

    var onReadyCallback: ((NWConnection) -> Void)? = nil
    var onStopCallback: ((Error?) -> Void)? = nil
    var onReceiveCallback: ((Data?) -> Void)? = nil

    func start() {
        nwConnection.stateUpdateHandler = onStateChange(to:)
        setupReceive()
        nwConnection.start(queue: queue)
    }

    private func setupReceive() {
        nwConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                if let onReceiveCallback = self.onReceiveCallback {
                    onReceiveCallback(data)
                }
            }
            if isComplete {
                self.onConnectionEnded()
            } else if let error {
                self.onConnectionFailed(error: error)
            } else {
                self.setupReceive()
            }
        }
    }

    private func onStateChange(to state: NWConnection.State) {
        print("Connection: \(state)")
        switch state {
        case .waiting(let error):
            onConnectionFailed(error: error)
        case .ready:
            if let onReadyCallback {
                onReadyCallback(nwConnection)
            }
        case .failed(let error):
            onConnectionFailed(error: error)
        default:
            break
        }
    }

    func send(data: Data) {
        nwConnection.send(content: data, completion: .contentProcessed( { error in
            if let error = error {
                self.onConnectionFailed(error: error)
            }
        }))
    }

    func stop() {
        stop(error: nil)
    }

    private func onConnectionFailed(error: Error) {
        print("Connection failed with error: \(error)")
        self.stop(error: error)
    }

    private func onConnectionEnded() {
        self.stop(error: nil)
    }

    private func stop(error: Error?) {
        self.nwConnection.stateUpdateHandler = nil
        self.nwConnection.cancel()
        if let onStopCallback {
            //self.onStopCallback = nil
            onStopCallback(error)
        }
    }
}
