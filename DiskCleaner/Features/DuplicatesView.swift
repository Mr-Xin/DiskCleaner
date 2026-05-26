//
//  DuplicatesView.swift
//  DiskCleaner
//
//  Sprint 5 — Duplicates per DiskFlow §4.1:
//
//    ┌───────────────┬────────────────────────────────────────────┐
//    │ 260pt group   │  KEEP card (green glow) │ VS │ DELETE cards │
//    │ list          │  ──────────────────────────────────────── │
//    │ ──────────── │  Floating bar: Skip / Customize / Apply ✨  │
//    └───────────────┴────────────────────────────────────────────┘
//
//  Large-files functionality moved out to its own screen
//  (`LargeFilesView`) in this Sprint.
//

import SwiftUI
import AppKit
import Observation
import DiskCleanerCore

// MARK: - View Model

@MainActor
@Observable
final class DuplicatesViewModel {

    var duplicateGroups: [DuplicateGroup] = []
    var isScanning = false
    var hasScanned = false
    var lastError: (any Error)?
    var scanProgress: ScanProgress?
    var phaseMessage = ""
    var permissionWarning: String?
    var selectedGroupIndex: Int = 0
    /// Per-group set of URLs the user has marked "keep". Anything not in
    /// this set is implicitly "delete". Defaults to the first URL in each
    /// group (smart-pick) when results arrive.
    var keepers: [Int: URL] = [:]

    @ObservationIgnored private var rootURL: URL?
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private let permissionsChecker = PermissionsChecker()

    var reclaimableTotal: Int64 {
        duplicateGroups.reduce(0) { $0 + $1.reclaimableBytes }
    }

    var activeGroup: DuplicateGroup? {
        guard duplicateGroups.indices.contains(selectedGroupIndex) else { return nil }
        return duplicateGroups[selectedGroupIndex]
    }

    var activeKeeper: URL? {
        keepers[selectedGroupIndex] ?? activeGroup?.urls.first
    }

    var activeDeletes: [URL] {
        guard let group = activeGroup else { return [] }
        let keep = activeKeeper
        return group.urls.filter { $0 != keep }
    }

