import Foundation
import Network

class StreamingSocketWithURLModelProducer: StreamingSocketModelProducer {
    let socketUrl: URL
    
    init(socketUrl: URL) {
        self.socketUrl = socketUrl
    }
    override func retryConnection(model: Model) {
        connectionName = socketUrl.absoluteString
        model.title = "Connecting to \(connectionName!)"
        let host = NWEndpoint.Host(socketUrl.host!)
        let port = NWEndpoint.Port(rawValue: UInt16(socketUrl.port!))!
        openConnection(model: model, nwConnection: NWConnection(host: host, port:  port, using: .tcp))
    }
}
