import Foundation
import ModrawLib

class EpsiModrawPacketParser_SB49 : EpsiModrawPacketParser {
    init() {
        super.init(signature: "$SB49")
    }
    var sbe_cal_ta0 = 0.0
    var sbe_cal_ta1 = 0.0
    var sbe_cal_ta2 = 0.0
    var sbe_cal_ta3 = 0.0
    var sbe_cal_pa0 = 0.0
    var sbe_cal_pa1 = 0.0
    var sbe_cal_pa2 = 0.0
    var sbe_cal_ptempa0 = 0.0
    var sbe_cal_ptempa1 = 0.0
    var sbe_cal_ptempa2 = 0.0
    var sbe_cal_ptca0 = 0.0
    var sbe_cal_ptca1 = 0.0
    var sbe_cal_ptca2 = 0.0
    var sbe_cal_ptcb0 = 0.0
    var sbe_cal_ptcb1 = 0.0
    var sbe_cal_ptcb2 = 0.0
    var sbe_cal_cg = 0.0
    var sbe_cal_ch = 0.0
    var sbe_cal_ci = 0.0
    var sbe_cal_cj = 0.0
    var sbe_cal_ctcor = 0.0
    var sbe_cal_cpcor = 0.0
    var PCodeData_lat = 0.0
    override func parse(header: ModrawHeader) {
        sbe_cal_ta0 = header.getValueForKeyAsDouble("TA0") ?? 8.966051e-004
        sbe_cal_ta1 = header.getValueForKeyAsDouble("TA1") ?? 2.679749e-004
        sbe_cal_ta2 = header.getValueForKeyAsDouble("TA2") ?? -6.163411e-007
        sbe_cal_ta3 = header.getValueForKeyAsDouble("TA3") ?? 1.421661e-007
        sbe_cal_pa0 = header.getValueForKeyAsDouble("PA0") ?? -3.118436e+000
        sbe_cal_pa1 = header.getValueForKeyAsDouble("PA1") ?? 8.882233e-003
        sbe_cal_pa2 = header.getValueForKeyAsDouble("PA2") ?? -1.613100e-010
        sbe_cal_ptempa0 = header.getValueForKeyAsDouble("PTEMPA0") ?? -6.404567e+001
        sbe_cal_ptempa1 = header.getValueForKeyAsDouble("PTEMPA1") ?? 5.531468e+001
        sbe_cal_ptempa2 = header.getValueForKeyAsDouble("PTEMPA2") ?? -1.148773e+000
        sbe_cal_ptca0 = header.getValueForKeyAsDouble("PTCA0") ?? 5.245131e+005
        sbe_cal_ptca1 = header.getValueForKeyAsDouble("PTCA1") ?? -2.821193e+001
        sbe_cal_ptca2 = header.getValueForKeyAsDouble("PTCA2") ?? 5.771249e-001
        sbe_cal_ptcb0 = header.getValueForKeyAsDouble("PTCB0") ?? 2.517913e+001
        sbe_cal_ptcb1 = header.getValueForKeyAsDouble("PTCB1") ?? 1.825000e-003
        sbe_cal_ptcb2 = header.getValueForKeyAsDouble("PTCB2") ?? 0.000000e+000
        sbe_cal_cg = header.getValueForKeyAsDouble("CG") ?? -9.797148e-001
        sbe_cal_ch = header.getValueForKeyAsDouble("CH") ?? 1.247451e-001
        sbe_cal_ci = header.getValueForKeyAsDouble("CI") ?? -1.115099e-004
        sbe_cal_cj = header.getValueForKeyAsDouble("CJ") ?? 2.674915e-005
        sbe_cal_ctcor = header.getValueForKeyAsDouble("CTCOR") ?? 3.250000e-006
        sbe_cal_cpcor = header.getValueForKeyAsDouble("CPCOR") ?? -9.570000e-008
        PCodeData_lat = header.getValueForKeyAsDouble("PCodeData.lat") ?? 0.0
    }
    let sbe_recs_per_block = 2
    let sbe_timestamp_len = 16
    let sbe_channel6_len = 6
    let sbe_channel4_len = 4
    func sbe_block_rec_len() -> Int {
        return sbe_timestamp_len + 3 * sbe_channel6_len + sbe_channel4_len + 2 // <CR><LF>
    }
    override func getExpectedBlockSize() -> Int {
        return sbe_block_rec_len() * sbe_recs_per_block
    }
    func parseSbeTimestamp(packet: ModrawPacket, i: inout Int) -> Double {
        let time_s = Double(packet.parent.peekHex(at: i, len: sbe_timestamp_len)!) / 1000.0
        i += sbe_timestamp_len
        return time_s
    }
    func parseSbeChannel6(packet: ModrawPacket, i: inout Int) -> Int {
        let channel = packet.parent.peekHex(at: i, len: sbe_channel6_len)!
        i += sbe_channel6_len
        return Int(channel)
    }
    func parseSbeChannel4(packet: ModrawPacket, i: inout Int) -> Int {
        let channel = packet.parent.peekHex(at: i, len: sbe_channel4_len)!
        i += sbe_channel4_len
        return Int(channel)
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
    func sw_salrt(T: Double) -> Double {
        let c0 =  0.6766097
        let c1 =  2.00564e-2
        let c2 =  1.104259e-4
        let c3 = -6.9698e-7
        let c4 =  1.0031e-9
        return c0 + (c1 + (c2 + (c3 + c4 * T) * T) * T) * T
    }
    func sw_salrp(R: Double, T: Double, P: Double) -> Double {
        let d1 =  3.426e-2
        let d2 =  4.464e-4
        let d3 =  4.215e-1
        let d4 = -3.107e-3
        let e1 =  2.070e-5
        let e2 = -6.370e-10
        let e3 =  3.989e-15
        
        return 1 + (P * (e1 + e2 * P + e3 * P*P)) / (1 + d1 * T + d2 * T*T + (d3 + d4 * T) * R)
    }
    func sw_sals(Rt: Double, T: Double) -> Double {
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
    func sw_salt(cndr: Double, T: Double, P: Double) -> Double {
        let R = cndr
        let rt = sw_salrt(T: T)
        let Rp = sw_salrp(R: R, T: T, P: P)
        let Rt = R / (Rp * rt)
        return sw_sals(Rt: Rt, T: T)
    }
    func sw_dpth(P: Double, LAT: Double) -> Double {
        let c1 = +9.72659
        let c2 = -2.2512E-5
        let c3 = +2.279E-10
        let c4 = -1.82E-15
        let gam_dash = 2.184e-6
        
        let X = sin(abs(LAT) * Double.pi / 180.0)
        let X2 = X * X
        let bot_line = 9.780318 * (1.0 + (5.2788 - 3 + 2.36 - 5 * X2) * X2) + gam_dash * 0.5 * P
        let top_line = (((c4 * P + c3) * P + c2) * P + c1) * P
        return top_line / bot_line
    }
    override func parse(packet: ModrawPacket, model: Model) {
        var i = getEpsiPayloadStart(packet: packet)

        let (prev_block, this_block) = model.d.ctd_blocks.getLastTwoBlocks()
        var prev_time_s = prev_block?.time_s.last!

        for j in 0..<sbe_recs_per_block {
            let time_s = parseSbeTimestamp(packet: packet, i: &i)

            let T_raw = parseSbeChannel6(packet: packet, i: &i)
            let C_raw = parseSbeChannel6(packet: packet, i: &i)
            let P_raw = parseSbeChannel6(packet: packet, i: &i)
            let PT_raw = parseSbeChannel4(packet: packet, i: &i)
            i += 2 // skip the <CR><LF>

            if !isValidSample(this_block: this_block, sample_index: j, prev_time_s: &prev_time_s, time_s: time_s) {
                continue
            }

            let T = sbe49_get_temperature(T_raw: T_raw)
            let P = sbe49_get_pressure(P_raw: P_raw, PT_raw: PT_raw)
            let C = sbe49_get_conductivity(C_raw: C_raw, T: T, P: P)
            let sbe_c3515 = 42.914
            let S = sw_salt(cndr: max(C, 0.0) * 10.0 / sbe_c3515, T: T, P: P);
            let z = sw_dpth(P: P, LAT: PCodeData_lat)

            this_block.time_s.append(time_s)
            this_block.P.append(P)
            this_block.T.append(T)
            this_block.S.append(S)
            this_block.z.append(z)
        }
        model.d.ctd_blocks.removeLastBlockIfEmpty()
    }
}
