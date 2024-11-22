import Foundation
import Network

class StreamingSocketModel: StreamingModel{
    var connection: ClientConnection! = nil
    var browser: NWBrowser!

    override init() {
        browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: ""), using: .tcp)
        super.init()
        
        print("Using Bonjour to discover services on the network...")
        browser.stateUpdateHandler = { newState in
            print("NWBrowser: state '\(newState)'")
            switch newState {
            case .failed(let error):
                print(error)
                self.browser.cancel()
            default:
                break
            }}
        browser.browseResultsChangedHandler = { ( results, changes ) in
            for result in results {
                switch result.endpoint {
                case let .service(name: name, type: type, domain: domain, interface: _):
                    print("NWBrowser: service '\(name)' Type: \(type) Domain: \(domain)")
                    if name.contains("MODraw"){
                        let proto: NWParameters = .tcp
                        if let opt = proto.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
                            opt.version = .v4
                        }
                        if (self.connection == nil) {
                            self.openConnection(NWConnection(to: result.endpoint, using: proto))
                        }
                    }
                default:
                    break
                }
            }
        }
        browser.start(queue: .main)
    }
    init(socketUrl: URL) {
        super.init()
        let host = NWEndpoint.Host(socketUrl.host!)
        let port = NWEndpoint.Port(rawValue: UInt16(socketUrl.port!))!
        self.openConnection(NWConnection(host: host, port:  port, using: .tcp))
    }

    func openConnection(_ nwConnection: NWConnection) {
        connection = ClientConnection(nwConnection: nwConnection)
        print("Connection created.")
        connection.onStopCallback = onStopCallback(error:)
        connection.onReceiveCallback = onReceiveCallback(data:)
        connection.start()
        print("Connection started.")
        connection.send(data: "!modraw".data(using: .utf8)!)
    }
    func onStopCallback(error: Error?) {
        if error == nil {
            print("Connection stopped.")
        } else {
            print("Connection stopped with error: \(error!)")
        }
    }
    func stringFrom(bytes: ArraySlice<UInt8>) -> String {
        var str = ""
        for byte in bytes {
            str += String(Character(UnicodeScalar(byte)))
        }
        return str
    }
    func onReceiveCallback(data: Data?) {
        if data != nil {
            let bytes = newByteArrayFrom(data: data!)
            let header = stringFrom(bytes: bytes[0..<7])
            var dataLen:Int
            if header == "!modraw" {
                epsiModrawParser = EpsiModrawParser(bytes: bytes[header.count..<bytes.count])
                epsiModrawParser!.parseHeader(model: self)
                dataLen = bytes.count - header.count
            } else {
                epsiModrawParser!.modrawParser.appendData(bytes: bytes[...])
                dataLen = bytes.count
            }
            if dataLen < 65536 {
                epsiModrawParser!.parsePackets(model: self)
            }
        }
    }
    override func update() -> Bool
    {
        return super.update()
    }
}
