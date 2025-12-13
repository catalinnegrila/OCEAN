import Foundation
import SwiftUI
public class ViewModel: ObservableObject
{
    @AppStorage("lastOpenFile") var lastOpenFile : URL?
    @AppStorage("lastOpenFolder") var lastOpenFolder : URL?
    @AppStorage("lastOpenSocket") var lastOpenSocket : URL?

    var model = Model()
    @Published var time_window = (0.0, 0.0)
    var epsi = EpsiViewModelData()
    var ctd = CtdViewModelData()
    var fluor = FluorViewModelData()
    var vnav = VnavViewModelData()
    var ttv = TtvViewModelData()
    @Published var broadcaster = ViewModelBroadcaster()

    var currentGraphPreset = "n/a"
    @Published var graphs = [GraphDescriptor]()

    @Published var modelProducer: ModelProducer? {
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
    init() {
        initializeGraphDescriptors()
        _ = openLast()
    }
    func openLast() -> Bool {
        if let lastOpenFile {
            openFile(lastOpenFile)
        } else if let lastOpenFolder {
            openFolder(lastOpenFolder)
        } else if let lastOpenSocket {
            openSocket(lastOpenSocket)
        } else {
            return false
            //openSocketWithBonjour()
        }
        return true
    }
    fileprivate func initializeGraphDescriptors() {
        graphs.append(GraphDescriptor("FP07 [Volt]",   [true, false], self.epsi.renderT))
        graphs.append(GraphDescriptor("Shear [Volt]",  [true, false], self.epsi.renderS))
        graphs.append(GraphDescriptor("s1 [Volt]",     [false, true], self.epsi.renderS1))
        graphs.append(GraphDescriptor("s2 [Volt]",     [false, true], self.epsi.renderS2))
        graphs.append(GraphDescriptor("Accel [g]",     [true, true], self.epsi.renderA))

        graphs.append(GraphDescriptor("T [\u{00B0}C]", [true, true], self.ctd.renderT))
        graphs.append(GraphDescriptor("S",             [true, true], self.ctd.renderS))
        graphs.append(GraphDescriptor("dzdt [m/s]",    [true, false], self.ctd.renderDzdt))
        graphs.append(GraphDescriptor("z [m]",         [true, false], self.ctd.renderZ))
        graphs.append(GraphDescriptor("z [m] + dzdt",  [false, true], self.ctd.renderDzdtStyledZ))

        graphs.append(GraphDescriptor("Compass",       [false, false], self.vnav.renderCompass))
        graphs.append(GraphDescriptor("Acceleration",  [false, false], self.vnav.renderAcceleration))
        graphs.append(GraphDescriptor("Gyro",          [false, false], self.vnav.renderGyro))
        graphs.append(GraphDescriptor("Yaw/Pitch/Roll", [false, false], self.vnav.renderYawPitchRoll))

        graphs.append(GraphDescriptor("bb",            [false, false], self.fluor.render_bb))
        graphs.append(GraphDescriptor("chla",          [false, false], self.fluor.render_chla))
        graphs.append(GraphDescriptor("fDOM",          [false, false], self.fluor.render_fDOM))

        graphs.append(GraphDescriptor("tof",           [false, false], self.ttv.render_tof))
        graphs.append(GraphDescriptor("dtof",          [false, false], self.ttv.render_dtof))
        graphs.append(GraphDescriptor("vfr [\u{00B5}s]", [false, false], self.ttv.render_vfr))
    }
    func clearLastOpen() {
        lastOpenFile = nil
        lastOpenFolder = nil
        lastOpenSocket = nil
    }
    func openFile(_ fileUrl: URL) {
        clearLastOpen()
        lastOpenFile = fileUrl
        modelProducer = SingleFileModelProducer(fileUrl: fileUrl)
    }
    func openFolder(_ folderUrl: URL) {
        clearLastOpen()
        lastOpenFolder = folderUrl
        modelProducer = StreamingFolderModelProducer(folderUrl: folderUrl)
    }
    func openSocket(_ socketUrl: URL) {
        clearLastOpen()
        lastOpenSocket = socketUrl
        modelProducer = StreamingSocketWithURLModelProducer(socketUrl: socketUrl)
    }
    func openSocketWithBonjour() {
        clearLastOpen()
        modelProducer = StreamingSocketWithBonjourModelProducer()
    }
    func update() -> Bool {
        var updateView = false
        if let modelProducer = modelProducer {
            if modelProducer.update(model: model) {
                time_window = modelProducer.getTimeWindow(model: model)

                epsi.fromMergedBlocks(time_window: time_window, blocks: &model.d.epsi_blocks)
                ctd.fromMergedBlocks(time_window: time_window, blocks: &model.d.ctd_blocks)
                fluor.fromMergedBlocks(time_window: time_window, blocks: &model.d.fluor_blocks)
                vnav.fromMergedBlocks(time_window: time_window, blocks: &model.d.vnav_blocks)
                ttv.fromMergedBlocks(time_window: time_window, blocks: &model.d.ttv_blocks)

                broadcaster.broadcast(vm: self)
                updateView = true
            }
        }
        if model.d.fishflag != currentGraphPreset {
            currentGraphPreset = model.d.fishflag
            for i in 0..<graphs.count {
                graphs[i].resetVisibleFromUserDefaultFor(preset: currentGraphPreset)
            }
            updateView = true
        }
        return updateView
    }
}
