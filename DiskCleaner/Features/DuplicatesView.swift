//
//  DuplicatesView.swift
//  DiskCleaner
//
//  Feature 3 — large files and duplicate files: scan a folder, then list the
//  biggest files and groups of identical files (APFS clones excluded).
//

import SwiftUI
import AppKit
import Observation
import DiskCleanerCore

// MARK: - View Model

@MainActor
@Observable
final class DuplicatesViewModel {

    enum Mode: String, CaseIterable, Identifiable {
        case largeFiles
        case duplicates

        var id: String { rawValue }

        var title: String {
            switch self {
            case .largeFiles: "大文件"
            case .duplicates: "重复文件"
            }
        }
    }

    var mode: Mode = .largeFiles
    var largeFiles: [LargeFile] = []
    var duplicateGroups: [DuplicateGroup] = []
    var isScanning = false
    var hasScanned = false
    var lastError: (any Error)?
    var scanProgress: ScanProgress?
    var phaseMessage = ""
    var permissionWarning: String?

    @ObservationIgnored private var rootURL: URL?
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private let permissionsChecker = PermissionsChecker()

    var reclaimableFromDuplicates: Int64 {
        duplicateGroups.reduce(0) { $0 + $1.reclaimableBytes }
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
        lastError = nil
        scanProgress = nil
        phaseMessage = "正在扫描文件树…"
        permissionWarning = nil
        largeFiles = []
        duplicateGroups = []

        scanTask = Task { [weak self] in
            let progressHandler: (@Sendable (ScanProgress) -> Void) = { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.scanProgress = progress
                }
            }
            do {
                let scanResult = try await DiskScanner().scan(root: url, onProgress: progressHandler)
                if Task.isCancelled { return }

                self?.scanProgress = nil
                self?.phaseMessage = "正在查找大文件与重复文件…"

                guard let self else { return }
                let tree = scanResult.root
                let thresholdBytes = Int64(AppSettings.largeFileThresholdMB()) * 1024 * 1024
                self.largeFiles = LargeFileFinder().find(in: tree, minimumSize: thresholdBytes)

                let urls = tree.allFiles().map { $0.url }
                let groups = try await DuplicateFinder().findDuplicates(among: urls)
                if Task.isCancelled { return }
                self.duplicateGroups = groups
                self.hasScanned = true

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

    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func moveToTrash(_ url: URL) {
        Task { [weak self] in
            do {
                _ = try await DeletionService().moveToTrash([url], source: "duplicates")
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
}

// MARK: - View

struct DuplicatesView: View {

    @State private var model = DuplicatesViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .navigationTitle("大文件 / 重复文件")
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button { model.chooseFolderAndScan() } label: {
                Label("选择文件夹", systemImage: "folder")
            }
            .disabled(model.isScanning)

            if model.hasScanned {
                Picker("", selection: Binding(
                    get: { model.mode },
                    set: { model.mode = $0 }
                )) {
                    ForEach(DuplicatesViewModel.Mode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 220)
            }

            Spacer()
        }
        .padding(10)
    }

    @ViewBuilder
    private var content: some View {
        if model.isScanning {
            scanningView
        } else if let error = model.lastError {
            errorView(error)
        } else if !model.hasScanned {
            ContentUnavailableView {
                Label("大文件 / 重复文件", systemImage: "doc.on.doc")
            } description: {
                Text("选择一个文件夹，找出占空间的大文件和内容重复的文件。")
            } actions: {
                Button("选择文件夹") { model.chooseFolderAndScan() }
            }
        } else {
            VStack(spacing: 0) {
                if let warning = model.permissionWarning {
                    PermissionBanner(
                        message: warning,
                        onOpenSettings: { model.openSystemSettings() },
                        onDismiss: { model.dismissPermissionWarning() }
                    )
                }
                switch model.mode {
                case .largeFiles: largeFilesList
                case .duplicates: duplicatesList
                }
            }
        }
    }

    private var scanningView: some View {
        VStack(spacing: 14) {
            ProgressView()
            if !model.phaseMessage.isEmpty {
                Text(model.phaseMessage)
                    .foregroundStyle(.secondary)
            }
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
            }
            Button("取消", role: .cancel) { model.cancelScan() }
                .keyboardShortcut(.escape, modifiers: [])
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
    }

    private func errorView(_ error: any Error) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
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

    @ViewBuilder
    private var largeFilesList: some View {
        if model.largeFiles.isEmpty {
            ContentUnavailableView("没有发现大文件", systemImage: "checkmark.circle")
        } else {
            List(model.largeFiles) { file in
                HStack(spacing: 10) {
                    Image(systemName: "doc")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.name).lineLimit(1)
                        Text(file.url.deletingLastPathComponent().path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    Text(ByteSize.formatted(file.size))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .contextMenu {
                    Button("在访达中显示") { model.revealInFinder(file.url) }
                    Button("移到废纸篓", role: .destructive) { model.moveToTrash(file.url) }
                }
            }
        }
    }

    @ViewBuilder
    private var duplicatesList: some View {
        if model.duplicateGroups.isEmpty {
            ContentUnavailableView("没有发现重复文件", systemImage: "checkmark.circle")
        } else {
            List {
                Text("约可回收 \(ByteSize.formatted(model.reclaimableFromDuplicates))")
                    .foregroundStyle(.secondary)
                ForEach(model.duplicateGroups) { group in
                    Section("\(group.urls.count) 个相同文件 · 每个 \(ByteSize.formatted(group.fileSize))") {
                        ForEach(group.urls, id: \.self) { url in
                            HStack {
                                Text(url.lastPathComponent).lineLimit(1)
                                Spacer()
                                Text(url.deletingLastPathComponent().path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            .contextMenu {
                                Button("在访达中显示") { model.revealInFinder(url) }
                                Button("移到废纸篓", role: .destructive) { model.moveToTrash(url) }
                            }
                        }
                    }
                }
            }
        }
    }
}
