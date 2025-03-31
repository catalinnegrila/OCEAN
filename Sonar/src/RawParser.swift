import Foundation

public extension UInt8 {
    func toChar() -> Character {
        return Character(UnicodeScalar(self))
    }
    var isHexDigit: Bool { get { toChar().isHexDigit }}
    var isNumber: Bool { get { toChar().isNumber }}
}

internal class RawBlock_fheader_param {
    var seq_length: Int         // no. of samples per sequence
    var samples_to_acquire: Int // # of samples to record
    var n_channels: Int         // number channels (2* total receiver boards)
    var sample_period: Int      // microseconds
    var fclk0_freq: Int   // Hz
    var tx_map_period: Int      // b5P H1 clocks(2/xtal_freq)
    var n_tx_specs: Int         // no. of tx specs
    var rly_control: Int        // relay control word
    var sync_mode: Int          // tds or free running or standard sync mode
    var sync_modulus: Int       // sequence start interval in tds clks units
    var mix_freq: Int           // mixer frequency
    var n_power_amps: Int       // number of power amps installed
    var rx_hdf_deci_pin_slct: Int // HSP HDF decimator pin select
    var rx_hsp_card_slots: Int  // HSP DSP card slots
    var set_time_on_run: Int    // this option allows the user the set the time at beginning of run
    var detect_flood: Int
    var clk_wiz_phase: Int      // phase of the slower clock for sampling sonar data (x1000)
    var clk_wiz_duty_cycle: Int // duty cycle of the slower clock for sampling sonar data (x1000)
    var dummy: Int
    internal init(reader: ByteArrayReader) {
        seq_length = reader.readLEUInt32()
        samples_to_acquire = reader.readLEUInt32()
        n_channels = reader.readLEUInt32()
        sample_period = reader.readLEUInt32()
        fclk0_freq = reader.readLEUInt32()
        tx_map_period = reader.readLEUInt32()
        n_tx_specs = reader.readLEUInt32()
        rly_control = reader.readLEUInt32()
        sync_mode = reader.readLEUInt32()
        sync_modulus = reader.readLEUInt32()
        mix_freq = reader.readLEUInt32()
        n_power_amps = reader.readLEUInt32()
        rx_hdf_deci_pin_slct = reader.readLEUInt32()
        rx_hsp_card_slots = reader.readLEUInt32()
        set_time_on_run = reader.readLEUInt32()
        detect_flood = reader.readLEUInt32()
        clk_wiz_phase = reader.readLEUInt32()
        clk_wiz_duty_cycle = reader.readLEUInt32()
        dummy = reader.readLEUInt32()
    }
}

internal class RawBlock_fheader_txspec {
    var tx_num: Int             // transmit number
    var start_time: Int         // sample no. to start xmit
    var carrier_freq0: Int      // carrier frequency in hertz
    var carrier_freq1: Int      // carrier frequency2 in hertz
    var tx_reps: Int            // no. of transmissions of code
    var tx_rep_period: Int      // samples till next transmission
    var bit_length: Int         // no. of samples per bit
    var code_nbits: Int         // no. of bits in sub-code
    var code: [Int]             // code bit pattern
    var code_reps: Int          // no. of sub-code repeats
    var bit_smoothing_fact: Int // time constant to smooth bits
    var power_stg_out_slct: Int // not used currently
    var dac_slct: Int           // output DAC select 0 or 1
    var gate_slct: Int          // output gate select
    var tx_pre_gate_delay: Int  // gate delay before transmit (should be in ms)
    var tx_post_gate_delay: Int // gate delay after transmit (should be in ms)
    var power_level: Int        // default power amp power level

    internal init(reader: ByteArrayReader) {
        tx_num = reader.readLEUInt32()
        start_time = reader.readLEUInt32()
        carrier_freq0 = reader.readLEUInt32()
        carrier_freq1 = reader.readLEUInt32()
        tx_reps = reader.readLEUInt32()
        tx_rep_period = reader.readLEUInt32()
        bit_length = reader.readLEUInt32()
        code_nbits = reader.readLEUInt32()
        code = [Int](repeating: 0, count: 32)
        for i in 0..<code.count {
            code[i] = reader.readLEInt32()
        }
        code_reps = reader.readLEUInt32()
        bit_smoothing_fact = reader.readLEUInt32()
        power_stg_out_slct = reader.readLEUInt32()
        dac_slct = reader.readLEUInt32()
        gate_slct = reader.readLEUInt32()
        tx_pre_gate_delay = reader.readLEUInt32()
        tx_post_gate_delay = reader.readLEUInt32()
        power_level = reader.readLEUInt32()
    }
}

