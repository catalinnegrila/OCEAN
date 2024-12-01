import SwiftUI

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
