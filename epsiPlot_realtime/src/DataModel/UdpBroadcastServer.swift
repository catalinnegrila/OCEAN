import Darwin

class UdpBroadcastServer {
    fileprivate let server_socket: Int32
    fileprivate var server_address = sockaddr_in()

    init(_ port: UInt16 = 37020) {
        server_address.sin_len = __uint8_t(MemoryLayout<sockaddr_in>.size)
        server_address.sin_family = sa_family_t(AF_INET)
        server_address.sin_addr.s_addr = in_addr_t((0).bigEndian)
        inet_aton("<broadcast>", &server_address.sin_addr)
        server_address.sin_port = port.bigEndian
        
        server_socket = socket(AF_INET,SOCK_DGRAM,IPPROTO_UDP)
        assert(server_socket >= 0)
        
        var trueVal:Int32 = 1
        var status = setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &trueVal, socklen_t(MemoryLayout<Int32>.size))
        assert(status >= 0)
        status = setsockopt(server_socket, SOL_SOCKET, SO_BROADCAST, &trueVal, socklen_t(MemoryLayout<Int32>.size))
        assert(status >= 0)
        
        let timeout_s = 0.2
        var timeout = timeval()
        timeout.tv_sec = __darwin_time_t(floor(timeout_s));
        timeout.tv_usec = __darwin_suseconds_t(((timeout_s-floor(timeout_s))*1.0e6));
        status = setsockopt(server_socket, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        assert(status >= 0)
    }
    deinit {
        close(server_socket)
    }
    func broadcast(_ buf: inout [UInt8]) {
        // convert between sockaddr type and sockadd_in type for pointer
        var server_address_sockaddr = withUnsafePointer(to: &server_address){
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                $0.pointee
            }
        }
        let result = sendto(server_socket, &buf, buf.count, 0, &server_address_sockaddr, socklen_t(MemoryLayout<sockaddr_in>.size))
        assert(result == buf.count)
    }
}
