//
//  ContentView.swift
//  DiskCleaner
//
//  The application shell — wraps everything in the DiskFlow `DesignFrame`
//  with the new `DesignSidebar` + `DesignToolbar`. Settings is now a regular
//  sidebar Feature (`.settings`), routed to `SettingsScreen` inline.
//

import SwiftUI
import AppKit
import DiskCleanerCore

/// Top-level features of the app. Order and ids align with the DiskFlow
/// sidebar in `design_handoff_diskflow/hifi-shared.jsx :: SIDE_ITEMS`, plus
/// DiskCleaner's own extras and a `.settings` item under SYSTEM.
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

    // System
    case settings

    var id: String { rawValue }

    /// i18n key resolved via `Localizable.xcstrings`. Use with
    /// `Text(LocalizedStringKey(feature.titleKey))`.
    var titleKey: String {
        switch self {
        case .overview:     return "feature.overview"
        case .storage:      return "feature.storage"
        case .largeFiles:   return "feature.large_files"
        case .duplicates:   return "feature.duplicates"
        case .applications: return "feature.applications"
        case .memory:       return "feature.memory"
        case .external:     return "feature.external"
        case .junk:         return "feature.junk"
        case .history:      return "feature.history"
        case .activity:     return "feature.activity"
        case .settings:     return "feature.settings"
        }
    }

    var systemImage: String {
        switch self {
        case .overview:     return "square.grid.2x2"
        case .storage:      return "internaldrive"
        case .largeFiles:   return "doc"
        case .duplicates:   return "doc.on.doc"
        case .applications: return "square.grid.3x3"
        case .memory:       return "cpu"
        case .external:     return "externaldrive"
        case .junk:         return "trash"
        case .history:      return "chart.line.uptrend.xyaxis"
        case .activity:     return "clock.arrow.circlepath"
        case .settings:     return "gearshape"
        }
    }
}

struct ContentView: View {

    @Binding var selection: Feature?
    @State private var hasFullDiskAccess: Bool
    @State private var showOnboarding: Bool
    @State private var searchText: String = ""

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
        DesignFrame {
            sidebar
        } main: {
            VStack(spacing: 0) {
                DesignToolbar(
                    searchText: $searchText,
                    placeholderKey: "toolbar.search.placeholder",
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
            systemItems: systemItems,
            selection: Binding(
                get: { selection?.rawValue },
                set: { newID in
                    if let newID, let feature = Feature(rawValue: newID) {
                        selection = feature
                    }
                }
            ),
            brandName: "DiskFlow",
            storageVolume: usage.label,
            storageUsedBytes: usage.used,
            storageFreeBytes: usage.free,
            storageBreakdown: Self.placeholderBreakdown()
        )
    }

    /// Features that go under the WORKSPACE section (everything except
    /// `.settings`, which lives under SYSTEM).
    private var workspaceItems: [DesignNavItem] {
        Feature.allCases
            .filter { $0 != .settings }
            .map { feature in
                DesignNavItem(
                    id: feature.rawValue,
                    labelKey: feature.titleKey,
                    systemImage: feature.systemImage
                )
            }
    }

    private var systemItems: [DesignNavItem] {
        [
            DesignNavItem(
                id: Feature.settings.rawValue,
                labelKey: Feature.settings.titleKey,
                systemImage: Feature.settings.systemImage
            )
        ]
    }

    // MARK: - Detail routing

    @ViewBuilder
    private var detailView: some View {
        switch selection ?? .storage {
        case .overview:
            ComingSoonView(titleKey: "feature.overview",  systemImage: "square.grid.2x2",       plannedSprint: "Sprint 2")
        case .storage:
            DiskMapView()
        case .largeFiles:
            DuplicatesView()
        case .duplicates:
            DuplicatesView()
        case .applications:
            UninstallView()
        case .memory:
            ComingSoonView(titleKey: "feature.memory",    systemImage: "cpu",                   plannedSprint: "Sprint 6")
        case .external:
            ComingSoonView(titleKey: "feature.external",  systemImage: "externaldrive",         plannedSprint: "later")
        case .junk:
            JunkCleaningView()
        case .history:
            HistoryView()
        case .activity:
            AuditLogView()
        case .settings:
            SettingsScreen()
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
}

#Preview {
    ContentView(selection: .constant(.storage))
}
