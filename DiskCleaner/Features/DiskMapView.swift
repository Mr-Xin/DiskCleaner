//
//  DiskMapView.swift
//  DiskCleaner
//
//  Sprint 3 — Storage Analyzer. Wraps the existing treemap engine in the
//  DiskFlow chrome:
//
//    ┌──────────────────────────────────────┬────────────────────────┐
//    │                                      │ Breadcrumb            │
//    │                                      │ ─────────────────     │
//    │   Treemap canvas (1.4fr)             │ Breakdown list (top   │
//    │                                      │   6 children w/ bars) │
//    │                                      │ ─────────────────     │
//    │                                      │ ✨ Insight card        │
//    │                                      │ Clean X GB CTA        │
//    └──────────────────────────────────────┴────────────────────────┘
//
//  Sunburst is intentionally swapped out for the existing squarified
//  treemap (README §10 explicitly allows this) — the redesign focuses on
//  visual polish and the right-panel narrative.
//

import SwiftUI
import AppKit
import Observation
import DiskCleanerCore

// MARK: - View Model

@MainActor
@Observable
final class DiskMapViewModel {

    var tree: FileNode?
    var currentNode: FileNode?
    var selectedNodeID: UUID?
    var isScanning = false
    var lastError: (any Error)?
    var scanProgress: ScanProgress?
    var permissionWarning: String?

