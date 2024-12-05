import SwiftUI
import UniformTypeIdentifiers

struct FileMenuCommands: Commands {
    var vm: ViewModel

    static func modalOpenPanel(chooseFiles: Bool, vm: ViewModel) -> Bool {
        let picker = NSOpenPanel(contentRect: CGRect.zero, styleMask: .utilityWindow, backing: .buffered, defer: true)
        
        picker.canChooseDirectories = !chooseFiles
        picker.canChooseFiles = chooseFiles
        picker.allowsMultipleSelection = false
        picker.canDownloadUbiquitousContents = true
        picker.canResolveUbiquitousConflicts = true

        if (chooseFiles) {
            picker.allowedContentTypes = [
                UTType(filenameExtension: "modraw")!,
                UTType(filenameExtension: "mat")!
            ]
        }

        guard picker.runModal() == .OK else { return false }

        if chooseFiles {
            vm.openFile(picker.urls[0])
        } else {
            vm.openFolder(picker.urls[0])
        }
        return true
    }
    @MainActor
    var body: some Commands {
        CommandGroup(replacing: .newItem)
        {
            Section {
                Button("Open Folder...") {
                    let _ = FileMenuCommands.modalOpenPanel(chooseFiles: false, vm: vm)
                }.keyboardShortcut("o")
                Button("Open File...") {
                    let _ = FileMenuCommands.modalOpenPanel(chooseFiles: true, vm: vm)
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
                }
                Button("Connect to localhost") {
                    vm.openSocket(URL(string: "tcp://localhost:31415")!)
                }
                Button("Connect to Local IP") {
                    vm.openSocket(URL(string: "tcp://\(getWiFiAddress()!):31415")!)
                }
            }
            #endif
        }
    }
}

