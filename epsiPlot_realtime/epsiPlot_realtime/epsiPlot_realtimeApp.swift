//
//  epsiPlot_realtimeApp.swift
//  epsiPlot_realtime
//
//  Created by Catalin Negrila on 11/7/24.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct epsiPlot_realtimeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    func openPicker(chooseFiles: Bool, ext: String? = nil) -> NSOpenPanel {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 500, height: 600))
        let picker = NSOpenPanel(contentRect: rect, styleMask: .utilityWindow, backing: .buffered, defer: true)
        
        picker.canChooseDirectories = !chooseFiles
        picker.canChooseFiles = chooseFiles
        picker.allowsMultipleSelection = false
        picker.canDownloadUbiquitousContents = true
        picker.canResolveUbiquitousConflicts = true
        if (chooseFiles && ext != nil) {
            picker.allowedFileTypes = [ext!]
        }
        return picker
    }

    func openFolder(dataModel: EpsiDataModel) {
        let picker = openPicker(chooseFiles: false)
        if (picker.runModal() == .OK) {
            epsiDataModel = dataModel
            epsiDataModel!.openFolder(picker.urls[0])
        }
    }
    func openFile(dataModel: EpsiDataModel, ext: String) {
        let picker = openPicker(chooseFiles: true, ext: ext)
        if (picker.runModal() == .OK) {
            epsiDataModel = dataModel
            epsiDataModel!.openFile(picker.urls[0])
        }
    }
    var body: some Scene {
        WindowGroup {
            EpsiPlotView()
                .onAppear {
                    let _ = NSApplication.shared.windows.map { $0.tabbingMode = .disallowed }
                }
        }.commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {}

            CommandMenu("EPSI") {
                Section {
                    Button("Open folder...") {
                        openFolder(dataModel: EpsiDataModelModraw(mode: .EPSI))
                    }.keyboardShortcut("f")
                }
                Section {
                    Button("Open .modraw file...") {
                        openFile(dataModel: EpsiDataModelModraw(mode: .EPSI), ext: "modraw")
                    }.keyboardShortcut("o")
                    Button("Open .mat file...") {
                        openFile(dataModel: EpsiDataModelMat(mode: .EPSI), ext: "mat")
                    }.keyboardShortcut("a")
                }
            }
            CommandMenu("FCTD") {
                Section {
                    Button("Open folder...") {
                        openFolder(dataModel: EpsiDataModelModraw(mode: .FCTD))
                    }.keyboardShortcut("f")
                }
                Section {
                    Button("Open .modraw file...") {
                        openFile(dataModel: EpsiDataModelModraw(mode: .FCTD), ext: "modraw")
                    }.keyboardShortcut("o")
                    Button("Open .mat file...") {
                        openFile(dataModel: EpsiDataModelMat(mode: .FCTD), ext: "mat")
                    }.keyboardShortcut("a")
                }
            }
        }
    }
}
