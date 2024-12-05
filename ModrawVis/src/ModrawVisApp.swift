import SwiftUI
/*
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    var vm: ViewModel?
    func createSourceSelectionWindow() {
        for window in NSApp.windows {
            print("\(window.identifier?.rawValue ?? "none"): \(window.title)")
            window.orderOut(nil)
            //window.close()
        }

        // Create the SwiftUI view that provides the window contents.
        let contentView = SelectSourceView()
            .edgesIgnoringSafeArea(.top) // to extend entire content under titlebar

        // Create the window and set the content view.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 768, height: 512),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered, defer: false)
        //guard let window else { return }
        window.center()
        //window.setFrameAutosaveName("SelectSourceWindow")

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false

        window.contentView = NSHostingView(rootView: contentView)
        //DispatchQueue.main.async {
            //window.orderOut(nil)
            window.makeKeyAndOrderFront(nil)
        //}
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        /*for window in NSApp.windows {
            let title = window.title
            print(title)
            window.orderOut(nil)
            //window.close()
        }*/
        if let vm {
            if vm.modelProducer == nil {
                createSourceSelectionWindow()
            }
        }
    }
}
*/
@main
struct ModrawVisApp: App {
    //@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var vm = ViewModel()

    init() {
        //appDelegate.vm = vm
    }
    var body: some Scene {
        Window("Visualizer", id: "main" ) {
            ModrawView(vm: vm)
        }.commands {
            FileMenuCommands(vm: vm)
            CommandGroup(before: .windowArrangement) {
                InfoWindowToggle(vm: vm)
            }
        }.windowToolbarStyle(.unifiedCompact)

        UtilityWindow("Info", id: "info") {
            InfoView(vm: vm)
        }.commandsRemoved()
            .windowResizability(.contentSize)
    }
}
