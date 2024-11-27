import Foundation

class ViewModel
{
    var model = Model()
    var time_window = (0.0, 0.0)
    var epsi = EpsiViewModelData()
    var ctd = CtdViewModelData()
    var broadcaster = ViewModelBroadcaster()

    var modelProducer: ModelProducer? {
        willSet {
            if let modelProducer {
                modelProducer.stop()
            }
            model.reset()
        }
        didSet {
            if let modelProducer {
                modelProducer.start(model: model)
            }
        }
    }
    func update() -> Bool {
        if let modelProducer = modelProducer {
            if modelProducer.update(model: model) {
                time_window = modelProducer.getTimeWindow(model: model)
                epsi.mergeBlocks(time_window: time_window, blocks: &model.epsi_blocks)
                ctd.mergeBlocks(time_window: time_window, blocks: &model.ctd_blocks)
                broadcaster.broadcast(vm: self)
                return true
            }
        }

        return false
    }
}
