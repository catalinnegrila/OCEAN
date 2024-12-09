import Foundation
import Network

class StreamingSocketModelProducer: StreamingModelProducer {
    var connection: ClientConnection! = nil
    var connectionName: String! = nil
    var retryCount = 0
    var connectionStarted = false

    func retryConnection(model: Model) {
    }
    override func start(model: Model) {
        retryCount = 0
        connectionStarted = true
        retryConnection(model: model)
    }
    override func stop() {
        connectionStarted = false
        if connection != nil {
            connection!.stop()
            connection = nil
        }
    }
    func openConnection(model: Model, endpoint: NWEndpoint) {
        connectionName = endpoint.debugDescription
        connection = ClientConnection(endpoint)
        print("\(connectionName!): created")
        connection.onStateUpdateCallback = { [weak self](newState: NWConnection.State) -> Void in
            switch newState {
            case .ready:
                if let path = self?.connection.nwConnection.currentPath, let endpoint = path.remoteEndpoint {
                    model.title = "Connected to \(endpoint.toString())"
                }
            case .cancelled:
                DispatchQueue.main.async {
                    self?.epsiModrawParser = nil
                }
                if self?.connectionStarted ?? false {
                    self!.retryCount += 1
                    DispatchQueue.main.async {
                        model.title = "Connection to \(self!.connectionName!) stopped. Retrying (attempt \(self!.retryCount))..."
                    }
                    sleep(1)
                    self!.retryConnection(model: model)
                }
            default:
                break
            }
        }
        connection.onReceiveCallback = { (data: Data?) -> Void in
            self.onReceiveCallback(model: model, data: data)
        }
        connection.start()
        print("\(connectionName!): started")
        connection.send(data: "!modraw".data(using: .utf8)!)
    }
    func stringFrom(bytes: ArraySlice<UInt8>) -> String {
        var str = ""
        for byte in bytes {
            str += String(Character(UnicodeScalar(byte)))
        }
        return str
    }
    fileprivate func onReceiveCallback(model: Model, data: Data?) {
        guard let data = data else { return }
        DispatchQueue.main.async {
            guard self.connectionStarted else { return }
            let bytes = newByteArrayFrom(data: data)
            let header = self.stringFrom(bytes: bytes[0..<min(7, bytes.count)])
            if header == "!reset" {
                model.reset()
            } else if header == "!modraw" {
                if let epsiModrawParser = self.epsiModrawParser {
                    epsiModrawParser.parse(model: model)
                }
                model.appendNewFileBoundary()
                self.epsiModrawParser = EpsiModrawParser(bytes: bytes[header.count..<bytes.count])
            } else if let epsiModrawParser = self.epsiModrawParser {
                epsiModrawParser.modrawParser.appendData(bytes: bytes[...])
            }
            if let epsiModrawParser = self.epsiModrawParser {
                epsiModrawParser.parse(model: model)
            }
        }
    }
}
