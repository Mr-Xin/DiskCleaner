//
//  UninstallView.swift
//  DiskCleaner
//
//  Sprint 7 — Application Uninstaller per DiskFlow §4.2.
//
//  Layout:
//    • 4-column LazyVGrid of installed apps. Each card: app icon (loaded
//      from NSWorkspace) + name + bundle identifier.
//    • Selected card glows blue and expands an inline panel below with
//      leftover details bucketed by Caches / App Support / Preferences /
//      LaunchAgents / Other.
//    • Floating bottom bar: "Keep app, clean leftovers" (ghost) vs.
//      "Uninstall completely" (danger primary).
//

import SwiftUI
import AppKit
import Observation
import DiskCleanerCore

// MARK: - View Model

@MainActor
@Observable
final class UninstallViewModel {

    var apps: [InstalledApp] = []
    var selectedAppID: String?
    var leftovers: [LeftoverFile] = []
    var leftoverSelection: Set<UUID> = []
    var isLoadingApps = false
    var isLoadingLeftovers = false
    var isUninstalling = false
    var statusMessage: String?
    var lastError: (any Error)?
    var searchText: String = ""

    var selectedApp: InstalledApp? {
        guard let id = selectedAppID else { return nil }
        return apps.first { $0.id == id }
    }

    var selectedLeftoverCount: Int { leftoverSelection.count }
    var selectedLeftoverBytes: Int64 {
        leftovers
            .filter { leftoverSelection.contains($0.id) }
            .reduce(Int64(0)) { $0 + $1.size }
    }

    var filteredApps: [InstalledApp] {
        guard !searchText.isEmpty else { return apps }
        let lowered = searchText.lowercased()
        return apps.filter { $0.name.lowercased().contains(lowered) || $0.bundleIdentifier.lowercased().contains(lowered) }
    }

    /// Groups leftover files by which Library subdirectory they sit in. Used
    /// for the inline detail panel under the selected app.
    var leftoverBuckets: [(label: LocalizedStringKey, files: [LeftoverFile])] {
        let caches    = leftovers.filter { $0.url.path.contains("/Library/Caches/") }
        let support   = leftovers.filter { $0.url.path.contains("/Application Support/") }
        let prefs     = leftovers.filter { $0.url.path.contains("/Preferences/") }
        let agents    = leftovers.filter { $0.url.path.contains("LaunchAgents") || $0.url.path.contains("LaunchDaemons") }
        let used      = Set((caches + support + prefs + agents).map { $0.id })
        let other     = leftovers.filter { !used.contains($0.id) }
        return [
            ("uninstall.bucket.caches",   caches),
            ("uninstall.bucket.support",  support),
            ("uninstall.bucket.prefs",    prefs),
            ("uninstall.bucket.agents",   agents),
            ("uninstall.bucket.other",    other)
        ].filter { !$0.1.isEmpty }
    }

    func loadApps() {
        isLoadingApps = true
        lastError = nil
        Task { [weak self] in
            do {
                self?.apps = try await AppUninstaller().installedApps()
            } catch {
                self?.lastError = error
            }
            self?.isLoadingApps = false
        }
    }

    func selectApp(_ app: InstalledApp) {
        if selectedAppID == app.id {
            selectedAppID = nil
            leftovers = []
            leftoverSelection = []
            return
        }
        selectedAppID = app.id
        leftovers = []
        leftoverSelection = []
        statusMessage = nil
        lastError = nil
        isLoadingLeftovers = true
        Task { [weak self] in
            do {
                let found = try await AppUninstaller().leftovers(for: app)
                self?.leftovers = found
                self?.leftoverSelection = Set(
                    found.filter { $0.confidence == .high }.map { $0.id }
                )
            } catch {
                self?.lastError = error
            }
            self?.isLoadingLeftovers = false
        }
    }

    func isLeftoverSelected(_ file: LeftoverFile) -> Bool {
        leftoverSelection.contains(file.id)
    }

    func toggleLeftover(_ file: LeftoverFile) {
        if leftoverSelection.contains(file.id) {
            leftoverSelection.remove(file.id)
        } else {
            leftoverSelection.insert(file.id)
        }
    }

    /// "Keep app, clean leftovers" — trash only the selected leftover files.
    func cleanLeftoversOnly() {
        let urls = leftovers.filter { leftoverSelection.contains($0.id) }.map { $0.url }
        guard !urls.isEmpty else { return }
        isUninstalling = true
        lastError = nil
        statusMessage = nil
        Task { [weak self] in
            AppUninstaller().unloadLaunchServices(among: urls)
            do {
                _ = try await DeletionService().moveToTrash(urls, source: "uninstall-leftovers")
                self?.statusMessage = NSLocalizedString("uninstall.status.leftovers_done", comment: "")
                // Refresh leftovers for the same app.
                if let app = self?.selectedApp { self?.selectApp(app); self?.selectApp(app) }
            } catch {
                self?.lastError = error
            }
            self?.isUninstalling = false
        }
    }

