class EpsiModrawPacketParser_EFE4 : EpsiModrawPacketParser {
    init() {
        super.init(signature: "$EFE4")
    }

    enum DeploymentType: Int {
        case EPSI = 1, FCTD
    }
    var deployment_type = DeploymentType.EPSI
    override func parse(header: String) {
        let key = "CTD.fishflag"
        let fishflag = getKeyValueString(key: "\n\(key)=", header: header)
        switch fishflag {
        case "'EPSI'": deployment_type = .EPSI
        case "'FCTD'": deployment_type = .FCTD
        default:
            print("Unknown \(key): \(fishflag)")
            deployment_type = .EPSI
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
    override func getExpectedBlockSize() -> Int {
        return efe_rec_len() * efe_recs_per_block
    }
    let t_FR = 2.5
    let s_FR = 2.5
    let a_FR = 1.8
    func Unipolar(FR: Double, data: Int) -> Double {
        return FR / efe_gain * (Double(data) / Double(efe_bit_count_mask))
    }
    func Bipolar(FR: Double, data: Int) -> Double {
        return FR / efe_gain * (Double(data) / Double(efe_bit_count_mask_1) - 1)
    }
    func volt_to_g(data: Double) -> Double {
        return (data - efe_acc_offset) / efe_acc_factor
    }
    func parseEfeTimestamp(packet: ModrawPacket, i: inout Int) -> Double {
        let time_s = Double(packet.parent.parseBinBE(start: i, len: efe_timestamp_len)) / 1000.0
        i += efe_timestamp_len
        return time_s
    }
    func parseEfeChannel(packet: ModrawPacket, i: inout Int) -> Int {
        let channel = Int(packet.parent.parseBin(start: i, len: efe_channel_len))
        i += efe_channel_len
        return channel
    }
    override func parse(packet: ModrawPacket, data: inout ProgressiveEpsiData)
    {
        var i = getEpsiPayloadStart(packet: packet)

        let prev_block = data.epsi_blocks.last
        var prev_time_s = (prev_block != nil) ? prev_block!.time_s.last! : nil

        let this_block : EpsiData
        if (prev_block == nil || prev_block!.isFull()) {
            this_block = EpsiData()
            data.epsi_blocks.append(this_block)
        } else {
            this_block = prev_block!
        }

        for _ in 0..<efe_recs_per_block {
            let time_s = parseEfeTimestamp(packet: packet, i: &i)
            let t1_count = parseEfeChannel(packet: packet, i: &i)
            let t2_count = parseEfeChannel(packet: packet, i: &i)
            let s1_count = parseEfeChannel(packet: packet, i: &i)
            let s2_count = parseEfeChannel(packet: packet, i: &i)
            let a1_count = parseEfeChannel(packet: packet, i: &i)
            let a2_count = parseEfeChannel(packet: packet, i: &i)
            let a3_count = parseEfeChannel(packet: packet, i: &i)

            if (prev_time_s != nil) {
                assert(prev_time_s! < time_s)
                this_block.checkAndAppendGap(t0: prev_time_s!, t1: time_s)
            }
            prev_time_s = time_s

            this_block.time_s.append(time_s)
            this_block.t1_volt.append(Unipolar(FR: t_FR, data: t1_count))
            this_block.t2_volt.append(Unipolar(FR: t_FR, data: t2_count))

            switch deployment_type {
            case .EPSI:
                this_block.s1_volt.append(Bipolar(FR: s_FR, data: s1_count))
                this_block.s2_volt.append(Bipolar(FR: s_FR, data: s2_count))
            case .FCTD:
                this_block.s1_volt.append(Unipolar(FR: s_FR, data: s1_count))
                this_block.s2_volt.append(Unipolar(FR: s_FR, data: s2_count))
            }

            let a1_volt = Unipolar(FR: a_FR, data: a1_count)
            let a2_volt = Unipolar(FR: a_FR, data: a2_count)
            let a3_volt = Unipolar(FR: a_FR, data: a3_count)

            this_block.a1_g.append(volt_to_g(data: a1_volt))
            this_block.a2_g.append(volt_to_g(data: a2_volt))
            this_block.a3_g.append(volt_to_g(data: a3_volt))
        }
    }
}
