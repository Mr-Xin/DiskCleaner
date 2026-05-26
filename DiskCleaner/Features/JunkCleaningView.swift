//
//  JunkCleaningView.swift
//  DiskCleaner
//
//  Feature 2 — junk cleaning: scan for cleanable caches, logs and temporary
//  files, then move the selected items to the Trash.
//

import SwiftUI
import Observation
import DiskCleanerCore

// MARK: - View Model

@MainActor
@Observable
final class JunkCleaningViewModel {

    var items: [JunkItem] = []
    var selectedIDs: Set<UUID> = []
    var isScanning = false
    var isCleaning = false
    var hasScanned = false
    var statusMessage: String?
    var errorMessage: String?
    var scanProgress: JunkScanProgress?

    @ObservationIgnored private var scanTask: Task<Void, Never>?

    var totalFoundSize: Int64 {
        items.reduce(0) { $0 + $1.size }
    }

    var selectedSize: Int64 {
        items.filter { selectedIDs.contains($0.id) }.reduce(0) { $0 + $1.size }
    }

    var groupedItems: [(category: JunkCategory, items: [JunkItem])] {
        Dictionary(grouping: items, by: { $0.rule.category })
            .map { (category: $0.key, items: $0.value.sorted { $0.size > $1.size }) }
            .sorted { lhs, rhs in
                lhs.items.reduce(0) { $0 + $1.size } > rhs.items.reduce(0) { $0 + $1.size }
            }
    }

    func scan() {
        scanTask?.cancel()
        isScanning = true
        errorMessage = nil
        statusMessage = nil
        scanProgress = nil
        items = []
        selectedIDs = []

        scanTask = Task { [weak self] in
            let progressHandler: (@Sendable (JunkScanProgress) -> Void) = { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.scanProgress = progress
                }
            }
            do {
                let found = try await JunkRulesEngine().scan(onProgress: progressHandler)
                self?.items = found
                self?.selectedIDs = Set(found.filter { $0.rule.safety == .safe }.map { $0.id })
                self?.hasScanned = true
            } catch is CancellationError {
                // ignored
            } catch {
                self?.errorMessage = error.localizedDescription
            }
            self?.isScanning = false
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        isScanning = false
    }

    func isSelected(_ item: JunkItem) -> Bool {
        selectedIDs.contains(item.id)
    }

    func toggle(_ item: JunkItem) {
        if selectedIDs.contains(item.id) {
            selectedIDs.remove(item.id)
        } else {
            selectedIDs.insert(item.id)
        }
    }

    func cleanSelected() {
        let targets = items.filter { selectedIDs.contains($0.id) }
        guard !targets.isEmpty else { return }
        isCleaning = true
        errorMessage = nil
        statusMessage = nil
        Task { [weak self] in
            do {
                let result = try await DeletionService().moveToTrash(
                    targets.map { $0.url },
                    source: "junk-clean"
                )
                let trashedURLs = Set(result.trashed)
                self?.items.removeAll { trashedURLs.contains($0.url) }
                self?.selectedIDs = []
                if result.failures.isEmpty {
                    self?.statusMessage = "已将 \(result.trashed.count) 项移到废纸篓。"
                } else {
                    self?.statusMessage = "已清理 \(result.trashed.count) 项；\(result.failures.count) 项失败（可能需要管理员权限）。"
                }
            } catch {
                self?.errorMessage = error.localizedDescription
            }
            self?.isCleaning = false
        }
    }
}

// MARK: - View

struct JunkCleaningView: View {

    @State private var model = JunkCleaningViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .navigationTitle("垃圾清理")
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button { model.scan() } label: {
                Label("扫描垃圾", systemImage: "magnifyingglass")
            }
            .disabled(model.isScanning || model.isCleaning)

            Spacer()

            if !model.items.isEmpty {
                Text("已选 \(ByteSize.formatted(model.selectedSize)) / 共 \(ByteSize.formatted(model.totalFoundSize))")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Button { model.cleanSelected() } label: {
                    Label("清理所选", systemImage: "trash")
                }
                .disabled(model.selectedSize == 0 || model.isCleaning)
            }
        }
        .padding(10)
        .disabled(model.isScanning)
    }

    @ViewBuilder
    private var content: some View {
        if model.isScanning {
            scanningView
        } else if model.isCleaning {
            centeredProgress("正在移到废纸篓…")
        } else if model.items.isEmpty {
            emptyState
        } else {
            itemList
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if model.hasScanned {
            ContentUnavailableView("没有发现可清理的垃圾", systemImage: "checkmark.circle")
        } else {
            ContentUnavailableView {
                Label("垃圾清理", systemImage: "trash")
            } description: {
                Text("扫描缓存、日志、临时文件等可安全回收的内容。")
            } actions: {
                Button("扫描垃圾") { model.scan() }
            }
        }
    }

    private var scanningView: some View {
        VStack(spacing: 14) {
            ProgressView()
            if let progress = model.scanProgress {
                Text("已发现 \(progress.itemsFound) 项 · \(ByteSize.formatted(progress.bytesFound))")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                if !progress.currentRule.isEmpty {
                    Text("正在检查：\(progress.currentRule)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("正在扫描垃圾文件…").foregroundStyle(.secondary)
            }
            Button("取消", role: .cancel) { model.cancelScan() }
                .keyboardShortcut(.escape, modifiers: [])
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
    }

    private var itemList: some View {
        List {
            if let status = model.statusMessage {
                Text(status).foregroundStyle(.secondary)
            }
            if let error = model.errorMessage {
                Text(error).foregroundStyle(.red)
            }
            ForEach(model.groupedItems, id: \.category) { group in
                Section(categoryTitle(group.category)) {
                    ForEach(group.items) { item in
                        itemRow(item)
                    }
                }
            }
        }
    }

    private func itemRow(_ item: JunkItem) -> some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { model.isSelected(item) },
                set: { _ in model.toggle(item) }
            ))
            .labelsHidden()

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).lineLimit(1)
                HStack(spacing: 6) {
                    Text(item.rule.name)
                    if item.rule.safety == .reviewNeeded {
                        Text("需确认")
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.25), in: Capsule())
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(ByteSize.formatted(item.size))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }

    private func centeredProgress(_ text: String) -> some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(text).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func categoryTitle(_ category: JunkCategory) -> String {
        switch category {
        case .userCache:           "用户缓存"
        case .logs:                "日志"
        case .trash:               "废纸篓"
        case .browserCache:        "浏览器缓存"
        case .developerJunk:       "开发者垃圾"
        case .packageManagerCache: "包管理器缓存"
        case .oldDeviceBackup:     "设备备份"
        case .mailDownloads:       "邮件下载"
        case .systemCache:         "系统缓存"
        case .largeOldDownloads:   "旧下载文件"
        }
    }
}
