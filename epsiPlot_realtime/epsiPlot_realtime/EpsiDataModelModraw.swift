import Foundation

class EpsiDataModelModraw: EpsiDataModel
{
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
    var PCodeData_lat : Double = 0

    var epsi_blocks : [EpsiData] = []
    var ctd_blocks : [CtdData] = []

    var scanningFolderUrl : URL?
    override init(mode: Mode) {
        super.init(mode: mode)
        // Debugging:
#if DEBUG
        openFile(URL(fileURLWithPath: "/Usjnjners/catalin/Documents/OCEAN_data/epsiPlot/EPSI24_11_06_054202.modraw"))
#endif
    }
    var lastUpdateTime = 0.0
    var prev_time_window_start = 0.0
    override func updateViewData() -> Bool {
        if (scanningFolderUrl != nil) {
            scanFolder()
        }

        if (!dataChanged) {
            return false
        }

        epsi.removeAll()
        ctd.removeAll()

        let epsi_time = epsi_blocks.isEmpty ? 0.0 : epsi_blocks.last!.time_s.last! - time_window_length
        let ctd_time = ctd_blocks.isEmpty ? 0.0 : ctd_blocks.last!.time_s.last! - time_window_length
        time_window_start = max(epsi_time, ctd_time)

        while !epsi_blocks.isEmpty && epsi_blocks.first!.time_s.last! < time_window_start {
            epsi_blocks.remove(at: 0)
        }
        if (!epsi_blocks.isEmpty) {
            epsi.reserveCapacity(epsi_blocks.reduce(0) { $0 + $1.time_s.count })
            var first_entry = epsi_blocks[0].getIndexForTime(time_window_start)
            for block in epsi_blocks {
                epsi.append(from: block, first: first_entry, count: block.time_s.count - first_entry)
                first_entry = 0
            }
        }
        while !ctd_blocks.isEmpty && ctd_blocks.first!.time_s.last! < time_window_start {
            ctd_blocks.remove(at: 0)
        }
        if (!ctd_blocks.isEmpty) {
            ctd.reserveCapacity(ctd_blocks.reduce(0) { $0 + $1.time_s.count })
            var first_entry = ctd_blocks[0].getIndexForTime(time_window_start)
            for block in ctd_blocks {
                ctd.append(from: block, first: first_entry, count: block.time_s.count - first_entry)
                first_entry = 0
            }
        }
        super.onDataChanged()
        return true
    }

    static func getKeyValue(key: String, header: String) -> Double {
        let indexOfKey = header.index(of: key)
        if (indexOfKey == nil) {
            print("Key '\(key)' not found in header!")
            assert(false)
            return 0
        }
        let indexAfterKey = header.index(indexOfKey!, offsetBy: key.count)
        let valueOnwards = header[indexAfterKey...]
        var indexOfCrlf = valueOnwards.index(of: "\r\n")
        if (indexOfCrlf == nil || indexOfCrlf! > valueOnwards.index(indexAfterKey, offsetBy: 32)) {
            indexOfCrlf = valueOnwards.index(of: "\n")
        }
        if (indexOfCrlf == nil) {
            print("Unterminated key '\(key)' value '\(valueOnwards)'")
            assert(false)
            return 0
        }
        let valueStr = valueOnwards[..<indexOfCrlf!].trimmingCharacters(in: .whitespaces)
        //print("\(key.trimmingCharacters(in: .whitespacesAndNewlines))\(value)")
        return Double(valueStr)!
    }

