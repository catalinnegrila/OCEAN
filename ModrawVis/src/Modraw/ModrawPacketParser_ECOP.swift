import Foundation
import ModrawLib

class ModrawPacketParser_ECOP : ModrawPacketParser_BlockData {
    init() {
        super.init(signature: "$ECOP")
    }
    let ecop_recs_per_block = 1
    let ecop_timestamp_len = 16
    let ecop_channel_len = 4
    func ecop_block_rec_len() -> Int {
        return ecop_timestamp_len + 3 * ecop_channel_len // <CR><LF>
    }
    override func getExpectedBlockDataLen() -> Int? {
        return ecop_block_rec_len() * ecop_recs_per_block
    }
    func parseEcopTimestamp(packet: ModrawPacket, i: inout Int) -> Double {
        let time_s = Double(packet.parent.peekHex(at: i, len: ecop_timestamp_len)!) / 1000.0
        i += ecop_timestamp_len
        return time_s
    }
    func parseEcopChannel(packet: ModrawPacket, i: inout Int) -> Double {
        let channel = packet.parent.peekHex(at: i, len: ecop_channel_len)
        i += ecop_channel_len
        guard let channel else { return Double.nan }
        return Double(channel) / Double(0xFFFF) // TODO: replace this with the real conversion
    }
    override func parse(packet: ModrawPacket, model: Model) {
        var i = getBlockDataPayloadStart(packet: packet)

        let (prev_block, this_block) = model.d.fluor_blocks.getLastTwoBlocks()
        var prev_time_s = prev_block?.time_s.data.last!

        for j in 0..<ecop_recs_per_block {
            let time_s = parseEcopTimestamp(packet: packet, i: &i)

            let bb_raw = parseEcopChannel(packet: packet, i: &i)
            let chla_raw = parseEcopChannel(packet: packet, i: &i)
            let fDOM_raw = parseEcopChannel(packet: packet, i: &i)

            if !isValidSample(this_block: this_block, sample_index: j, prev_time_s: &prev_time_s, time_s: time_s) {
                continue
            }

            // TODO: convert to real values. Not yet implemented in Matlab either.
            this_block.time_s.append(time_s)
            this_block.bb.append(bb_raw)
            this_block.chla.append(chla_raw)
            this_block.fDOM.append(fDOM_raw)
        }
        model.d.fluor_blocks.removeLastBlockIfEmpty()
    }
}
