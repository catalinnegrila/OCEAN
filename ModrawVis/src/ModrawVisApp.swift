import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    var vm: ViewModel?
    func applicationDidFinishLaunching(_ notification: Notification) {
        assert(vm != nil)
        if let vm {
            DispatchQueue.main.async {
                //@Environment(\.openWindow) var openWindow
                //openWindow(id: NSWindowUtils.MainWindowId)

                //let socketView = OpenSocketView()
                //let _ = NSWindowUtils.runModal(contentView: socketView, title: "Open Socket")

                if vm.modelProducer == nil {
                    NSWindowUtils.createWelcomeWindow(vm: vm)
                }
            }
        }
    }
}

@main
struct ModrawVisApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var vm = ViewModel()

    init() {
        appDelegate.vm = vm
    }
    var body: some Scene {
        // HACK to inhibit main window displaying before the Welcome window
        MenuBarExtra {} label: {}
        
        Window("Visualizer", id: NSWindowUtils.MainWindowId) {
            ModrawView(vm: vm)
        }.commands {
            FileMenuCommands(vm: vm)
            CommandGroup(before: .windowArrangement) {
                WelcomeWindowToggle(vm: vm)
                InfoWindowToggle(vm: vm)
            }
        }
        .windowToolbarStyle(.unifiedCompact)

        UtilityWindow("Info", id: NSWindowUtils.InfoWindowId) {
            InfoView(vm: vm)
        }
        .commandsRemoved()
        .windowResizability(.contentSize)
    }
}
