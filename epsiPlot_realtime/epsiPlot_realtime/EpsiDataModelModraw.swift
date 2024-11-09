import Foundation

class EpsiDataModelModraw: EpsiDataModel
{
    var modraw : ModrawParser
    var channels : [String : [Double]] = [:]

    var epsi_t1_volt : [Double] = []
    var epsi_t2_volt : [Double] = []
    var epsi_s1_volt : [Double] = []
    var epsi_s2_volt : [Double] = []
    var epsi_a1_g : [Double] = []
    var epsi_a2_g : [Double] = []
    var epsi_a3_g : [Double] = []

    var ctd_T_raw : [Int] = []
    var ctd_C_raw : [Int] = []
    var ctd_P_raw : [Int] = []
    var ctd_PT_raw : [Int] = []

    var ctd_P : [Double] = []
    var ctd_T : [Double] = []
    var ctd_S : [Double] = []
    var ctd_C : [Double] = []
    var ctd_dPdt : [Double] = []

    enum SBE_Format : Int {
        case eng = 1, PTS
    }

    var sbe_cal_ta0 : Double = 0
    var sbe_cal_ta1 : Double = 0
    var sbe_cal_ta2 : Double = 0
    var sbe_cal_ta3 : Double = 0

    var sbe_cal_pa0 : Double = 0
    var sbe_cal_pa1 : Double = 0
    var sbe_cal_pa2 : Double = 0
    var sbe_cal_ptempa0 : Double = 0
    var sbe_cal_ptempa1 : Double = 0
    var sbe_cal_ptempa2 : Double = 0
    var sbe_cal_ptca0 : Double = 0
    var sbe_cal_ptca1 : Double = 0
    var sbe_cal_ptca2 : Double = 0
    var sbe_cal_ptcb0 : Double = 0
    var sbe_cal_ptcb1 : Double = 0
    var sbe_cal_ptcb2 : Double = 0

    var sbe_cal_cg : Double = 0
    var sbe_cal_ch : Double = 0
    var sbe_cal_ci : Double = 0
    var sbe_cal_cj : Double = 0
    var sbe_cal_ctcor : Double = 0
    var sbe_cal_cpcor : Double = 0
    let sbe_c3515 = 42.914

    static func getKeyValue(key: String, header: String) -> Double {
        let indexOfKey = header.index(of: key)
        let indexAfterKey = header.index(indexOfKey!, offsetBy: key.count)
        let valueOnwards = header[indexAfterKey...]
        var indexOfCrlf = valueOnwards.index(of: "\r\n")
        if indexOfCrlf! > valueOnwards.index(indexAfterKey, offsetBy: 32) {
            indexOfCrlf = valueOnwards.index(of: "\n")
        }
        let value = valueOnwards[..<indexOfCrlf!].trimmingCharacters(in: .whitespaces)
        //print("\(key.trimmingCharacters(in: .whitespacesAndNewlines))\(value)")
        return Double(value)!
    }