internal class RawBlock_fheader_fwriter {
    var size: Int
    var max_file_size: Int
    var max_rec_num: Int
    var raw1_rec_enable: Int
    var raw2_rec_enable: Int
    var log_rec_enable: Int
    var log_file_size: Int
    var raw1_path: String
    var raw2_path: String
    var log_path: String
    var raw1_recs_written: Int
    var raw2_recs_written: Int
    internal init(reader: ByteArrayReader) {
        size = reader.readLEInt64()
        max_file_size = reader.readLEInt64()
        max_rec_num = reader.readLEInt32()
        raw1_rec_enable = reader.readLEInt32()
        raw2_rec_enable = reader.readLEInt32()
        log_rec_enable = reader.readLEInt32()
        log_file_size = reader.readLEInt64()
        raw1_path = reader.readString(256)
        raw2_path = reader.readString(256)
        log_path = reader.readString(256)
        raw1_recs_written = reader.readLEInt32()
        raw2_recs_written = reader.readLEInt32()
    }
}

internal class RawBlock_fheader {
    var size: Int
    var app_ver: String
    var header_ver: String
    var setup_ver: String
    var cntrl_ser_num: Int
    var runname: String
    var runnotes: String
    var param: RawBlock_fheader_param
    var txspec0: RawBlock_fheader_txspec
    var txspec1: RawBlock_fheader_txspec
    var fwriter: RawBlock_fheader_fwriter
    var rec_size: Int
    var rec_header_size: Int
    var rec_count: Int
    var file_size: Int
    var setup_file_size: Int
    var setup_file: String
    internal init(reader: ByteArrayReader) {
        size = reader.readLEUInt64()
        app_ver = reader.readString(64)
        header_ver = reader.readString(32)
        setup_ver = reader.readString(32)
        cntrl_ser_num = reader.readLEUInt32()
        runname = reader.readString(256)
        runnotes = reader.readString(1024)
        param = RawBlock_fheader_param(reader: reader)
        txspec0 = RawBlock_fheader_txspec(reader: reader)
        txspec1 = RawBlock_fheader_txspec(reader: reader)
        fwriter = RawBlock_fheader_fwriter(reader: reader)
        rec_size = reader.readLEUInt64()
        rec_header_size = reader.readLEUInt64()
        rec_count = reader.readLEUInt64()
        file_size = reader.readLEUInt64()
        setup_file_size = reader.readLEUInt64()
        setup_file = reader.readString(setup_file_size)
    }
}
internal class RawBlock_rheader {
    var size: Int
    var rec_size: Int
    var id: Int
    var timemark: Int // timemark from hydra sonar record
    var status: Int
    var quality: Int // tests if buffer is synchronous
    var hdss_mru_recs_cnt: Int
    var ship_nav_recs_cnt: Int
    var sbe38fwd_recs_cnt: Int
    var sbe38aft_recs_cnt: Int

    internal init(reader: ByteArrayReader) {
        size = reader.readLEUInt64()
        rec_size = reader.readLEUInt64()
        id = reader.readLEUInt64()
        timemark = reader.readLEUInt64()
        status = reader.readLEUInt32()
        quality = reader.readLEUInt32()
        hdss_mru_recs_cnt = reader.readLEUInt32()
        ship_nav_recs_cnt = reader.readLEUInt32()
        sbe38fwd_recs_cnt = reader.readLEUInt32()
        sbe38aft_recs_cnt = reader.readLEUInt32()
    }
}

internal class RawBlock_hdss_mru_rec {
    var size: Int
    var timemark: Int // timemark from hydra sonar record
    var type: String
    var heave_m: Float
    var roll_deg: Float
    var pitch_deg: Float
    var heading_deg: Float
    var temperature_c: Float
    var input_volt: Float
    var unit_stat_wrd: Int
    var raw_str: String // $PAPR,AAAA.aa,B,RRRR.rr,PPP.pp,HHH.hh,TTT.t,VV.v,SSSS*CC<CR><LF>
    internal init(reader: ByteArrayReader) {
        size = reader.readLEUInt32()
        timemark = reader.readLEUInt64()
        type = reader.readString(8)
        heave_m = reader.readLESingle()
        roll_deg = reader.readLESingle()
        pitch_deg = reader.readLESingle()
        heading_deg = reader.readLESingle()
        temperature_c = reader.readLESingle()
        input_volt = reader.readLESingle()
        unit_stat_wrd = reader.readLEUInt16()
        raw_str = reader.readString(59)
    }
}