    @ObservationIgnored private var rootURL: URL?
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private let permissionsChecker = PermissionsChecker()

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "选择要扫描的文件夹"
        panel.prompt = "扫描"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        startScan(url)
    }

    /// Scans whatever the user picked as their default scan root in Settings.
    func scanDefault() {
        switch AppSettings.defaultScanRoot() {
        case .home:
            startScan(FileManager.default.homeDirectoryForCurrentUser)
        case .lastUsed:
            if let last = lastUsedScanRoot() {
                startScan(last)
            } else {
                chooseFolder()
            }
        case .ask:
            chooseFolder()
        }
    }

    func rescan() {
        if let rootURL { startScan(rootURL) }
    }

    func cancelScan() {
        scanTask?.cancel()
        isScanning = false
    }

    private func startScan(_ url: URL) {
        scanTask?.cancel()
        rootURL = url
        storeLastScanned(url)
        isScanning = true
        lastError = nil
        scanProgress = nil
        permissionWarning = nil
        tree = nil
        currentNode = nil
        selectedNodeID = nil

        scanTask = Task { [weak self] in
            let progressHandler: (@Sendable (ScanProgress) -> Void) = { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.scanProgress = progress
                }
            }
            let excludedPaths = AppSettings.excludedPaths()
            do {
                let result = try await DiskScanner().scan(
                    root: url,
                    excludedPaths: excludedPaths,
                    onProgress: progressHandler
                )
                if Task.isCancelled { return }
                guard let self else { return }
                self.tree = result.root
                self.currentNode = result.root
                if result.blockedDirectoryCount > 0 && !self.permissionsChecker.hasFullDiskAccess() {
                    self.permissionWarning = "扫描中有 \(result.blockedDirectoryCount) 个目录因权限受阻。授予完全磁盘访问后重新扫描，结果会更完整。"
                }
                await Self.recordSnapshot(rootURL: url, tree: result.root)
            } catch is CancellationError {
                // Superseded by a newer scan — ignore.
            } catch {
                self?.lastError = error
            }
            self?.isScanning = false
        }
    }

    /// Adds `path` to the global exclude list and re-scans so the result no
    /// longer includes it.
    func excludePath(_ path: String) {
        AppSettings.addExcludedPath(path)
        rescan()
    }

    private static func recordSnapshot(rootURL: URL, tree: FileNode) async {
        let snapshot = ScanSnapshot(
            timestamp: Date(),
            rootPath: rootURL.path,
            totalAllocatedBytes: tree.allocatedSize,
            itemCount: tree.totalItemCount
        )
        await ScanHistoryStore.shared.record(snapshot)
        AppSettings.markScanCompleted()
    }

    func drill(into node: FileNode) {
        guard node.isDirectory, !node.children.isEmpty else { return }
        currentNode = node
        selectedNodeID = nil
    }

    func navigateUp() {
        guard let parent = currentNode?.parent else { return }
        currentNode = parent
        selectedNodeID = nil
    }

    func revealInFinder(_ node: FileNode) {
        NSWorkspace.shared.activateFileViewerSelecting([node.url])
    }

    func moveToTrash(_ node: FileNode) {
        Task { [weak self] in
            do {
                _ = try await DeletionService().moveToTrash([node.url], source: "disk-map")
                self?.rescan()
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

    // MARK: - Breadcrumb

    /// Path from `tree` root → `currentNode`, used by the right panel.
    var breadcrumb: [FileNode] {
        guard let current = currentNode else { return [] }
        var path: [FileNode] = []
        var cur: FileNode? = current
        while let n = cur {
            path.insert(n, at: 0)
            cur = n.parent
        }
        return path
    }

    /// Top children by size for the right panel's breakdown list.
    func topChildren(limit: Int = 6) -> [FileNode] {
        guard let node = currentNode else { return [] }
        return Array(node.childrenBySize.prefix(limit))
    }

    /// Selected node (if any), used to enable the right-panel "Clean" CTA.
    var selectedNode: FileNode? {
        guard let id = selectedNodeID, let node = currentNode else { return nil }
        return node.childrenBySize.first { $0.id == id }
    }

    // MARK: - Last-used scan root

    private func lastUsedScanRoot() -> URL? {
        guard let path = UserDefaults.standard.string(forKey: AppSettings.lastScannedPathKey) else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }

    private func storeLastScanned(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: AppSettings.lastScannedPathKey)
    }
}

// MARK: - Main View

struct DiskMapView: View {

    @State private var model = DiskMapViewModel()

    var body: some View {
        VStack(spacing: 0) {
            actionBar
            Divider().background(DesignTokens.Palette.line1)
            content
        }
    }

    // MARK: Action bar

    private var actionBar: some View {
        HStack(spacing: 10) {
            DesignButton(.default, size: .small, action: { model.chooseFolder() }) {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                    Text("storage.action.choose_folder")
                }
            }
            DesignButton(.ghost, size: .small, action: { model.scanDefault() }) {
                HStack(spacing: 6) {
                    Image(systemName: "house")
                    Text("storage.action.scan_default")
                }
            }
            if model.currentNode?.parent != nil {
                DesignButton(.ghost, size: .small, action: { model.navigateUp() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up")
                        Text("storage.action.up")
                    }
                }
            }
            if model.tree != nil && !model.isScanning {
                DesignButton(.ghost, size: .small, action: { model.rescan() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("storage.action.rescan")
                    }
                }
            }
            Spacer()
            if let node = model.currentNode {
                DesignChip {
                    Text(verbatim: node.name)
                }
                Text(verbatim: ByteSize.formatted(node.allocatedSize))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Palette.text1)
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
                duplicateGroups: 0,
                reclaimableBytes: model.scanProgress?.bytesScanned ?? 0,
                currentPath: model.scanProgress?.currentPath ?? "",
                onCancel: { model.cancelScan() }
            )
        } else if let error = model.lastError {
            errorView(error)
        } else if let node = model.currentNode {
            VStack(spacing: 0) {
                if let warning = model.permissionWarning {
                    PermissionBanner(
                        message: warning,
                        onOpenSettings: { model.openSystemSettings() },
                        onDismiss: { model.dismissPermissionWarning() }
                    )
                }
                if node.children.isEmpty {
                    emptyFolderState
                } else {
                    HStack(spacing: 0) {
                        treemapColumn(node)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Divider().background(DesignTokens.Palette.line1)
                        detailsPanel(node)
                            .frame(width: 320)
                    }
                }
            }
        } else {
            EmptyStateView(
                onChooseFolder: { model.chooseFolder() },
                onScanAll: { model.scanDefault() }
            )
        }
    }

    private var emptyFolderState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.system(size: 40))
                .foregroundStyle(DesignTokens.Palette.text3)
            Text("storage.empty_folder")
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.Palette.text3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    // MARK: Treemap column

    private func treemapColumn(_ node: FileNode) -> some View {
        VStack(spacing: 0) {
            TreemapView(
                node: node,
                selectedID: model.selectedNodeID,
                onSelect: { model.selectedNodeID = $0.id },
                onDrill: { model.drill(into: $0) }
            )
            .padding(14)
        }
    }

    // MARK: Right details panel

    private func detailsPanel(_ node: FileNode) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                breadcrumbView
                breakdownList
                insightCard
                cleanCTA
            }
            .padding(16)
        }
        .background(DesignTokens.Palette.glass1)
    }

    private var breadcrumbView: some View {
        let crumbs = model.breadcrumb
        return VStack(alignment: .leading, spacing: 6) {
            Text("storage.panel.location")
                .font(DesignTokens.Typography.label)
                .foregroundStyle(DesignTokens.Palette.text4)
                .textCase(.uppercase)
                .tracking(0.8)
            HStack(spacing: 4) {
                ForEach(Array(crumbs.suffix(4).enumerated()), id: \.offset) { idx, n in
                    if idx > 0 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(DesignTokens.Palette.text4)
                    }
                    Text(verbatim: n.name)
                        .font(.system(size: 12, weight: idx == crumbs.suffix(4).count - 1 ? .semibold : .regular))
                        .foregroundStyle(idx == crumbs.suffix(4).count - 1
                            ? DesignTokens.Palette.text1
                            : DesignTokens.Palette.text3)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var breakdownList: some View {
        let kids = model.topChildren(limit: 6)
        let totalBytes = max(model.currentNode?.allocatedSize ?? 1, 1)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("storage.panel.breakdown")
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(DesignTokens.Palette.text4)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                Text(verbatim: String(
                    format: NSLocalizedString("storage.panel.breakdown_count", comment: ""),
                    model.currentNode?.children.count ?? 0
                ))
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.Palette.text4)
            }
            VStack(spacing: 6) {
                ForEach(kids) { child in
                    breakdownRow(child, totalBytes: totalBytes)
                }
            }
        }
    }

    private func breakdownRow(_ child: FileNode, totalBytes: Int64) -> some View {
        let fraction = totalBytes > 0 ? Double(child.allocatedSize) / Double(totalBytes) : 0
        let selected = child.id == model.selectedNodeID
        return Button {
            model.selectedNodeID = child.id
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: child.isDirectory ? "folder.fill" : "doc")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.Palette.blueHi)
                    Text(verbatim: child.name)
                        .font(.system(size: 12, weight: selected ? .semibold : .regular))
                        .foregroundStyle(DesignTokens.Palette.text1)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text(verbatim: ByteSize.formatted(child.allocatedSize))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(DesignTokens.Palette.text2)
                }
                DesignBar(fill: fraction, variant: .default)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(selected ? DesignTokens.Palette.blue.opacity(0.10) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .strokeBorder(selected ? DesignTokens.Palette.blue.opacity(0.30) : .clear, lineWidth: 1)
            )
            .contextMenu {
                Button("storage.context.reveal") { model.revealInFinder(child) }
                if child.isDirectory && !child.children.isEmpty {
                    Button("storage.context.drill") { model.drill(into: child) }
                }
                Button("storage.context.exclude") { model.excludePath(child.url.path) }
                Divider()
                Button("storage.context.trash", role: .destructive) { model.moveToTrash(child) }
            }
            .onTapGesture(count: 2) { model.drill(into: child) }
        }
        .buttonStyle(.plain)
    }

    private var insightCard: some View {
        let kids = model.topChildren(limit: 1)
        let topName = kids.first?.name ?? ""
        let topSize = kids.first?.allocatedSize ?? 0
        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(DesignTokens.Palette.blueHi)
            VStack(alignment: .leading, spacing: 2) {
                Text("storage.panel.insight.title")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignTokens.Palette.text2)
                if !topName.isEmpty {
                    Text(verbatim: String(
                        format: NSLocalizedString("storage.panel.insight.body", comment: ""),
                        topName,
                        ByteSize.formatted(topSize)
                    ))
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.Palette.text3)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("storage.panel.insight.empty")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.Palette.text3)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Palette.blue.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .strokeBorder(DesignTokens.Palette.blue.opacity(0.25), lineWidth: 1)
        )
    }

    private var cleanCTA: some View {
        Group {
            if let selected = model.selectedNode {
                DesignButton(.primary, action: { model.moveToTrash(selected) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text(verbatim: String(
                            format: NSLocalizedString("storage.panel.clean_cta", comment: ""),
                            ByteSize.formatted(selected.allocatedSize)
                        ))
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                DesignButton(.ghost, action: {}) {
                    Text("storage.panel.clean_hint")
                        .frame(maxWidth: .infinity)
                }
                .disabled(true)
            }
        }
    }

    private func errorView(_ error: any Error) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(DesignTokens.Palette.warn)
            ErrorView(
                error: error,
                onRetry: { model.rescan() },
                onOpenSettings: { model.openSystemSettings() }
            )
            .frame(maxWidth: 460)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
    }
}

