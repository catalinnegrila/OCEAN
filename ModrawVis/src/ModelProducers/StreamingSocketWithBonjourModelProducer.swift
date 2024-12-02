import Foundation
import Network

class StreamingSocketWithBonjourModelProducer: StreamingSocketModelProducer {
    var browser: NWBrowser!
    
    override func retryConnection(model: Model)
    {
        model.title = "Using Bonjour to discover services on the network..."
        browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: ""), using: .tcp)
        browser.stateUpdateHandler = { newState in
            print("NWBrowser: state '\(newState)'")
            switch newState {
            case .failed(let error):
                model.title = error.localizedDescription
                self.browser.cancel()
            default:
                break
            }}
        browser.browseResultsChangedHandler = { (results, changes) in
            enumerateResults: for result in results {
                switch result.endpoint {
                case let .service(name: name, type: _, domain: domain, interface: _):
                    self.connectionName = "\(domain)\(name)"
                    print("Discovered service \(self.connectionName!)")
                    if name == "ModrawServer" {
                        let proto: NWParameters = .tcp
                        if let opt = proto.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
                            opt.version = .v4
                        }
                        self.openConnection(model: model, nwConnection: NWConnection(to: result.endpoint, using: proto))
                        break enumerateResults
                    }
                default:
                    break
                }
            }
        }
        browser.start(queue: .main)
    }
}
