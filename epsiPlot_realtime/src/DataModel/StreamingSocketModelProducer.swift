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
    func openConnection(model: Model, nwConnection: NWConnection) {
        connection = ClientConnection(nwConnection: nwConnection)
        print("\(connectionName!): created")
        connection.onStopCallback = { (error: Error?) -> Void in
            self.onStopCallback(model: model, error: error)
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
        guard connectionStarted else { return }
        guard let data = data else { return }

        let bytes = newByteArrayFrom(data: data)
        let header = stringFrom(bytes: bytes[0..<min(7, bytes.count)])
        DispatchQueue.main.async {
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
    fileprivate func onStopCallback(model: Model, error: Error?) {
        DispatchQueue.main.async {
            self.epsiModrawParser = nil
        }
        if error == nil {
            if connectionStarted {
                retryCount += 1
                model.status = "Connection to \(connectionName!) stopped. Retrying (attempt \(retryCount))..."
                Task {
                    sleep(1)
                    retryConnection(model: model)
                }
            }
        } else {
            print("\(connectionName!): stopped with error: \(error!)")
        }
    }
}
