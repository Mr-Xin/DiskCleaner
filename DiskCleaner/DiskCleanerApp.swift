//
//  DiskCleanerApp.swift
//  DiskCleaner
//
//  SwiftUI application entry point. Owns the top-level feature selection so
//  menu commands and keyboard shortcuts can drive it.
//
//  Settings is no longer a separate `Settings` scene — it's an inline
//  `.settings` Feature. Cmd+, sets `selection = .settings` rather than
//  opening a new window. (Closer to the DiskFlow design intent.)
//

import SwiftUI

@main
struct DiskCleanerApp: App {

    @State private var selection: Feature? = .overview

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
            CommandMenu(LocalizedStringKey("command.menu.features")) {
                featureButton(.overview,     shortcut: "1")
                featureButton(.storage,      shortcut: "2")
                featureButton(.largeFiles,   shortcut: "3")
                featureButton(.duplicates,   shortcut: "4")
                featureButton(.applications, shortcut: "5")
                featureButton(.memory,       shortcut: "6")
                featureButton(.external,     shortcut: "7")
                Divider()
                featureButton(.junk)
                featureButton(.history)
                featureButton(.activity)
                Divider()
                featureButton(.settings,     shortcut: ",")
            }
        }
    }

    private func featureButton(
        _ feature: Feature,
        shortcut: KeyEquivalent? = nil
    ) -> some View {
        Button {
            selection = feature
        } label: {
            Text(LocalizedStringKey(feature.titleKey))
        }
        .keyboardShortcut(shortcut.map { KeyboardShortcut($0) })
    }
}