    func readCalibrationData(header: String) {
        sbe_cal_ta0 = EpsiDataModelModraw.getKeyValue(key: "\nTA0=", header: header)
        sbe_cal_ta1 = EpsiDataModelModraw.getKeyValue(key: "\nTA1=", header: header)
        sbe_cal_ta2 = EpsiDataModelModraw.getKeyValue(key: "\nTA2=", header: header)
        sbe_cal_ta3 = EpsiDataModelModraw.getKeyValue(key: "\nTA3=", header: header)
        sbe_cal_pa0 = EpsiDataModelModraw.getKeyValue(key: "\nPA0=", header: header)
        sbe_cal_pa1 = EpsiDataModelModraw.getKeyValue(key: "\nPA1=", header: header)
        sbe_cal_pa2 = EpsiDataModelModraw.getKeyValue(key: "\nPA2=", header: header)
        sbe_cal_ptempa0 = EpsiDataModelModraw.getKeyValue(key: "\nPTEMPA0=", header: header)
        sbe_cal_ptempa1 = EpsiDataModelModraw.getKeyValue(key: "\nPTEMPA1=", header: header)
        sbe_cal_ptempa2 = EpsiDataModelModraw.getKeyValue(key: "\nPTEMPA2=", header: header)
        sbe_cal_ptca0 = EpsiDataModelModraw.getKeyValue(key: "\nPTCA0=", header: header)
        sbe_cal_ptca1 = EpsiDataModelModraw.getKeyValue(key: "\nPTCA1=", header: header)
        sbe_cal_ptca2 = EpsiDataModelModraw.getKeyValue(key: "\nPTCA2=", header: header)
        sbe_cal_ptcb0 = EpsiDataModelModraw.getKeyValue(key: "\nPTCB0=", header: header)
        sbe_cal_ptcb1 = EpsiDataModelModraw.getKeyValue(key: "\nPTCB1=", header: header)
        sbe_cal_ptcb2 = EpsiDataModelModraw.getKeyValue(key: "\nPTCB2=", header: header)
        sbe_cal_cg = EpsiDataModelModraw.getKeyValue(key: "\nCG=", header: header)
        sbe_cal_ch = EpsiDataModelModraw.getKeyValue(key: "\nCH=", header: header)
        sbe_cal_ci = EpsiDataModelModraw.getKeyValue(key: "\nCI=", header: header)
        sbe_cal_cj = EpsiDataModelModraw.getKeyValue(key: "\nCJ=", header: header)
        sbe_cal_ctcor = EpsiDataModelModraw.getKeyValue(key: "\nCTCOR=", header: header)
        sbe_cal_cpcor = EpsiDataModelModraw.getKeyValue(key: "\nCPCOR=", header: header)
        PCodeData_lat = EpsiDataModelModraw.getKeyValue(key: "\nPCodeData.lat =", header: header)
    }

    var currentModraw: ModrawParser? = nil
    var currentModrawUrl: URL? = nil
    var partialEndPacket: Data? = nil

    func parsePacketsLoop()
    {
        var packet = currentModraw!.parsePacket()
        while packet != nil {
            switch packet!.signature {
            case "$EFE4":
                if (isValidPacketEFE4(packet: packet!)) {
                    parseEFE4(packet: packet!)
                    dataChanged = true
                } else {
                    currentModraw!.rewindPacket(packet: packet!)
                }
            case "$SB49":
                if (isValidPacketSB49(packet: packet!)) {
                    parseSB49(packet: packet!, sbe_format: SBE_Format.eng)
                    dataChanged = true
                } else {
                    currentModraw!.rewindPacket(packet: packet!)
                }
            default:
                break
            }
            packet = currentModraw!.parsePacket()
        }
    }
    override func openFolder(_ folderUrl: URL)
    {
        super.openFolder(folderUrl)
        scanningFolderUrl = folderUrl

        time_window_start = 0.0
        time_window_length = 20.0 // seconds
    }
    func scanFolder()
    {
        if let enumerator = FileManager.default.enumerator(at: scanningFolderUrl!, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            var allFiles = [String]()
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile! {
                        let fileURLString = fileURL.path
                        if fileURLString.lowercased().hasSuffix(".modraw") {
                            allFiles.append(fileURLString)
                        }
                    }
                } catch {
                    windowTitle = error.localizedDescription
                    print(error, fileURL)
                }
            }

            allFiles.sort()

