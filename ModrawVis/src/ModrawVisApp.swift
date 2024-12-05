import SwiftUI

class NSWindowUtils {
    static let SplashWindowId = "splash"
    static let MainWindowId = "main"
    static let InfoWindowId = "info"

    static func findWindow(_ id: String) -> NSWindow? {
        for window in NSApp.windows {
            if window.identifier?.rawValue == id {
                return window
            }
        }
        return nil
    }
    static func showWindow(_ id: String) {
        if let window = NSWindowUtils.findWindow(id) {
            window.makeKeyAndOrderFront(nil)
        }
    }
    static func hideWindow(_ id: String) {
        if let window = NSWindowUtils.findWindow(id) {
            window.orderOut(nil)
        }
    }
    static func closeWindow(_ id: String) {
        if let window = NSWindowUtils.findWindow(id) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    var vm: ViewModel?
    func createSourceSelectionWindow() {
        NSWindowUtils.hideWindow(NSWindowUtils.MainWindowId)

        // Create the SwiftUI view that provides the window contents.
        let contentView = SelectSourceView(vm: self.vm!)
            .edgesIgnoringSafeArea(.top) // to extend entire content under titlebar

        // Create the window and set the content view.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 768, height: 512),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.identifier = NSUserInterfaceItemIdentifier(NSWindowUtils.SplashWindowId)
        window.center()

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false

        window.contentView = NSHostingView(rootView: contentView)
        //DispatchQueue.main.async {
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

@main
struct ModrawVisApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var vm = ViewModel()

    init() {
        appDelegate.vm = vm
    }
    var body: some Scene {
        Window("Visualizer", id: NSWindowUtils.MainWindowId) {
            ModrawView(vm: vm)
        }.commands {
            FileMenuCommands(vm: vm)
            CommandGroup(before: .windowArrangement) {
                InfoWindowToggle(vm: vm)
            }
        }.windowToolbarStyle(.unifiedCompact)

        UtilityWindow("Info", id: NSWindowUtils.InfoWindowId) {
            InfoView(vm: vm)
        }.commandsRemoved()
            .windowResizability(.contentSize)
    }
}
