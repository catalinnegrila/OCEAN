import Foundation
import ModrawLib

class ModrawPacketParser_INGG: ModrawPacketParser {
    init() {
        super.init(signature: "$INGGA")
    }
    func isValidCardinal(cardinal: String) -> Bool {
        return (cardinal == "S" || cardinal == "N" || cardinal == "E" || cardinal == "W")
    }
    func toScientific(from: String, cardinal: String) -> Double? {
        if isValidCardinal(cardinal: cardinal) {
            if var ll = Double(from) {
                ll = floor(ll / 100.0) + ll.truncatingRemainder(dividingBy: 100) / 60
                return cardinal == "S" || cardinal == "W" ? -ll : ll
            }
        }
        return nil
    }
    func toLatLon(from: String, cardinal: String) -> String? {
        if isValidCardinal(cardinal: cardinal) {
            if let ll = Double(from) {
                let deg = Int(ll / 100.0)
                let min = Int(ll) - 100 * deg
                return "\(deg)\u{00B0} \(min)'\(cardinal)"
            }
        }
        return nil
    }
    override func parse(packet: ModrawPacket, model: Model) {
        let str = packet.parent.peekString(at: packet.signatureStart, len: packet.checksumStart - packet.signatureStart)
        let comp = str.components(separatedBy: ",")

        model.d.mostRecentLatitudeScientific = toScientific(from: comp[2], cardinal: comp[3]) ?? 0.0
        model.d.mostRecentLongitudeScientific = toScientific(from: comp[4], cardinal: comp[5]) ?? 0.0
        model.d.mostRecentLatitude = toLatLon(from: comp[2], cardinal: comp[3]) ?? ""
        model.d.mostRecentLongitude = toLatLon(from: comp[4], cardinal: comp[5]) ?? ""
    }
}