import Foundation
import Network

class StreamingSocketWithURLModelProducer: StreamingSocketModelProducer {
    let socketUrl: URL
    
    init(socketUrl: URL) {
        self.socketUrl = socketUrl
        super.init()
        self.connectionName = socketUrl.absoluteString
    }
    override func retryConnection(model: Model) {
        openConnection(model: model, endpoint: NWEndpoint.url(socketUrl))
    }
}
