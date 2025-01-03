import ModrawLib

class ModrawPacketParser_EFE4 : ModrawPacketParser_BlockData {
    init() {
        super.init(signature: "$EFE4")
        self.s_volt_func = self.unipolar
    }

    var s_volt_func: ((Double, Int) -> Double)?

    override func parse(header: ModrawHeader) {
        let fishflag = header.getValueForFishflag()
        switch fishflag {
        case "EPSI":
            s_volt_func = self.unipolar
        case "FCTD":
            s_volt_func = self.bipolar
        default:
            print("Unknown fishflag: \(fishflag)")
            assertionFailure()
        }
    }

    let efe_gain = 1.0
    let efe_bit_count_mask = 0x1000000 // 2^24 (channel_len)
    let efe_bit_count_mask_1 = 0x800000 // 2^23
    let efe_acc_offset = 1.8 / 2
    let efe_acc_factor = 0.4
    let efe_timestamp_len = 8
    let efe_n_channels = 7
    let efe_channel_len = 3
    let efe_recs_per_block = 80
    func efe_rec_len() -> Int {
        return efe_timestamp_len + efe_n_channels * efe_channel_len
    }
    override func getExpectedBlockDataLen() -> Int? {
        return efe_rec_len() * efe_recs_per_block
    }
    let t_FR = 2.5
    let s_FR = 2.5
    let a_FR = 1.8
    func unipolar(FR: Double, data: Int) -> Double {
        return FR / efe_gain * (Double(data) / Double(efe_bit_count_mask))
    }
    func bipolar(FR: Double, data: Int) -> Double {
        return FR / efe_gain * (Double(data) / Double(efe_bit_count_mask_1) - 1)
    }
    func calculateG(volt: Double) -> Double {
        return (volt - efe_acc_offset) / efe_acc_factor
    }
    func parseEfeTimestamp(packet: ModrawPacket, i: inout Int) -> Double {
        let time_s = Double(packet.parent.peekBinBE(at: i, len: efe_timestamp_len)) / 1000.0
        i += efe_timestamp_len
        return time_s
    }
    func parseEfeChannel(packet: ModrawPacket, i: inout Int) -> Int {
        let channel = Int(packet.parent.peekBinLE(at: i, len: efe_channel_len))
        i += efe_channel_len
        return channel
    }
    override func parse(packet: ModrawPacket, model: Model)
    {
        var i = getBlockDataPayloadStart(packet: packet)
        let (prev_block, this_block) = model.d.epsi_blocks.getLastTwoBlocks()
        var prev_time_s = prev_block?.time_s.data.last!

        for j in 0..<efe_recs_per_block {
            let time_s = parseEfeTimestamp(packet: packet, i: &i)
            let t1_count = parseEfeChannel(packet: packet, i: &i)
            let t2_count = parseEfeChannel(packet: packet, i: &i)
            let s1_count = parseEfeChannel(packet: packet, i: &i)
            let s2_count = parseEfeChannel(packet: packet, i: &i)
            let a1_count = parseEfeChannel(packet: packet, i: &i)
            let a2_count = parseEfeChannel(packet: packet, i: &i)
            let a3_count = parseEfeChannel(packet: packet, i: &i)

            if !isValidSample(this_block: this_block, sample_index: j, prev_time_s: &prev_time_s, time_s: time_s) {
                continue
            }

            this_block.time_s.append(time_s)
            this_block.t1_volt.append(unipolar(FR: t_FR, data: t1_count))
            this_block.t2_volt.append(unipolar(FR: t_FR, data: t2_count))

            this_block.s1_volt.append(s_volt_func!(s_FR, s1_count))
            this_block.s2_volt.append(s_volt_func!(s_FR, s2_count))

            let a1_volt = unipolar(FR: a_FR, data: a1_count)
            let a2_volt = unipolar(FR: a_FR, data: a2_count)
            let a3_volt = unipolar(FR: a_FR, data: a3_count)

            this_block.a1_g.append(calculateG(volt: a1_volt))
            this_block.a2_g.append(calculateG(volt: a2_volt))
            this_block.a3_g.append(calculateG(volt: a3_volt))
        }
        model.d.epsi_blocks.removeLastBlockIfEmpty()
    }
}
