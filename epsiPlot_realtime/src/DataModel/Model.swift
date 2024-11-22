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

    let semaphore = DispatchSemaphore(value: 1)
    // BEGIN thread safe data protected by the sempahore
    var deploymentType: DeploymentType = .EPSI
    var epsi_blocks = [EpsiModelData]()
    var ctd_blocks = [CtdModelData]()
    var mostRecentLatitudeScientific = 0.0
    var mostRecentLongitudeScientific = 0.0
    var mostRecentLatitude = ""
    var mostRecentLongitude = ""
    var isUpdated: Bool = false
    // END thread safe data protected by the sempahore

    var status = "No data source"
    var fileUrl: URL?

    func update() -> Bool {
        defer { isUpdated = false }
        return isUpdated
    }
    func getTimeWindow() -> (Double, Double) {
        return (0.0, 0.0)
    }

}
