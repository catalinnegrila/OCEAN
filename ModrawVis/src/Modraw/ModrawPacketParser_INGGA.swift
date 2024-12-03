import Foundation
import ModrawLib

struct LatLonValue {
    enum Cardinal: String {
        case north = "N", south = "S", east = "E", west = "W"
    }
    let value: Double
    let cardinal: Cardinal
    init?(_ value: String, cardinal: String) {
        guard let v = Double(value) else { return nil }
        self.value = v
        guard let c = Cardinal(rawValue: cardinal) else { return nil }
        self.cardinal = c
    }
    var degrees: Int {
        Int(floor(value / 100.0))
    }
    var minutes: Double {
        value.truncatingRemainder(dividingBy: 100)
    }
    func describeSci() -> String {
        let sign = switch cardinal {
        case .south, .west: -1.0
        case .north, .east: 1.0
        }
        let sci = sign * (Double(degrees) + minutes / 60)
        return String(format: "%.2f", sci)
    }
    func describe() -> String {
        return "\(degrees)\u{00B0} \(Int(minutes))'\(cardinal.rawValue)"
    }
}

struct LatLon {
    let lat: LatLonValue
    let lon: LatLonValue
    init?(ingga: [String]) {
        guard ingga.count > 5 else { return nil }
        guard ingga[0] == "$INGGA" else { return nil }
        guard let lat = LatLonValue(ingga[2], cardinal: ingga[3]) else { return nil }
        self.lat = lat
        guard let lon = LatLonValue(ingga[4], cardinal: ingga[5]) else { return nil }
        self.lon = lon
    }
    func describeSci() -> String {
        return "lat: \(lat.describeSci()), lon: \(lon.describeSci())"
    }
    func describe() -> String {
        return "\(lat.describe()), \(lon.describe())"
    }
}

class ModrawPacketParser_INGG: ModrawPacketParser {
    init() {
        super.init(signature: "$INGGA")
    }
    override func parse(packet: ModrawPacket, model: Model) {
        let str = packet.parent.peekString(at: packet.signatureStart, len: packet.endChecksumStart - packet.signatureStart)
        model.d.mostRecentCoords = LatLon(ingga: str.components(separatedBy: ","))
    }
}
