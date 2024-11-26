import Foundation

class ViewModelBroadcaster {
    var server = UdpBroadcastServer(port: 50211)
    var lastBroadcast: TimeInterval = 0
    var broadcastFreq = 0.1
    func broadcast(vm: ViewModel) {
        guard !vm.epsi.time_s.isEmpty else { return }
        guard let server = server else { return }

        let currentBroadcast = ProcessInfo.processInfo.systemUptime
        guard currentBroadcast - lastBroadcast > broadcastFreq else { return }
        lastBroadcast = currentBroadcast

        let time_s = vm.epsi.time_s[...]
        let a1_g = vm.epsi.a1_g[...]

        let duration = 5.0 // seconds
        let samples = 256
        let first_time_s = time_s.last! - duration
        var i = time_s.count - 1
        while i > 0 && time_s[i] > first_time_s {
            i -= 1
        }

        var minv = a1_g[i]
        var maxv = a1_g[i]
        var samples_f = [(Double, Double)]()
        samples_f.reserveCapacity(samples)
        for j in 0..<samples {
            var sample_minv = a1_g[i]
            var sample_maxv = a1_g[i]
            let last_time_s = first_time_s + duration * Double(j) / Double(samples - 1)
            while i < time_s.count && time_s[i] < last_time_s {
                sample_minv = min(sample_minv, a1_g[i])
                sample_maxv = max(sample_maxv, a1_g[i])
                i += 1
            }
            samples_f.append((sample_minv, sample_maxv))
            minv = min(minv, sample_minv)
            maxv = max(maxv, sample_maxv)
        }

        let midv = min(0.5, max(-0.5, (minv + maxv) / 2.0))
        maxv = midv + 0.5
        minv = midv - 0.5
        
        let header_size = 4 + 4 + 2
        var buf = Array<UInt8>()
        buf.reserveCapacity(header_size + 2 * samples)

        func toByte(_ v: Double) -> UInt8 {
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
        append(value: UInt16(samples))
        for j in 0..<samples {
            buf.append(toByte(samples_f[j].0))
            buf.append(toByte(samples_f[j].1))
        }

        server.broadcast(&buf)
    }
}
