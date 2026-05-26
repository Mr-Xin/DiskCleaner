//
//  HistoryView.swift
//  DiskCleaner
//
//  Sprint v1.2 polish — scan history restyled with DiskFlow tokens.
//
//  Layout: top chart card (Swift Charts) + recent-snapshot list with
//  per-row glass card. Cleanup history (deletions by feature) lives in
//  the dedicated AuditLogView screen.
//

import SwiftUI
import Charts
import Observation
import DiskCleanerCore

// MARK: - View Model

@MainActor
@Observable
final class HistoryViewModel {

    var snapshots: [ScanSnapshot] = []
    var isLoading = false

    func load() {
        isLoading = true
        Task { [weak self] in
            let loaded = await ScanHistoryStore.shared.loadAll(limit: 500)
            self?.snapshots = loaded
            self?.isLoading = false
        }
    }

    func clearHistory() {
        Task { [weak self] in
            await ScanHistoryStore.shared.clear()
            self?.snapshots = []
        }
    }
}

// MARK: - View

struct HistoryView: View {

    @State private var model = HistoryViewModel()

    var body: some View {
        VStack(spacing: 0) {
            actionBar
            Divider().background(DesignTokens.Palette.line1)
            content
        }
        .onAppear {
            if model.snapshots.isEmpty { model.load() }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            DesignButton(.ghost, size: .small, action: { model.load() }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("history.action.reload")
                }
            }
            Spacer()
            if !model.snapshots.isEmpty {
                DesignChip {
                    Text(verbatim: String(
                        format: NSLocalizedString("history.chip.snapshots", comment: ""),
                        model.snapshots.count
                    ))
                }
                DesignButton(.danger, size: .small, action: { model.clearHistory() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("history.action.clear")
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .disabled(model.isLoading)
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading {
            LoadingStateView(
                percent: 0, itemsIndexed: 0, duplicateGroups: 0,
                reclaimableBytes: 0, currentPath: ""
            )
        } else if model.snapshots.isEmpty {
            ContentUnavailableView(
                "history.empty.title", systemImage: "chart.line.uptrend.xyaxis",
                description: Text("history.empty.body")
            )
            .padding()
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    chartCard
                    snapshotsCard
                }
                .padding(20)
            }
        }
    }

    private var chartCard: some View {
        DesignCard(.elevated, padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("history.chart.title")
                        .font(DesignTokens.Typography.h2)
                        .foregroundStyle(DesignTokens.Palette.text1)
                    Spacer()
                }
                chart
                    .frame(height: 240)
            }
        }
    }

    private var chart: some View {
        Chart(model.snapshots.sorted(by: { $0.timestamp < $1.timestamp })) { snapshot in
            LineMark(
                x: .value("时间", snapshot.timestamp),
                y: .value("大小", Double(snapshot.totalAllocatedBytes))
            )
            .foregroundStyle(by: .value("路径", snapshot.rootPath))
            .interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: 2))

            PointMark(
                x: .value("时间", snapshot.timestamp),
                y: .value("大小", Double(snapshot.totalAllocatedBytes))
            )
            .foregroundStyle(by: .value("路径", snapshot.rootPath))
            .symbolSize(40)
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                    .foregroundStyle(DesignTokens.Palette.line1)
                AxisValueLabel {
                    if let bytes = value.as(Double.self) {
                        Text(verbatim: ByteSize.formatted(Int64(bytes)))
                            .font(.system(size: 9))
                            .foregroundStyle(DesignTokens.Palette.text4)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                    .foregroundStyle(DesignTokens.Palette.line1)
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
    }

    private var snapshotsCard: some View {
        DesignCard(.default, padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("history.list.title")
                        .font(DesignTokens.Typography.label)
                        .foregroundStyle(DesignTokens.Palette.text4)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Spacer()
                }
                .padding(16)
                Rectangle()
                    .fill(DesignTokens.Palette.line1)
                    .frame(height: 1)
                ForEach(Array(model.snapshots.prefix(50).enumerated()), id: \.element.id) { idx, snapshot in
                    snapshotRow(snapshot)
                    if idx < min(50, model.snapshots.count) - 1 {
                        Rectangle()
                            .fill(DesignTokens.Palette.line1.opacity(0.4))
                            .frame(height: 1)
                    }
                }
            }
        }
    }

    private func snapshotRow(_ snapshot: ScanSnapshot) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.Palette.text3)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: snapshot.rootPath)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(DesignTokens.Palette.text1)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(snapshot.timestamp,
                     format: .dateTime.year().month().day().hour().minute())
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(DesignTokens.Palette.text3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(verbatim: ByteSize.formatted(snapshot.totalAllocatedBytes))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Palette.text1)
                Text(verbatim: String(
                    format: NSLocalizedString("history.row.items", comment: ""),
                    snapshot.itemCount
                ))
                .font(.system(size: 10.5))
                .foregroundStyle(DesignTokens.Palette.text3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

#Preview {
    HistoryView()
        .frame(width: 980, height: 720)
        .background(MeshGradientBackground())
        .preferredColorScheme(.dark)
}
