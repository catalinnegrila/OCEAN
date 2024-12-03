import Foundation
import ModrawLib

class ModrawPacketParser_VNAV: ModrawPacketParser_BlockData {
    init() {
        super.init(signature: "$VNAV")
    }
    let vnav_timestamp_len = 16
    func parseVnavTimestamp(packet: ModrawPacket, i: inout Int) -> Double {
        let time_s = Double(packet.parent.peekHex(at: i, len: vnav_timestamp_len)!) / 1000.0
        i += vnav_timestamp_len
        return time_s
    }
    override func parse(packet: ModrawPacket, model: Model) {
        var i = getBlockDataPayloadStart(packet: packet)
        let (prev_block, this_block) = model.d.vnav_blocks.getLastTwoBlocks()
        var prev_time_s = prev_block?.time_s.data.last!

        var j = 0
        while let checksumStart = packet.findNextPacketEndChecksum(from: i),
              checksumStart < packet.endChecksumStart {

            let time_s = parseVnavTimestamp(packet: packet, i: &i)
            if !isValidSample(this_block: this_block, sample_index: j, prev_time_s: &prev_time_s, time_s: time_s) {
                continue
            }

            let str = packet.parent.peekString(at: i, len: checksumStart - i)
            let comp = str.components(separatedBy: ",")
            switch comp[0] {
            case "$VNMAR":
                assert(comp.count == 10)
                this_block.time_s.append(time_s)
                this_block.compass_x.append(Double(comp[1])!)
                this_block.compass_y.append(Double(comp[2])!)
                this_block.compass_z.append(Double(comp[3])!)
                this_block.acceleration_x.append(Double(comp[4])!)
                this_block.acceleration_y.append(Double(comp[5])!)
                this_block.acceleration_z.append(Double(comp[6])!)
                this_block.gyro_x.append(Double(comp[7])!)
                this_block.gyro_y.append(Double(comp[8])!)
                this_block.gyro_z.append(Double(comp[9])!)
            case "$VNYPR":
                assert(comp.count == 4)
                this_block.time_s.append(time_s)
                this_block.yaw.append(Double(comp[1])!)
                this_block.pitch.append(Double(comp[2])!)
                this_block.roll.append(Double(comp[3])!)
            default:
                print("Unknown VNAV packet type: \(comp[0])")
                assertionFailure()
            }
            i = checksumStart + ModrawPacket.PACKET_END_CHECKSUM_LEN
            j += 1
        }
        model.d.vnav_blocks.removeLastBlockIfEmpty()
    }
}
