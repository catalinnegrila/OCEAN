import Foundation
import Network

class StreamingSocketWithBonjourModelProducer: StreamingSocketModelProducer {
    var browser: NWBrowser!
    
    override func retryConnection(model: Model)
    {
        model.status = "Using Bonjour to discover services on the network..."
        browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: ""), using: .tcp)
        browser.stateUpdateHandler = { newState in
            print("NWBrowser: state '\(newState)'")
            switch newState {
            case .failed(let error):
                model.status = error.localizedDescription
                self.browser.cancel()
            default:
                break
            }}
        browser.browseResultsChangedHandler = { (results, changes) in
            for result in results {
                switch result.endpoint {
                case let .service(name: name, type: type, domain: domain, interface: _):
                    self.connectionName = name
                    model.status = "Streaming from service '\(name)' Type: \(type) Domain: \(domain)"
                    if name.contains("MODraw"){
                        let proto: NWParameters = .tcp
                        if let opt = proto.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
                            opt.version = .v4
                        }
                        if (self.connection == nil) {
                            self.openConnection(model: model, nwConnection: NWConnection(to: result.endpoint, using: proto))
                        }
                    }
                default:
                    break
                }
            }
        }
        browser.start(queue: .main)
    }
}