            let secondMostRecentFile : String? = allFiles.count > 1 ? allFiles[allFiles.count - 2] : nil
            let mostRecentFile : String? = allFiles.count > 0 ? allFiles[allFiles.count - 1] : nil
            if (secondMostRecentFile != nil) {
                if (currentModrawUrl != nil) {
                    if (mostRecentFile! == currentModrawUrl!.path) {
                        // We are parsing the most recent file
                        tryReadMoreData()
                    } else if (secondMostRecentFile! == currentModrawUrl!.path) {
                        // We are parsing the second most recent file
                        tryReadMoreData()
                        // Start parsing the most recent one
                        startParsing(fileUrl: URL(fileURLWithPath: mostRecentFile!))
                    }
                } else {
                    // Parse the second most recent file first, in the case the most recent is partial
                    startParsing(fileUrl: URL(fileURLWithPath: secondMostRecentFile!))
                    // Start parsing the most recent file
                    startParsing(fileUrl: URL(fileURLWithPath: mostRecentFile!))
                }
            } else if (mostRecentFile != nil) {
                if (currentModrawUrl != nil && mostRecentFile! == currentModrawUrl!.path) {
                    // We only have one file and are already parsing it
                    tryReadMoreData()
                } else {
                    // We only have one file, start parsing it
                    startParsing(fileUrl: URL(fileURLWithPath: mostRecentFile!))
                }
            } // else no files to parse yet in the folder
        }
    }
    func startParsing(fileUrl: URL)
    {
        if (currentModraw != nil){
            partialEndPacket = currentModraw!.extractPartialEndPacket()
            if partialEndPacket != nil {
                print("Extracted partial last packet of \(partialEndPacket!).")
            }
        }

        currentModrawUrl = fileUrl
        do {
            currentModraw = try ModrawParser(fileUrl: fileUrl)
        } catch {
            windowTitle = error.localizedDescription
            print(error)
            return
        }

        let header = currentModraw!.parseHeader()
        readCalibrationData(header: header!)

        if (partialEndPacket != nil) {
            print("Patching partial first packet with \(partialEndPacket!).")
            currentModraw!.insertPartialEndPacket(partialEndPacket!)
            partialEndPacket = nil
        } else {
            currentModraw!.skipToFirstPacket()
        }

        parsePacketsLoop()
    }
    override func openFile(_ fileUrl: URL)
    {
        assert(fileUrl.pathExtension == "modraw")
        super.openFile(fileUrl)
        scanningFolderUrl = nil

        startParsing(fileUrl: fileUrl)

        let epsi_time_begin = epsi_blocks.isEmpty ? 0.0 : epsi_blocks.first!.time_s.first!
        let ctd_time_begin = ctd_blocks.isEmpty ? 0.0 : ctd_blocks.first!.time_s.first!
        let epsi_time_end = epsi_blocks.isEmpty ? 0.0 : epsi_blocks.last!.time_s.last!
        let ctd_time_end = ctd_blocks.isEmpty ? 0.0 : ctd_blocks.last!.time_s.last!

        if (!epsi_blocks.isEmpty && !ctd_blocks.isEmpty) {
            time_window_start = min(epsi_time_begin, ctd_time_begin)
            time_window_length = max(epsi_time_end, ctd_time_end) - time_window_start
        } else if (!ctd_blocks.isEmpty) {
            time_window_start = ctd_time_begin
            time_window_length = ctd_time_end - time_window_start
        } else if (!epsi_blocks.isEmpty) {
            time_window_start = epsi_time_begin
            time_window_length = epsi_time_end - time_window_start
        }
    }
    func tryReadMoreData()
    {
        let fileAttributes = try! FileManager.default.attributesOfItem(atPath: currentModrawUrl!.path)
        let newModrawSize = fileAttributes[.size] as! Int
        let oldModrawSize = currentModraw!.getSize()
        if (oldModrawSize < newModrawSize)
        {
            let inputFileData = try! Data(contentsOf: currentModrawUrl!)
            var newData = [UInt8](repeating: 0, count: newModrawSize - oldModrawSize)
            inputFileData.copyBytes(to: &newData, from: oldModrawSize..<newModrawSize)
            currentModraw!.appendData(data: newData)
            parsePacketsLoop()
        }
    }
    static let block_timestamp_len = 16
    static let block_size_len = 8
    static let chksum1_len = 3 // *<HEX><HEX>
    static let chksum2_len = 5 // *<HEX><HEX><CR><LF>

    static let efe_gain = Double(1)
    static let efe_bit_counts = 24
    static let efe_acc_offset = 1.8 / 2
    static let efe_acc_factor = 0.4
    static let efe_timestamp_len = 8
    static let efe_n_channels = 7
    static let efe_channel_len = 3
    static let efe_recs_per_block = 80
    static let efe_rec_len = EpsiDataModelModraw.efe_timestamp_len + EpsiDataModelModraw.efe_n_channels * EpsiDataModelModraw.efe_channel_len
    static let efe_block_data_len = EpsiDataModelModraw.efe_rec_len * EpsiDataModelModraw.efe_recs_per_block

    static func Unipolar(FR: Double, data: Int) -> Double {
        return FR / EpsiDataModelModraw.efe_gain * (Double(data) / Double(pow(Double(2), Double(EpsiDataModelModraw.efe_bit_counts))))
    }
    static func Bipolar(FR: Double, data: Int) -> Double {
        return FR / EpsiDataModelModraw.efe_gain * (Double(data) / Double(pow(Double(2), Double(EpsiDataModelModraw.efe_bit_counts - 1))) - 1)
    }
    static func volt_to_g(data: Double) -> Double {
        return (data - EpsiDataModelModraw.efe_acc_offset) / EpsiDataModelModraw.efe_acc_factor
    }
    func parseEfeChannel(_ i: inout Int) -> Int {
        let channel = Int(currentModraw!.parseBin(start: i, len: EpsiDataModelModraw.efe_channel_len))
        i += EpsiDataModelModraw.efe_channel_len
        return channel
    }
    func parseEFE4(packet : ModrawPacket) {
        var i = packet.payloadStart
        i += EpsiDataModelModraw.block_timestamp_len
        i += EpsiDataModelModraw.block_size_len
        i += EpsiDataModelModraw.chksum1_len

        let prev_block = epsi_blocks.last
        var prev_time_s = (prev_block != nil) ? prev_block!.time_s.last! : nil

        let this_block : EpsiData
        if (prev_block == nil || prev_block!.isFull()) {
            this_block = EpsiData()
            epsi_blocks.append(this_block)
        } else {
            this_block = prev_block!
        }

        for _ in 0..<EpsiDataModelModraw.efe_recs_per_block {
            let time_s = Double(currentModraw!.parseBinBE(start: i, len: EpsiDataModelModraw.efe_timestamp_len)) / 1000.0
            i += EpsiDataModelModraw.efe_timestamp_len

            if (prev_time_s != nil) {
                this_block.checkAndAppendGap(t0: prev_time_s!, t1: time_s)
            }
            prev_time_s = time_s

            let t1_count = parseEfeChannel(&i)
            let t2_count = parseEfeChannel(&i)
            let s1_count = parseEfeChannel(&i)
            let s2_count = parseEfeChannel(&i)
            let a1_count = parseEfeChannel(&i)
            let a2_count = parseEfeChannel(&i)
            let a3_count = parseEfeChannel(&i)

            this_block.time_s.append(time_s)
            this_block.t1_volt.append(EpsiDataModelModraw.Unipolar(FR: 2.5, data: t1_count))
            this_block.t2_volt.append(EpsiDataModelModraw.Unipolar(FR: 2.5, data: t2_count))

            switch mode {
            case .EPSI:
                this_block.s1_volt.append(EpsiDataModelModraw.Bipolar(FR: 2.5, data: s1_count))
                this_block.s2_volt.append(EpsiDataModelModraw.Bipolar(FR: 2.5, data: s2_count))
            case .FCTD:
                this_block.s1_volt.append(EpsiDataModelModraw.Unipolar(FR: 2.5, data: s1_count))
                this_block.s2_volt.append(EpsiDataModelModraw.Unipolar(FR: 2.5, data: s2_count))
            }

            let a1_volt = EpsiDataModelModraw.Unipolar(FR: 1.8, data: a1_count)
            let a2_volt = EpsiDataModelModraw.Unipolar(FR: 1.8, data: a2_count)
            let a3_volt = EpsiDataModelModraw.Unipolar(FR: 1.8, data: a3_count)

            this_block.a1_g.append(EpsiDataModelModraw.volt_to_g(data: a1_volt))
            this_block.a2_g.append(EpsiDataModelModraw.volt_to_g(data: a2_volt))
            this_block.a3_g.append(EpsiDataModelModraw.volt_to_g(data: a3_volt))
        }
    }

    static let sbe_recs_per_block = 2
    static let sbe_timestamp_length = 16
    static let sbe_channel6_len = 6
    static let sbe_channel4_len = 4
    static let sbe_block_rec_len = EpsiDataModelModraw.sbe_timestamp_length + 3 * EpsiDataModelModraw.sbe_channel6_len + EpsiDataModelModraw.sbe_channel4_len + 2 // <CR><LF>
    static let sbe_block_data_len = EpsiDataModelModraw.sbe_block_rec_len * EpsiDataModelModraw.sbe_recs_per_block

    func parseSbeChannel6(_ i: inout Int) -> Int {
        let channel = currentModraw!.parseHex(start: i, len: EpsiDataModelModraw.sbe_channel6_len)
        i += EpsiDataModelModraw.sbe_channel6_len
        return Int(channel)
    }
    func parseSbeChannel4(_ i: inout Int) -> Int {
        let channel = currentModraw!.parseHex(start: i, len: EpsiDataModelModraw.sbe_channel4_len)
        i += EpsiDataModelModraw.sbe_channel4_len
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
    static func sw_dpth(P: Double, LAT: Double) -> Double {
        assert(LAT >= -90 && LAT <= 90)
        
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
    func parseSB49(packet : ModrawPacket, sbe_format : SBE_Format) {
        var i = packet.payloadStart
        i += EpsiDataModelModraw.block_timestamp_len
        i += EpsiDataModelModraw.block_size_len
        i += EpsiDataModelModraw.chksum1_len

        let prev_block = ctd_blocks.last
        var prev_time_s = (prev_block != nil) ? prev_block!.time_s.last! : nil

        let this_block : CtdData
        if (prev_block == nil || prev_block!.isFull()) {
            this_block = CtdData()
            ctd_blocks.append(this_block)
        } else {
            this_block = prev_block!
        }
        for _ in 0..<EpsiDataModelModraw.sbe_recs_per_block {
            let time_s = Double(currentModraw!.parseHex(start: i, len: EpsiDataModelModraw.sbe_timestamp_length)) / 1000.0
            i += EpsiDataModelModraw.sbe_timestamp_length

            if (prev_time_s != nil) {
                this_block.checkAndAppendGap(t0: prev_time_s!, t1: time_s)
            }
            prev_time_s = time_s

            this_block.time_s.append(time_s)
            switch sbe_format {
            case SBE_Format.PTS:
                assert(false)

            case SBE_Format.eng:
                let T_raw = parseSbeChannel6(&i)
                let C_raw = parseSbeChannel6(&i)
                let P_raw = parseSbeChannel6(&i)
                let PT_raw = parseSbeChannel4(&i)

                let T = sbe49_get_temperature(T_raw: T_raw)
                let P = sbe49_get_pressure(P_raw: P_raw, PT_raw: PT_raw)
                let C = sbe49_get_conductivity(C_raw: C_raw, T: T, P: P)
                let sbe_c3515 = 42.914
                let S = EpsiDataModelModraw.sw_salt(cndr: max(C, 0.0) * 10.0 / sbe_c3515, T: T, P: P);
                let z = EpsiDataModelModraw.sw_dpth(P: P, LAT: PCodeData_lat)
                this_block.P.append(P)
                this_block.T.append(T)
                this_block.S.append(S)
                this_block.z.append(z)
            }
            i += 2 // skip the <CR><LF>
        }
    }
    func isValidPacket(packet : ModrawPacket, expectedDataLen: Int) -> Bool {
        var i = packet.payloadStart
        if (i + EpsiDataModelModraw.block_timestamp_len >= packet.packetEnd) { return false }
        //print("block_timestamp: \(currentModraw!.parseString(start: i, len: EpsiDataModelModraw.block_timestamp_len))")
        i += EpsiDataModelModraw.block_timestamp_len

        if (i + EpsiDataModelModraw.block_size_len >= packet.packetEnd) { return false }
        //print("block_size: \(currentModraw!.parseString(start: i, len: EpsiDataModelModraw.block_size_len))")
        let block_size = currentModraw!.parseHex(start: i, len: EpsiDataModelModraw.block_size_len)
        if (block_size != expectedDataLen) { return false }
        i += EpsiDataModelModraw.block_size_len

        if (i + EpsiDataModelModraw.chksum1_len >= packet.packetEnd) { return false }
        //print("chksum1: \(currentModraw!.parseString(start: i, len: EpsiDataModelModraw.chksum1_len))")
        if (currentModraw!.data[i] != ModrawParser.ASCII_STAR) { return false }
        i += EpsiDataModelModraw.chksum1_len

        //print("chksum2: \(currentModraw!.parseString(start: packet.packetEnd - EpsiDataModelModraw.chksum2_len, len: EpsiDataModelModraw.chksum2_len))")
        if (currentModraw!.data[packet.packetEnd - EpsiDataModelModraw.chksum2_len] != ModrawParser.ASCII_STAR) { return false }

        let actual_data_len = packet.packetEnd - i - EpsiDataModelModraw.chksum2_len
        //print("actual_data_len: \(actual_data_len) expectedDataLen: \(expectedDataLen)")
        if (actual_data_len != expectedDataLen) { return false }

        return true
    }
    func isValidPacketEFE4(packet : ModrawPacket) -> Bool {
        return isValidPacket(packet: packet, expectedDataLen: EpsiDataModelModraw.efe_block_data_len)
    }
    func isValidPacketSB49(packet : ModrawPacket) -> Bool {
        return isValidPacket(packet: packet, expectedDataLen: EpsiDataModelModraw.sbe_block_data_len)
    }
}
