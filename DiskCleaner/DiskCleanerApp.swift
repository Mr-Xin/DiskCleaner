//
//  DiskCleanerApp.swift
//  DiskCleaner
//
//  SwiftUI application entry point. This replaces the AppKit + Storyboard
//  template the project started from.
//

import SwiftUI

@main
struct DiskCleanerApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 760, minHeight: 480)
        }
        .windowResizability(.contentMinSize)
    }
}