    /// Full uninstall — move the .app bundle + all selected leftovers to Trash.
    func uninstall() {
        guard let app = selectedApp else { return }
        let leftoverURLs = leftovers
            .filter { leftoverSelection.contains($0.id) }
            .map { $0.url }
        let targets = [app.bundleURL] + leftoverURLs

        isUninstalling = true
        lastError = nil
        statusMessage = nil
        Task { [weak self] in
            AppUninstaller().unloadLaunchServices(among: leftoverURLs)
            do {
                let result = try await DeletionService().moveToTrash(targets, source: "uninstall")
                if result.failures.isEmpty {
                    self?.statusMessage = String(
                        format: NSLocalizedString("uninstall.status.done", comment: ""),
                        app.name, leftoverURLs.count
                    )
                } else {
                    self?.statusMessage = String(
                        format: NSLocalizedString("uninstall.status.partial", comment: ""),
                        result.trashed.count, result.failures.count
                    )
                }
                self?.apps.removeAll { $0.id == app.id }
                self?.selectedAppID = nil
                self?.leftovers = []
                self?.leftoverSelection = []
            } catch {
                self?.lastError = error
            }
            self?.isUninstalling = false
        }
    }
}

// MARK: - View

struct UninstallView: View {

    @State private var model = UninstallViewModel()
    @State private var pendingConfirm: Bool = false

