import Foundation
import Network

class StreamingSocketModel: StreamingModel{
    let socketUrl: URL
    let connection: ClientConnection

    init(socketUrl: URL) {
        self.socketUrl = socketUrl
        print("Opening \(socketUrl)")
        let host = NWEndpoint.Host(socketUrl.host!)
        let port = NWEndpoint.Port(rawValue: UInt16(socketUrl.port!))!
        let nwConnection = NWConnection(host: host, port: port, using: .tcp)
        self.connection = ClientConnection(nwConnection: nwConnection)
        super.init()
        print("Connection created.")
        connection.onStopCallback = onStopCallback(error:)
        connection.onReceiveCallback = onReceiveCallback(data:)
        connection.start()
        print("Connection started.")
        connection.send(data: "!modraw".data(using: .utf8)!)
        status = "Streaming \(socketUrl)" // TODO: -- \(epsiModrawParser!.getHeaderInfo())"
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