internal class RawBlock_ship_nav_rec {
    var size: Int
    var timemark: Int           // timemark from hydra sonar record
    var header_1_byte: Int
    var header_2_byte: Int
    var time_secs: Int          // seconds from Epoch (1970-1-1)
    var time_frac_secs: Int     // 0.0001 second (0-9999)
    var latitude: Int           // 2^30 = 90 deg, +/- 90 degrees, -2^30 to 2^30
    var longitude: Int          // 2^30 = 90 deg, +/- 180 degrees, -2^31 to 2^31
    var height: Int             // cm
    var heave_realtime: Int     // cm
    var vel_n: Int              // velocity north cm/s
    var vel_e: Int              // velocity east cm/s
    var vel_d: Int              // velocity down cm/s
    var roll: Int               // 2^14 = 90 degrees (-2^15 to 2^15)
    var pitch: Int              // 2^14 = 90 degrees (-2^15 to 2^15)
    var heading: Int            // 2^14 = 90 degrees (0 to 2^16)
    var roll_rate: Int          // 2^14 = 90 degrees/sec (-2^15 to 2^15)
    var pitch_rate: Int         // 2^14 = 90 degrees/sec (-2^15 to 2^15)
    var yaw_rate: Int           // 2^14 = 90 degrees/sec (-2^15 to 2^15)
    var delayed_heave_time_sec: Int // seconds
    var delayed_heave_time_frac_secs: Int // 0.0001 second (0-9999)
    var heave_delayed: Int      // cm
    var status_wrd: Int
    var chk_sum: Int
    
    internal init(reader: ByteArrayReader) {
        size = reader.readLEUInt32()
        timemark = reader.readLEUInt64()
        header_1_byte = reader.readLEUInt8()
        header_2_byte = reader.readLEUInt8()
        time_secs = reader.readLEInt32()
        time_frac_secs = reader.readLEUInt16()
        latitude = reader.readLEInt32()
        longitude = reader.readLEInt32()
        height = reader.readLEInt32()
        heave_realtime = reader.readLEInt16()
        vel_n = reader.readLEInt16()
        vel_e = reader.readLEInt16()
        vel_d = reader.readLEInt16()
        roll = reader.readLEInt16()
        pitch = reader.readLEInt16()
        heading = reader.readLEUInt16()
        roll_rate = reader.readLEInt16()
        pitch_rate = reader.readLEInt16()
        yaw_rate = reader.readLEInt16()
        delayed_heave_time_sec = reader.readLEInt32()
        delayed_heave_time_frac_secs = reader.readLEUInt16()
        heave_delayed = reader.readLEInt16()
        status_wrd = reader.readLEUInt16()
        chk_sum = reader.readLEUInt16()
    }
}

internal class RawBlock_sbe38_rec {
    var size: Int
    var timemark: Int // timemark from hydra sonar record
    var temperature_c: Float

    internal init(reader: ByteArrayReader) {
        size = reader.readLEUInt32()
        timemark = reader.readLEUInt64()
        temperature_c = reader.readLESingle()
    }
}

let SONAR_UART_HDSS_MRU_N_RECS_SEQ = 250
let SONAR_UART_SHIP_NAV_N_RECS_SEQ = 250
let SONAR_UART_SBE38FWD_N_RECS_SEQ = 20
let SONAR_UART_SBE38AFT_N_RECS_SEQ = 20

public class RawParser {
    public var data = [UInt8]()
    var cursor = 0

    public convenience init(fileUrl: URL) throws {
        let fileData = try Data(contentsOf: fileUrl)
        self.init(data: fileData)
    }
    public init(bytes: ArraySlice<UInt8>) {
        self.data.append(contentsOf: bytes)
    }
    init(data: Data) {
        self.data = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &self.data, count: data.count)
    }
    public func appendData(bytes: [UInt8]) {
        self.data.append(contentsOf: bytes) //[0..<bytes.count])
    }
    public func appendData(bytes: ArraySlice<UInt8>) {
        self.data.append(contentsOf: bytes)
    }
    public func atBeginning() -> Bool {
        return cursor == 0
    }
    func atEnd(offset: Int = 0) -> Bool {
        return cursor + offset >= data.count
    }
    func peekByte() -> UInt8 {
        return data[cursor]
    }
    func parseLine() -> String? {
        var line = ""
        while true {
            guard !atEnd() else { return nil }
            let c = data[cursor].toChar()
            cursor += 1
            if c == "\r" { continue }
            if c == "\n" { break }
            line += String(c)
        }
        return line
    }
    public func peekString(at: Int, len: Int) -> String {
        var str = ""
        for b in data[at..<at+len] {
            if (b == 0) {
                str += "<0>"
            } else {
                str += String(b.toChar())
            }
        }
        return str
    }
    public func peekHex(at: Int, len: Int) -> UInt64? {
        let str = peekString(at: at, len: len)
        return UInt64(str, radix: 16)
    }
    public func peekBinLE(at: Int, len: Int) -> UInt64 {
        assert(len <= MemoryLayout<UInt64>.size)
        return data[at..<at + len]
            .reduce(0, { soFar, new in
                    (soFar << 8) | UInt64(new)
            })
    }
    public func peekBinBE(at: Int, len: Int) -> UInt64 {
        assert(len <= MemoryLayout<UInt64>.size)
        return data[at..<at + len]
            .reversed()
            .reduce(0, { soFar, new in
                    (soFar << 8) | UInt64(new)
            })
    }
}
