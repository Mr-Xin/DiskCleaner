//
//  ContentView.swift
//  DiskCleaner
//
//  The application shell. The top-level Feature selection is owned by
//  `DiskCleanerApp` so the menu bar's CommandMenu can drive it; ContentView
//  accepts it as a `Binding`.
//

import SwiftUI
import DiskCleanerCore

/// Top-level features of DiskCleaner.
enum Feature: String, CaseIterable, Identifiable {
    case visualization
    case junk
    case duplicates
    case uninstall
    case audit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .visualization: "磁盘空间可视化"
        case .junk:          "垃圾清理"
        case .duplicates:    "大文件 / 重复文件"
        case .uninstall:     "应用卸载"
        case .audit:         "最近操作"
        }
    }

    var systemImage: String {
        switch self {
        case .visualization: "chart.pie"
        case .junk:          "trash"
        case .duplicates:    "doc.on.doc"
        case .uninstall:     "xmark.bin"
        case .audit:         "clock.arrow.circlepath"
        }
    }
}

struct ContentView: View {

    @Binding var selection: Feature?
    @State private var hasFullDiskAccess: Bool
    @State private var showOnboarding: Bool

    init(selection: Binding<Feature?>) {
        self._selection = selection
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
        case .audit:         AuditLogView()
        }
    }
}

#Preview {
    ContentView(selection: .constant(.visualization))
}
