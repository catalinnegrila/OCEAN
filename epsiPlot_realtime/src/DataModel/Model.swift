import Foundation

class Model {
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
    
    var deploymentType: DeploymentType = .EPSI
    var epsi_blocks = [EpsiModelData]()
    var ctd_blocks = [CtdModelData]()
    var mostRecentLatitudeScientific = 0.0
    var mostRecentLongitudeScientific = 0.0
    var mostRecentLatitude = ""
    var mostRecentLongitude = ""
    var isUpdated = true

    fileprivate var _status = "No data source"
    var status: String {
        get {
            return _status
        }
        set(newStatus) {
            isUpdated = true
            _status = newStatus
            print(_status)
        }
    }

    func reset() {
        deploymentType = .EPSI
        epsi_blocks = [EpsiModelData]()
        ctd_blocks = [CtdModelData]()
        mostRecentLatitudeScientific = 0.0
        mostRecentLongitudeScientific = 0.0
        mostRecentLatitude = ""
        mostRecentLongitude = ""
        isUpdated = true
        status = "No data source"
    }

    func appendNewFileBoundary() {
        if !epsi_blocks.isEmpty {
            epsi_blocks.last!.appendNewFileBoundary()
        }
        if !ctd_blocks.isEmpty {
            ctd_blocks.last!.appendNewFileBoundary()
        }
    }
}

class ModelProducer {
    func start(model: Model) {
    }
    func stop() {
    }
    func update(model: Model) -> Bool {
        defer { model.isUpdated = false }
        return model.isUpdated
    }
    func getTimeWindow(model: Model) -> (Double, Double) {
        return (0.0, 0.0)
    }
}