    func chooseFolderAndScan() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "选择要分析的文件夹"
        panel.prompt = "分析"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        startScan(url)
    }

    func scanHome() {
        startScan(FileManager.default.homeDirectoryForCurrentUser)
    }

    func rescan() {
        if let rootURL { startScan(rootURL) } else { scanHome() }
    }

    func cancelScan() {
        scanTask?.cancel()
        isScanning = false
    }

    func selectGroup(_ index: Int) {
        selectedGroupIndex = index
    }

    /// Switch which URL is the "keep" in the current group.
    func setKeeper(_ url: URL) {
        keepers[selectedGroupIndex] = url
    }

    /// Move all non-keep URLs in the active group to Trash and advance to
    /// the next group.
    func applySmartPick() {
        let urls = activeDeletes
        guard !urls.isEmpty else { advance(); return }
        Task { [weak self] in
            do {
                _ = try await DeletionService().moveToTrash(urls, source: "duplicates")
                self?.duplicateGroups.remove(at: self?.selectedGroupIndex ?? 0)
                self?.keepers.removeValue(forKey: self?.selectedGroupIndex ?? 0)
                if let s = self, s.selectedGroupIndex >= s.duplicateGroups.count {
                    s.selectedGroupIndex = max(0, s.duplicateGroups.count - 1)
                }
            } catch {
                self?.lastError = error
            }
        }
    }

    /// Skip the active group without changes.
    func skipGroup() { advance() }

    private func advance() {
        if selectedGroupIndex + 1 < duplicateGroups.count {
            selectedGroupIndex += 1
        }
    }

    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func moveToTrash(_ url: URL) {
        Task { [weak self] in
            do {
                _ = try await DeletionService().moveToTrash([url], source: "duplicates")
                guard let self else { return }
                let idx = self.selectedGroupIndex
                guard let group = self.activeGroup else { return }
                let remaining = group.urls.filter { $0 != url }
                if remaining.count < 2 {
                    // No longer a duplicate set — drop the whole group.
                    self.duplicateGroups.remove(at: idx)
                    self.keepers.removeValue(forKey: idx)
                    if idx >= self.duplicateGroups.count {
                        self.selectedGroupIndex = max(0, self.duplicateGroups.count - 1)
                    }
                } else {
                    self.duplicateGroups[idx] = DuplicateGroup(
                        urls: remaining, fileSize: group.fileSize
                    )
                    if self.keepers[idx] == url {
                        self.keepers[idx] = remaining.first
                    }
                }
            } catch {
                self?.lastError = error
            }
        }
    }

    func dismissPermissionWarning() {
        permissionWarning = nil
    }

    func openSystemSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        ]
        for urlString in candidates {
            if let url = URL(string: urlString), NSWorkspace.shared.open(url) { return }
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
    }

    private func startScan(_ url: URL) {
        scanTask?.cancel()
        rootURL = url
        isScanning = true
        hasScanned = false
        lastError = nil
        scanProgress = nil
        phaseMessage = NSLocalizedString("duplicates.phase.scanning_tree", comment: "")
        permissionWarning = nil
        duplicateGroups = []
        keepers = [:]
        selectedGroupIndex = 0

        scanTask = Task { [weak self] in
            let progressHandler: (@Sendable (ScanProgress) -> Void) = { [weak self] progress in
                Task { @MainActor [weak self] in self?.scanProgress = progress }
            }
            let excludedPaths = AppSettings.excludedPaths()
            do {
                let scanResult = try await DiskScanner().scan(
                    root: url,
                    excludedPaths: excludedPaths,
                    onProgress: progressHandler
                )
                if Task.isCancelled { return }

                self?.scanProgress = nil
                self?.phaseMessage = NSLocalizedString("duplicates.phase.hashing", comment: "")

                guard let self else { return }
                let tree = scanResult.root
                let urls = tree.allFiles().map { $0.url }
                let groups = try await DuplicateFinder().findDuplicates(among: urls)
                if Task.isCancelled { return }
                self.duplicateGroups = groups
                self.hasScanned = true
                AppSettings.markScanCompleted()

                if scanResult.blockedDirectoryCount > 0 && !self.permissionsChecker.hasFullDiskAccess() {
                    self.permissionWarning = "扫描中有 \(scanResult.blockedDirectoryCount) 个目录因权限受阻。授予完全磁盘访问后重新分析，结果会更完整。"
                }
            } catch is CancellationError {
                // ignored
            } catch {
                self?.lastError = error
            }
            self?.isScanning = false
            self?.phaseMessage = ""
        }
    }
}

// MARK: - View

struct DuplicatesView: View {

    @State private var model = DuplicatesViewModel()

