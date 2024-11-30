import SwiftUI

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
    var vm = ViewModel()

    var body: some Scene {
        WindowGroup {
            RealtimePlotView(vm: vm)
#if os(macOS)
                .onAppear {
                    let _ = NSApplication.shared.windows.map { $0.tabbingMode = .disallowed }
                }
#endif
        }.commands {
            FileMenuCommands(vm: vm)
            CommandGroup(before: .windowArrangement) {
                WindowVisibilityToggle(windowID: "info")
                    .keyboardShortcut("i", modifiers: [.command])
            }
        } .windowToolbarStyle(.unifiedCompact)
        UtilityWindow("Info", id: "info") {
            InfoView(vm: vm)
        }.commandsRemoved().windowResizability(.contentSize) 
    }
}
