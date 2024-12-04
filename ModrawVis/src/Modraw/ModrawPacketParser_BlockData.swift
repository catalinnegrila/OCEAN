import ModrawLib

class ModrawPacketParser_BlockData: ModrawPacketParser {
    func getExpectedBlockDataLen() -> Int? {
        return nil
    }
    
    let block_timestamp_len = 16
    let block_size_len = 8
    func getBlockDataPayloadStart(packet: ModrawPacket) -> Int {
        return getPayloadStart(packet: packet) +
                block_timestamp_len +
                block_size_len +
                ModrawPacket.PACKET_CHECKSUM_LEN
    }
    let DEBUG_VALIDATION = false
    override func isValid(packet: ModrawPacket) -> Bool {
        guard super.isValid(packet: packet) else { return false }
        
        if DEBUG_VALIDATION {
            print(signature)
        }
        var i = packet.getPayloadStart(signatureLen: signature.count)
        guard i + block_timestamp_len < packet.endChecksumStart else { return false }
        if DEBUG_VALIDATION {
            print("block_timestamp: \(packet.parent.peekString(at: i, len: block_timestamp_len))")
        }
        i += block_timestamp_len
        
        guard i + block_size_len < packet.endChecksumStart else { return false }
        if (DEBUG_VALIDATION) {
            print("block_size: \(packet.parent.peekString(at: i, len: block_size_len))")
        }
        guard let block_size = packet.parent.peekHex(at: i, len: block_size_len) else { return false }
        i += block_size_len
        
        if DEBUG_VALIDATION {
            print("chksum1: \(packet.parent.peekString(at: i, len: ModrawPacket.PACKET_CHECKSUM_LEN))")
        }
        guard packet.isChecksum(i) else { return false }
        i += ModrawPacket.PACKET_CHECKSUM_LEN
        
        if DEBUG_VALIDATION {
            print("chksum2: \(packet.parent.peekString(at: packet.endChecksumStart, len: ModrawPacket.PACKET_CHECKSUM_LEN))")
        }

        let actual_data_len = packet.endChecksumStart - i
        if DEBUG_VALIDATION {
            print("actual_data_len: \(actual_data_len)")
        }
        guard actual_data_len == block_size else { return false }

        if let expectedBlockSize = getExpectedBlockDataLen() {
            if DEBUG_VALIDATION {
                print("expectedBlockSize: \(expectedBlockSize)")
            }
            guard actual_data_len == expectedBlockSize else { return false }
        }
        return true
    }
    func isValidSample(this_block: TimestampedData, sample_index: Int, prev_time_s: inout Double!, time_s: Double) -> Bool {
        guard prev_time_s != nil else {
            prev_time_s = time_s
            return true
        }
        guard prev_time_s < time_s else {
            if DEBUG_VALIDATION && sample_index == 0 {
                print("Dropping \(signature) past sample[\(sample_index)] current timestamp \(time_s) < previous timestamp \(prev_time_s!)")
            }
            return false
        }
        this_block.checkAndAppendMissingData(t0: prev_time_s, t1: time_s)
        prev_time_s = time_s
        return true
    }
}
