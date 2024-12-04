import Foundation
import ModrawLib

class ModrawPacketParser_TTVP : ModrawPacketParser_BlockData {
    init() {
        super.init(signature: "$TTVP")
    }
    let ttv_recs_per_block = 10
    let ttv_timestamp_len = 16
    let ttv_channel_len = 8
    func ttv_block_rec_len() -> Int {
        return ttv_timestamp_len + 4 * ttv_channel_len + 3 /* commas */ + 2 // <CR><LF>
    }
    override func getExpectedBlockDataLen() -> Int {
        return ttv_block_rec_len() * ttv_recs_per_block
    }
    func parseTtvTimestamp(packet: ModrawPacket, i: inout Int) -> Double {
        let time_s = Double(packet.parent.peekHex(at: i, len: ttv_timestamp_len)!) / 1000.0
        i += ttv_timestamp_len
        return time_s
    }
    func parseTtvChannel(packet: ModrawPacket, i: inout Int) -> Double {
        let channel = packet.parent.peekHex(at: i, len: ttv_channel_len)!
        i += ttv_channel_len
        return Double(channel) / 1_000_000_000.0 // TODO: remove division once we have good data
    }
    override func parse(packet: ModrawPacket, model: Model) {
        var i = getBlockDataPayloadStart(packet: packet)

        let (prev_block, this_block) = model.d.ttv_blocks.getLastTwoBlocks()
        var prev_time_s = prev_block?.time_s.data.last!

        for j in 0..<ttv_recs_per_block {
            let time_s = parseTtvTimestamp(packet: packet, i: &i)

            let tof_up = parseTtvChannel(packet: packet, i: &i)
            assert(packet.parent.data[i].toChar() == ",")
            i += 1
            let tof_down = parseTtvChannel(packet: packet, i: &i)
            assert(packet.parent.data[i].toChar() == ",")
            i += 1
            let dtof = parseTtvChannel(packet: packet, i: &i)
            assert(packet.parent.data[i].toChar() == ",")
            i += 1
            let vfr = parseTtvChannel(packet: packet, i: &i)
            assert(packet.parent.data[i].toChar() == "\r")
            i += 1
            assert(packet.parent.data[i].toChar() == "\n")
            i += 1

            if !isValidSample(this_block: this_block, sample_index: j, prev_time_s: &prev_time_s, time_s: time_s) {
                continue
            }

            this_block.time_s.append(time_s)
            this_block.tof_up.append(tof_up)
            this_block.tof_down.append(tof_down)
            this_block.dtof.append(dtof)
            this_block.vfr.append(vfr)
        }
        model.d.ctd_blocks.removeLastBlockIfEmpty()
    }
}

