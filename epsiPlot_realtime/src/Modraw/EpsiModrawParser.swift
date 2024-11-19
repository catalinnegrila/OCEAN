import Foundation

class EpsiModrawParser {
    var modrawParser: ModrawParser
    var packetParsers: [EpsiModrawPacketParser] =
        [ EpsiModrawPacketParser_EFE4(), EpsiModrawPacketParser_SB49() ]

    var PCodeData_lat = ""
    var PCodeData_lon = ""
    var CTD_fishflag = ""

    init(model: Model) throws {
        modrawParser = try ModrawParser(fileUrl: model.fileUrl!)
        let header = modrawParser.parseHeader()
        for packetParser in packetParsers {
            packetParser.parse(header: header)
        }

        CTD_fishflag = header.getKeyValueString(key: "\nCTD.fishflag=")
        PCodeData_lat = header.getKeyValueString(key: "\nPCodeData.lat =")
        PCodeData_lon = header.getKeyValueString(key: "\nPCodeData.lon =")
        parsePackets(model: model)
    }
    func getHeaderInfo() -> String {
        let info = [CTD_fishflag, "lat=\(PCodeData_lat)", "lon=\(PCodeData_lon)"]
        return info.joined(separator: ", ")
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
