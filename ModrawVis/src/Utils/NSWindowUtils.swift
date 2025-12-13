import SwiftUI
import UniformTypeIdentifiers

final class ModalWindow: NSWindow {
    fileprivate static var stack = [ModalWindow]()
    static var current: ModalWindow {
        get { return stack.last! }
    }

    override func becomeKey() {
        super.becomeKey()
        level = .statusBar
    }
    
    override func close() {
        assert(!ModalWindow.stack.isEmpty)
        assert(ModalWindow.stack.last! === self)
        ModalWindow.stack.removeLast()
        super.close()
        NSApp.stopModal()
    }

    func endModal(withCode: NSApplication.ModalResponse) {
        close()
        NSApp.stopModal(withCode: withCode)
    }
}

class InfoWindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSWindowUtils.InfoWindowVisible = false
    }
}

class NSWindowUtils {
    static let WelcomeWindowId = "welcome"
    static let MainWindowId = "main"
    static let InfoWindowId = "info"
    static let WelcomeWindowTitle = "Welcome to \(getBundleKey(key: "CFBundleDisplayName"))"
    static var InfoWindow: NSPanel?
    static private var InfoWindowDelegatePtr = InfoWindowDelegate()
    static let InfoWindowVisibleKey = "InfoWindowVisibleOnStartup"
    static var InfoWindowVisible = true
    static func findWindow(_ id: String) -> NSWindow? {
        for window in NSApp.windows {
            if let windowId = window.identifier?.rawValue, windowId.starts(with: id) {
                return window
            }
        }
        print("WARNING: Could not find window with id: \(id)")
        return nil
    }
    static func showWindow(_ id: String) {
        if let window = findWindow(id) {
            window.makeKeyAndOrderFront(nil)
        }
    }
    static func hideWindow(_ id: String) {
        if let window = findWindow(id) {
            window.orderOut(nil)
        }
    }
    static func closeWindow(_ id: String) {
        if let window = findWindow(id) {
            window.close()
        }
    }
    static func createWelcomeWindow(vm: ViewModel) {
        // Is the window already open?
        if let window = findWindow(WelcomeWindowId) {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let contentView = WelcomeView(vm: vm)
            .edgesIgnoringSafeArea(.top)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 768, height: 512),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.identifier = NSUserInterfaceItemIdentifier(NSWindowUtils.WelcomeWindowId)
        window.title = WelcomeWindowTitle
        window.center()
        //window.level = .floating
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false

        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }
    static func createInfoWindow(vm: ViewModel)
    {
        let panel = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: 400, height: 300),
            styleMask: [.titled, .closable, .utilityWindow, .resizable],
            backing: .buffered, defer: false)
        panel.identifier = NSUserInterfaceItemIdentifier(NSWindowUtils.InfoWindowId)
        panel.title = "Info"
        panel.isFloatingPanel = true // Utility windows are typically floating
        panel.level = .floating // Ensures it stays above normal windows
        panel.isMovableByWindowBackground = true
        panel.delegate = InfoWindowDelegatePtr

        panel.contentView = NSHostingView(rootView: InfoView(vm: vm))
        if InfoWindowVisible {
            panel.makeKeyAndOrderFront(nil)
        } else {
            panel.orderOut(nil)
        }
        InfoWindow = panel // keep it alive while hidden
    }
    static func restoreInfoWindowState() {
        let value = UserDefaults.standard.object(forKey: InfoWindowVisibleKey)
        InfoWindowVisible = value as? Bool ?? true
    }
    static func toggleInfoWindow()
    {
        if let InfoWindow {
            if InfoWindowVisible {
                InfoWindow.orderOut(nil)
            } else {
                InfoWindow.makeKeyAndOrderFront(nil)
            }
            InfoWindowVisible.toggle()
            UserDefaults.standard.set(InfoWindowVisible, forKey: InfoWindowVisibleKey)
        }
    }
    static func runModal(contentView: some View, title: String) -> NSApplication.ModalResponse {
        let window = ModalWindow(
            contentRect: .zero,
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        ModalWindow.stack.append(window)
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.title = title
        window.center()
        let hosting = NSHostingView(rootView: contentView)
        window.contentView = hosting
        //hosting.autoresizingMask = [.width, .height]
        return NSApp.runModal(for: window)
    }
    static func modalOpenPanel(chooseFiles: Bool) -> URL? {
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
        
        if picker.runModal() == .OK {
            return picker.url
        } else {
            return nil
        }
    }
    static func getBundleKey(in bundle: Bundle = .main, key: String) -> String {
        guard let value = bundle.object(forInfoDictionaryKey: key) as? String else {
            print("\(key) not found in the info dictionary")
            return "n/a"
        }
        return value
    }
}
