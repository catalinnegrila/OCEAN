import Foundation

// TODO: boxed array for data channels
// TODO: generic ViewModelData

class Model: Observable {
    struct ModelData {
        var epsi_blocks = [EpsiModelData]()
        var ctd_blocks = [CtdModelData]()
        var fluor_blocks = [FluorModelData]()
        var vnav_blocks = [VnavModelData]()
        var ttv_blocks = [TtvModelData]()
        var fishflag: String = "n/a"
        var mostRecentCoords: LatLon? {
            didSet {
                isUpdated = true
            }
        }
        var isUpdated = true
    }
    @Published var d = ModelData()
    @Published var title: String {
        didSet {
            d.isUpdated = true
            print(title)
        }
    }

    init() {
        title = ""
    }
    func reset() {
        print("model reset")
        d = ModelData()
    }
    func appendNewFileBoundary() {
        if !d.epsi_blocks.isEmpty {
            d.epsi_blocks.last!.appendNewFileBoundary()
        }
        if !d.ctd_blocks.isEmpty {
            d.ctd_blocks.last!.appendNewFileBoundary()
        }
        if !d.fluor_blocks.isEmpty {
            d.fluor_blocks.last!.appendNewFileBoundary()
        }
        if !d.vnav_blocks.isEmpty {
            d.vnav_blocks.last!.appendNewFileBoundary()
        }
        if !d.ttv_blocks.isEmpty {
            d.ttv_blocks.last!.appendNewFileBoundary()
        }
    }
    func getEndTime() -> Double {
        var endTime = d.epsi_blocks.getEndTime()
        endTime = max(endTime, d.ctd_blocks.getEndTime())
        endTime = max(endTime, d.fluor_blocks.getEndTime())
        endTime = max(endTime, d.vnav_blocks.getEndTime())
        endTime = max(endTime, d.ttv_blocks.getEndTime())
        return endTime
    }
    func getBeginTime() -> Double {
        var beginTime = d.epsi_blocks.getBeginTime()
        beginTime = min(beginTime, d.ctd_blocks.getBeginTime())
        beginTime = min(beginTime, d.fluor_blocks.getBeginTime())
        beginTime = min(beginTime, d.vnav_blocks.getBeginTime())
        beginTime = min(beginTime, d.ttv_blocks.getBeginTime())
        return beginTime
    }
    func resetIsUpdated() -> Bool {
        defer { d.isUpdated = false }
        return d.isUpdated
    }
}
