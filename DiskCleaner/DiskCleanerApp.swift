//
//  DiskCleanerApp.swift
//  DiskCleaner
//
//  SwiftUI application entry point. Owns the top-level feature selection so
//  menu commands and keyboard shortcuts can drive it, and registers the
//  Settings scene.
//

import SwiftUI

@main
struct DiskCleanerApp: App {

    @State private var selection: Feature? = .storage

    init() {
        // Register the periodic scan-reminder activity (no-op if disabled).
        ScanReminder.shared.applyCurrentSettings()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(selection: $selection)
                .frame(minWidth: 980, minHeight: 620)
        }
        .windowResizability(.contentMinSize)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandMenu("Features") {
                Button("Overview")     { selection = .overview }
                    .keyboardShortcut("1")
                Button("Storage")      { selection = .storage }
                    .keyboardShortcut("2")
                Button("Large Files")  { selection = .largeFiles }
                    .keyboardShortcut("3")
                Button("Duplicates")   { selection = .duplicates }
                    .keyboardShortcut("4")
                Button("Applications") { selection = .applications }
                    .keyboardShortcut("5")
                Button("Memory")       { selection = .memory }
                    .keyboardShortcut("6")
                Button("External")     { selection = .external }
                    .keyboardShortcut("7")
                Divider()
                Button("Junk Cleaning")    { selection = .junk }
                Button("Scan History")     { selection = .history }
                Button("Recent Activity")  { selection = .activity }
            }
        }

        Settings {
            SettingsView()
        }
    }
}
