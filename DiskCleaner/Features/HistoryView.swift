//
//  HistoryView.swift
//  DiskCleaner
//
//  Feature 5 — scan history: shows every scan as a trend line (Swift Charts)
//  plus a list of past snapshots with timestamp, root path, and size.
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
            header
            Divider()
            content
        }
        .navigationTitle("扫描历史")
        .onAppear {
            if model.snapshots.isEmpty { model.load() }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button { model.load() } label: {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            .disabled(model.isLoading)

            Spacer()

            if !model.snapshots.isEmpty {
                Button(role: .destructive) { model.clearHistory() } label: {
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
        } else if model.snapshots.isEmpty {
            ContentUnavailableView {
                Label("还没有扫描记录", systemImage: "chart.line.uptrend.xyaxis")
            } description: {
                Text("每次扫描完成后会自动保存一个快照，在这里查看时间维度上的变化。")
            }
        } else {
            VSplitView {
                chartView
                    .frame(minHeight: 240)
                snapshotList
                    .frame(minHeight: 160)
            }
        }
    }

    private var chartView: some View {
        Chart(model.snapshots.sorted(by: { $0.timestamp < $1.timestamp })) { snapshot in
            LineMark(
                x: .value("时间", snapshot.timestamp),
                y: .value("大小", Double(snapshot.totalAllocatedBytes))
            )
            .foregroundStyle(by: .value("路径", snapshot.rootPath))
            .interpolationMethod(.monotone)

            PointMark(
                x: .value("时间", snapshot.timestamp),
                y: .value("大小", Double(snapshot.totalAllocatedBytes))
            )
            .foregroundStyle(by: .value("路径", snapshot.rootPath))
            .symbolSize(35)
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let bytes = value.as(Double.self) {
                        Text(ByteSize.formatted(Int64(bytes)))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .padding()
    }

    private var snapshotList: some View {
        List(model.snapshots) { snapshot in
            HStack(spacing: 10) {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.rootPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(snapshot.timestamp,
                         format: .dateTime.year().month().day().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(ByteSize.formatted(snapshot.totalAllocatedBytes))
                        .monospacedDigit()
                    Text("\(snapshot.itemCount) 项")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    HistoryView()
}
