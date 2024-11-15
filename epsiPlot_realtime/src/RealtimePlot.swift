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

    func openFolder(mode: EpsiDataModel.Mode) {
        if let folderUrl = modalFilePicker(chooseFiles: false) {
            epsiDataModel = EpsiDataModelModraw(mode: mode)
            epsiDataModel!.openFolder(folderUrl)
        }
    }
    func openFile(mode: EpsiDataModel.Mode) {
        if let fileUrl = modalFilePicker(chooseFiles: true) {
            switch fileUrl.pathExtension {
            case "modraw":
                epsiDataModel = EpsiDataModelModraw(mode: mode)
            case "mat":
                epsiDataModel = EpsiDataModelMat(mode: mode)
            default:
                assert(false)
            }
            epsiDataModel!.openFile(fileUrl)
        }
    }
    var body: some Scene {
        WindowGroup {
            RealtimePlotView()
                .onAppear {
                    let _ = NSApplication.shared.windows.map { $0.tabbingMode = .disallowed }
                }
        }.commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {}

            CommandMenu("EPSI") {
                Button("Open Folder...") {
                    openFolder(mode: .EPSI)
                }.keyboardShortcut("o")
                Button("Open File...") {
                    openFile(mode: .EPSI)
                }.keyboardShortcut("f")
            }
            CommandMenu("FCTD") {
                Button("Open Folder...") {
                    openFolder(mode: .FCTD)
                }.keyboardShortcut("o")
                Button("Open File...") {
                    openFile(mode: .FCTD)
                }.keyboardShortcut("f")
            }
        }
    }
}