    override init() throws
    {
        //let mat = try! EpsiDataModelMat()

        let fileUrl = URL(fileURLWithPath: "/Users/catalin/Downloads/OCEAN/EPSI24_11_06_054202.modraw")
        let inputFileData = try! Data(contentsOf: fileUrl)
        self.modraw = ModrawParser(data: inputFileData)

        try super.init()

        let header = self.modraw.parseHeader()
        guard header != nil else {
            throw MyError.runtimeError("Invalid file format. Could not parse header.")
        }

        sbe_cal_ta0 = EpsiDataModelModraw.getKeyValue(key: " TA0 = ", header: header!)
        sbe_cal_ta1 = EpsiDataModelModraw.getKeyValue(key: " TA1 = ", header: header!)
        sbe_cal_ta2 = EpsiDataModelModraw.getKeyValue(key: " TA2 = ", header: header!)
        sbe_cal_ta3 = EpsiDataModelModraw.getKeyValue(key: " TA3 = ", header: header!)

        sbe_cal_pa0 = EpsiDataModelModraw.getKeyValue(key: "\nPA0=", header: header!)
        sbe_cal_pa1 = EpsiDataModelModraw.getKeyValue(key: "\nPA1=", header: header!)
        sbe_cal_pa2 = EpsiDataModelModraw.getKeyValue(key: "\nPA2=", header: header!)
        sbe_cal_ptempa0 = EpsiDataModelModraw.getKeyValue(key: "\nPTEMPA0=", header: header!)
        sbe_cal_ptempa1 = EpsiDataModelModraw.getKeyValue(key: "\nPTEMPA1=", header: header!)
        sbe_cal_ptempa2 = EpsiDataModelModraw.getKeyValue(key: "\nPTEMPA2=", header: header!)
        sbe_cal_ptca0 = EpsiDataModelModraw.getKeyValue(key: "\nPTCA0=", header: header!)
        sbe_cal_ptca1 = EpsiDataModelModraw.getKeyValue(key: "\nPTCA1=", header: header!)
        sbe_cal_ptca2 = EpsiDataModelModraw.getKeyValue(key: "\nPTCA2=", header: header!)
        sbe_cal_ptcb0 = EpsiDataModelModraw.getKeyValue(key: "\nPTCB0=", header: header!)
        sbe_cal_ptcb1 = EpsiDataModelModraw.getKeyValue(key: "\nPTCB1=", header: header!)
        sbe_cal_ptcb2 = EpsiDataModelModraw.getKeyValue(key: "\nPTCB2=", header: header!)

        sbe_cal_cg = EpsiDataModelModraw.getKeyValue(key: "\nCG=", header: header!)
        sbe_cal_ch = EpsiDataModelModraw.getKeyValue(key: "\nCH=", header: header!)
        sbe_cal_ci = EpsiDataModelModraw.getKeyValue(key: "\nCI=", header: header!)
        sbe_cal_cj = EpsiDataModelModraw.getKeyValue(key: "\nCJ=", header: header!)
        sbe_cal_ctcor = EpsiDataModelModraw.getKeyValue(key: "\nCTCOR=", header: header!)
        sbe_cal_cpcor = EpsiDataModelModraw.getKeyValue(key: "\nCPCOR=", header: header!)

        let som = self.modraw.parsePacket()
        guard som != nil &&
                som!.timeOffsetMs == nil &&
                som!.signature == "$SOM3" else {
            throw MyError.runtimeError("Expected $SOM first packet.")
        }

        /* TODO: handle partial packets
         if partialEndPacket != nil {
            print("Patching partial first packet with \(partialEndPacket!).")
            inputFileParser.insertPartialEndPacket(partialEndPacket!)
        }
        partialEndPacket = inputFileParser.extractPartialEndPacket()
        if partialEndPacket != nil {
            print("Extracted partial last packet of \(partialEndPacket!).")
        }*/

        var packet = self.modraw.parsePacket()
        while packet != nil {
            if packet!.timeOffsetMs == nil || packet!.date == nil {
                throw MyError.runtimeError("Expected timestamp on packet.")
            }
            if (packet!.signature == "$EFE4") {
                parseEFE4(packet: packet!)
            } else if (packet!.signature == "$SB49") {
                parseSB49(packet: packet!, sbe_format: SBE_Format.eng)
            } else if (packet!.signature == "$SB41") {
                parseSB49(packet: packet!, sbe_format: SBE_Format.PTS)
            }
            packet = self.modraw.parsePacket()
        }

        self.channels = [String : [Double]]()
        self.channels["epsi.t1_volt"] = self.epsi_t1_volt
        self.channels["epsi.t2_volt"] = self.epsi_t2_volt
        self.channels["epsi.s1_volt"] = self.epsi_s1_volt
        self.channels["epsi.s2_volt"] = self.epsi_s2_volt
        self.channels["epsi.a1_g"] = self.epsi_a1_g
        self.channels["epsi.a2_g"] = self.epsi_a2_g
        self.channels["epsi.a3_g"] = self.epsi_a3_g

        self.channels["ctd.P"] = self.ctd_P
        self.channels["ctd.T"] = self.ctd_T
        self.channels["ctd.S"] = self.ctd_S
        self.channels["ctd.C"] = self.ctd_C
        self.channels["ctd.dPdt"] = self.ctd_dPdt

        print("MODRAW:")
        /*print("------- \(epsi_t1_volt.count)")
        print("t1_volt: \(epsi_t1_volt[0])")
        print("t2_volt: \(epsi_t2_volt[0])")
        print("s1_volt: \(epsi_s1_volt[0])")
        print("s2_volt: \(epsi_s2_volt[0])")
        print("a1_g: \(epsi_a1_g[0])")
        print("a2_g: \(epsi_a2_g[0])")
        print("a3_g: \(epsi_a3_g[0])")*/
        /*print("------- \(ctd_T_raw.count)")
        print("T_raw: \(ctd_T_raw[0])")
        print("C_raw: \(ctd_C_raw[0])")
        print("P_raw: \(ctd_P_raw[0])")
        print("PT_raw: \(ctd_PT_raw[0])")*/
        print("------- \(ctd_P.count)")
        let (P_min, P_max) = EpsiDataModel.getMinMaxMat1(mat: ctd_P)
        print("P: \(ctd_P[0]) (\(P_min),\(P_max))")
        let (T_min, T_max) = EpsiDataModel.getMinMaxMat1(mat: ctd_T)
        print("T: \(ctd_T[0]) (\(T_min),\(T_max))")
        let (S_min, S_max) = EpsiDataModel.getMinMaxMat1(mat: ctd_S)
        print("S: \(ctd_S[0]) (\(S_min),\(S_max))")
        let (C_min, C_max) = EpsiDataModel.getMinMaxMat1(mat: ctd_C)
        print("C: \(ctd_C[0]) (\(C_min),\(C_max))")
        let (dPdt_min, dPdt_max) = EpsiDataModel.getMinMaxMat1(mat: ctd_dPdt)
        print("dPdt: \(ctd_dPdt[0]) (\(dPdt_min),\(dPdt_max))")
        print("-------")
        /*
        let mat_T_raw = mat.getChannel(name: "ctd.T_raw")
        assert(mat_T_raw.count == ctd_T_raw.count)
        for i in 0..<mat_T_raw.count {
            if ctd_T_raw[i] != Int(mat_T_raw[i]) {
                print("[\(i)]: modraw: \(ctd_T_raw[i]) mat: \(mat_T_raw[i])")
            }
        }
        */
    }

