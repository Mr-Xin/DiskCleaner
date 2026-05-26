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

    @State private var selection: Feature? = .visualization

    var body: some Scene {
        WindowGroup {
            ContentView(selection: $selection)
                .frame(minWidth: 760, minHeight: 480)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandMenu("功能") {
                Button("磁盘可视化") { selection = .visualization }
                    .keyboardShortcut("1")
                Button("垃圾清理") { selection = .junk }
                    .keyboardShortcut("2")
                Button("大文件 / 重复文件") { selection = .duplicates }
                    .keyboardShortcut("3")
                Button("应用卸载") { selection = .uninstall }
                    .keyboardShortcut("4")
                Divider()
                Button("最近操作") { selection = .audit }
                    .keyboardShortcut("5")
            }
        }

        Settings {
            SettingsView()
        }
    }
}
