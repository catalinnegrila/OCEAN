//
//  epsiPlot_realtimeApp.swift
//  epsiPlot_realtime
//
//  Created by Catalin Negrila on 11/7/24.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct RealtimePlotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("lastOpenFile") var lastOpenFile : URL?
    @AppStorage("lastOpenFolder") var lastOpenFolder : URL?
    //@StateObject var menuState = MenuState()

    init() {
        if lastOpenFolder != nil {
            epsiDataModel = EpsiDataModel.createInstanceFromFolder(lastOpenFolder!)
        } else if lastOpenFile != nil {
            epsiDataModel = EpsiDataModel.createInstanceFromFile(lastOpenFile!)
        }
    }
    func modalFilePicker(chooseFiles: Bool) -> URL? {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 500, height: 600))
        let picker = NSOpenPanel(contentRect: rect, styleMask: .utilityWindow, backing: .buffered, defer: true)
        
        picker.canChooseDirectories = !chooseFiles
        picker.canChooseFiles = chooseFiles
        picker.allowsMultipleSelection = false
        picker.canDownloadUbiquitousContents = true
        picker.canResolveUbiquitousConflicts = true

        if (chooseFiles) {
            picker.allowedFileTypes = ["mat", "modraw"]
            /*
            picker.allowedContentTypes = [UTType]()
            for ext in ["mat", "modraw"] {
                picker.allowedContentTypes.append(UTType(tag: ext, tagClass: .filenameExtension, conformingTo: nil)!)
            }*/
        }

        if (picker.runModal() == .OK) {
            return picker.urls[0]
        } else {
            return nil
        }
    }

    var body: some Scene {
        @State var realtimePlotView = RealtimePlotView()
        WindowGroup {
            realtimePlotView
                .onAppear {
                    let _ = NSApplication.shared.windows.map { $0.tabbingMode = .disallowed }
                }
        }.commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem)
            {
                Button("Open Folder...") {
                    if let folderUrl = modalFilePicker(chooseFiles: false) {
                        epsiDataModel = EpsiDataModel.createInstanceFromFolder(folderUrl)
                        lastOpenFile = nil
                        lastOpenFolder = folderUrl
                    }
                }.keyboardShortcut("o")
                Button("Open File...") {
                    if let fileUrl = modalFilePicker(chooseFiles: true) {
                        epsiDataModel = EpsiDataModel.createInstanceFromFile(fileUrl)
                        lastOpenFile = fileUrl
                        lastOpenFolder = nil
                    }
                }.keyboardShortcut("f")
            }
            CommandGroup(before: CommandGroupPlacement.toolbar) {
                Section {
                    Picker("CTD.fishflag", selection: $realtimePlotView.viewMode) {
                        Text("EPSI Mode").tag(EpsiDataModel.Mode.EPSI)
                        Text("FCTD Mode").tag(EpsiDataModel.Mode.FCTD)
                    }
                    .pickerStyle(InlinePickerStyle())
                    .onChange(of: realtimePlotView.viewMode) { value in
                        if (epsiDataModel != nil) {
                            realtimePlotView.viewMode = value
                            epsiDataModel!.mode = value
                            epsiDataModel!.updateWindowTitle()
                            epsiDataModel!.sourceDataChanged = true
                            print("changed to \(value)")
                        }
                    }
                }
                //ViewModeMenu(menuState: menuState)
            }
        }
    }
}

class MenuState : ObservableObject {
    @Published var viewMode = EpsiDataModel.Mode.EPSI
}

struct ViewModeMenu : View {
    @ObservedObject var menuState : MenuState
    
    var body: some View {
        Section {
            Picker("CTD.fishflag", selection: $menuState.viewMode) {
                Text("EPSI Mode").tag(EpsiDataModel.Mode.EPSI)
                Text("FCTD Mode").tag(EpsiDataModel.Mode.FCTD)
            }
            .pickerStyle(InlinePickerStyle())
            .onChange(of: menuState.viewMode) { value in
                if (epsiDataModel != nil) {
                    epsiDataModel!.mode = value
                    epsiDataModel!.updateWindowTitle()
                    epsiDataModel!.sourceDataChanged = true
                    print("changed to \(value)")
                }
            }
        }
    }
}
