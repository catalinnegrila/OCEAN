//
//  ContentView.swift
//  FCTD Data Display
//
//  Created by San Nguyen on 9/25/20.
//  Copyright © 2020 MOD. All rights reserved.
//

import SwiftUI

import Darwin
import Dispatch
import os.log
import AVFoundation

enum udp_server_error: Error {
    case mod_udp_EPERM
    case mod_udp_ENOENT
    case mod_udp_ESRCH
    case mod_udp_EINTR
    case mod_udp_EIO
    case mod_udp_ENXIO
    case mod_udp_E2BIG
    case mod_udp_ENOEXEC
    case mod_udp_EBADF
    case mod_udp_ECHILD
    case mod_udp_EDEADLK
    case mod_udp_ENOMEM
    case mod_udp_EACCES
    case mod_udp_EFAULT
    case mod_udp_ENOTBLK
    case mod_udp_EBUSY
    case mod_udp_EEXIST
    case mod_udp_EXDEV
    case mod_udp_ENODEV
    case mod_udp_ENOTDIR
    case mod_udp_EISDIR
    case mod_udp_EINVAL
    case mod_udp_ENFILE
    case mod_udp_EMFILE
    case mod_udp_ENOTTY
    case mod_udp_ETXTBSY
    case mod_udp_EFBIG
    case mod_udp_ENOSPC
    case mod_udp_ESPIPE
    case mod_udp_EROFS
    case mod_udp_EMLINK
    case mod_udp_EPIPE
    case mod_udp_EDOM
    case mod_udp_ERANGE
    case mod_udp_EAGAIN
    case mod_udp_EINPROGRESS
    case mod_udp_EALREADY
    case mod_udp_ENOTSOCK
    case mod_udp_EDESTADDRREQ
    case mod_udp_EMSGSIZE
    case mod_udp_EPROTOTYPE
    case mod_udp_ENOPROTOOPT
    case mod_udp_EPROTONOSUPPORT
    case mod_udp_ESOCKTNOSUPPORT
    case mod_udp_ENOTSUP
    case mod_udp_EPFNOSUPPORT
    case mod_udp_EAFNOSUPPORT
    case mod_udp_EADDRINUSE
    case mod_udp_EADDRNOTAVAIL
    case mod_udp_ENETDOWN
    case mod_udp_ENETUNREACH
    case mod_udp_ENETRESET
    case mod_udp_ECONNABORTED
    case mod_udp_ECONNRESET
    case mod_udp_ENOBUFS
    case mod_udp_EISCONN
    case mod_udp_ENOTCONN
    case mod_udp_ESHUTDOWN
    case mod_udp_ETOOMANYREFS
    case mod_udp_ETIMEDOUT
    case mod_udp_ECONNREFUSED
    case mod_udp_ELOOP
    case mod_udp_ENAMETOOLONG
    case mod_udp_EHOSTDOWN
    case mod_udp_EHOSTUNREACH
    case mod_udp_ENOTEMPTY
    case mod_udp_EPROCLIM
    case mod_udp_EUSERS
    case mod_udp_EDQUOT
    case mod_udp_ESTALE
    case mod_udp_EREMOTE
    case mod_udp_EBADRPC
    case mod_udp_ERPCMISMATCH
    case mod_udp_EPROGUNAVAIL
    case mod_udp_EPROGMISMATCH
    case mod_udp_EPROCUNAVAIL
    case mod_udp_ENOLCK
    case mod_udp_ENOSYS
    case mod_udp_EFTYPE
    case mod_udp_EAUTH
    case mod_udp_ENEEDAUTH
    case mod_udp_EPWROFF
    case mod_udp_EDEVERR
    case mod_udp_EOVERFLOW
    case mod_udp_EBADEXEC
    case mod_udp_EBADARCH
    case mod_udp_ESHLIBVERS
    case mod_udp_EBADMACHO
    case mod_udp_ECANCELED
    case mod_udp_EIDRM
    case mod_udp_ENOMSG
    case mod_udp_EILSEQ
    case mod_udp_ENOATTR
    case mod_udp_EBADMSG
    case mod_udp_EMULTIHOP
    case mod_udp_ENODATA
    case mod_udp_ENOLINK
    case mod_udp_ENOSR
    case mod_udp_ENOSTR
    case mod_udp_EPROTO
    case mod_udp_ETIME
    case mod_udp_EOPNOTSUPP
    case mod_udp_ENOPOLICY
    case mod_udp_ENOTRECOVERABLE
    case mod_udp_EOWNERDEAD
    case mod_udp_EQFULL
    case mod_udp_ELAST
    
    case mod_udp_socket_no_create
    case mod_udp_set_reuse_addr
    case mod_udp_rcv_timeout_lim
    case mod_udp_snd_timeout_lim
    case mod_udp_rcv_buff_size
    case mod_udp_snd_buff_size
    case mod_udp_bind_err
    
