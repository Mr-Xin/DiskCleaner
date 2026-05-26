//
//  ContentView.swift
//  DiskCleaner
//
//  The application shell: a Full Disk Access gate, then a sidebar that routes
//  to the four feature screens.
//

import SwiftUI
import DiskCleanerCore

/// The four top-level features of DiskCleaner.
enum Feature: String, CaseIterable, Identifiable {
    case visualization
    case junk
    case duplicates
    case uninstall

    var id: String { rawValue }

    var title: String {
        switch self {
        case .visualization: "磁盘空间可视化"
        case .junk:          "垃圾清理"
        case .duplicates:    "大文件 / 重复文件"
        case .uninstall:     "应用卸载"
        }
    }

    var systemImage: String {
        switch self {
        case .visualization: "chart.pie"
        case .junk:          "trash"
        case .duplicates:    "doc.on.doc"
        case .uninstall:     "xmark.bin"
        }
    }
}

struct ContentView: View {

    @State private var selection: Feature? = .visualization
    @State private var hasFullDiskAccess: Bool
    @State private var showOnboarding: Bool

    init() {
        let granted = PermissionsChecker().hasFullDiskAccess()
        _hasFullDiskAccess = State(initialValue: granted)
        _showOnboarding = State(initialValue: !granted)
    }

    var body: some View {
        if showOnboarding {
            FullDiskAccessView(
                hasAccess: hasFullDiskAccess,
                onRecheck: { hasFullDiskAccess = PermissionsChecker().hasFullDiskAccess() },
                onContinue: { showOnboarding = false }
            )
        } else {
            mainView
        }
    }

    private var mainView: some View {
        NavigationSplitView {
            List(Feature.allCases, selection: $selection) { feature in
                Label(feature.title, systemImage: feature.systemImage)
                    .tag(feature)
            }
            .navigationTitle("DiskCleaner")
            .navigationSplitViewColumnWidth(min: 210, ideal: 240)
        } detail: {
            detailView
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection ?? .visualization {
        case .visualization: DiskMapView()
        case .junk:          JunkCleaningView()
        case .duplicates:    DuplicatesView()
        case .uninstall:     UninstallView()
        }
    }
}

#Preview {
    ContentView()
}