    static let hextimestamplength = 16
    static let hexblocksizelength = 8
    static let chksum1length = 3 // *<HEX><HEX>
    static let chksum2length = 5 // *<HEX><HEX><CR><LF>

    static let efe_gain = Double(1)
    static let efe_bit_counts = 24
    static let efe_acc_offset = 1.8 / 2
    static let efe_acc_factor = 0.4
    static let efe_timestamp_length = 8
    static let efe_n_channels = 7
    static let efe_bytes_per_channel = 3
    static let efe_recs_per_block = 80
    static let efe_n_elements = EpsiDataModelModraw.efe_timestamp_length + EpsiDataModelModraw.efe_n_channels * EpsiDataModelModraw.efe_bytes_per_channel

    static func Unipolar(FR: Double, data: Int) -> Double {
        return FR / EpsiDataModelModraw.efe_gain * (Double(data) / Double(pow(Double(2), Double(EpsiDataModelModraw.efe_bit_counts))))
    }
    static func Bipolar(FR: Double, data: Int) -> Double {
        return FR / EpsiDataModelModraw.efe_gain * (Double(data) / Double(pow(Double(2), Double(EpsiDataModelModraw.efe_bit_counts - 1))) - 1)
    }
    static func volt_to_g(data: Double) -> Double {
        return (data - EpsiDataModelModraw.efe_acc_offset) / EpsiDataModelModraw.efe_acc_factor
    }
    static func parseEfeChannel(packet: ModrawPacket, i: inout Int) -> Int {
        let channel = packet.parseBin(start: i, len: EpsiDataModelModraw.efe_bytes_per_channel)
        i += EpsiDataModelModraw.efe_bytes_per_channel
        return channel
    }
    func parseEFE4(packet : ModrawPacket) {
        var i = packet.payloadStart
        //print("hextimestamp: \(packet.parseString(start: i, len: EpsiDataModelModraw.hextimestamplength))")
        i += EpsiDataModelModraw.hextimestamplength
        //print("hexlengthblock: \(packet.parseString(start: i, len: EpsiDataModelModraw.hexblocksizelength))")
        let hexlengthblock = packet.parseHex(start: i, len: EpsiDataModelModraw.hexblocksizelength)
        i += EpsiDataModelModraw.hexblocksizelength
        //print("checksum1: \(packet.parseString(start: i, len: EpsiDataModelModraw.chksum1length))")
        assert(packet.data[i] == ModrawParser.ASCII_STAR)
        i += EpsiDataModelModraw.chksum1length
        //print("checksum2: \(packet.parseString(start: packet.data.count - EpsiDataModelModraw.chksum2length, len: EpsiDataModelModraw.chksum1length))")
        assert(packet.data[packet.data.count - EpsiDataModelModraw.chksum2length] == ModrawParser.ASCII_STAR)

        //print("ending: \(packet.parseString(start: packet.data.count - 16, len: 16))")
        let block_data_len = packet.data.count - i - EpsiDataModelModraw.chksum2length
        assert(hexlengthblock == block_data_len)
        assert(block_data_len == EpsiDataModelModraw.efe_n_elements * EpsiDataModelModraw.efe_recs_per_block)

        let newCapacity = epsi_t1_volt.count + EpsiDataModelModraw.efe_recs_per_block
        epsi_t1_volt.reserveCapacity(newCapacity)
        epsi_t2_volt.reserveCapacity(newCapacity)
        epsi_s1_volt.reserveCapacity(newCapacity)
        epsi_s2_volt.reserveCapacity(newCapacity)
        epsi_a1_g.reserveCapacity(newCapacity)
        epsi_a2_g.reserveCapacity(newCapacity)
        epsi_a3_g.reserveCapacity(newCapacity)

        for _ in 0..<EpsiDataModelModraw.efe_recs_per_block {
            i += EpsiDataModelModraw.efe_timestamp_length
            let t1_count = EpsiDataModelModraw.parseEfeChannel(packet: packet, i: &i)
            let t2_count = EpsiDataModelModraw.parseEfeChannel(packet: packet, i: &i)
            let s1_count = EpsiDataModelModraw.parseEfeChannel(packet: packet, i: &i)
            let s2_count = EpsiDataModelModraw.parseEfeChannel(packet: packet, i: &i)
            let a1_count = EpsiDataModelModraw.parseEfeChannel(packet: packet, i: &i)
            let a2_count = EpsiDataModelModraw.parseEfeChannel(packet: packet, i: &i)
            let a3_count = EpsiDataModelModraw.parseEfeChannel(packet: packet, i: &i)

            epsi_t1_volt.append(EpsiDataModelModraw.Unipolar(FR: 2.5, data: t1_count))
            epsi_t2_volt.append(EpsiDataModelModraw.Unipolar(FR: 2.5, data: t2_count))

            epsi_s1_volt.append(EpsiDataModelModraw.Bipolar(FR: 2.5, data: s1_count))
            epsi_s2_volt.append(EpsiDataModelModraw.Bipolar(FR: 2.5, data: s2_count))

            let a1_volt = EpsiDataModelModraw.Unipolar(FR: 1.8, data: a1_count)
            let a2_volt = EpsiDataModelModraw.Unipolar(FR: 1.8, data: a2_count)
            let a3_volt = EpsiDataModelModraw.Unipolar(FR: 1.8, data: a3_count)

            epsi_a1_g.append(EpsiDataModelModraw.volt_to_g(data: a1_volt))
            epsi_a2_g.append(EpsiDataModelModraw.volt_to_g(data: a2_volt))
            epsi_a3_g.append(EpsiDataModelModraw.volt_to_g(data: a3_volt))
        }
    }

