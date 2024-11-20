import Foundation

class EpsiModrawPacketParser_INGG: EpsiModrawPacketParser {
    init() {
        super.init(signature: "$INGG")
    }
    func toScientific(from: String, cardinal: String) -> Double {
        var ll = Double(from)!
        ll = floor(ll / 100.0) + ll.truncatingRemainder(dividingBy: 100) / 60
        return cardinal == "S" || cardinal == "W" ? -ll : ll
    }
    func toLatLon(from: String, cardinal: String) -> String {
        let ll = Double(from)!
        let deg = Int(ll / 100.0)
        let min = Int(ll) - 100 * deg
        return "\(deg)\u{00B0} \(min)'\(cardinal)"
    }
    override func parse(packet: ModrawPacket, model: Model) {
        let str = packet.parent.parseString(start: packet.payloadStart, len: packet.payloadEnd - packet.payloadStart)
        let comp = str.components(separatedBy: ",")

        model.mostRecentLatitudeScientific = toScientific(from: comp[2], cardinal: comp[3])
        model.mostRecentLongitudeScientific = toScientific(from: comp[4], cardinal: comp[5])
        model.mostRecentLatitude = toLatLon(from: comp[2], cardinal: comp[3])
        model.mostRecentLongitude = toLatLon(from: comp[4], cardinal: comp[5])
    }
    override func isValid(packet: ModrawPacket) -> Bool {
        return (packet.signature == signature) &&
        packet.parent.data[packet.payloadStart] == ModrawParser.ASCII_A // $INGGA
    }
}