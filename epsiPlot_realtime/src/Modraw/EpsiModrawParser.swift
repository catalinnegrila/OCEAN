import Foundation

class EpsiModrawParser {
    var modrawParser: ModrawParser
    var packetParsers: [EpsiModrawPacketParser] =
    [ EpsiModrawPacketParser_EFE4(), EpsiModrawPacketParser_SB49() ]
    
    init(model: Model) throws {
        modrawParser = try ModrawParser(fileUrl: model.fileUrl!)
        if let header = modrawParser.parseHeader() {
            for packetParser in packetParsers {
                packetParser.parse(header: header)
            }
        }
        parsePackets(model: model)
    }
    func getParserFor(packet: ModrawPacket) -> EpsiModrawPacketParser? {
        for packetParser in packetParsers {
            if packet.signature == packetParser.signature {
                return packetParser
            }
        }
        return nil
    }
    func parsePackets(model: Model) {
        while true {
            if let packet = modrawParser.parsePacket() {
                if let packetParser = getParserFor(packet: packet) {
                    if (packetParser.isValid(packet: packet)) {
                        packetParser.parse(packet: packet, model: model)
                        model.isUpdated = true
                    } else {
                        modrawParser.rewindPacket(packet: packet)
                        break
                    }
                }
            } else {
                break
            }
        }
    }
}
