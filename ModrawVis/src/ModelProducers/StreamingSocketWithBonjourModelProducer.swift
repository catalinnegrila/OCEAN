import Foundation
import Network

class StreamingSocketWithBonjourModelProducer: StreamingSocketModelProducer {
    var browser = BrowseBonjourService("ModrawServer")
    override func retryConnection(model: Model)
    {
        model.title = "Searching for Bonjour services on the local network..."
        browser.onFound = { endpoint in
            self.openConnection(model: model, endpoint: endpoint)
            self.browser.stop()
        }
        //browser.onStateUpdate = { error in
        //    print(error.localizedDescription)
        //}
        browser.start()
    }
}
