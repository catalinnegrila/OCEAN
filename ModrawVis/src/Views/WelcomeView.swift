import SwiftUI

struct WelcomeButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ?
                        Color(red: 0.20, green: 0.20, blue: 0.20) :
                        Color(red: 0.16, green: 0.16, blue: 0.16))
            .cornerRadius(12.0)
    }
}

struct WelcomeButton: View {
    let image: String
    let label: String
    let info: String
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack {
                Image(systemName: self.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24)
                    .foregroundColor(WelcomeView.iconGrayColor)
                VStack {
                    HStack {
                        Text(self.label).font(.system(.title3/*, design: .rounded*/).bold())
                        Spacer()
                    }
                    HStack {
                        Text(info).font(.system(.caption/*, design: .rounded*/))
                        Spacer()
                    }
                }.foregroundColor(WelcomeView.textGrayColor)
            }.padding(8)
        }
        .focusEffectDisabled()
        .buttonStyle(WelcomeButtonStyle())
    }
}

struct AppVersionView: View {
    func appVersion() -> String {
        let version = NSWindowUtils.getBundleKey(key: "CFBundleShortVersionString")
        let build = NSWindowUtils.getBundleKey(key: "CFBundleVersion")
        return "\(version) (build \(build))"
    }
    var body: some View {
        VStack {
            if let image = NSImage(named: "AppIcon") {
                Image(nsImage: image)
                    .shadow(color: .gray, radius: 36)
            }
            VStack {
                Text(NSWindowUtils.getBundleKey(key: "CFBundleDisplayName"))
                    .font(.system(.title, design: .rounded).bold())
                    .foregroundColor(WelcomeView.textGrayColor)
                Text("Version \(appVersion())")
                    .font(.body)
                    .foregroundColor(WelcomeView.iconGrayColor)
            }
        }
    }
}

struct WelcomeWindowToggle: View {
    @StateObject var vm: ViewModel
    var body: some View {
        Button(NSWindowUtils.WelcomeWindowTitle) {
            NSWindowUtils.createWelcomeWindow(vm: vm)
        }.keyboardShortcut("1", modifiers: [.command, .shift])
    }
}

struct WelcomeView: View {
    @Environment(\.openWindow) var openWindow
    static let iconGrayColor = Color(red: 0.6, green: 0.6, blue: 0.6)
    static let textGrayColor = Color(red: 0.87, green: 0.87, blue: 0.87)
    @State var presentOpenSocketSheet = false
    func nextWindow() {
        NSWindowUtils.hideWindow(NSWindowUtils.WelcomeWindowId)
        openWindow(id: NSWindowUtils.MainWindowId)
        //NSWindowUtils.showWindow(NSWindowUtils.MainWindowId)
    }
    @StateObject var vm: ViewModel
    var body: some View {
        HStack(spacing: 0) {
            Image("FCTD")
                .resizable()
                .aspectRatio(contentMode: .fit)
            VStack {
                Spacer()
                AppVersionView()
                Spacer()
                
                VStack(spacing: 8) {
                    WelcomeButton(
                        image: "text.document",
                        label: "Open file...",
                        info: "Select a .modraw or Matlab .mat file containing FCTD/EPSI data.",
                        action: {
                            if FileMenuCommands.modalOpenPanel(chooseFiles: true, vm: vm) {
                                nextWindow()
                            }
                        })
                    WelcomeButton(
                        image: "folder",
                        label: "Open folder...",
                        info: "Start streaming .modraw data from a folder.",
                        action: {
                            if FileMenuCommands.modalOpenPanel(chooseFiles: false, vm: vm) {
                                nextWindow()
                            }
                        })
                    WelcomeButton(
                        image: "network.badge.shield.half.filled",
                        label: "Connect to ModrawServer...",
                        info: "Discover ModrawServer on the local network using Bonjour.",
                        action: {
                            presentOpenSocketSheet = true
                            //vm.openSocketWithBonjour()
                            //nextWindow()
                        })
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(red: 0.13, green: 0.13, blue: 0.13))
            .sheet(isPresented: $presentOpenSocketSheet) {
                OpenSocketView() //(vm: vm)
            }
        }
    }
}