    init?(err_num: Int32) {
        switch err_num {
        case 1: self = .mod_udp_EPERM
        case 2: self = .mod_udp_ENOENT
        case 3: self = .mod_udp_ESRCH
        case 4: self = .mod_udp_EINTR
        case 5: self = .mod_udp_EIO
        case 6: self = .mod_udp_ENXIO
        case 7: self = .mod_udp_E2BIG
        case 8: self = .mod_udp_ENOEXEC
        case 9: self = .mod_udp_EBADF
        case 10: self = .mod_udp_ECHILD
        case 11: self = .mod_udp_EDEADLK
        case 12: self = .mod_udp_ENOMEM
        case 13: self = .mod_udp_EACCES
        case 14: self = .mod_udp_EFAULT
        case 15: self = .mod_udp_ENOTBLK
        case 16: self = .mod_udp_EBUSY
        case 17: self = .mod_udp_EEXIST
        case 18: self = .mod_udp_EXDEV
        case 19: self = .mod_udp_ENODEV
        case 20: self = .mod_udp_ENOTDIR
        case 21: self = .mod_udp_EISDIR
        case 22: self = .mod_udp_EINVAL
        case 23: self = .mod_udp_ENFILE
        case 24: self = .mod_udp_EMFILE
        case 25: self = .mod_udp_ENOTTY
        case 26: self = .mod_udp_ETXTBSY
        case 27: self = .mod_udp_EFBIG
        case 28: self = .mod_udp_ENOSPC
        case 29: self = .mod_udp_ESPIPE
        case 30: self = .mod_udp_EROFS
        case 31: self = .mod_udp_EMLINK
        case 32: self = .mod_udp_EPIPE
        case 33: self = .mod_udp_EDOM
        case 34: self = .mod_udp_ERANGE
        case 35: self = .mod_udp_EAGAIN
        case 36: self = .mod_udp_EINPROGRESS
        case 37: self = .mod_udp_EALREADY
        case 38: self = .mod_udp_ENOTSOCK
        case 39: self = .mod_udp_EDESTADDRREQ
        case 40: self = .mod_udp_EMSGSIZE
        case 41: self = .mod_udp_EPROTOTYPE
        case 42: self = .mod_udp_ENOPROTOOPT
        case 43: self = .mod_udp_EPROTONOSUPPORT
        case 44: self = .mod_udp_ESOCKTNOSUPPORT
        case 45: self = .mod_udp_ENOTSUP
        case 46: self = .mod_udp_EPFNOSUPPORT
        case 47: self = .mod_udp_EAFNOSUPPORT
        case 48: self = .mod_udp_EADDRINUSE
        case 49: self = .mod_udp_EADDRNOTAVAIL
        case 50: self = .mod_udp_ENETDOWN
        case 51: self = .mod_udp_ENETUNREACH
        case 52: self = .mod_udp_ENETRESET
        case 53: self = .mod_udp_ECONNABORTED
        case 54: self = .mod_udp_ECONNRESET
        case 55: self = .mod_udp_ENOBUFS
        case 56: self = .mod_udp_EISCONN
        case 57: self = .mod_udp_ENOTCONN
        case 58: self = .mod_udp_ESHUTDOWN
        case 59: self = .mod_udp_ETOOMANYREFS
        case 60: self = .mod_udp_ETIMEDOUT
        case 61: self = .mod_udp_ECONNREFUSED
        case 62: self = .mod_udp_ELOOP
        case 63: self = .mod_udp_ENAMETOOLONG
        case 64: self = .mod_udp_EHOSTDOWN
        case 65: self = .mod_udp_EHOSTUNREACH
        case 66: self = .mod_udp_ENOTEMPTY
        case 67: self = .mod_udp_EPROCLIM
        case 68: self = .mod_udp_EUSERS
        case 69: self = .mod_udp_EDQUOT
        case 70: self = .mod_udp_ESTALE
        case 71: self = .mod_udp_EREMOTE
        case 72: self = .mod_udp_EBADRPC
        case 73: self = .mod_udp_ERPCMISMATCH
        case 74: self = .mod_udp_EPROGUNAVAIL
        case 75: self = .mod_udp_EPROGMISMATCH
        case 76: self = .mod_udp_EPROCUNAVAIL
        case 77: self = .mod_udp_ENOLCK
        case 78: self = .mod_udp_ENOSYS
        case 79: self = .mod_udp_EFTYPE
        case 80: self = .mod_udp_EAUTH
        case 81: self = .mod_udp_ENEEDAUTH
        case 82: self = .mod_udp_EPWROFF
        case 83: self = .mod_udp_EDEVERR
        case 84: self = .mod_udp_EOVERFLOW
        case 85: self = .mod_udp_EBADEXEC
        case 86: self = .mod_udp_EBADARCH
        case 87: self = .mod_udp_ESHLIBVERS
        case 88: self = .mod_udp_EBADMACHO
        case 89: self = .mod_udp_ECANCELED
        case 90: self = .mod_udp_EIDRM
        case 91: self = .mod_udp_ENOMSG
        case 92: self = .mod_udp_EILSEQ
        case 93: self = .mod_udp_ENOATTR
        case 94: self = .mod_udp_EBADMSG
        case 95: self = .mod_udp_EMULTIHOP
        case 96: self = .mod_udp_ENODATA
        case 97: self = .mod_udp_ENOLINK
        case 98: self = .mod_udp_ENOSR
        case 99: self = .mod_udp_ENOSTR
        case 100: self = .mod_udp_EPROTO
        case 101: self = .mod_udp_ETIME
        case 102: self = .mod_udp_EOPNOTSUPP
        case 103: self = .mod_udp_ENOPOLICY
        case 104: self = .mod_udp_ENOTRECOVERABLE
        case 105: self = .mod_udp_EOWNERDEAD
        case 106: self = .mod_udp_EQFULL
            
        case 107: self = .mod_udp_socket_no_create
        case 108: self = .mod_udp_set_reuse_addr
        case 109: self = .mod_udp_rcv_timeout_lim
        case 110: self = .mod_udp_snd_timeout_lim
        case 111: self = .mod_udp_rcv_buff_size
        case 112: self = .mod_udp_snd_buff_size
        case 113: self = .mod_udp_bind_err
        default: return nil
        }
    }
}

class udp_server_t {
    
    //    // syncQueue help us print and read/write safely from our internal storage
    //    // while running, the main queue is blocking with readLine()
    //
    //    private let syncQueue = DispatchQueue(label: "syncQueue")
    //
    //    // to be able maintain curren status of all DispatchSources
    //    // we store all the information here
    //
    //    var serverSources:[Int32:DispatchSourceRead] = [:]
    //
    var server_socket:Int32 = -1
    var client_ip_to_accept:String?
    var client_address:[sockaddr_in]?
    var client_address_data_length:[UInt32]?
    var port:UInt16 = 50210
    var window_size:UInt32 = 65536
    var timeout:Float = 20.0;
    var is_listening:Bool = false
    var current_empty_client_ind:Int32 = -1
    init(port:UInt16){
        self.port = port
    }
    init(port:UInt16,timeout:Float){
        self.port = port
        self.timeout = timeout
    }
    init(){
        
    }
    init(port:UInt16,timeout:Float, window_size:UInt32){
        self.port = port
        self.timeout = timeout
        self.window_size = window_size
    }
    init(timeout:Float, window_size:UInt32){
        self.timeout = timeout
        self.window_size = window_size
    }
    init(timeout:Float){
        self.timeout = timeout
    }
    init(port:UInt16, window_size:UInt32){
        self.port = port
        self.window_size = window_size
    }
    init(window_size:UInt32){
        self.window_size = window_size
    }
    deinit {
        // first stop the server !!
        stop()
        print("Echo UDP Server deinit")
    }
    
    func start() throws {
        NSLog("FCTD Data Display start()")
        var status:Int32
        //        var port: UInt16 = 2550
        var server_address = sockaddr_in()
        //        var udp_timeout:Float = 20.0;
        var udp_window_size:UInt32 = 65536
        
        server_address.sin_len = __uint8_t(MemoryLayout<sockaddr_in>.size)
        server_address.sin_family = sa_family_t(AF_INET)
        server_address.sin_addr.s_addr = in_addr_t((0).bigEndian)
        server_address.sin_port = port.bigEndian
        
        // convert between sockaddr type and sockadd_in type for pointer
        var server_address_sockaddr = withUnsafePointer(to: &server_address){
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                $0.pointee
            }
        }
        //            withUnsafeMutablePointer(to: &server_address)
        
        //        var server_socket: Int32
        self.server_socket = socket(AF_INET,SOCK_DGRAM,0)
        if self.server_socket<0{
            throw udp_server_error(err_num: errno)!
        }
        var timeout = timeval()
        timeout.tv_sec = __darwin_time_t(floor(self.timeout));
        timeout.tv_usec = __darwin_suseconds_t(((self.timeout-floor(self.timeout))*1.0e6));
        
