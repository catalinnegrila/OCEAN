import SwiftUI
import AppKit
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct RealtimePlotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("lastOpenFile") var lastOpenFile : URL?
    @AppStorage("lastOpenFolder") var lastOpenFolder : URL?
    @State private var model = Model()

    init() {
        if lastOpenFolder != nil {
            modelFromFolder(lastOpenFolder!)
        } else if lastOpenFile != nil {
            modelFromFile(lastOpenFile!)
        }
    }
    func modelFromFile(_ fileUrl: URL) {
        lastOpenFile = fileUrl
        lastOpenFolder = nil
        model.currentFileUrl = fileUrl
        model.currentFolderUrl = nil
        switch fileUrl.pathExtension {
        case "mat":
            let parser = EpsiMatParser()
            parser.readFile(model: model)
        case "modraw":
            let parser = EpsiModrawParser()
            parser.readFile(model: model)
        default:
            print("Unknown file extension for \(fileUrl.path)")
        }
    }
    func modelFromFolder(_ folderUrl: URL) {
        lastOpenFile = nil
        lastOpenFolder = folderUrl
        model.currentFileUrl = nil
        model.currentFolderUrl = folderUrl
    }
    func modalFilePicker(chooseFiles: Bool) -> URL? {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 500, height: 600))
        let picker = NSOpenPanel(contentRect: rect, styleMask: .utilityWindow, backing: .buffered, defer: true)
        
        picker.canChooseDirectories = !chooseFiles
        picker.canChooseFiles = chooseFiles
        picker.allowsMultipleSelection = false
        picker.canDownloadUbiquitousContents = true
        picker.canResolveUbiquitousConflicts = true

        if (chooseFiles) {
            picker.allowedFileTypes = ["mat", "modraw"]
            /*
            picker.allowedContentTypes = [UTType]()
            for ext in ["mat", "modraw"] {
                picker.allowedContentTypes.append(UTType(tag: ext, tagClass: .filenameExtension, conformingTo: nil)!)
            }*/
        }

        if (picker.runModal() == .OK) {
            return picker.urls[0]
        } else {
            return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            RealtimePlotView(model: model)
                .onAppear {
                    let _ = NSApplication.shared.windows.map { $0.tabbingMode = .disallowed }
                }
        }.commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem)
            {
                Button("Open Folder...") {
                    if let folderUrl = modalFilePicker(chooseFiles: false) {
                        modelFromFolder(folderUrl)
                    }
                }.keyboardShortcut("o")
                Button("Open File...") {
                    if let fileUrl = modalFilePicker(chooseFiles: true) {
                        modelFromFile(fileUrl)
                    }
                }.keyboardShortcut("f")
            }
/*
            CommandGroup(before: CommandGroupPlacement.toolbar) {
                Section {
                    Picker("CTD.fishflag", selection: $realtimePlotView.viewMode) {
                        Text("EPSI Mode").tag(EpsiDataModel.Mode.EPSI)
                        Text("FCTD Mode").tag(EpsiDataModel.Mode.FCTD)
                    }
                    .pickerStyle(InlinePickerStyle())
                    .onChange(of: realtimePlotView.viewMode) { value in
                        if (epsiDataModel != nil) {
                            realtimePlotView.viewMode = value
                            epsiDataModel!.mode = value
                            epsiDataModel!.updateWindowTitle()
                            epsiDataModel!.sourceDataChanged = true
                            print("changed to \(value)")
                        }
                    }
                }
            }
 */
        }
    }
}
