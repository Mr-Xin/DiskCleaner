//
//  UninstallView.swift
//  DiskCleaner
//
//  Feature 4 — application uninstaller: list installed apps, find the files
//  each leaves behind, and move the app plus its leftovers to the Trash.
//

import SwiftUI
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

    var selectedApp: InstalledApp? {
        guard let id = selectedAppID else { return nil }
        return apps.first { $0.id == id }
    }

    var selectedLeftoverCount: Int {
        leftoverSelection.count
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
            do {
                let result = try await DeletionService().moveToTrash(targets, source: "uninstall")
                if result.failures.isEmpty {
                    self?.statusMessage = "已将 \(app.name) 及 \(leftoverURLs.count) 个关联文件移到废纸篓。"
                } else {
                    self?.statusMessage = "已移除 \(result.trashed.count) 项；\(result.failures.count) 项失败（应用本体可能需要管理员权限）。"
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

    var body: some View {
        HSplitView {
            appList
                .frame(minWidth: 220, idealWidth: 260)
            detail
                .frame(minWidth: 340)
        }
        .navigationTitle("应用卸载")
        .onAppear {
            if model.apps.isEmpty { model.loadApps() }
        }
    }

    private var appList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("已安装应用").font(.headline)
                Spacer()
                Button { model.loadApps() } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(model.isLoadingApps)
            }
            .padding(8)
            Divider()

            if model.isLoadingApps {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(model.apps, selection: Binding(
                    get: { model.selectedAppID },
                    set: { newID in
                        if let newID, let app = model.apps.first(where: { $0.id == newID }) {
                            model.selectApp(app)
                        }
                    }
                )) { app in
                    HStack(spacing: 8) {
                        Image(systemName: "app.dashed")
                            .foregroundStyle(.secondary)
                        Text(app.name).lineLimit(1)
                    }
                    .tag(app.id)
                }
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let app = model.selectedApp {
            VStack(spacing: 0) {
                appHeader(app)
                Divider()
                if model.isLoadingLeftovers {
                    ProgressView("查找关联文件…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    leftoversList
                }
                Divider()
                footer(app)
            }
        } else {
            ContentUnavailableView(
                "选择一个应用",
                systemImage: "app.dashed",
                description: Text("从左侧选择要卸载的应用，DiskCleaner 会找出它的残留文件。")
            )
        }
    }

    private func appHeader(_ app: InstalledApp) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "app.dashed")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(app.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
    }

    private var leftoversList: some View {
        List {
            if let status = model.statusMessage {
                Text(status).foregroundStyle(.secondary)
            }
            if let error = model.lastError {
                ErrorView(error: error)
            }

            let highConfidence = model.leftovers.filter { $0.confidence == .high }
            let lowConfidence = model.leftovers.filter { $0.confidence == .low }

            if model.leftovers.isEmpty && model.lastError == nil {
                Text("没有找到明显的关联文件。")
                    .foregroundStyle(.secondary)
            }
            if !highConfidence.isEmpty {
                Section("高匹配度（建议清理）") {
                    ForEach(highConfidence) { leftoverRow($0) }
                }
            }
            if !lowConfidence.isEmpty {
                Section("低匹配度（请确认）") {
                    ForEach(lowConfidence) { leftoverRow($0) }
                }
            }
        }
    }

    private func leftoverRow(_ file: LeftoverFile) -> some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { model.isLeftoverSelected(file) },
                set: { _ in model.toggleLeftover(file) }
            ))
            .labelsHidden()

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
    }

    private func footer(_ app: InstalledApp) -> some View {
        HStack {
            Text("将移除应用本体 + 选中的 \(model.selectedLeftoverCount) 个关联文件")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button(role: .destructive) {
                model.uninstall()
            } label: {
                Label("卸载并清理", systemImage: "trash")
            }
            .disabled(model.isUninstalling)
        }
        .padding(10)
    }
}
