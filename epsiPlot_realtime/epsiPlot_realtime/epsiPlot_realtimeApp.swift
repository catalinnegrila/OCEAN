//
//  epsiPlot_realtimeApp.swift
//  epsiPlot_realtime
//
//  Created by Catalin Negrila on 11/7/24.
//

import SwiftUI

@main
struct epsiPlot_realtimeApp: App {
    
    init() {
    }

    var body: some Scene {
        let epsiPlotView = EpsiPlotView()
        WindowGroup {
            epsiPlotView
        }.commands {
            CommandGroup(before: CommandGroupPlacement.newItem) {
                Button("Select folder...") {
                    let folderChooserPoint = CGPoint(x: 0, y: 0)
                    let folderChooserSize = CGSize(width: 500, height: 600)
                    let folderChooserRectangle = CGRect(origin: folderChooserPoint, size: folderChooserSize)
                    let folderPicker = NSOpenPanel(contentRect: folderChooserRectangle, styleMask: .utilityWindow, backing: .buffered, defer: true)
                    
                    folderPicker.canChooseDirectories = true
                    folderPicker.canChooseFiles = false
                    folderPicker.allowsMultipleSelection = false
                    folderPicker.canDownloadUbiquitousContents = true
                    folderPicker.canResolveUbiquitousConflicts = true

                    let response = folderPicker.runModal()
                    if response == .OK {
                        epsiPlotView.dataModel.selectFolder(folderPicker.urls[0])
                    }
                }.keyboardShortcut("f")
            }
        }
    }
}
