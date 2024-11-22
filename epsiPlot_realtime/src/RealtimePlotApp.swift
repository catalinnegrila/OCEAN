import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
#endif

@main
struct RealtimePlotApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
    @AppStorage("lastOpenFile") var lastOpenFile : URL?
    @AppStorage("lastOpenFolder") var lastOpenFolder : URL?
    @AppStorage("lastOpenSocket") var lastOpenSocket : URL?
    @State private var vm = ViewModel()

    init() {
#if os(macOS)
        if lastOpenFile != nil {
            openFile(lastOpenFile!)
        } else if lastOpenFolder != nil {
            openFolder(lastOpenFolder!)
        } else if lastOpenSocket != nil {
            openSocket(URL(string:"tcp://127.0.0.1:31415")!)
            //openSocket(lastOpenSocket!)
        }
#endif
#if os(iOS)
        //openSocket(lastOpenSocket!)
#endif
    }
    func clearLastOpen() {
        lastOpenFile = nil
        lastOpenFolder = nil
        lastOpenSocket = nil
    }
    func openFile(_ fileUrl: URL) {
        clearLastOpen()
        lastOpenFile = fileUrl
        vm.model = SingleFileModel(fileUrl: fileUrl)
    }
    func openFolder(_ folderUrl: URL) {
        clearLastOpen()
        lastOpenFolder = folderUrl
        vm.model = StreamingFolderModel(folderUrl: folderUrl)
    }
    func openSocket(_ socketUrl: URL) {
        clearLastOpen()
        lastOpenSocket = socketUrl
        vm.model = StreamingSocketModel(socketUrl: socketUrl)
    }
#if os(macOS)
    func modalFilePicker(chooseFiles: Bool) -> URL? {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 500, height: 600))
        let picker = NSOpenPanel(contentRect: rect, styleMask: .utilityWindow, backing: .buffered, defer: true)
        
        picker.canChooseDirectories = !chooseFiles
        picker.canChooseFiles = chooseFiles
        picker.allowsMultipleSelection = false
        picker.canDownloadUbiquitousContents = true
        picker.canResolveUbiquitousConflicts = true

        if (chooseFiles) {
            //picker.allowedFileTypes = ["mat", "modraw"] // Deprecated
            picker.allowedContentTypes = [UTType]()
            for ext in ["mat", "modraw"] {
                picker.allowedContentTypes.append(UTType(tag: ext, tagClass: .filenameExtension, conformingTo: nil)!)
            }
        }

        if (picker.runModal() == .OK) {
            return picker.urls[0]
        } else {
            return nil
        }
    }
#endif
    var body: some Scene {
        WindowGroup {
            RealtimePlotView(vm: vm)
#if os(macOS)
                .onAppear {
                    let _ = NSApplication.shared.windows.map { $0.tabbingMode = .disallowed }
                }
#endif
        }.commands {
#if os(macOS)
            CommandGroup(replacing: CommandGroupPlacement.newItem)
            {
                Section {
                    Button("Open Folder...") {
                        if let folderUrl = modalFilePicker(chooseFiles: false) {
                            openFolder(folderUrl)
                        }
                    }.keyboardShortcut("o")
                    Button("Open File...") {
                        if let fileUrl = modalFilePicker(chooseFiles: true) {
                            openFile(fileUrl)
                        }
                    }.keyboardShortcut("f")
                }
                Section {
                    Button("Connect to DEV1") {
                        openSocket(URL(string: "tcp://192.168.1.168:31415")!)
                    }.keyboardShortcut("d")
                    Button("Connect to localhost") {
                        openSocket(URL(string: "tcp://localhost:31415")!)
                    }.keyboardShortcut("l")
                }
            }
#endif
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
