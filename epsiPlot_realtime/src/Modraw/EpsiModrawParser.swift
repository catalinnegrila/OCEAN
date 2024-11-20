import Foundation

class EpsiModrawParser {
    var modrawParser: ModrawParser
    var packetParsers: [EpsiModrawPacketParser] =
        [ EpsiModrawPacketParser_EFE4(), EpsiModrawPacketParser_SB49(), EpsiModrawPacketParser_INGG()  ]

    var CTD_fishflag = ""

    init(model: Model) throws {
        modrawParser = try ModrawParser(fileUrl: model.fileUrl!)
        let header = modrawParser.parseHeader()
        for packetParser in packetParsers {
            packetParser.parse(header: header)
        }

        CTD_fishflag = header.getKeyValueString(key: "\nCTD.fishflag=")
        model.deploymentType = Model.DeploymentType.from(fishflag: CTD_fishflag)

        parsePackets(model: model)
    }
    func getHeaderInfo() -> String {
        return CTD_fishflag
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