        var optval:Int32 = 1
        
        print("setsockopt")
        os_log(.info,"setsockopt")
        status = setsockopt(self.server_socket, SOL_SOCKET, SO_REUSEADDR, &optval, socklen_t(MemoryLayout<Int32>.size))
        if(status < 0){
            close(self.server_socket)
            throw udp_server_error(err_num: errno)!
        }
        status = setsockopt(self.server_socket, SOL_SOCKET, SO_REUSEPORT, &optval, socklen_t(MemoryLayout<Int32>.size))
        if(status < 0){
            close(self.server_socket)
            throw udp_server_error(err_num: errno)!
        }

        print("setsockopt")
        status = setsockopt(self.server_socket, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        if(status < 0){
            close(self.server_socket)
            throw udp_server_error(err_num: errno)!
        }
        print("setsockopt")
        status = setsockopt(self.server_socket, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        if(status < 0){
            close(self.server_socket)
            throw udp_server_error(err_num: errno)!
        }
        print("setsockopt")
        status = setsockopt(self.server_socket, SOL_SOCKET, SO_RCVBUF, &udp_window_size, socklen_t(MemoryLayout<UInt32>.size))
        if(status < 0){
            close(self.server_socket)
            throw udp_server_error(err_num: errno)!
        }
        print("setsockopt")
        status = setsockopt(self.server_socket, SOL_SOCKET, SO_SNDBUF, &udp_window_size, socklen_t(MemoryLayout<UInt32>.size))
        if(status < 0){
            close(self.server_socket)
            throw udp_server_error(err_num: errno)!
        }
        print("bind")
        os_log(.info,"bind")
        NSLog("bind")
        status = bind(self.server_socket, &server_address_sockaddr, socklen_t(MemoryLayout<sockaddr_in>.size))
        if(status < 0){
            close(self.server_socket)
            throw udp_server_error(err_num: errno)!
        }
        print(status)
        self.is_listening = true
        self.current_empty_client_ind = 0
        
        print("listen")
        os_log(.info,"listen")
        NSLog("listen")
        if listen(self.server_socket, 5) < 0 {} else {
            print("$ERR - not working")
            os_log(.info,"$ERR: socket not connecting")
            NSLog("$ERR: not working")
            close(self.server_socket)
            throw udp_server_error(err_num: errno)!
        }

    }
    
    func stop() {
        close(self.server_socket)
    }
}

func press2dpth(pressure:Double,latitude:Double)->Double{
    let DEG2RAD:Double = Double(3.14159265359/180.0)
    let c1:Double = +9.72659
    let c2:Double = -2.2512E-5
    let c3:Double = +2.279E-10
    let c4:Double = -1.82E-15
    let gam_dash:Double = 2.184e-6
    
    var lat:Double = abs(latitude)
    lat   = sin(lat * DEG2RAD)  //% convert to radians
    lat   = lat * lat
    let bot_line:Double = 9.780318 * (1.0 + (5.2788E-3 + 2.36E-5 * lat) * lat) + gam_dash * 0.5 * pressure
    let top_line:Double = (((c4 * pressure + c3) * pressure + c2) * pressure+c1) * pressure
    let depth:Double   = top_line/bot_line
    return depth
}

struct custom_title_style: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    func body(content: Content) -> some View {
        let red_light: Double = 150 / 255.0
        let green_light: Double = 200 / 255.0
        let blue_light: Double = 220 / 255.0
        
        let red_dark: Double = 60 / 255.0
        let green_dark: Double = 90 / 255.0
        let blue_dark: Double = 100 / 255.0
        
        content
            .font(.system(size: 50, weight: .bold, design: .default)) // Customize as needed
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(colorScheme == .dark ? Color(red: red_dark, green: green_dark, blue: blue_dark) : Color(red: red_light, green: green_light, blue: blue_light))
//            .cornerRadius(5)
        //.foregroundColor(.blue) // Optional: change text color
    }
}
extension View {
    func custom_title() -> some View {
        self.modifier(custom_title_style())
    }
}

struct custom_title_2_style: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    func body(content: Content) -> some View {
        let red_light: Double = 150 / 255.0
        let green_light: Double = 200 / 255.0
        let blue_light: Double = 220 / 255.0
        
        let red_dark: Double = 60 / 255.0
        let green_dark: Double = 90 / 255.0
        let blue_dark: Double = 100 / 255.0
        content
            .font(.system(size: 30, weight: .bold, design: .default)) // Customize as needed
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(colorScheme == .dark ? Color(red: red_dark, green: green_dark, blue: blue_dark) : Color(red: red_light, green: green_light, blue: blue_light))
//            .cornerRadius(5)
        //.foregroundColor(.blue) // Optional: change text color
    }
}
extension View {
    func custom_title_2() -> some View {
        self.modifier(custom_title_2_style())
    }
}

struct custom_text_field_style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 70.0, weight: .regular, design: .default)) // Customize as needed
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
        //.foregroundColor(.blue) // Optional: change text color
    }
}
extension View {
    func custom_text_field_title() -> some View {
        self.modifier(custom_text_field_style())
    }
}

struct custom_text_field_2_style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 36.0, weight: .regular, design: .default)) // Customize as needed
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
        //.foregroundColor(.blue) // Optional: change text color
    }
}
extension View {
    func custom_text_field_2_title() -> some View {
        self.modifier(custom_text_field_2_style())
    }
}

struct border_modifier: ViewModifier {
    //    var color: Color
    var line_width: CGFloat
    var radius: CGFloat
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        let red_light: Double = 150 / 255.0
        let green_light: Double = 200 / 255.0
        let blue_light: Double = 220 / 255.0
        
        let red_dark: Double = 60 / 255.0
        let green_dark: Double = 90 / 255.0
        let blue_dark: Double = 100 / 255.0
        content
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius,style: .continuous)
                    .stroke(colorScheme == .dark ? Color(red: red_dark, green: green_dark, blue: blue_dark) : Color(red: red_light, green: green_light, blue: blue_light), lineWidth: line_width)
            )
    }
}
extension View {
    func draw_border(line_width: CGFloat = 1, radius: CGFloat = 6   ) -> some View {
        self.modifier(border_modifier(line_width: line_width,radius: radius))
    }
}

struct bottom_border_modifier: ViewModifier {
    var line_width: CGFloat
    @Environment(\.colorScheme) var colorScheme
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .frame(height: line_width)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black),
                alignment: .bottom
            )
    }
}

extension View {
    func draw_border_bottom(line_width: CGFloat = 1) -> some View {
        self.modifier(bottom_border_modifier(line_width: line_width))
    }
}



