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
    @Published var broadcaster = ViewModelBroadcaster()

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
                broadcaster.broadcast(vm: self)
                return true
            }
        }
        return false
    }
}