    static let sbe_recs_per_block = 2
    static let sbe_timestamp_length = 16
    static let sbe_block_length = (24 + EpsiDataModelModraw.sbe_timestamp_length) * EpsiDataModelModraw.sbe_recs_per_block
    static let sbe_hex_per_channel1 = 6
    static let sbe_hex_per_channel2 = 4
    static func parseSbeChannel1(packet: ModrawPacket, i: inout Int) -> Int {
        let channel = packet.parseHex(start: i, len: EpsiDataModelModraw.sbe_hex_per_channel1)
        i += EpsiDataModelModraw.sbe_hex_per_channel1
        return channel
    }
    static func parseSbeChannel2(packet: ModrawPacket, i: inout Int) -> Int {
        let channel = packet.parseHex(start: i, len: EpsiDataModelModraw.sbe_hex_per_channel2)
        i += EpsiDataModelModraw.sbe_hex_per_channel2
        return channel
    }
    func sbe49_get_temperature(T_raw: Int) -> Double {
        let a0 = sbe_cal_ta0
        let a1 = sbe_cal_ta1
        let a2 = sbe_cal_ta2
        let a3 = sbe_cal_ta3
        
        let mv = (Double(T_raw) - 524288) / 1.6e7
        let r = (mv * 2.295e10 + 9.216e8) / (6.144e4 - mv * 5.3e5)
        let log_r = log(r)
        let T = a0 + a1 * log_r + a2 * log_r*log_r + a3 * log_r*log_r*log_r
        return 1.0 / T - 273.15
    }

