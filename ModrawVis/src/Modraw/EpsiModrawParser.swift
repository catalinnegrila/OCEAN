import Foundation
import ModrawLib

class EpsiModrawParser {
    var modrawParser: ModrawParser
    fileprivate var packetParsers: [ModrawPacketParser] =
        [ EpsiModrawPacketParser_EFE4(), EpsiModrawPacketParser_SB49(), ModrawPacketParser_INGG()  ]

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
        model.d.fishflag = header.getValueForKeyAsString(Model.fishflagFieldName) ?? "n/a"
        model.d.deploymentType = Model.DeploymentType.from(fishflag: model.d.fishflag)
        return true
    }
    fileprivate func getParserFor(packet: ModrawPacket) -> ModrawPacketParser? {
        for packetParser in packetParsers {
            if packet.checkSignature(packetParser.signature) {
                return packetParser
            }
        }
        return nil
    }
    func parse(model: Model) {
        if modrawParser.atBeginning() {
            guard parseHeader(model: model) else { return }
        }

        while !modrawParser.foundEndMarker() {
            if let packet = modrawParser.parsePacket() {
                if let packetParser = getParserFor(packet: packet) {
                    if packetParser.isValid(packet: packet) {
                        packetParser.parse(packet: packet, model: model)
                        model.d.isUpdated = true
                    } else {
                        assertionFailure()
                        break
                    }
                }
            } else {
                break
            }
        }
    }
}
