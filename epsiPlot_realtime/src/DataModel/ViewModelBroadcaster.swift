import Foundation

struct ViewModelBroadcaster {
    fileprivate var server = UdpBroadcastServer(port: 50211)
    fileprivate var lastBroadcast: TimeInterval = 0
    fileprivate let broadcastFreq = 0.1
    fileprivate let duration = 5.0 // seconds
    fileprivate let num_samples = 5 * 30
    fileprivate let range = 1.5

    enum State: String {
        case Starting, Sending, Stopped, Error
    }
    public var state: State = .Starting

    mutating func broadcast(vm: ViewModel) {
        guard !vm.epsi.time_s.isEmpty else { return }
        guard let server = server else { state = .Error; return }
        guard state != .Stopped else { return }

        let currentBroadcast = ProcessInfo.processInfo.systemUptime
        guard currentBroadcast - lastBroadcast > broadcastFreq else { return }
        lastBroadcast = currentBroadcast

        let time_s = vm.epsi.time_s[...]
        let a1_g = vm.epsi.a1_g[...]

        let first_time_s = time_s.last! - duration
        var i = time_s.count - 1
        var prevNumber = a1_g[i]
        while i > 0 && time_s[i] > first_time_s {
            if !a1_g[i].isNaN {
                prevNumber = a1_g[i]
            }
            i -= 1
        }

        let v = a1_g[i].isNaN ? prevNumber : a1_g[i]
        var minv = v
        var maxv = v
        var samples_f = [Double]()
        samples_f.reserveCapacity(num_samples)
        for j in 0..<num_samples {
            let v = a1_g[i].isNaN ? prevNumber : a1_g[i]
            var sum = v
            var n = 1
            let last_time_s = first_time_s + duration * Double(j) / Double(num_samples - 1)
            while i < time_s.count - 1 && time_s[i] < last_time_s {
                i += 1
                let v = a1_g[i].isNaN ? prevNumber : a1_g[i]
                minv = min(minv, v)
                maxv = max(maxv, v)
                prevNumber = v
                sum += v
                n += 1
            }
            samples_f.append(sum / Double(n))
        }

        let midv = (minv + maxv) / 2
        maxv = midv + range / 2
        minv = midv - range / 2

        let header_size = 4 + 4 + 2
        var buf = Array<UInt8>()
        buf.reserveCapacity(header_size + samples_f.count)

        func toByte(_ v: Double) -> UInt8 {
            guard v > minv else { return UInt8(0) }
            guard v < maxv else { return UInt8(255) }
            return UInt8(255.0 * (v - minv) / (maxv - minv))
        }
        func append<T>(value: T) {
            var v = value
            withUnsafeBytes(of: &v) {
                buf.append(contentsOf: Array($0))
            }
        }

        append(value: Float(minv))
        append(value: Float(maxv))
        append(value: UInt16(samples_f.count))
        for j in 0..<samples_f.count {
            buf.append(toByte(samples_f[j]))
        }

        func readValue<Result>(_: Result.Type, at: Int) -> Result
        {
            let size = MemoryLayout<Result>.size
            assert(at + size <= buf.count)
            let value: Result = buf.withUnsafeBytes {
                return $0.load(fromByteOffset: at, as: Result.self)
            }
            return value
        }

        state = server.broadcast(&buf) ? .Sending : .Error
    }
}
