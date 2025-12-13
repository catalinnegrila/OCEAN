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
        Int(value / 100.0)
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
        // Print 2 digits without rounding
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.roundingMode = .down // Truncates towards zero
        return formatter.string(from: NSNumber(value: sci)) ?? "\(sci)"
    }
    func describe() -> String {
        return "\(degrees)\u{00B0} \(Int(minutes))'\(cardinal.rawValue)"
    }
}

struct LatLon {
    let lat: LatLonValue
    let lon: LatLonValue
    init?(_ comp: [String]) {
        guard comp.count > 5 else { return nil }
        guard ["$INGGA", "$GPGGA"].contains(comp[0]) else { return nil }
        guard let lat = LatLonValue(comp[2], cardinal: comp[3]) else { return nil }
        self.lat = lat
        guard let lon = LatLonValue(comp[4], cardinal: comp[5]) else { return nil }
        self.lon = lon
    }
    func describeSci() -> String {
        return "lat: \(lat.describeSci()), lon: \(lon.describeSci())"
    }
    func describe() -> String {
        return "\(lat.describe()), \(lon.describe())"
    }
}

class ModrawPacketParser_GPS: ModrawPacketParser {
    override func parse(packet: ModrawPacket, model: Model) {
        let str = packet.parent.peekString(at: packet.signatureStart, len: packet.endChecksumStart - packet.signatureStart)
        model.d.mostRecentCoords = LatLon(str.components(separatedBy: ","))
    }
}

class ModrawPacketParser_INGG: ModrawPacketParser_GPS {
    init() {
        super.init(signature: "$INGGA")
    }
}

class ModrawPacketParser_GPGG: ModrawPacketParser_GPS {
    init() {
        super.init(signature: "$GPGGA")
    }
}

