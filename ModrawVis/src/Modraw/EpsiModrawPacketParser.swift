import ModrawLib

class EpsiModrawPacketParser: ModrawPacketParser {
    func getExpectedBlockSize() -> Int {
        assertionFailure()
        return 0
    }
    
    let block_timestamp_len = 16
    let block_size_len = 8
    func getEpsiPayloadStart(packet: ModrawPacket) -> Int {
        return getPayloadStart(packet: packet) +
        block_timestamp_len +
        block_size_len +
        ModrawPacket.PACKET_CHECKSUM_LEN
    }
    let DEBUG_VALIDATION = false
    override func isValid(packet: ModrawPacket) -> Bool {
        guard super.isValid(packet: packet) else { return false }
        
        if (DEBUG_VALIDATION) {
            print(signature)
        }
        var i = packet.getPayloadStart(signatureLen: signature.count)
        if (i + block_timestamp_len >= packet.checksumStart) { return false }
        if (DEBUG_VALIDATION) {
            print("block_timestamp: \(packet.parent.peekString(at: i, len: block_timestamp_len))")
        }
        i += block_timestamp_len
        
        if (i + block_size_len >= packet.checksumStart) { return false }
        if (DEBUG_VALIDATION) {
            print("block_size: \(packet.parent.peekString(at: i, len: block_size_len))")
        }
        let block_size = packet.parent.peekHex(at: i, len: block_size_len)
        if (block_size == nil || block_size! != getExpectedBlockSize()) { return false }
        i += block_size_len
        
        if (DEBUG_VALIDATION) {
            print("chksum1: \(packet.parent.peekString(at: i, len: ModrawPacket.PACKET_CHECKSUM_LEN))")
        }
        if (!packet.isChecksum(i)) { return false }
        i += ModrawPacket.PACKET_CHECKSUM_LEN
        
        if (DEBUG_VALIDATION) {
            print("chksum2: \(packet.parent.peekString(at: packet.checksumStart, len: ModrawPacket.PACKET_CHECKSUM_LEN))")
        }
        let actual_data_len = packet.checksumStart - i
        if (DEBUG_VALIDATION) {
            print("actual_data_len: \(actual_data_len) expectedDataLen: \(getExpectedBlockSize())")
        }
        if (actual_data_len != getExpectedBlockSize()) { return false }
        
        return true
    }
    func isValidSample(this_block: TimestampedData, sample_index: Int, prev_time_s: inout Double!, time_s: Double) -> Bool {
        guard prev_time_s != nil else {
            prev_time_s = time_s
            return true
        }
        guard prev_time_s < time_s else {
            if (sample_index == 0) {
                print("Dropping \(signature) past sample[\(sample_index)] current timestamp \(time_s) < previous timestamp \(prev_time_s!)")
            }
            return false
        }
        this_block.checkAndAppendMissingData(t0: prev_time_s, t1: time_s)
        prev_time_s = time_s
        return true
    }
}