    func sbe49_get_conductivity(C_raw: Int, T: Double, P: Double) -> Double {
        let g = sbe_cal_cg
        let h = sbe_cal_ch
        let i = sbe_cal_ci
        let j = sbe_cal_cj
        let tcor = sbe_cal_ctcor
        let pcor = sbe_cal_cpcor
        
        let f = Double(C_raw) / 256.0 / 1000.0
        return (g + h * f*f + i * f*f*f + j * f*f*f*f) / (1 + tcor * T + pcor * P)
    }

    func sbe49_get_pressure(P_raw: Int, PT_raw: Int) -> Double {
        let pa0 = sbe_cal_pa0
        let pa1 = sbe_cal_pa1
        let pa2 = sbe_cal_pa2
        let ptempa0 = sbe_cal_ptempa0
        let ptempa1 = sbe_cal_ptempa1
        let ptempa2 = sbe_cal_ptempa2
        let ptca0 = sbe_cal_ptca0
        let ptca1 = sbe_cal_ptca1
        let ptca2 = sbe_cal_ptca2
        let ptcb0 = sbe_cal_ptcb0
        let ptcb1 = sbe_cal_ptcb1
        let ptcb2 = sbe_cal_ptcb2
        
        
        let y = Double(PT_raw / 13107)
        let t = ptempa0 + ptempa1 * y + ptempa2 * y*y
        let x = Double(P_raw) - ptca0 - ptca1 * t - ptca2 * t*t
        let n = x * ptcb0 / (ptcb0 + ptcb1 * t + ptcb2 * t*t)
        return (pa0 + pa1 * n + pa2 * n*n - 14.7) * 0.689476
    }
    static func sw_salrt(T: Double) -> Double {
        let c0 =  0.6766097
        let c1 =  2.00564e-2
        let c2 =  1.104259e-4
        let c3 = -6.9698e-7
        let c4 =  1.0031e-9
        return c0 + (c1 + (c2 + (c3 + c4 * T) * T) * T) * T
    }
    static func sw_salrp(R: Double, T: Double, P: Double) -> Double {
        let d1 =  3.426e-2
        let d2 =  4.464e-4
        let d3 =  4.215e-1
        let d4 = -3.107e-3
        let e1 =  2.070e-5
        let e2 = -6.370e-10
        let e3 =  3.989e-15
        
        return 1 + (P * (e1 + e2 * P + e3 * P*P)) / (1 + d1 * T + d2 * T*T + (d3 + d4 * T) * R)
    }
    static func sw_sals(Rt: Double, T: Double) -> Double {
        let a0 =  0.0080
        let a1 = -0.1692
        let a2 = 25.3851
        let a3 = 14.0941
        let a4 = -7.0261
        let a5 =  2.7081
        
        let b0 =  0.0005
        let b1 = -0.0056
        let b2 = -0.0066
        let b3 = -0.0375
        let b4 =  0.0636
        let b5 = -0.0144
        
        let k  =  0.0162
        
        let Rtx   = sqrt(Rt)
        let del_T = T - 15
        let del_S = (del_T / (1 + k * del_T)) * (b0 + (b1 + (b2 + (b3 + (b4 + b5 * Rtx) * Rtx) * Rtx) * Rtx) * Rtx)
        return a0 + (a1 + (a2 + (a3 + (a4 + a5 * Rtx) * Rtx) * Rtx) * Rtx) * Rtx + del_S
    }
    static func sw_salt(cndr: Double, T: Double, P: Double) -> Double {
        let R = cndr
        let rt = EpsiDataModelModraw.sw_salrt(T: T)
        let Rp = EpsiDataModelModraw.sw_salrp(R: R, T: T, P: P)
        let Rt = R / (Rp * rt)
        return EpsiDataModelModraw.sw_sals(Rt: Rt, T: T)
    }
    func parseSB49(packet : ModrawPacket, sbe_format : SBE_Format) {
        //let sbe_data_recs_per_block = Meta_Data.CTD.sample_per_record;
        var i = packet.payloadStart
        //print("hextimestamp: \(packet.parseString(start: i, len: EpsiDataModelModraw.hextimestamplength))")
        i += EpsiDataModelModraw.hextimestamplength
        //print("hexlengthblock: \(packet.parseString(start: i, len: EpsiDataModelModraw.hexblocksizelength))")
        let hexlengthblock = packet.parseHex(start: i, len: EpsiDataModelModraw.hexblocksizelength)
        i += EpsiDataModelModraw.hexblocksizelength
        assert(hexlengthblock == EpsiDataModelModraw.sbe_block_length)
        //print("checksum1: \(packet.parseString(start: i, len: EpsiDataModelModraw.chksum1length))")
        assert(packet.data[i] == ModrawParser.ASCII_STAR)
        i += EpsiDataModelModraw.chksum1length
        assert(hexlengthblock == packet.data.count - i - EpsiDataModelModraw.chksum2length)

        //print("checksum2: \(packet.parseString(start: packet.data.count - EpsiDataModelModraw.chksum2length, len: EpsiDataModelModraw.chksum1length))")
        assert(packet.data[packet.data.count - EpsiDataModelModraw.chksum2length] == ModrawParser.ASCII_STAR)

        let newCapacity = ctd_P.count + EpsiDataModelModraw.sbe_recs_per_block
        ctd_P.reserveCapacity(newCapacity)
        ctd_T.reserveCapacity(newCapacity)
        ctd_S.reserveCapacity(newCapacity)
        ctd_C.reserveCapacity(newCapacity)
        ctd_dPdt.reserveCapacity(newCapacity)

        ctd_T_raw.reserveCapacity(newCapacity)
        ctd_C_raw.reserveCapacity(newCapacity)
        ctd_P_raw.reserveCapacity(newCapacity)
        ctd_PT_raw.reserveCapacity(newCapacity)

        for _ in 0..<EpsiDataModelModraw.sbe_recs_per_block {
            //print("[\(j)] hextimestamp: \(packet.parseString(start: i, len: EpsiDataModelModraw.sbe_timestamp_length))")
            i += EpsiDataModelModraw.sbe_timestamp_length // skip hex timestamp
            //let rec_ctd = packet.parseString(start: i, len: 24)
            //print("[\(j)] rec: \(rec_ctd)")
            switch sbe_format {
            case SBE_Format.PTS:
                assert(false)

            case SBE_Format.eng:
                let T_raw = EpsiDataModelModraw.parseSbeChannel1(packet: packet, i: &i)
                let C_raw = EpsiDataModelModraw.parseSbeChannel1(packet: packet, i: &i)
                let P_raw = EpsiDataModelModraw.parseSbeChannel1(packet: packet, i: &i)
                let PT_raw = EpsiDataModelModraw.parseSbeChannel2(packet: packet, i: &i)

                ctd_T_raw.append(T_raw)
                ctd_C_raw.append(C_raw)
                ctd_P_raw.append(P_raw)
                ctd_PT_raw.append(PT_raw)

                let T = sbe49_get_temperature(T_raw: T_raw)
                let P = sbe49_get_pressure(P_raw: P_raw, PT_raw: PT_raw)
                let C = sbe49_get_conductivity(C_raw: C_raw, T: T, P: P)
                let S = EpsiDataModelModraw.sw_salt(cndr: C * 10 / sbe_c3515, T: T, P: P);
                //ctd.dPdt = [0; diff(ctd.P)./diff(ctd.time_s)];
                ctd_P.append(P)
                ctd_T.append(T)
                ctd_S.append(S)
                ctd_C.append(C)
                ctd_dPdt.append(0)
            }
            i += 2 // skip the <CR><LF>
        }
    }
    override func getChannel(name : String) -> [Double]
    {
        return channels[name]!
    }
}
