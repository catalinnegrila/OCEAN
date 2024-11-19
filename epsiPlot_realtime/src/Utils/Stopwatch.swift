import Foundation

class Stopwatch {
    let label: String
    let start_time: TimeInterval
    init(label: String) {
        self.label = label
        self.start_time = ProcessInfo.processInfo.systemUptime
    }
    func printElapsed() {
        let end_time = ProcessInfo.processInfo.systemUptime
        let msec = Int((end_time - start_time) * 1000)
        print("\(label): \(msec) ms")
    }
}
