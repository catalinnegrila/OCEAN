import Darwin

class UdpBroadcastServer {
    fileprivate let server_socket: Int32
    fileprivate var server_address = sockaddr_in()

    init?(port: UInt16) {
        server_address.sin_len = __uint8_t(MemoryLayout<sockaddr_in>.size)
        server_address.sin_family = sa_family_t(AF_INET)
        server_address.sin_addr.s_addr = in_addr_t((0).bigEndian)
#if DEBUG
        inet_aton("<broadcast>", &server_address.sin_addr)
#else
        inet_aton("255.255.255.255", &server_address.sin_addr)
#endif
        server_address.sin_port = port.bigEndian
        
        server_socket = socket(AF_INET,SOCK_DGRAM,IPPROTO_UDP)
        guard server_socket >= 0 else { return nil}
        
        var trueVal:Int32 = 1
        var status = setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &trueVal, socklen_t(MemoryLayout<Int32>.size))
        guard status >= 0 else { return nil}
        status = setsockopt(server_socket, SOL_SOCKET, SO_REUSEPORT, &trueVal, socklen_t(MemoryLayout<Int32>.size))
        guard status >= 0 else { return nil}
        status = setsockopt(server_socket, SOL_SOCKET, SO_BROADCAST, &trueVal, socklen_t(MemoryLayout<Int32>.size))
        guard status >= 0 else { return nil}

        let timeout_s = 0.2
        var timeout = timeval()
        timeout.tv_sec = __darwin_time_t(floor(timeout_s));
        timeout.tv_usec = __darwin_suseconds_t((timeout_s - floor(timeout_s)) * 1.0e6);
        status = setsockopt(server_socket, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        guard status >= 0 else { return nil}
    }
    deinit {
        close(server_socket)
    }
    func broadcast(_ buf: inout [UInt8]) -> Bool {
        // convert between sockaddr type and sockaddr_in type for pointer
        var server_address_sockaddr = withUnsafePointer(to: &server_address){
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                $0.pointee
            }
        }
        let result = sendto(server_socket, &buf, buf.count, 0, &server_address_sockaddr, socklen_t(MemoryLayout<sockaddr_in>.size))
        guard result == buf.count else {
            print("Broadcast failed: \(result) of \(buf.count) bytes")
            return false
        }
        return true
    }
}
