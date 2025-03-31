//
//  SonarApp.swift
//  Sonar
//
//  Created by Catalin Negrila on 3/29/25.
//

import SwiftUI

@main
struct SonarApp: App {
    public init()
    {
        let parser = try! RawParser(data: Data(contentsOf: URL(fileURLWithPath: "/Users/catalin/Downloads/sonar/HDSS_50k_RR2403_20240415_231038.hdss_raw"), options: .alwaysMapped))
        let reader = ByteArrayReader(data: parser.data[...])
        let fheader = RawBlock_fheader(reader: reader)
        assert(fheader.app_ver.starts(with: "20.24.03"))
        // Dereference some useful variables
        let nchannels = fheader.param.n_channels
        let nsamples  = fheader.param.samples_to_acquire
        let rec_data_size = fheader.rec_size - fheader.rec_header_size
        let total_file_header_size = fheader.size + fheader.setup_file_size
        // Calculate total data record size
        let nbytes = parser.data.count - total_file_header_size
        let nrecs = nbytes / fheader.rec_size
        assert(nrecs == fheader.rec_count)
        let extra = nbytes % fheader.rec_size
        assert(extra == 0)
        let extra2 = rec_data_size % nchannels
        assert(extra2 == 0)

        var data = Array(repeating: Array(repeating: 0, count: nsamples), count: nchannels)
        //for i in 0..<nrecs {
        let i = 0
            reader.cursor = total_file_header_size + i * fheader.rec_size
            let rheader = RawBlock_rheader(reader: reader)
            print("Rec \(i): \(rheader.id)")
            reader.cursor = total_file_header_size + i * fheader.rec_size + fheader.rec_header_size
            for k in 0..<nsamples {
                for j in 0..<nchannels {
                    data[j][i * nsamples + k] = Int(reader.readLEInt16())
                    //_ = reader.readLEInt16()
                    //_ = Int(reader.data[reader.cursor]) + Int(reader.data[reader.cursor+1]) * 256
                    //reader.cursor += 2
                }
            }
        for j in 0..<nchannels {
            print("Channel \(j) min \(data[j].min()!) max \(data[j].max()!)")
        }
        //}
        print("Done.")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
