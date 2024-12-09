import SwiftUI

struct TestButton: View {
    @State var presentOpenSocketSheet = false
    var body: some View {
        Button("test") {
            presentOpenSocketSheet = true
        }.sheet(isPresented: $presentOpenSocketSheet, content: {
            OpenSocketView()
        })
    }
}

struct FileMenuCommands: Commands {
    var vm: ViewModel

    static func modalOpenPanel(chooseFiles: Bool, vm: ViewModel) -> Bool {
        guard let url = NSWindowUtils.modalOpenPanel(chooseFiles: chooseFiles) else { return false }
        if chooseFiles {
            vm.openFile(url)
        } else {
            vm.openFolder(url)
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
                    vm.openSocket(URL(string: "192.168.1.168:31415")!)
                }.keyboardShortcut("d")
            }
            #if DEBUG
            Section {
                Button("Connect with Bonjour") {
                    vm.openSocketWithBonjour()
                }
                Button("Connect to localhost") {
                    vm.openSocket(URL(string: "localhost:31415")!)
                }
                Button("Connect to Local IP") {
                    vm.openSocket(URL(string: "\(getWiFiAddress()!):31415")!)
                }
            }
            #endif
            TestButton()
        }
    }
}