    var body: some View {
        VStack(spacing: 0) {
            actionBar
            Divider().background(DesignTokens.Palette.line1)
            content
        }
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            DesignButton(.default, size: .small, action: { model.chooseFolderAndScan() }) {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                    Text("duplicates.action.choose")
                }
            }
            DesignButton(.ghost, size: .small, action: { model.scanHome() }) {
                HStack(spacing: 6) {
                    Image(systemName: "house")
                    Text("duplicates.action.home")
                }
            }
            if model.hasScanned && !model.isScanning {
                DesignButton(.ghost, size: .small, action: { model.rescan() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("duplicates.action.rescan")
                    }
                }
            }
            Spacer()
            if model.hasScanned, !model.duplicateGroups.isEmpty {
                DesignChip(.good, showsDot: true) {
                    Text(verbatim: String(
                        format: NSLocalizedString("duplicates.chip.reclaimable", comment: ""),
                        ByteSize.formatted(model.reclaimableTotal)
                    ))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .disabled(model.isScanning)
    }

    @ViewBuilder
    private var content: some View {
        if model.isScanning {
            LoadingStateView(
                percent: 0,
                itemsIndexed: model.scanProgress?.scannedItemCount ?? 0,
                duplicateGroups: model.duplicateGroups.count,
                reclaimableBytes: model.reclaimableTotal,
                currentPath: model.phaseMessage.isEmpty
                    ? (model.scanProgress?.currentPath ?? "")
                    : model.phaseMessage,
                onCancel: { model.cancelScan() }
            )
        } else if let err = model.lastError {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundStyle(DesignTokens.Palette.warn)
                ErrorView(error: err, onRetry: { model.rescan() })
                    .frame(maxWidth: 460)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(30)
        } else if !model.hasScanned {
            EmptyStateView(
                onChooseFolder: { model.chooseFolderAndScan() },
                onScanAll: { model.scanHome() }
            )
        } else if model.duplicateGroups.isEmpty {
            ContentUnavailableView(
                "duplicates.empty.title",
                systemImage: "checkmark.circle",
                description: Text("duplicates.empty.body")
            )
            .padding()
        } else {
            mainSplit
        }
    }

    private var mainSplit: some View {
        HStack(spacing: 0) {
            groupList
                .frame(width: 260)
                .background(DesignTokens.Palette.glass1)
            Divider().background(DesignTokens.Palette.line1)
            VStack(spacing: 0) {
                if let warn = model.permissionWarning {
                    PermissionBanner(
                        message: warn,
                        onOpenSettings: { model.openSystemSettings() },
                        onDismiss: { model.dismissPermissionWarning() }
                    )
                }
                comparePane
                Divider().background(DesignTokens.Palette.line1)
                floatingBar
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Group list

    private var groupList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(Array(model.duplicateGroups.enumerated()), id: \.element.id) { idx, group in
                    groupRow(idx: idx, group: group)
                    Rectangle()
                        .fill(DesignTokens.Palette.line1.opacity(0.4))
                        .frame(height: 1)
                }
            }
        }
    }

    private func groupRow(idx: Int, group: DuplicateGroup) -> some View {
        let isActive = idx == model.selectedGroupIndex
        return Button {
            model.selectGroup(idx)
        } label: {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(isActive ? DesignTokens.Palette.blueHi : Color.clear)
                    .frame(width: 3)
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: group.urls.first?.lastPathComponent ?? "—")
                        .font(.system(size: 12.5, weight: isActive ? .semibold : .medium))
                        .foregroundStyle(DesignTokens.Palette.text1)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(verbatim: String(
                            format: NSLocalizedString("duplicates.group.count", comment: ""),
                            group.urls.count
                        ))
                        .font(.system(size: 10.5))
                        .foregroundStyle(DesignTokens.Palette.text3)
                        Text(verbatim: "·")
                            .foregroundStyle(DesignTokens.Palette.text4)
                        Text(verbatim: ByteSize.formatted(group.reclaimableBytes))
                            .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                            .foregroundStyle(DesignTokens.Palette.good)
                    }
                }
                Spacer(minLength: 4)
            }
            .padding(.vertical, 10)
            .padding(.trailing, 12)
            .background(isActive ? DesignTokens.Palette.blue.opacity(0.10) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    // MARK: Compare pane

    @ViewBuilder
    private var comparePane: some View {
        if let group = model.activeGroup {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    compareHeader(group)
                    HStack(alignment: .top, spacing: 16) {
                        keeperCard
                        VStack {
                            Text("duplicates.vs")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(DesignTokens.Palette.text4)
                                .padding(.vertical, 24)
                                .tracking(1.2)
                        }
                        deleteStack
                    }
                }
                .padding(20)
            }
        } else {
            Spacer()
        }
    }

    private func compareHeader(_ group: DuplicateGroup) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: group.urls.first?.lastPathComponent ?? "—")
                    .font(DesignTokens.Typography.h1)
                    .foregroundStyle(DesignTokens.Palette.text1)
                Text(verbatim: String(
                    format: NSLocalizedString("duplicates.header.summary", comment: ""),
                    group.urls.count,
                    ByteSize.formatted(group.fileSize)
                ))
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.Palette.text3)
            }
            Spacer()
        }
    }

    private var keeperCard: some View {
        let url = model.activeKeeper
        return DesignCard(.glowBlue, padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(DesignTokens.Palette.good)
                        .frame(width: 8, height: 8)
                        .shadow(color: DesignTokens.Palette.good, radius: 4)
                    Text("duplicates.keep_badge")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DesignTokens.Palette.good)
                        .textCase(.uppercase)
                        .tracking(0.8)
                }
                if let url {
                    Text(verbatim: url.lastPathComponent)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DesignTokens.Palette.text1)
                        .lineLimit(2)
                    Text(verbatim: url.deletingLastPathComponent().path)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(DesignTokens.Palette.text3)
                        .lineLimit(2)
                        .truncationMode(.middle)
                } else {
                    Text("duplicates.empty.body")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.Palette.text3)
                }
                HStack {
                    Spacer()
                    if let url {
                        DesignButton(.ghost, size: .small, action: { model.revealInFinder(url) }) {
                            Text("duplicates.action.reveal")
                        }
                    }
                }
            }
        }
        .frame(width: 320)
    }

    private var deleteStack: some View {
        VStack(spacing: 10) {
            ForEach(model.activeDeletes, id: \.self) { url in
                deleteCard(url: url)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func deleteCard(url: URL) -> some View {
        DesignCard(.default, padding: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(DesignTokens.Palette.danger)
                            .frame(width: 8, height: 8)
                            .shadow(color: DesignTokens.Palette.danger, radius: 4)
                        Text("duplicates.delete_badge")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(DesignTokens.Palette.danger)
                            .textCase(.uppercase)
                            .tracking(0.8)
                    }
                    Text(verbatim: url.lastPathComponent)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(DesignTokens.Palette.text1)
                        .lineLimit(1)
                    Text(verbatim: url.deletingLastPathComponent().path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(DesignTokens.Palette.text3)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                VStack(spacing: 4) {
                    DesignButton(.ghost, size: .small, action: { model.setKeeper(url) }) {
                        Text("duplicates.action.swap_keeper")
                    }
                    DesignButton(.danger, size: .small, action: { model.moveToTrash(url) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("duplicates.action.trash")
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(DesignTokens.Palette.danger.opacity(0.03))
        )
    }

    // MARK: Floating bar

    private var floatingBar: some View {
        let group = model.activeGroup
        let saving = (group?.fileSize ?? 0) * Int64(max(0, (group?.urls.count ?? 1) - 1))
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: String(
                    format: NSLocalizedString("duplicates.fab.this_group", comment: ""),
                    ByteSize.formatted(saving)
                ))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DesignTokens.Palette.text1)
                Text(verbatim: String(
                    format: NSLocalizedString("duplicates.fab.total", comment: ""),
                    model.duplicateGroups.count,
                    ByteSize.formatted(model.reclaimableTotal)
                ))
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.Palette.text3)
            }
            Spacer()
            DesignButton(.ghost, size: .small, action: { model.skipGroup() }) {
                Text("duplicates.fab.skip")
            }
            DesignButton(.primary, size: .standard, action: { model.applySmartPick() }) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("duplicates.fab.apply")
                }
            }
        }
        .padding(.horizontal, 18)
        .frame(height: DesignTokens.Spacing.floatingBarHeight)
        .background(
            DesignTokens.Palette.glass1
        )
    }
}

#Preview {
    DuplicatesView()
        .frame(width: 1180, height: 720)
        .background(MeshGradientBackground())
        .preferredColorScheme(.dark)
}
