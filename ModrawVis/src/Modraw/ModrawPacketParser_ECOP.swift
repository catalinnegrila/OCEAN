import Foundation
import ModrawLib

class ModrawPacketParser_ECOP : ModrawPacketParser_BlockData {
    init() {
        super.init(signature: "$ECOP")
    }
    //sensor.name="tridente";
    //sensor.bb.cal0=-1.720756e-6;
    //sensor.bb.cal1= 5.871734e4;
    //sensor.chla.cal0=-158.44269e-6;
    //sensor.chla.cal1= 504.23178e3;
    //sensor.fDOM.cal0=-49.728096e-3;
    //sensor.fDOM.cal1= 30.125764e3;
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
    func parseEcopChannel(packet: ModrawPacket, i: inout Int) -> Int {
        let channel = packet.parent.peekHex(at: i, len: ecop_channel_len)!
        i += ecop_channel_len
        return Int(channel)
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
            this_block.bb.append(Double(bb_raw))
            this_block.chla.append(Double(chla_raw))
            this_block.fDOM.append(Double(fDOM_raw))
        }
        model.d.ctd_blocks.removeLastBlockIfEmpty()
    }
}
