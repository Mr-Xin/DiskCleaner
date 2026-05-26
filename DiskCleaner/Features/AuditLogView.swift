//
//  AuditLogView.swift
//  DiskCleaner
//
//  "最近操作" — shows the deletion audit log written by `AuditLog`.
//

import SwiftUI
import AppKit
import Observation
import DiskCleanerCore

// MARK: - View Model

@MainActor
@Observable
final class AuditLogViewModel {

    var entries: [AuditEntry] = []
    var isLoading = false

    func load() {
        isLoading = true
        Task {
            let recent = await AuditLog.shared.readRecent(limit: AppSettings.auditLogMaxEntries())
            self.entries = recent
            self.isLoading = false
        }
    }

    func clearLog() {
        Task {
            await AuditLog.shared.clear()
            self.entries = []
        }
    }

    func revealLogFile() {
        NSWorkspace.shared.activateFileViewerSelecting([AuditLog.shared.fileURL])
    }

    func revealItem(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

// MARK: - View

struct AuditLogView: View {

    @State private var model = AuditLogViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .navigationTitle("最近操作")
        .onAppear {
            if model.entries.isEmpty { model.load() }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button { model.load() } label: {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            .disabled(model.isLoading)

            Spacer()

            if !model.entries.isEmpty {
                Button { model.revealLogFile() } label: {
                    Label("在访达中显示日志", systemImage: "doc")
                }
                Button(role: .destructive) {
                    model.clearLog()
                } label: {
                    Label("清空", systemImage: "trash")
                }
            }
        }
        .padding(10)
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.entries.isEmpty {
            ContentUnavailableView {
                Label("还没有操作记录", systemImage: "clock.arrow.circlepath")
            } description: {
                Text("DiskCleaner 每次把文件移到废纸篓时，都会记录在这里。")
            }
        } else {
            List(model.entries) { entry in
                row(entry)
            }
        }
    }

    private func row(_ entry: AuditEntry) -> some View {
        HStack(spacing: 10) {
            Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(entry.success ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.url.lastPathComponent).lineLimit(1)
                HStack(spacing: 6) {
                    Text(entry.url.deletingLastPathComponent().path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text("·")
                    Text(sourceLabel(entry.source))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(ByteSize.formatted(entry.sizeBytes))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Text(entry.timestamp, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button("在访达中显示") { model.revealItem(entry.url) }
        }
    }

    private func sourceLabel(_ source: String) -> String {
        switch source {
        case "disk-map":   "磁盘可视化"
        case "junk-clean": "垃圾清理"
        case "duplicates": "重复文件"
        case "uninstall":  "应用卸载"
        default:           source
        }
    }
}

#Preview {
    AuditLogView()
}
