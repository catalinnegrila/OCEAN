import SwiftUI
import UniformTypeIdentifiers

struct FileMenuCommands: Commands {
    var vm: ViewModel

    func modalFilePicker(chooseFiles: Bool) -> URL? {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 500, height: 600))
        let picker = NSOpenPanel(contentRect: rect, styleMask: .utilityWindow, backing: .buffered, defer: true)
        
        picker.canChooseDirectories = !chooseFiles
        picker.canChooseFiles = chooseFiles
        picker.allowsMultipleSelection = false
        picker.canDownloadUbiquitousContents = true
        picker.canResolveUbiquitousConflicts = true

        if (chooseFiles) {
            picker.allowedFileTypes = ["mat", "modraw"] // Deprecated
            /*picker.allowedContentTypes = [UTType]()
            for ext in ["mat", "modraw"] {
                let utt = UTType(tag: ext, tagClass: .filenameExtension, conformingTo: nil)
                assert(utt != nil)
                picker.allowedContentTypes.append(utt!)
            }*/
        }

        if (picker.runModal() == .OK) {
            return picker.urls[0]
        } else {
            return nil
        }
    }

    @MainActor
    var body: some Commands {
        CommandGroup(replacing: CommandGroupPlacement.newItem)
        {
            Section {
                Button("Open Folder...") {
                    if let folderUrl = modalFilePicker(chooseFiles: false) {
                        vm.openFolder(folderUrl)
                    }
                }.keyboardShortcut("o")
                Button("Open File...") {
                    if let fileUrl = modalFilePicker(chooseFiles: true) {
                        vm.openFile(fileUrl)
                    }
                }.keyboardShortcut("f")
            }
            Section {
                Button("Connect to DEV1") {
                    vm.openSocket(URL(string: "tcp://192.168.1.168:31415")!)
                }.keyboardShortcut("d")
            }
            #if DEBUG
            Section {
                Button("Connect with Bonjour") {
                    vm.openSocketWithBonjour()
                }.keyboardShortcut("b")
                Button("Connect to localhost") {
                    vm.openSocket(URL(string: "tcp://localhost:31415")!)
                }.keyboardShortcut("l")
                Button("Connect to Local IP") {
                    vm.openSocket(URL(string: "tcp://\(getWiFiAddress()!):31415")!)
                }.keyboardShortcut("i")
            }
            #endif
        }
    }
}

