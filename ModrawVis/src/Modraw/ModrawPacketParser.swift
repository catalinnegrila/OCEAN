import ModrawLib

class ModrawPacketParser {
    let signature: String
    init(signature: String) {
        self.signature = signature
    }
    func getPayloadStart(packet: ModrawPacket) -> Int {
        return packet.getPayloadStart(signatureLen: signature.count)
    }
    func parse(header: ModrawHeader) {
    }
    func parse(packet: ModrawPacket, model: Model) {
        assertionFailure()
    }
    func isValid(packet: ModrawPacket) -> Bool {
        return packet.checkSignature(signature)
    }
}