// MARK: - Treemap

struct TreemapView: View {

    let node: FileNode
    let selectedID: UUID?
    let onSelect: (FileNode) -> Void
    let onDrill: (FileNode) -> Void

    var body: some View {
        GeometryReader { geometry in
            let children = Array(node.childrenBySize.prefix(80))
            let tiles = TreemapLayout.layout(
                items: children.map { TreemapItem(id: $0.id, weight: Double(max($0.allocatedSize, 1))) },
                in: CGRect(origin: .zero, size: geometry.size)
            )
            let nodesByID = Dictionary(uniqueKeysWithValues: children.map { ($0.id, $0) })

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .fill(DesignTokens.Palette.glass1)
                ForEach(tiles) { tile in
                    if let child = nodesByID[tile.id] {
                        TreemapTileView(node: child, isSelected: child.id == selectedID)
                            .frame(width: max(tile.rect.width, 1), height: max(tile.rect.height, 1))
                            .offset(x: tile.rect.minX, y: tile.rect.minY)
                            .onTapGesture(count: 2) { onDrill(child) }
                            .onTapGesture { onSelect(child) }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .strokeBorder(DesignTokens.Palette.line1, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl))
        }
    }
}

private struct TreemapTileView: View {

    let node: FileNode
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(tileColor)
            Rectangle().strokeBorder(
                isSelected ? DesignTokens.Palette.blueHi : Color.black.opacity(0.30),
                lineWidth: isSelected ? 2.5 : 0.5
            )
            if isSelected {
                Rectangle()
                    .strokeBorder(DesignTokens.Palette.blueHi.opacity(0.4), lineWidth: 4)
                    .blur(radius: 4)
            }
            Text(verbatim: node.name)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
                .padding(4)
        }
        .clipped()
        .help("\(node.name) — \(ByteSize.formatted(node.allocatedSize))")
    }

    /// Tile colour rotates through the DiskFlow category palette so the
    /// treemap reads as a cohesive piece of the rest of the app.
    private var tileColor: Color {
        let palette: [Color] = [
            DesignTokens.Palette.catApps,
            DesignTokens.Palette.catDocs,
            DesignTokens.Palette.catVideo,
            DesignTokens.Palette.catPhoto,
            DesignTokens.Palette.catSystem,
            DesignTokens.Palette.catCache,
            DesignTokens.Palette.catOther,
            DesignTokens.Palette.blue,
            DesignTokens.Palette.cyan,
            DesignTokens.Palette.purple
        ]
        let scalarSum = node.name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return palette[scalarSum % palette.count].opacity(0.78)
    }
}

// MARK: - Permission Banner (shared style)

struct PermissionBanner: View {

    let message: String
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundStyle(DesignTokens.Palette.warn)
            Text(verbatim: message)
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.Palette.text2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            DesignButton(.ghost, size: .small, action: onOpenSettings) {
                Text("permission.cta.grant")
            }
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.Palette.text3)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(DesignTokens.Palette.warn.opacity(0.10))
        .overlay(
            Rectangle()
                .fill(DesignTokens.Palette.warn.opacity(0.30))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}
