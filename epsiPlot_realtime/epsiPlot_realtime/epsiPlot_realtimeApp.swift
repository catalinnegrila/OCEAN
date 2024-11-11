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

    func openPicker(chooseFiles: Bool) -> NSOpenPanel {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 500, height: 600))
        let picker = NSOpenPanel(contentRect: rect, styleMask: .utilityWindow, backing: .buffered, defer: true)
        
        picker.canChooseDirectories = !chooseFiles
        picker.canChooseFiles = chooseFiles
        picker.allowsMultipleSelection = false
        picker.canDownloadUbiquitousContents = true
        picker.canResolveUbiquitousConflicts = true

        return picker
    }

    var body: some Scene {
        WindowGroup {
            EpsiPlotView()
        }.commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                Button("Open folder...") {
                    let picker = openPicker(chooseFiles: false)
                    if (picker.runModal() == .OK) {
                        epsiDataModel = EpsiDataModelModraw()
                        epsiDataModel!.openFolder(picker.urls[0])
                    }
                }.keyboardShortcut("f")
                Button("Open .modraw file...") {
                    let picker = openPicker(chooseFiles: true)
                    picker.allowedFileTypes = ["modraw"]

                    if (picker.runModal() == .OK) {
                        epsiDataModel = EpsiDataModelModraw()
                        epsiDataModel!.openFile(picker.urls[0])
                    }
                }.keyboardShortcut("o")
                Button("Open .mat file...") {
                    let picker = openPicker(chooseFiles: true)
                    picker.allowedFileTypes = ["mat"]

                    if (picker.runModal() == .OK) {
                        epsiDataModel = EpsiDataModelMat()
                        epsiDataModel!.openFile(picker.urls[0])
                    }
                }.keyboardShortcut("m")
            }
        }
    }
}
