//
//  ContentView.swift
//  DiskCleaner
//
//  The application shell — now wraps everything in the DiskFlow `DesignFrame`
//  with the new `DesignSidebar` + `DesignToolbar`. Detail views remain the
//  existing implementations; they'll be visually re-skinned in later sprints.
//

import SwiftUI
import AppKit
import DiskCleanerCore

/// Top-level features of the app. Order and ids align with the DiskFlow
/// sidebar in `design_handoff_diskflow/hifi-shared.jsx :: SIDE_ITEMS`, plus
/// DiskCleaner's own extras (`junk` / `history` / `activity`) tacked on.
enum Feature: String, CaseIterable, Identifiable {
    // DiskFlow workspace items
    case overview
    case storage
    case largeFiles
    case duplicates
    case applications
    case memory
    case external

    // DiskCleaner extras
    case junk
    case history
    case activity

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview:     "Overview"
        case .storage:      "Storage"
        case .largeFiles:   "Large Files"
        case .duplicates:   "Duplicates"
        case .applications: "Applications"
        case .memory:       "Memory"
        case .external:     "External"
        case .junk:         "Junk Cleaning"
        case .history:      "Scan History"
        case .activity:     "Recent Activity"
        }
    }

    var systemImage: String {
        switch self {
        case .overview:     "square.grid.2x2"
        case .storage:      "internaldrive"
        case .largeFiles:   "doc"
        case .duplicates:   "doc.on.doc"
        case .applications: "square.grid.3x3"
        case .memory:       "cpu"
        case .external:     "externaldrive"
        case .junk:         "trash"
        case .history:      "chart.line.uptrend.xyaxis"
        case .activity:     "clock.arrow.circlepath"
        }
    }
}

struct ContentView: View {

    @Binding var selection: Feature?
    @State private var hasFullDiskAccess: Bool
    @State private var showOnboarding: Bool
    @State private var searchText: String = ""

    @AppStorage(AppSettings.appLanguageKey)
    private var appLanguage: AppLanguage = AppSettings.appLanguageDefault
    @State private var showLanguageRestartAlert = false

    @Environment(\.openSettings) private var openSettings

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
                .alert("语言已更改", isPresented: $showLanguageRestartAlert) {
                    Button("立即重启") { relaunchApp() }
                    Button("稍后", role: .cancel) {}
                } message: {
                    Text("退出后再次打开 DiskCleaner，新语言才会生效。")
                }
        }
    }

    private var mainView: some View {
        DesignFrame {
            sidebar
        } main: {
            VStack(spacing: 0) {
                DesignToolbar(
                    searchText: $searchText,
                    placeholder: "Search files, apps, caches…",
                    onRefresh: {},
                    onNotifications: {}
                )
                detailView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        let usage = Self.mainVolumeUsage()
        return DesignSidebar(
            workspaceItems: workspaceItems,
            selection: Binding(
                get: { selection?.rawValue },
                set: { newID in
                    if let newID, let feature = Feature(rawValue: newID) {
                        selection = feature
                    }
                }
            ),
            onSettingsTap: { openSettings() },
            brandName: "DiskFlow",
            storageVolume: usage.label,
            storageHealth: "Healthy",
            storageUsedBytes: usage.used,
            storageFreeBytes: usage.free,
            storageBreakdown: Self.placeholderBreakdown()
        )
    }

    private var workspaceItems: [DesignNavItem] {
        Feature.allCases.map { feature in
            DesignNavItem(
                id: feature.rawValue,
                label: feature.title,
                systemImage: feature.systemImage
            )
        }
    }

    // MARK: - Detail routing

    @ViewBuilder
    private var detailView: some View {
        switch selection ?? .storage {
        case .overview:
            ComingSoonView(title: "Overview",  systemImage: "square.grid.2x2", plannedSprint: "Sprint 2")
        case .storage:
            DiskMapView()
        case .largeFiles:
            DuplicatesView()
        case .duplicates:
            DuplicatesView()
        case .applications:
            UninstallView()
        case .memory:
            ComingSoonView(title: "Memory",    systemImage: "cpu",            plannedSprint: "Sprint 6")
        case .external:
            ComingSoonView(title: "External Drives", systemImage: "externaldrive", plannedSprint: "later")
        case .junk:
            JunkCleaningView()
        case .history:
            HistoryView()
        case .activity:
            AuditLogView()
        }
    }

    // MARK: - Storage usage helpers

    private static func mainVolumeUsage() -> (used: Int64, free: Int64, label: String) {
        let url = URL(fileURLWithPath: "/")
        let keys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeNameKey
        ]
        guard let values = try? url.resourceValues(forKeys: keys) else {
            return (used: 0, free: 0, label: "Macintosh HD")
        }
        let total = Int64(values.volumeTotalCapacity ?? 0)
        let free = Int64(values.volumeAvailableCapacity ?? 0)
        let used = max(0, total - free)
        let label = values.volumeName ?? "Macintosh HD"
        return (used: used, free: free, label: label)
    }

    /// Placeholder category breakdown ratios. Real per-category data will be
    /// surfaced in Sprint 2 when the Overview/Dashboard is built.
    private static func placeholderBreakdown() -> [StorageBreakdownSegment] {
        [
            .init(color: DesignTokens.Palette.catApps,   percent: 0.22),
            .init(color: DesignTokens.Palette.catDocs,   percent: 0.14),
            .init(color: DesignTokens.Palette.catVideo,  percent: 0.10),
            .init(color: DesignTokens.Palette.catPhoto,  percent: 0.08),
            .init(color: DesignTokens.Palette.catSystem, percent: 0.07),
            .init(color: DesignTokens.Palette.catCache,  percent: 0.04)
        ]
    }

    // MARK: - Misc

    private func relaunchApp() {
        let bundleURL = Bundle.main.bundleURL
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-n", bundleURL.path]
        try? process.run()
        NSApplication.shared.terminate(nil)
    }
}

#Preview {
    ContentView(selection: .constant(.storage))
}
