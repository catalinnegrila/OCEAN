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
    @Published var isEmpty = true
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
    fileprivate func forEachArray(_ body: (inout Array<TimestampedData>) -> Void) {
        for child in Mirror(reflecting: d).children {
            if var tda = child.value as? Array<TimestampedData> {
                body(&tda)
            }
        }
    }
    func appendNewFileBoundary() {
        forEachArray( { tda in
            if !tda.isEmpty {
                tda.last!.appendNewFileBoundary()
            }
        })
    }
    func getEndTime() -> Double {
        var endTime = 0.0
        forEachArray( { tda in
            endTime = max(endTime, tda.getEndTime())
            endTime = max(endTime, tda.getEndTime())
        })
        return endTime
    }
    func getBeginTime() -> Double {
        var beginTime = Double.greatestFiniteMagnitude
        forEachArray( { tda in
            beginTime = min(beginTime, tda.getBeginTime())
        })
        return beginTime
    }
    func resetIsUpdated() -> Bool {
        isEmpty = true
        forEachArray( { tda in
            if !tda.isEmpty {
                isEmpty = false
            }
        })
        defer { d.isUpdated = false }
        return d.isUpdated
    }
}