    private let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(minimum: 140, maximum: 240), spacing: 12),
        count: 4
    )

    var body: some View {
        VStack(spacing: 0) {
            actionBar
            Divider().background(DesignTokens.Palette.line1)
            content
        }
        .onAppear {
            if model.apps.isEmpty { model.loadApps() }
        }
        .sheet(isPresented: $pendingConfirm) {
            if let app = model.selectedApp {
                ConfirmUninstallSheet(
                    appName: app.name,
                    appBundleURL: app.bundleURL,
                    buckets: model.leftoverBuckets.map { bucket in
                        (
                            label: bucket.label,
                            files: bucket.files.count,
                            bytes: bucket.files.reduce(Int64(0)) { $0 + $1.size },
                            // "App Support" is highlighted as risky per design.
                            isRisky: isAppSupport(bucket.label)
                        )
                    },
                    totalLeftoverBytes: model.leftovers.reduce(Int64(0)) { $0 + $1.size },
                    onCancel: { pendingConfirm = false },
                    onConfirm: { keepSupport in
                        pendingConfirm = false
                        if keepSupport {
                            // Strip Application Support entries from the
                            // selection set before letting the model run.
                            for file in model.leftovers where file.url.path.contains("/Application Support/") {
                                model.leftoverSelection.remove(file.id)
                            }
                        }
                        model.uninstall()
                    }
                )
            }
        }
    }

    /// Crude match — works because the bucket labels are stable i18n keys.
    private func isAppSupport(_ key: LocalizedStringKey) -> Bool {
        // `LocalizedStringKey` doesn't expose its raw key, so compare via
        // the localized string instead. The lookup is cheap.
        let label = String(describing: key)
        return label.contains("support")
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            DesignButton(.ghost, size: .small, action: { model.loadApps() }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("uninstall.action.reload")
                }
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.Palette.text3)
                TextField("uninstall.search.placeholder", text: $model.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .frame(width: 200)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(DesignTokens.Palette.glass1)
            )
            .overlay(
                Capsule().strokeBorder(DesignTokens.Palette.line1, lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .disabled(model.isLoadingApps)
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoadingApps && model.apps.isEmpty {
            LoadingStateView(
                percent: 0, itemsIndexed: 0, duplicateGroups: 0,
                reclaimableBytes: 0, currentPath: ""
            )
        } else if let err = model.lastError, model.apps.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundStyle(DesignTokens.Palette.warn)
                ErrorView(error: err, onRetry: { model.loadApps() })
                    .frame(maxWidth: 460)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.apps.isEmpty {
            ContentUnavailableView(
                "uninstall.empty.title", systemImage: "app.dashed",
                description: Text("uninstall.empty.body")
            )
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    appGrid
                    if model.selectedApp != nil {
                        leftoverPanel
                    }
                }
                .padding(16)
                .padding(.bottom, 80)
            }
            .overlay(alignment: .bottom) {
                if let app = model.selectedApp {
                    floatingBar(for: app)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                }
            }
        }
    }

    private var appGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(model.filteredApps) { app in
                appCard(app)
            }
        }
    }

    private func appCard(_ app: InstalledApp) -> some View {
        let isSelected = model.selectedAppID == app.id
        return Button {
            model.selectApp(app)
        } label: {
            VStack(spacing: 10) {
                AppIconView(bundleURL: app.bundleURL, size: 56)
                VStack(spacing: 2) {
                    Text(verbatim: app.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DesignTokens.Palette.text1)
                        .lineLimit(1)
                    Text(verbatim: app.bundleIdentifier)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(DesignTokens.Palette.text3)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .fill(isSelected ? DesignTokens.Palette.blue.opacity(0.12) : DesignTokens.Palette.glass1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .strokeBorder(
                        isSelected ? DesignTokens.Palette.blueHi : DesignTokens.Palette.line1,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(
                color: isSelected ? DesignTokens.Palette.blue.opacity(0.4) : .clear,
                radius: isSelected ? 16 : 0
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Leftover panel

    @ViewBuilder
    private var leftoverPanel: some View {
        if let app = model.selectedApp {
            DesignCard(.elevated, padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        AppIconView(bundleURL: app.bundleURL, size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: app.name)
                                .font(DesignTokens.Typography.h2)
                                .foregroundStyle(DesignTokens.Palette.text1)
                            Text(verbatim: app.bundleIdentifier)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(DesignTokens.Palette.text3)
                        }
                        Spacer()
                        if model.isLoadingLeftovers {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            DesignChip(showsDot: false) {
                                Text(verbatim: String(
                                    format: NSLocalizedString("uninstall.leftover.summary", comment: ""),
                                    model.leftovers.count,
                                    ByteSize.formatted(model.leftovers.reduce(Int64(0)) { $0 + $1.size })
                                ))
                            }
                        }
                    }

                    if let status = model.statusMessage {
                        statusBanner(text: status, color: DesignTokens.Palette.good)
                    }

                    if !model.isLoadingLeftovers, model.leftovers.isEmpty {
                        Text("uninstall.leftover.none")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignTokens.Palette.text3)
                            .padding(.vertical, 12)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(model.leftoverBuckets.enumerated()), id: \.offset) { _, bucket in
                                bucketSection(label: bucket.label, files: bucket.files)
                            }
                        }
                    }
                }
            }
        }
    }

    private func bucketSection(label: LocalizedStringKey, files: [LeftoverFile]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(DesignTokens.Palette.text4)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                Text(verbatim: ByteSize.formatted(files.reduce(Int64(0)) { $0 + $1.size }))
                    .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Palette.text2)
            }
            VStack(spacing: 0) {
                ForEach(Array(files.enumerated()), id: \.element.id) { idx, file in
                    leftoverRow(file)
                    if idx < files.count - 1 {
                        Rectangle()
                            .fill(DesignTokens.Palette.line1.opacity(0.4))
                            .frame(height: 1)
                    }
                }
            }
            .background(DesignTokens.Palette.glass1)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .strokeBorder(DesignTokens.Palette.line1, lineWidth: 1)
            )
        }
    }

    private func leftoverRow(_ file: LeftoverFile) -> some View {
        HStack(spacing: 10) {
            DesignCheckbox(on: model.isLeftoverSelected(file)) {
                model.toggleLeftover(file)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: file.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignTokens.Palette.text1)
                    .lineLimit(1)
                Text(verbatim: file.url.deletingLastPathComponent().path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(DesignTokens.Palette.text3)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 4)
            if file.confidence == .low {
                DesignChip(.warn) { Text("uninstall.confidence.low") }
            }
            Text(verbatim: ByteSize.formatted(file.size))
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Palette.text2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func statusBanner(text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(color)
            Text(verbatim: text)
                .font(.system(size: 11.5))
                .foregroundStyle(DesignTokens.Palette.text2)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    private func floatingBar(for app: InstalledApp) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: String(
                    format: NSLocalizedString("uninstall.fab.selected", comment: ""),
                    model.selectedLeftoverCount
                ))
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(DesignTokens.Palette.text1)
                Text(verbatim: ByteSize.formatted(model.selectedLeftoverBytes))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Palette.blueHi)
            }
            Spacer()
            DesignButton(.ghost, size: .small, action: { model.cleanLeftoversOnly() }) {
                Text("uninstall.fab.leftovers_only")
            }
            .disabled(model.isUninstalling || model.selectedLeftoverCount == 0)
            DesignButton(.danger, size: .standard, action: { pendingConfirm = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("uninstall.fab.full")
                }
            }
            .disabled(model.isUninstalling)
        }
        .padding(.horizontal, 18)
        .frame(height: DesignTokens.Spacing.floatingBarHeight)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(Color(hex: 0x161c27, opacity: 0.85))
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .strokeBorder(DesignTokens.Palette.line2, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.45), radius: 24, y: 8)
    }
}

// MARK: - App icon helper

/// Renders the .app bundle's icon via NSWorkspace. Fall-back is a generic
/// SF-Symbol app glyph styled to match the design.
struct AppIconView: View {

    let bundleURL: URL
    var size: CGFloat = 56

    var body: some View {
        if let nsImage = appIconImage {
            Image(nsImage: nsImage)
                .resizable()
                .interpolation(.high)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
                .shadow(color: Color.black.opacity(0.35), radius: 6, y: 2)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.22)
                    .fill(
                        LinearGradient(
                            colors: [DesignTokens.Palette.catApps,
                                     DesignTokens.Palette.catApps.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "app.dashed")
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(width: size, height: size)
        }
    }

    private var appIconImage: NSImage? {
        NSWorkspace.shared.icon(forFile: bundleURL.path)
    }
}
