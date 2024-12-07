import Network

class BrowseBonjourService {
    fileprivate let browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: ""), using: .tcp)
    fileprivate let browserQueue = DispatchQueue(label: "NWBrowserQueue")
    fileprivate let name: String
    var onFound: ((NWEndpoint)->Void)?
    var onStateUpdate: ((NWBrowser.State)->Void)?

    init(_ name: String) {
        self.name = name
    }
    func start() {
        assert(onFound != nil)
        browser.stateUpdateHandler = { newState in
            print("NWBrowser: state '\(newState)'")
            if let onStateUpdate = self.onStateUpdate {
                onStateUpdate(newState)
            }
        }
        browser.browseResultsChangedHandler = { (results, changes) in
            for result in results {
                print("NWBrowser: found '\(result.endpoint.toString())'")
                switch result.endpoint {
                case let .service(name: name, type: _, domain: _, interface: _):
                    if name.starts(with: self.name) {
                        if let onFound = self.onFound {
                            onFound(result.endpoint)
                        }
                    }
                default:
                    break
                }
            }
        }
        browser.start(queue: browserQueue)
    }
    func stop() {
        if browser.state != .cancelled {
            browser.cancel()
        }
    }
}
