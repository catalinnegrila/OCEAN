import Foundation

class Model {
    var epsi_blocks = [EpsiModelData]()
    var ctd_blocks = [CtdModelData]()
    var status = "No data source"
    var fileUrl: URL?
    var isUpdated: Bool = false

    func update() -> Bool {
        defer { isUpdated = false }
        return isUpdated
    }
    func getTimeWindow() -> (Double, Double) {
        return (0.0, 0.0)
    }

}
