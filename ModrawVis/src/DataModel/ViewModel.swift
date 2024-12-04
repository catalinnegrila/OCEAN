import Foundation
import SwiftUI

struct ChannelGraph: Observable {
    let id: String
    var label: String
    var visible: Bool
    let renderer: (GraphRenderer) -> Void

    init(id: String, label: String, defaults: [(String, Bool)], renderer: @escaping (GraphRenderer)->Void) {
        self.id = id
        self.label = label
        self.renderer = renderer
        self.visible = false
        for defaultValue in defaults {
            let id = ChannelGraph.userDefaultsId(fishflag: defaultValue.0, id: self.id)
            if (UserDefaults.standard.object(forKey: id) as? Bool) == nil {
                UserDefaults.standard.set(defaultValue.1, forKey: id)
            }
        }
    }
    static func userDefaultsId(fishflag: String, id: String) -> String {
        return "\(fishflag).\(id)"
    }
    mutating func resetVisible(fishflag: String) {
        let id = ChannelGraph.userDefaultsId(fishflag: fishflag, id: self.id)
        visible = UserDefaults.standard.object(forKey: id) as? Bool ?? true
    }
    mutating func setVisible(fishflag: String, visible: Bool) {
        let id = ChannelGraph.userDefaultsId(fishflag: fishflag, id: self.id)
        UserDefaults.standard.set(visible, forKey: id)
        self.visible = visible
    }
}

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
    var ttv = VnavViewModelData()
    @Published var broadcaster = ViewModelBroadcaster()
    fileprivate var graphsFishflag = "n/a"
    @Published var graphs = [ChannelGraph]()

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
        if let lastOpenFile {
            openFile(lastOpenFile)
        } else if let lastOpenFolder {
            openFolder(lastOpenFolder)
        } else if let lastOpenSocket {
            openSocket(lastOpenSocket)
        } else {
            openSocketWithBonjour()
        }

        graphs.append(ChannelGraph(id: "epsi_t_volt", label: "FP07 [Volt]",
                                   defaults: [("'EPSI'", true), ("'FCTD'", false)],
                                   renderer: { (gr: GraphRenderer) -> Void in self.epsi.renderEpsi_t(gr: gr) }))
        graphs.append(ChannelGraph(id: "epsi_s_volt", label: "Shear [Volt]",
                                   defaults: [("'EPSI'", true), ("'FCTD'", false)],
                                   renderer: { (gr: GraphRenderer) -> Void in self.epsi.renderEpsi_s(gr: gr) }))
        graphs.append(ChannelGraph(id: "epsi_s1_volt", label: "s1 [Volt]",
                                   defaults: [("'EPSI'", false), ("'FCTD'", true)],
                                   renderer: { (gr: GraphRenderer) -> Void in self.epsi.renderEpsi_s1(gr: gr) }))
        graphs.append(ChannelGraph(id: "epsi_s2_volt", label: "s2 [Volt]",
                                   defaults: [("'EPSI'", false), ("'FCTD'", true)],
                                   renderer: { (gr: GraphRenderer) -> Void in self.epsi.renderEpsi_s2(gr: gr) }))
        graphs.append(ChannelGraph(id: "epsi_a_volt", label: "Accel [g]",
                                   defaults: [("'EPSI'", true), ("'FCTD'", true)],
                                   renderer: { (gr: GraphRenderer) -> Void in self.epsi.renderEpsi_a(gr: gr) }))
        graphs.append(ChannelGraph(id: "ctd_T", label: "T [\u{00B0}C]",
                                   defaults: [("'EPSI'", true), ("'FCTD'", true)],
                                   renderer: { (gr: GraphRenderer) -> Void in self.ctd.renderCtd_T(gr: gr) }))
        graphs.append(ChannelGraph(id: "ctd_S", label: "S",
                                   defaults: [("'EPSI'", true), ("'FCTD'", true)],
                                   renderer: { (gr: GraphRenderer) -> Void in self.ctd.renderCtd_S(gr: gr) }))
        graphs.append(ChannelGraph(id: "ctd_dzdt", label: "dzdt [m/s]",
                                   defaults: [("'EPSI'", true), ("'FCTD'", false)],
                                   renderer: { (gr: GraphRenderer) -> Void in self.ctd.renderCtd_dzdt(gr: gr) }))
        graphs.append(ChannelGraph(id: "ctd_z", label: "z [m]",
                                   defaults: [("'EPSI'", true), ("'FCTD'", false)],
                                   renderer: { (gr: GraphRenderer) -> Void in self.ctd.renderCtd_z(gr: gr) }))
        graphs.append(ChannelGraph(id: "ctd_dzdt_z", label: "z [m] + dzdt",
                                   defaults: [("'EPSI'", false), ("'FCTD'", true)],
                                   renderer: { (gr: GraphRenderer) -> Void in self.ctd.renderCtd_z_dzdt(gr: gr) }))
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
        if let modelProducer = modelProducer {
            if modelProducer.update(model: model) {
                time_window = modelProducer.getTimeWindow(model: model)

                epsi.mergeBlocks(time_window: time_window, blocks: &model.d.epsi_blocks)
                ctd.mergeBlocks(time_window: time_window, blocks: &model.d.ctd_blocks)
                fluor.mergeBlocks(time_window: time_window, blocks: &model.d.fluor_blocks)
                vnav.mergeBlocks(time_window: time_window, blocks: &model.d.vnav_blocks)
                ttv.mergeBlocks(time_window: time_window, blocks: &model.d.vnav_blocks)

                broadcaster.broadcast(vm: self)

                if model.d.fishflag != graphsFishflag {
                    for i in 0..<graphs.count {
                        graphs[i].resetVisible(fishflag: model.d.fishflag)
                    }
                    graphsFishflag = model.d.fishflag
                }
                return true
            }
        }
        return false
    }
}
