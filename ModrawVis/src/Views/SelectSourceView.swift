import SwiftUI

struct PurpleButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(label, action: action)
            .font(.system(.title3, design: .rounded))
            .padding(EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .background(.purple)
            .clipShape(Capsule())
    }
}

struct SelectSourceView: View {
    //@StateObject var vm: ViewModel
    var body: some View {
        HStack() {
            Image("FCTD")
                .resizable()
                .aspectRatio(contentMode: .fit)
            VStack {
                PurpleButton(label: "Open file...", action: {})
                Text("Open folder...")
                Text("Open socket...")
                Text("Search for ModrawService...")
            }.frame(maxWidth: .infinity).border(.blue)
        }.border(.red)
    }
}
