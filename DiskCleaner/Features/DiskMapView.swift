//
//  DiskMapView.swift
//  DiskCleaner
//
//  Feature 1 — disk space visualization: scan a folder and explore it as a
//  treemap plus a size-ordered breakdown list. Reports live progress and
//  flags Full Disk Access issues when many directories are unreadable.
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
    var errorMessage: String?
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

    func scanHomeFolder() {
        startScan(FileManager.default.homeDirectoryForCurrentUser)
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
        isScanning = true
        errorMessage = nil
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
            do {
                let result = try await DiskScanner().scan(root: url, onProgress: progressHandler)
                if Task.isCancelled { return }
                guard let self else { return }
                self.tree = result.root
                self.currentNode = result.root
                if result.blockedDirectoryCount > 0 && !self.permissionsChecker.hasFullDiskAccess() {
                    self.permissionWarning = "扫描中有 \(result.blockedDirectoryCount) 个目录因权限受阻。授予完全磁盘访问后重新扫描，结果会更完整。"
                }
            } catch is CancellationError {
                // Superseded by a newer scan — ignore.
            } catch {
                self?.errorMessage = error.localizedDescription
            }
            self?.isScanning = false
        }
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
                self?.errorMessage = error.localizedDescription
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
}

// MARK: - Main View

struct DiskMapView: View {

    @State private var model = DiskMapViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .navigationTitle("磁盘空间可视化")
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button { model.chooseFolder() } label: {
                Label("选择文件夹", systemImage: "folder")
            }
            Button { model.scanHomeFolder() } label: {
                Label("扫描主目录", systemImage: "house")
            }
            Button { model.navigateUp() } label: {
                Label("上一级", systemImage: "arrow.up")
            }
            .disabled(model.currentNode?.parent == nil)

            Spacer()

            if let node = model.currentNode {
                Text(node.name)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                Text(ByteSize.formatted(node.allocatedSize))
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
        }
        .padding(10)
        .disabled(model.isScanning)
    }

    @ViewBuilder
    private var content: some View {
        if model.isScanning {
            scanningView
        } else if let message = model.errorMessage {
            ContentUnavailableView(
                "扫描失败",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
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
                    ContentUnavailableView("这个文件夹是空的", systemImage: "folder")
                } else {
                    VSplitView {
                        TreemapView(
                            node: node,
                            selectedID: model.selectedNodeID,
                            onSelect: { model.selectedNodeID = $0.id },
                            onDrill: { model.drill(into: $0) }
                        )
                        .frame(minHeight: 200)

                        childrenList(node)
                            .frame(minHeight: 160)
                    }
                }
            }
        } else {
            ContentUnavailableView {
                Label("还没有扫描结果", systemImage: "chart.pie")
            } description: {
                Text("选择一个文件夹，或扫描你的主目录，看看空间被什么占用了。")
            } actions: {
                Button("扫描主目录") { model.scanHomeFolder() }
            }
        }
    }

    private var scanningView: some View {
        VStack(spacing: 14) {
            ProgressView()
            if let progress = model.scanProgress {
                Text("\(progress.scannedItemCount) 项 · \(ByteSize.formatted(progress.bytesScanned))")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Text(progress.currentPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 480)
            } else {
                Text("正在扫描…").foregroundStyle(.secondary)
            }
            Button("取消", role: .cancel) { model.cancelScan() }
                .keyboardShortcut(.escape, modifiers: [])
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
    }

    private func childrenList(_ node: FileNode) -> some View {
        List(node.childrenBySize) { child in
            HStack(spacing: 8) {
                Image(systemName: child.isDirectory ? "folder.fill" : "doc")
                    .foregroundStyle(child.id == model.selectedNodeID ? Color.accentColor : .secondary)
                Text(child.name)
                    .lineLimit(1)
                Spacer()
                Text(ByteSize.formatted(child.allocatedSize))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { model.drill(into: child) }
            .onTapGesture { model.selectedNodeID = child.id }
            .contextMenu {
                Button("在访达中显示") { model.revealInFinder(child) }
                if child.isDirectory && !child.children.isEmpty {
                    Button("进入此文件夹") { model.drill(into: child) }
                }
                Divider()
                Button("移到废纸篓", role: .destructive) { model.moveToTrash(child) }
            }
        }
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
            .background(Color(nsColor: .windowBackgroundColor))
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
                isSelected ? Color.accentColor : Color.black.opacity(0.18),
                lineWidth: isSelected ? 2.5 : 0.5
            )
            Text(node.name)
                .font(.caption2)
                .lineLimit(1)
                .padding(3)
        }
        .clipped()
        .help("\(node.name) — \(ByteSize.formatted(node.allocatedSize))")
    }

    private var tileColor: Color {
        let scalarSum = node.name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        let hue = Double(scalarSum % 360) / 360.0
        return Color(hue: hue, saturation: 0.42, brightness: 0.82)
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
                .foregroundStyle(.orange)
            Text(message)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("去授权", action: onOpenSettings)
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
        }
        .padding(10)
        .background(.orange.opacity(0.12))
    }
}
