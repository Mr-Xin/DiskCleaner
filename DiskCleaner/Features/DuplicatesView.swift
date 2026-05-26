//
//  DuplicatesView.swift
//  DiskCleaner
//
//  Feature 3 — large files and duplicate files: scan a folder, then list the
//  biggest files and groups of identical files.
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
    var errorMessage: String?

    @ObservationIgnored private var rootURL: URL?
    @ObservationIgnored private var scanTask: Task<Void, Never>?

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

    private func startScan(_ url: URL) {
        scanTask?.cancel()
        rootURL = url
        isScanning = true
        errorMessage = nil
        largeFiles = []
        duplicateGroups = []

        scanTask = Task {
            do {
                let tree = try await DiskScanner().scan(root: url)
                if Task.isCancelled { return }
                self.largeFiles = LargeFileFinder().find(in: tree)
                let urls = tree.allFiles().map { $0.url }
                let groups = try await DuplicateFinder().findDuplicates(among: urls)
                if Task.isCancelled { return }
                self.duplicateGroups = groups
                self.hasScanned = true
            } catch is CancellationError {
                // Superseded by a newer scan — ignore.
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isScanning = false
        }
    }

    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func moveToTrash(_ url: URL) {
        Task {
            do {
                _ = try await DeletionService().moveToTrash([url])
                self.rescan()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
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
            centeredProgress("正在分析文件…")
        } else if let message = model.errorMessage {
            ContentUnavailableView(
                "分析失败",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        } else if !model.hasScanned {
            ContentUnavailableView {
                Label("大文件 / 重复文件", systemImage: "doc.on.doc")
            } description: {
                Text("选择一个文件夹，找出占空间的大文件和内容重复的文件。")
            } actions: {
                Button("选择文件夹") { model.chooseFolderAndScan() }
            }
        } else {
            switch model.mode {
            case .largeFiles: largeFilesList
            case .duplicates: duplicatesList
            }
        }
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

    private func centeredProgress(_ text: String) -> some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(text).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
