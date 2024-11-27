import Foundation

class EpsiModrawParser {
    var modrawParser: ModrawParser
    fileprivate var packetParsers: [EpsiModrawPacketParser] =
        [ EpsiModrawPacketParser_EFE4(), EpsiModrawPacketParser_SB49(), EpsiModrawPacketParser_INGG()  ]

    fileprivate var CTD_fishflag = ""

    init(fileUrl: URL) throws {
        modrawParser = try ModrawParser(fileUrl: fileUrl)
    }
    init(bytes: ArraySlice<UInt8>) {
        modrawParser = ModrawParser(bytes: bytes)
    }
    fileprivate func parseHeader(model: Model) -> Bool {
        guard let header = modrawParser.parseHeader() else { return false }
        for packetParser in packetParsers {
            packetParser.parse(header: header)
        }
        CTD_fishflag = header.getValueForKeyAsString("CTD.fishflag") ?? "'EPSI'"
        model.deploymentType = Model.DeploymentType.from(fishflag: CTD_fishflag)
        return true
    }
    func getHeaderInfo() -> String {
        return CTD_fishflag
    }
    fileprivate func getParserFor(packet: ModrawPacket) -> EpsiModrawPacketParser? {
        for packetParser in packetParsers {
            if packet.signature == packetParser.signature {
                return packetParser
            }
        }
        return nil
    }
    func parse(model: Model) {
        if modrawParser.cursor == 0 {
            guard parseHeader(model: model) else { return }
        }

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
