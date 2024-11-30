import Foundation

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
        var fishflag: String = ""
        var deploymentType: DeploymentType = .EPSI
        var epsi_blocks = [EpsiModelData]()
        var ctd_blocks = [CtdModelData]()
        var mostRecentLatitudeScientific = Double.nan
        var mostRecentLongitudeScientific = Double.nan
        var mostRecentLatitude = "n/a"
        var mostRecentLongitude = "n/a"
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
    }
    func getEndTime() -> Double {
        let epsi_time_end = d.epsi_blocks.getEndTime()
        let ctd_time_end = d.ctd_blocks.getEndTime()
        return max(epsi_time_end, ctd_time_end)
    }
    func getBeginTime() -> Double {
        let epsi_time_begin = d.epsi_blocks.getBeginTime()
        let ctd_time_begin = d.ctd_blocks.getBeginTime()
        return min(epsi_time_begin, ctd_time_begin)
    }
    func resetIsUpdated() -> Bool {
        defer { d.isUpdated = false }
        return d.isUpdated
    }
}

class ModelProducer {
    func start(model: Model) {
    }
    func stop() {
    }
    func update(model: Model) -> Bool {
        return model.resetIsUpdated()
    }
    func getTimeWindow(model: Model) -> (Double, Double) {
        return (0.0, 0.0)
    }
}
