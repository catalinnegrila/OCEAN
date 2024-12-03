import Foundation

// TODO: boxed array for data channels
// TODO: generic ViewModelData

class Model: Observable {
    enum DeploymentType: Int {
        case EPSI = 1, FCTD
        
        static func from(fishflag: String) -> DeploymentType{
            switch fishflag {
            case "'EPSI'": return .EPSI
            case "'FCTD'": return .FCTD
            default:
                print("Unknown fishflag: \(fishflag)")
                return .EPSI
            }
        }
    }
    static let fishflagFieldName = "CTD.fishflag"
    struct ModelData {
        var fishflag: String = "n/a"
        var deploymentType: DeploymentType = .EPSI
        var epsi_blocks = [EpsiModelData]()
        var ctd_blocks = [CtdModelData]()
        var fluor_blocks = [FluorModelData]()
        var vnav_blocks = [VnavModelData]()
        var mostRecentCoords: LatLon?
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
    }
    func getEndTime() -> Double {
        var endTime = d.epsi_blocks.getEndTime()
        endTime = max(endTime, d.ctd_blocks.getEndTime())
        //endTime = max(endTime, d.fluor_blocks.getEndTime())
        //endTime = max(endTime, d.vnav_blocks.getEndTime())
        return endTime
    }
    func getBeginTime() -> Double {
        var beginTime = d.epsi_blocks.getBeginTime()
        beginTime = min(beginTime, d.ctd_blocks.getBeginTime())
        //beginTime = min(beginTime, d.fluor_blocks.getBeginTime())
        //beginTime = min(beginTime, d.vnav_blocks.getBeginTime())
        return beginTime
    }
    func resetIsUpdated() -> Bool {
        defer { d.isUpdated = false }
        return d.isUpdated
    }
}