struct ContentView: View {
    @State var depth_val: String = "disconnected"
    @State var alti_val: String = "disconnected"
    @State var dzdt_val: String = "disconnected"
    @State var is_udp_connected:Bool = false
    @State var epsi_udp_server: udp_server_t = udp_server_t(timeout:5.0)
    @State var ctd_udp_server: udp_server_t = udp_server_t(timeout:5.0)
    @State var winch_udp_server: udp_server_t = udp_server_t(timeout:5.0)
    @State var serverSources:[DispatchSourceRead] = []
    @State var depth_old:Double = Double.nan
    @State var time_old:Double = Double.nan
    @State var epsi_server_src:DispatchSourceRead!
    @State var ctd_server_src:DispatchSourceRead!
    @State var winch_server_src:DispatchSourceRead!
    @State var sound_effect: AVAudioPlayer?
    @State var sound_effect_2: AVAudioPlayer?
    @State var epsi_a1_val = "disconnected"
    @State var epsi_a1_g = [UInt8]()
    @State var epsi_a1_g_min = 0.0
    @State var epsi_a1_g_max = 0.0
    @State var dz_dt: Double = Double.nan
    @State var dz_dt_filtered: Double = Double.nan
    @State var dz_dt_alpha: Double = 0.15;
    @State var winch_sheave_px_val: String = "disconnected"
    @State var winch_sheave_vx_val: String = "disconnected"
    @State var winch_rec_old_indx: UInt32 = 0xffff
    @State var winch_sheave_px_offset: Double = 0.0
    @State var winch_sheave_px_cable_payout: Double = Double.nan
    @State var winch_sheave_px_old: Double = Double.nan
    @State var winch_sheave_vx_old: Double = Double.nan
    @State var winch_ctd_line_depth_diff: Double = Double.nan;
    @State var winch_ctd_line_depth_diff_at_set: Double = Double.nan;
    @State var winch_ctd_line_depth_diff_val:  String = "NaN"
    @State var winch_ctd_line_depth_diff_at_set_val:  String = "NaN"
    @State var winch_warning_avail_flag: UInt8 = 0
    @State private var winch_warning_msg_blink_state: Bool = false
    @State var winch_warning_msg: String = "Check level wind"
    @State var winch_sheave_mode: String = "disconnected";
    @State var winch_payout_val: String = "disconnected"
    @State var winch_vel_val: String = "disconnected"
    @State var winch_curr_val: String = "disconnected"
    @Environment(\.colorScheme) var colorScheme
    
    
    var body: some View {
        GeometryReader { metrics in
            VStack{
                VStack{
                    //warning message
                    VStack(spacing:0){
                        TextField("warningmessage",text:$winch_warning_msg)
                            .disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                            .custom_title()
                            .background(winch_warning_msg_blink_state ? Color(red:0.6, green: 0.2, blue:0.1) : Color(.red))
                            .opacity(winch_warning_msg_blink_state ? 0 : 1)
                            .onAppear {
                                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                                    withAnimation {
                                        if(winch_warning_avail_flag>0){
                                            winch_warning_msg_blink_state.toggle();
                                        }else{
                                            winch_warning_msg_blink_state = true;
                                        }
                                    }
                                }
                            }
                    }
                    //                    .draw_border()
                    .padding(.horizontal,20.0)
                    .padding(.vertical,10.0)
                    //                    Spacer()
                }
                HStack{
                    VStack(spacing:1){
                        //CTD Depth
                        VStack(spacing:0){
                            Text("CTD depth")
                                .custom_title()
                            TextField("depth",text:$depth_val)
                                .custom_text_field_title()
                                .disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                        }
                        .draw_border()
                        .padding(.horizontal,20.0)
                        .padding(.vertical,10.0)
                        //Altitude
                        VStack(spacing:0){
                            Text("Altitude")
                                .custom_title()
                            TextField("altimeter",text:$alti_val)
                                .custom_text_field_title()
                                .foregroundColor(.red)
                                .disabled(true)
                        }
                        .draw_border()
                        .padding(.horizontal,20.0)
                        .padding(.vertical,50.0)
                        //Dz/Dt
                        VStack(spacing:0){
                            Text("dz/dt")
                                .custom_title_2()
                            TextField("dzdt",text:$dzdt_val)
                                .custom_text_field_2_title()
                                .disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                        }
                        .draw_border()
                        .padding(.horizontal,20.0)
                        .padding(.vertical,10.0)
                        //Acceleration
                        VStack(spacing:0){
                            Text("Z Accel")
                                .custom_title_2()
                            Canvas{ context, size in
                                renderA1(context: context, size: size)
                            }
                        }
                        .draw_border()
                        .padding(.horizontal,20.0)
                        .padding(.vertical,10.0)
                        Spacer()
                    }
                    .frame(width:metrics.size.width*0.65)
                    //                    .onAppear(perform: {
                    //                        connect_and_get_CTD_data()
                    //                    })
                    VStack{
                        //Sheave PX
                        VStack{
                            VStack(spacing:0){
                                Text("sheave PX")
                                    .custom_title_2()
                                TextField("sheave_px",text:$winch_sheave_px_val)
                                    .custom_text_field_2_title()
                                    .disabled(true)
                            }
                            .draw_border()
                            .padding(.horizontal,20.0)
                            .padding(.vertical,10.0)
                        }
                        VStack{
                            VStack(spacing:0){
                                Text("L/D Diff.")
                                    .custom_title_2()
                                TextField("line_depth_diff",text:$winch_ctd_line_depth_diff_val)
                                    .custom_text_field_2_title()
                                    .disabled(true)
                            }
                            .draw_border()
                            .padding(.horizontal,20.0)
                            .padding(.vertical,10.0)
                            VStack(spacing:0){
                                Text("Rec L/D Diff.")
                                    .custom_title_2()
                                    .multilineTextAlignment(.center)
                                TextField("rec_line_depth_diff",text:$winch_ctd_line_depth_diff_at_set_val)
                                    .custom_text_field_2_title()
                                    .disabled(true)
                            }
                            .draw_border()
                            .padding(.horizontal,20.0)
                            .padding(.vertical,10.0)
                            Button(action: {
                                if(!winch_sheave_px_old.isNaN){
                                    self.winch_ctd_line_depth_diff_at_set = self.winch_ctd_line_depth_diff;
                                }
                            }) {
                                Text("Rec L/D diff.")
                                    .font(.system(size: 30.0))
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .foregroundColor(.blue)
                                //                            .border(Color.purple, width: 5)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.blue, lineWidth: 5)
                                    )
                            }
                        }
                        .padding(.vertical,10.0)
                        //                        .padding(.bottom,50.0)
                        VStack(spacing:0){
                            Text("sheave VX")
                                .custom_title_2()
                                .multilineTextAlignment(.center)
                            TextField("sheave_vx",text:$winch_sheave_vx_val)
                                .custom_text_field_2_title()
                                .disabled(true)
                        }
                        .draw_border()
                        .padding(.horizontal,20.0)
                        .padding(.vertical,10.0)
                        VStack(spacing:0){
                            Text("sheave mode")
                                .custom_title_2()
                                .multilineTextAlignment(.center)
                            TextField("sheave_mode",text:$winch_sheave_mode)
                                .custom_text_field_2_title()
                                .disabled(true)
                        }
                        .draw_border()
                        .padding(.horizontal,20.0)
                        .padding(.vertical,10.0)
                        Spacer()
                    }
                }
                HStack{
                    //winch payout
                    VStack{
                        VStack(spacing:0){
                            Text("Payout [turns]")
                                .custom_title_2()
                            TextField("winch_payout",text:$winch_payout_val)
                                .custom_text_field_2_title()
                                .disabled(true)
                        }
                        .draw_border()
                        .padding(.horizontal,10.0)
                        .padding(.vertical,10.0)
                    }
                    //Winch vel
                    VStack{
                        VStack(spacing:0){
                            Text("Winch vel [rps]")
                                .custom_title_2()
                            TextField("winch_vel",text:$winch_vel_val)
                                .custom_text_field_2_title()
                                .disabled(true)
                        }
                        .draw_border()
                        .padding(.horizontal,10.0)
                        .padding(.vertical,10.0)
                    }
                    //Motor current
                    VStack{
                        VStack(spacing:0){
                            Text("Motor curr. [A]")
                                .custom_title_2()
                            TextField("winch_curr",text:$winch_curr_val)
                                .custom_text_field_2_title()
                                .disabled(true)
                        }
                        .draw_border()
                        .padding(.horizontal,10.0)
                        .padding(.vertical,10.0)
                    }
                    
                }
            }
            .onAppear(perform: {
                connect_and_get_winch_data()
                connect_and_get_CTD_data()
                connect_and_get_EPSI_data()
            })
        }
    }
    func update_line_depth_diff(){
        if(self.depth_old.isFinite && self.winch_sheave_px_cable_payout.isFinite){
            self.winch_ctd_line_depth_diff = self.winch_sheave_px_cable_payout-self.depth_old
        }
        if(self.winch_ctd_line_depth_diff.isNaN){
            self.winch_ctd_line_depth_diff_val = "NaN";
        }else{
            self.winch_ctd_line_depth_diff_val = String(format: "%+ .2f",self.winch_ctd_line_depth_diff) + " m"
        }
        if(self.winch_ctd_line_depth_diff_at_set.isNaN){
            self.winch_ctd_line_depth_diff_at_set_val = "NaN";
        }else{
            self.winch_ctd_line_depth_diff_at_set_val = String(format: "%+ .2f",self.winch_ctd_line_depth_diff_at_set) + " m"
        }
    }
    func populate_winch(parameters:[String]){
        let end_of_str = String(parameters.last!.prefix(1));
        if(parameters.first!.compare("$MWST", options: .caseInsensitive) != .orderedSame || end_of_str.compare("\r\n", options: .caseInsensitive) != .orderedSame){
            os_log(.info,"wrong data format")
            return;
        }
        let winch_rec_indx:UInt32? = UInt32(parameters[1].trimmingCharacters(in: .whitespacesAndNewlines))
        let winch_payout:Double? = Double(parameters[2].trimmingCharacters(in: .whitespacesAndNewlines))
        let winch_vel:Double? = Double(parameters[3].trimmingCharacters(in: .whitespacesAndNewlines))
        let winch_curr:Double? = Double(parameters[4].trimmingCharacters(in: .whitespacesAndNewlines))
        
        if winch_rec_indx != nil{
            if(winch_payout != nil){
                self.winch_payout_val = String(format: "%+ .2f",winch_payout!) + ""
            }
            if(winch_vel != nil){
                self.winch_vel_val = String(format: "%+ .1f",winch_vel!) + ""
            }
            if(winch_curr != nil){
                self.winch_curr_val = String(format: "%+ .1f",winch_curr!) + ""
            }
        }else{
            self.winch_payout_val = "NaN"
            self.winch_vel_val = "NaN"
            self.winch_curr_val = "NaN"
        }
    }
    func populate_sheave(parameters:[String]){
        let end_of_str = String(parameters.last!.prefix(1));
        if(parameters.first!.compare("$SHVE", options: .caseInsensitive) != .orderedSame || end_of_str.compare("\r\n", options: .caseInsensitive) != .orderedSame){
            os_log(.info,"wrong data format")
            return;
        }
        let winch_rec_indx:UInt32? = UInt32(parameters[1].trimmingCharacters(in: .whitespacesAndNewlines))
        let winch_sheave_px:Double? = Double(parameters[2].trimmingCharacters(in: .whitespacesAndNewlines))
        let winch_sheave_vx:Double? = Double(parameters[3].trimmingCharacters(in: .whitespacesAndNewlines))
        var winch_sheave_dir:Double? = Double(parameters[12].trimmingCharacters(in: .whitespacesAndNewlines))
        let sheave_count_per_turn:Double = 10000.0*60.0/22.0; // count per turn
        let sheave_length_per_turn:Double = 1.308; //m per turn
        let winch_sheave_stat_running_as_exp:UInt32? = UInt32(parameters[19].trimmingCharacters(in: .whitespacesAndNewlines))
        let winch_sheave_running_mode:UInt32? = UInt32(parameters[11].trimmingCharacters(in: .whitespacesAndNewlines))
        
        if winch_rec_indx != nil{
            if(winch_sheave_dir!>0){
                winch_sheave_dir = -1 //reverse
            }else{
                winch_sheave_dir = 1 // normal
            }
            if(winch_sheave_px != nil){
                self.winch_sheave_px_val = String(format: "%+ .2f",(winch_sheave_px!-winch_sheave_px_offset)*winch_sheave_dir!/sheave_count_per_turn*sheave_length_per_turn) + " m"
                self.winch_sheave_px_old = winch_sheave_px!;
            }
            if(winch_sheave_vx != nil && winch_sheave_dir != nil){
                self.winch_sheave_vx_val = String(format: "%+ .2f",winch_sheave_vx!*winch_sheave_dir!/sheave_count_per_turn*sheave_length_per_turn) + " m/s"
                self.winch_sheave_vx_old = winch_sheave_vx!;
            }
            if(winch_sheave_px != nil && winch_sheave_dir != nil){
                self.winch_sheave_px_cable_payout = winch_sheave_px!*winch_sheave_dir!/sheave_count_per_turn*sheave_length_per_turn;
                update_line_depth_diff()
            }
            // Checking if the sheave is running
            if (winch_sheave_stat_running_as_exp != nil && winch_sheave_stat_running_as_exp == 0){
                self.winch_warning_avail_flag |= 1<<1;
                self.winch_warning_msg = "Check sheave!"
            }else{
                self.winch_warning_avail_flag &= ~(UInt8(1)<<1);
                if(self.winch_warning_avail_flag==0){
                    self.winch_warning_msg = " "
                }
            }
            
            // SHEAVE Mode
            if(winch_sheave_running_mode != nil){
                switch(winch_sheave_running_mode!){
                case 0:
                    self.winch_sheave_mode = "stop"
                case 1:
                    self.winch_sheave_mode = "manual"
                case 2:
                    self.winch_sheave_mode = "auto out"
                case 3:
                    self.winch_sheave_mode = "auto in"
                default:
                    self.winch_sheave_mode = "error"
                }
            }
        }else{
            self.winch_sheave_px_val = "NaN"
            self.winch_sheave_vx_val = "NaN"
        }
    }
    func populate_levelwind(parameters:[String]){
        let end_of_str = String(parameters.last!.prefix(1));
        if(parameters.first!.compare("$LVWD", options: .caseInsensitive) != .orderedSame || end_of_str.compare("\r\n", options: .caseInsensitive) != .orderedSame){
            os_log(.info,"wrong data format")
            return;
        }
        let winch_lw_stat_running_as_exp:UInt32? = UInt32(parameters[12].trimmingCharacters(in: .whitespacesAndNewlines))
        if (winch_lw_stat_running_as_exp != nil && winch_lw_stat_running_as_exp == 0){
            self.winch_warning_avail_flag |= 1;
            self.winch_warning_msg = "Check level wind!"
        }else{
            self.winch_warning_avail_flag &= ~(UInt8(1));
            if(self.winch_warning_avail_flag==0){
                self.winch_warning_msg = " "
            }
        }
    }
    func populate_fish_data(parameters:[String]){
        if(parameters.count != 5){
            return
        }
        let altimeter:Double? = Double(parameters[4].trimmingCharacters(in: .whitespacesAndNewlines))
        let press:Double? = Double(parameters[1].trimmingCharacters(in: .whitespacesAndNewlines))
        let time:Double? = Double(parameters[0].trimmingCharacters(in: .whitespacesAndNewlines))
        
        if (press != nil){
            let depth:Double? = press2dpth(pressure: press!, latitude: 65.0)
            
            if(altimeter!.isNaN){
                self.alti_val = "NaN"
                if(self.sound_effect != nil || self.sound_effect!.isPlaying){
                    self.sound_effect?.stop();
                }
                if(self.sound_effect_2 != nil || self.sound_effect_2!.isPlaying){
                    self.sound_effect_2?.stop();
                }
                //                                        self.depth_val = "NaN"
            }else{
                //                                        self.depth_val = String(format: "%.2f", depth!) + " m"
                self.alti_val = String(format: "%.1f",altimeter!*1500.0/1000000.0) + " m"
                if(!self.dz_dt.isNaN && self.dz_dt>0){
                    if( (altimeter!*1500.0/1000000.0) < 20.0){
                        if(self.sound_effect != nil || self.sound_effect!.isPlaying){
                            self.sound_effect?.stop();
                        }
                        if(self.sound_effect_2 != nil || !self.sound_effect_2!.isPlaying){
                            self.sound_effect_2?.volume = 1.0
                            self.sound_effect_2?.play();
                        }
                    }else if( (altimeter!*1500.0/1000000.0) < 40.0){
                        if(self.sound_effect_2 != nil || self.sound_effect_2!.isPlaying){
                            self.sound_effect_2?.stop();
                        }
                        if(self.sound_effect != nil || !self.sound_effect!.isPlaying){
                            self.sound_effect?.volume = 1.0
                            self.sound_effect?.play();
                        }
                        
                    }else{
                        if(self.sound_effect_2 != nil || self.sound_effect_2!.isPlaying){
                            self.sound_effect_2?.stop();
                        }
                        if(self.sound_effect != nil || self.sound_effect!.isPlaying){
                            self.sound_effect?.stop();
                        }
                    }
                    
                }
                else{
                    if(self.sound_effect != nil || self.sound_effect!.isPlaying){
                        self.sound_effect?.stop();
                    }
                    if(self.sound_effect_2 != nil || self.sound_effect_2!.isPlaying){
                        self.sound_effect_2?.stop();
                    }
                }
            }
            
            if(press!.isNaN){
                self.depth_val = "NaN"
            }else{
                self.depth_val = String(format: "%.1f", depth!) + " m"
            }
            
            if (time != nil && !depth!.isNaN && !self.depth_old.isNaN && !time!.isNaN && !self.time_old.isNaN ){
                //                                    var dz_dt:Double = 0;
                if (time! <= self.time_old){
                    self.dz_dt = (depth!-self.depth_old)/(time!+10000.0-self.time_old)*100.0
                }else{
                    self.dz_dt =  (depth!-self.depth_old)/(time!-self.time_old)*100.0
                }
                if(self.dz_dt_filtered.isNaN || !self.dz_dt_filtered.isFinite){
                    self.dz_dt_filtered = self.dz_dt;
                }else{
                    if(!self.dz_dt.isNaN && self.dz_dt_filtered.isFinite && self.dz_dt_filtered.magnitude<15){
                        self.dz_dt_filtered += self.dz_dt_alpha*(self.dz_dt - self.dz_dt_filtered);
                    }
                }
                self.depth_old = depth!;
                self.time_old = time!;
                
                self.dzdt_val = String(format: "%+ 2.2f",self.dz_dt_filtered) + " m/s"
            }else{
                self.dzdt_val = "NaN"
            }
            if (time != nil && (self.time_old.isNaN)){
                self.time_old = time!;
            }
            if (depth != nil && (self.depth_old.isNaN)){
                self.depth_old = depth!;
                update_line_depth_diff();
            }
        }else{
            self.alti_val = "NaN"
            self.depth_val = "NaN/NaN"
            self.dzdt_val = "NaN"
        }
    }
    func connect_and_get_CTD_data(){
        do{
            ctd_udp_server.port = 50210
            try(ctd_udp_server.start())
            
            //prevent app from sleeping,
            //https://developer.apple.com/documentation/uikit/uiapplication/1623070-isidletimerdisabled
            UIApplication.shared.isIdleTimerDisabled = true
            if let fileURL = Bundle.main.url(forResource: "Beep", withExtension: "caf") {
                do {
                    
                    self.sound_effect = try AVAudioPlayer(contentsOf: fileURL)
                    
                } catch {
                    // couldn't load file :(
                    os_log(.info,"could not load sound")
                }
            }
            if let fileURL = Bundle.main.url(forResource: "CensorBeep", withExtension: "wav") {
                do {
                    
                    self.sound_effect_2 = try AVAudioPlayer(contentsOf: fileURL)
                    
                } catch {
                    // couldn't load file :(
                    os_log(.info,"could not load sound")
                }
            }
            //            let path = Bundle.main.path(forResource: "Beep", ofType:"caf")
            //            let url = URL(fileURLWithPath: path!)
            
            self.depth_val = "connected"
            self.alti_val = "connected"
            self.dzdt_val = "connected"
            
            //set up event trigger
            self.ctd_server_src = DispatchSource.makeReadSource(fileDescriptor: ctd_udp_server.server_socket)
            //            let serverSource = DispatchSource.makeReadSource(fileDescriptor: udp_server.server_socket)
            
            self.ctd_server_src.setEventHandler {
                
                var info = sockaddr_storage()
                var len = socklen_t(MemoryLayout<sockaddr_storage>.size)
                
                let s = Int32(self.ctd_server_src.handle)
                var buffer = [UInt8](repeating:0, count: 256)
                
                withUnsafeMutablePointer(to: &info, { (pinfo) -> () in
                    
                    let paddr = UnsafeMutableRawPointer(pinfo).assumingMemoryBound(to: sockaddr.self)
                    
                    let received = recvfrom(s, &buffer, buffer.count, 0, paddr, &len)
                    
                    if received < 0 {
                        return
                    }
                    
                    print("received \(received) bytes")
                    os_log(.info,"received \(received) bytes")
                    DispatchQueue.main.async {  // this is to correct for calling an update in the background
                        if let buffer_str = String(bytes: buffer, encoding: .utf8) {
                            //                            print(buffer_str);
                            let separated_str = buffer_str.components(separatedBy: ",")
                            //var separated_str1 = separated_str[4].components(separatedBy: "\0")
                            populate_fish_data(parameters: separated_str)
                        } else {
                            self.alti_val = "NaN"
                            self.depth_val = "NaN/NaN"
                            self.dzdt_val = "NaN"
                        }
                    }
                })
            }
            serverSources.append(self.ctd_server_src)
            
            self.ctd_server_src.resume()
        }
        catch{
            ctd_udp_server.stop()
            //enable app to sleep after timeout
            //https://developer.apple.com/documentation/uikit/uiapplication/1623070-isidletimerdisabled
            UIApplication.shared.isIdleTimerDisabled = false
            //                udp_server = nil
            print(error)
        }
    }
    func readValue<Result>(_: Result.Type, from: inout [UInt8], at: inout Int) -> Result
    {
        let size = MemoryLayout<Result>.size
        assert(at + size <= from.count)
        let value: Result = from.withUnsafeBytes {
            return $0.load(fromByteOffset: at, as: Result.self)
        }
        at += size
        return value
    }
    func vToLerp(v: Double) -> Double {
        return (v - epsi_a1_g_min) / (epsi_a1_g_max - epsi_a1_g_min)
    }
    func lerpToY(s: Double, rect: CGRect) -> Double {
        return floor(rect.maxY - rect.height * s)
    }
    func lerpToX(s: Double, rect: CGRect) -> Double {
        return floor(rect.minX + rect.width * s)
    }
    func dataToX(_ i: Int, rect: CGRect) -> Double {
        return lerpToX(s: Double(i) / Double(epsi_a1_g.count - 2), rect: rect)
    }
    func dataToY(v: UInt8, rect: CGRect) -> Double {
        return lerpToY(s: Double(v) / 255.0, rect: rect)
    }
    func dataToValue(v: UInt8) -> Double {
        return epsi_a1_g_min + (epsi_a1_g_max - epsi_a1_g_min) * Double(v) / 255.0
    }
    func dataToY(_ i: Int, rect: CGRect) -> Double {
        return dataToY(v: epsi_a1_g[i], rect: rect)
    }
    func drawArrow(context: GraphicsContext, from: CGPoint, to: CGPoint, thick: Double, head: Double, color: Color) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let len = sqrt(dx * dx + dy * dy)
        let dir = atan2(dy, dx)
        context.drawLayer { ctx in
            ctx.translateBy(x: from.x, y: from.y)
            ctx.rotate(by: Angle(radians: dir))
            ctx.stroke(Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: len - head, y: 0))
            }, with: .color(color),
                       lineWidth: thick)
            ctx.fill(Path { path in
                path.move(to: CGPoint(x: len, y: 0))
                path.addLine(to: CGPoint(x: len - head, y: head / 2))
                path.addLine(to: CGPoint(x: len - head, y: -head / 2))
            }, with: .color(color))
        }
    }
    let a1_pos_color = Color(red: 233/255, green: 145/255, blue: 195/255)
    let a1_neg_color = Color(red: 82/255, green: 135/255, blue: 187/255)
    func renderA1(context: GraphicsContext, size: CGSize) {
        guard !epsi_a1_g.isEmpty else { return }
        let vgap = 5.0
        let rect = CGRect(x: 0.0, y: 5.0, width: size.width, height: size.height - 2 * vgap)
    
        let label_x = lerpToX(s: 0.5, rect: rect)
        var mark = floor(epsi_a1_g_min)
        while mark <= ceil(epsi_a1_g_max) {
            let mark_y = lerpToY(s: vToLerp(v: mark), rect: rect)

            let style = mark - floor(mark) > 0.0 ?
                        StrokeStyle(lineWidth: 0.5, dash: [5]) :
                        StrokeStyle(lineWidth: 2.0)
            context.stroke(Path { path in
                path.move(to: CGPoint(x: rect.minX, y: mark_y))
                path.addLine(to: CGPoint(x: rect.maxX, y: mark_y))
            }, with: .color(.gray), style: style)

            let anchor:UnitPoint = (rect.maxY - mark_y) < 10.0 ? .bottom : .top
            context.draw(Text(String(format: "%.1f", mark)).foregroundColor(.gray),
                         at: CGPoint(x: label_x, y: mark_y),
                         anchor: anchor)
            if mark == 0.0 {
                let arrow_x = rect.maxX - 10.0
                let arrow_len = 50.0
                let arrow_thick = 10.0
                let arrow_head = 20.0
                let arrow_gap = 2.0
                var arrow_y = mark_y
                var hideUpArrow = false
                var hideDownArrow = false
                if mark_y < rect.minY {
                    arrow_y = max(mark_y, rect.minY)
                    hideUpArrow = true
                }
                if mark_y > rect.maxY {
                    arrow_y = min(mark_y, rect.maxY)
                    hideDownArrow = true
                }
                if !hideUpArrow {
                    drawArrow(context: context, from: CGPoint(x: arrow_x, y: arrow_y - arrow_gap), to: CGPoint(x: arrow_x, y: arrow_y - arrow_len), thick: arrow_thick, head: arrow_head, color: a1_pos_color)
                }
                if !hideDownArrow {
                    drawArrow(context: context, from: CGPoint(x: arrow_x, y: arrow_y + arrow_gap), to: CGPoint(x: arrow_x, y: arrow_y + arrow_len),    thick: arrow_thick, head: arrow_head, color: a1_neg_color)
                }
            }
            mark += 0.5
        }

        let path = Path { path in
            path.move(to: CGPoint(x: dataToX(0, rect: rect), y: dataToY(0, rect: rect)))
            for i in 1..<epsi_a1_g.count {
                path.addLine(to: CGPoint(x: dataToX(i, rect: rect), y: dataToY(i, rect: rect)))
            }
        }
        let lineWidth = 8.0
        let zero_y = lerpToY(s: vToLerp(v: 0.0), rect: rect)
        if (zero_y > rect.minY) {
            context.drawLayer { ctx in
                ctx.clip(to: Path(CGRect(x: rect.minX, y: rect.minY - vgap, width: rect.width, height: zero_y - rect.minY + vgap)))
                ctx.stroke(path, with: .color(a1_pos_color), lineWidth: lineWidth)
            }
        }
        if (zero_y < rect.maxY) {
            context.drawLayer { ctx in
                ctx.clip(to: Path(CGRect(x: rect.minX, y: zero_y, width: rect.width, height: rect.maxY - zero_y + vgap)))
                ctx.stroke(path, with: .color(a1_neg_color), lineWidth: lineWidth)
            }
        }
        /*
        let last_v = dataToValue(v: epsi_a1_g.last!)
        let last_y = dataToY(v: epsi_a1_g.last!, rect: rect)
        let anchor:UnitPoint = (rect.maxY - last_y) < 10.0 ? .bottomTrailing : .topTrailing
        context.draw(Text(String(format: "%.1fg", last_v)).font(.title).bold().foregroundColor(.black),
                     at: CGPoint(x: rect.maxX, y: last_y),
                     anchor: anchor)
         */
    }
    func connect_and_get_EPSI_data(){
        do{
            epsi_udp_server.port = 50211
            try(epsi_udp_server.start())
            
            //prevent app from sleeping,
            //https://developer.apple.com/documentation/uikit/uiapplication/1623070-isidletimerdisabled
            UIApplication.shared.isIdleTimerDisabled = true

            //set up event trigger
            self.epsi_server_src = DispatchSource.makeReadSource(fileDescriptor: epsi_udp_server.server_socket)
            self.epsi_server_src.setEventHandler {
                
                var info = sockaddr_storage()
                var len = socklen_t(MemoryLayout<sockaddr_storage>.size)

                let s = Int32(self.epsi_server_src.handle)
                var buffer = [UInt8](repeating:0, count: 5 * 1024)
                
                withUnsafeMutablePointer(to: &info, { (pinfo) -> () in
                    let paddr = UnsafeMutableRawPointer(pinfo).assumingMemoryBound(to: sockaddr.self)
                    let received = recvfrom(s, &buffer, buffer.count, 0, paddr, &len)
                    DispatchQueue.main.async {
                        if received > 0 {
                            self.epsi_a1_g.removeAll()
                            self.epsi_a1_val = "no data"
                            if received > 4 + 4 + 2 {
                                var i = 0
                                self.epsi_a1_g_min = Double(readValue(Float.self, from: &buffer, at: &i))
                                self.epsi_a1_g_max = Double(readValue(Float.self, from: &buffer, at: &i))
                                let samples = Int(readValue(UInt16.self, from: &buffer, at: &i))
                                if samples > 0 {
                                    self.epsi_a1_g = Array(buffer[i..<i+samples])
                                    i += samples
                                }
                                self.epsi_a1_val = ""
                            }
                        }
                    }
                })
            }
            serverSources.append(self.epsi_server_src)
            
            self.epsi_server_src.resume()
        }
        catch{
            epsi_udp_server.stop()
            //enable app to sleep after timeout
            //https://developer.apple.com/documentation/uikit/uiapplication/1623070-isidletimerdisabled
            UIApplication.shared.isIdleTimerDisabled = false
            print(error)
        }
    }
    func connect_and_get_winch_data(){
        do{
            winch_udp_server.port = 50500
            try(winch_udp_server.start())
            
            //prevent app from sleeping,
            //https://developer.apple.com/documentation/uikit/uiapplication/1623070-isidletimerdisabled
            UIApplication.shared.isIdleTimerDisabled = true
            if let fileURL = Bundle.main.url(forResource: "Beep", withExtension: "caf") {
                do {
                    
                    self.sound_effect = try AVAudioPlayer(contentsOf: fileURL)
                    
                } catch {
                    // couldn't load file :(
                    os_log(.info,"could not load sound")
                }
            }
            
            self.winch_sheave_px_val = "connected"
            self.winch_sheave_vx_val = "connected"
            self.winch_sheave_mode = "connected"
            
            //set up event trigger
            self.winch_server_src = DispatchSource.makeReadSource(fileDescriptor: winch_udp_server.server_socket)
            //            let serverSource = DispatchSource.makeReadSource(fileDescriptor: udp_server.server_socket)
            
            self.winch_server_src.setEventHandler {
                var info = sockaddr_storage()
                var len = socklen_t(MemoryLayout<sockaddr_storage>.size)
                
                let s = Int32(self.winch_server_src.handle)
                var buffer = [UInt8](repeating:0, count: 256)
                
                withUnsafeMutablePointer(to: &info, { (pinfo) -> () in
                    
                    let paddr = UnsafeMutableRawPointer(pinfo).assumingMemoryBound(to: sockaddr.self)
                    
                    let received = recvfrom(s, &buffer, buffer.count, 0, paddr, &len)
                    
                    if received < 0 {
                        return
                    }
                    
                    os_log(.info,"winch data received \(received) bytes")
                    DispatchQueue.main.async {  // this is to correct for calling an update in the background
                        let tag_termination_str: String = "\r\n"
                        if let buffer_str = String(bytes: buffer, encoding: .utf8) {
                            //                            print(buffer_str);
                            let separated_str = buffer_str.components(separatedBy: ",")
                            let end_of_str = String(separated_str.last!.prefix(1));
                            let start_of_str = String(separated_str.first!.prefix(1));
                            if(start_of_str.compare("$", options: .caseInsensitive) != .orderedSame || end_of_str.compare(tag_termination_str, options: .caseInsensitive) != .orderedSame){
                                os_log(.info,"wrong data format")
                                return;
                            }
                            os_log(.info,"\(separated_str.first!) data received \(received) bytes with \(separated_str.count) parameters");
                            switch separated_str.first! {
                            case "$SHVE":
                                populate_sheave(parameters: separated_str);
                            case "$LVWD":
                                populate_levelwind(parameters: separated_str);
                            case "$MWST":
                                populate_winch(parameters: separated_str);
                            default:
                                os_log(.info,"this tag is unknown");
                            }
                        }
                    }
                })
            }
            serverSources.append(self.winch_server_src)
            
            self.winch_server_src.resume()
        }
        catch{
            winch_udp_server.stop()
            //enable app to sleep after timeout
            //https://developer.apple.com/documentation/uikit/uiapplication/1623070-isidletimerdisabled
            UIApplication.shared.isIdleTimerDisabled = false
            //                udp_server = nil
            print(error)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
