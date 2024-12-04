import Foundation

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
        d = ModelData()
    }
    func appendNewFileBoundary() {
        for child in Mirror(reflecting: d).children {
            if let tda = child.value as? Array<TimestampedData> {
                if !tda.isEmpty {
                    tda.last!.appendNewFileBoundary()
                }
            }
        }
    }
    func getEndTime() -> Double {
        var endTime = 0.0
        for child in Mirror(reflecting: d).children {
            if let tda = child.value as? Array<TimestampedData> {
                endTime = max(endTime, tda.getEndTime())
            }
        }
        return endTime
    }
    func getBeginTime() -> Double {
        var beginTime = Double.greatestFiniteMagnitude
        for child in Mirror(reflecting: d).children {
            if let tda = child.value as? Array<TimestampedData> {
                beginTime = min(beginTime, tda.getBeginTime())
            }
        }
        return beginTime
    }
    func resetIsUpdated() -> Bool {
        defer { d.isUpdated = false }
        return d.isUpdated
    }
}
