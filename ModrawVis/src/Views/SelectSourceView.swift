import SwiftUI

struct SelectSourceButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ?
                        Color(red: 0.20, green: 0.20, blue: 0.20) :
                        Color(red: 0.16, green: 0.16, blue: 0.16))
            .cornerRadius(12.0)
    }
}

struct SelectSourceButton: View {
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
                    .foregroundColor(SelectSourceView.iconGrayColor)
                VStack {
                    HStack {
                        Text(self.label).font(.system(.title3/*, design: .rounded*/).bold())
                        Spacer()
                    }
                    HStack {
                        Text(info).font(.system(.caption/*, design: .rounded*/))
                        Spacer()
                    }
                }.foregroundColor(SelectSourceView.textGrayColor)
            }.padding(8)
        }
        .focusEffectDisabled()
        .buttonStyle(SelectSourceButtonStyle())
    }
}

struct AppVersionView: View {
    func getBundleKey(in bundle: Bundle = .main, key: String) -> String {
        guard let value = bundle.object(forInfoDictionaryKey: key) as? String else {
            print("\(key) not found in the info dictionary")
            return "n/a"
        }
        return value
    }
    func appVersion() -> String {
        let version = getBundleKey(key: "CFBundleShortVersionString")
        let build = getBundleKey(key: "CFBundleVersion")
        return "\(version) (build \(build))"
    }
    var body: some View {
        VStack {
            if let image = NSImage(named: "AppIcon") {
                Image(nsImage: image)
                    //.shadow(color: .gray, radius: 36)
                    .shadow(color: .gray, radius: 36)
            }
            VStack {
                Text(getBundleKey(key: "CFBundleDisplayName"))
                    .font(.system(.title, design: .rounded).bold())
                    .foregroundColor(SelectSourceView.textGrayColor)
                Text("Version \(appVersion())")
                    .font(.body)
                    .foregroundColor(SelectSourceView.iconGrayColor)
            }
        }
    }
}

struct SelectSourceView: View {
    static let iconGrayColor = Color(red: 0.6, green: 0.6, blue: 0.6)
    static let textGrayColor = Color(red: 0.87, green: 0.87, blue: 0.87)

    func nextWindow() {
        //NSWindowUtils.closeWindow(NSWindowUtils.SplashWindowId)
        NSWindowUtils.showWindow(NSWindowUtils.MainWindowId)
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
                    SelectSourceButton(
                        image: "text.document",
                        label: "Open file...",
                        info: "Select a .modraw or Matlab .mat file containing FCTD/EPSI data.",
                        action: {
                            if FileMenuCommands.modalOpenPanel(chooseFiles: true, vm: vm) {
                                nextWindow()
                            }
                        })
                    SelectSourceButton(
                        image: "folder",
                        label: "Open folder...",
                        info: "Start streaming .modraw data from a folder.",
                        action: {
                            if FileMenuCommands.modalOpenPanel(chooseFiles: false, vm: vm) {
                                nextWindow()
                            }
                        })
                    SelectSourceButton(
                        image: "network",
                        label: "Open socket...",
                        info: "Connect to the ModrawService on a local or remote socket.",
                        action: { print("socket") })
                    SelectSourceButton(
                        image: "network.badge.shield.half.filled",
                        label: "Search for ModrawService...",
                        info: "Discover ModrawService on the local network using Bonjour.",
                        action: { print("bonjour") })
                }
//                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(red: 0.13, green: 0.13, blue: 0.13))
        }
    }
}
