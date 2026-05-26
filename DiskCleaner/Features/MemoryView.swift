//
//  MemoryView.swift
//  DiskCleaner
//
//  Sprint 6 — Memory Monitor per DiskFlow §4.2.
//
//  Top row: 4 stat cards (In use · Cached · Swap · CPU), each with a 24pt
//  sparkline. Below: a 60-second line chart (RAM + CPU) and a small "real
//  process listing requires admin entitlements — not in this build" notice
//  card. Polling cadence: 1 Hz, kept in a 60-sample ring buffer.
//
//  All data comes from Mach `host_statistics64`, `sysctlbyname("vm.swapusage")`,
//  and `processor_info(PROCESSOR_CPU_LOAD_INFO)` — no Full Disk Access or
//  other entitlement is required for these aggregate metrics.
//

import SwiftUI
import Charts
import Observation
import Darwin

// MARK: - Sample types

struct MemorySample: Identifiable {
    let id = UUID()
    let timestamp: Date
    /// Bytes in active + wired + compressor — what users think of as "in use".
    let usedBytes: UInt64
    /// File-backed pages — purgeable.
    let cachedBytes: UInt64
    /// Wired (resident system).
    let wiredBytes: UInt64
    /// Compressed memory pool footprint.
    let compressedBytes: UInt64
    /// Total physical RAM.
    let totalBytes: UInt64
    /// 0…1.
    let cpuPercent: Double
    /// Swap used in bytes.
    let swapBytes: UInt64
}

// MARK: - One-shot reader (Dashboard mini)

/// Free function so the Dashboard mini can grab a single snapshot without
/// owning a polling timer. Returns nil on failure (no entitlement issues
/// today — `host_statistics64` is unrestricted).
@MainActor
func readMemorySampleOnce() -> MemorySample? {
    let reader = MemoryStatsModel()
    return reader.readSampleSnapshot()
}

// MARK: - Stats service

@MainActor
@Observable
final class MemoryStatsModel {

    var samples: [MemorySample] = []
    var isMonitoring: Bool = false

    /// Last 60 samples are retained for the 60s chart window.
    private let bufferLimit = 60

    @ObservationIgnored private var timer: Timer?

    /// Cached previous CPU ticks for delta-based usage calculation.
    @ObservationIgnored private var prevCPUTicks: (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64) = (0, 0, 0, 0)

    var latest: MemorySample? { samples.last }

    func start() {
        guard !isMonitoring else { return }
        isMonitoring = true
        // Seed an initial sample so the cards show data immediately.
        if let sample = readSample(initial: true) {
            samples.append(sample)
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func tick() {
        guard let sample = readSample(initial: false) else { return }
        samples.append(sample)
        if samples.count > bufferLimit { samples.removeFirst(samples.count - bufferLimit) }
    }

    /// One-shot snapshot for callers that don't need polling (e.g. the
    /// Dashboard memory mini-card). Sets `initial: true` so the CPU delta
    /// doesn't read from a zeroed cache.
    func readSampleSnapshot() -> MemorySample? {
        readSample(initial: true)
    }

    // MARK: - Mach calls

    private func readSample(initial: Bool) -> MemorySample? {
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64_data_t()
        let host = mach_host_self()
        let result: kern_return_t = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { ptr in
                host_statistics64(host, HOST_VM_INFO64, ptr, &size)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let pageSize = UInt64(vm_kernel_page_size)

        let activeBytes      = UInt64(vmStats.active_count)      * pageSize
        let wiredBytes       = UInt64(vmStats.wire_count)        * pageSize
        let compressedBytes  = UInt64(vmStats.compressor_page_count) * pageSize
        let inactiveBytes    = UInt64(vmStats.inactive_count)    * pageSize
        let purgeableBytes   = UInt64(vmStats.purgeable_count)   * pageSize

        let usedBytes = activeBytes + wiredBytes + compressedBytes
        let cachedBytes = max(0, Int64(inactiveBytes + purgeableBytes))
        let totalBytes = ProcessInfo.processInfo.physicalMemory

        // CPU — derive from delta of host_cpu_load_info ticks.
        let cpu = readCPUUsage(initial: initial)

        // Swap usage via sysctl.
        let swapBytes = readSwapUsed()

        return MemorySample(
            timestamp: Date(),
            usedBytes: usedBytes,
            cachedBytes: UInt64(cachedBytes),
            wiredBytes: wiredBytes,
            compressedBytes: compressedBytes,
            totalBytes: totalBytes,
            cpuPercent: cpu,
            swapBytes: swapBytes
        )
    }

    private func readCPUUsage(initial: Bool) -> Double {
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        var info = host_cpu_load_info_data_t()
        let host = mach_host_self()
        let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { ptr in
                host_statistics(host, HOST_CPU_LOAD_INFO, ptr, &size)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }

        let user   = UInt64(info.cpu_ticks.0)
        let system = UInt64(info.cpu_ticks.1)
        let idle   = UInt64(info.cpu_ticks.2)
        let nice   = UInt64(info.cpu_ticks.3)

        defer { prevCPUTicks = (user, system, idle, nice) }
        guard !initial else { return 0 }

        let dUser   = user   &- prevCPUTicks.user
        let dSystem = system &- prevCPUTicks.system
        let dIdle   = idle   &- prevCPUTicks.idle
        let dNice   = nice   &- prevCPUTicks.nice
        let totalTicks = dUser + dSystem + dIdle + dNice
        guard totalTicks > 0 else { return 0 }
        let busy = dUser + dSystem + dNice
        return Double(busy) / Double(totalTicks)
    }

    private func readSwapUsed() -> UInt64 {
        var swap = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        let result = sysctlbyname("vm.swapusage", &swap, &size, nil, 0)
        guard result == 0 else { return 0 }
        return swap.xsu_used
    }
}

// MARK: - View

struct MemoryView: View {

    @State private var model = MemoryStatsModel()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header
                statsRow
                liveChartCard
                processCard
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("memory.title")
                    .font(DesignTokens.Typography.h1)
                    .foregroundStyle(DesignTokens.Palette.text1)
                Text("memory.subtitle")
                    .font(.system(size: 12.5))
                    .foregroundStyle(DesignTokens.Palette.text3)
            }
            Spacer()
            if let latest = model.latest {
                DesignChip(memoryChipVariant(latest), showsDot: true) {
                    Text(memoryChipTitle(latest))
                }
            }
        }
    }

    private func memoryChipVariant(_ s: MemorySample) -> DesignChipVariant {
        let pct = Double(s.usedBytes) / Double(max(s.totalBytes, 1))
        switch pct {
        case ..<0.6: return .good
        case 0.6..<0.85: return .warn
        default: return .danger
        }
    }

    private func memoryChipTitle(_ s: MemorySample) -> LocalizedStringKey {
        let pct = Double(s.usedBytes) / Double(max(s.totalBytes, 1))
        switch pct {
        case ..<0.6: return "memory.status.good"
        case 0.6..<0.85: return "memory.status.warn"
        default: return "memory.status.danger"
        }
    }

    // MARK: Stats row

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(
                titleKey: "memory.stat.in_use",
                value: ByteSizeFormatter.short(Int64(model.latest?.usedBytes ?? 0)),
                color: DesignTokens.Palette.blueHi,
                values: model.samples.map { Double($0.usedBytes) }
            )
            statCard(
                titleKey: "memory.stat.cached",
                value: ByteSizeFormatter.short(Int64(model.latest?.cachedBytes ?? 0)),
                color: DesignTokens.Palette.cyan,
                values: model.samples.map { Double($0.cachedBytes) }
            )
            statCard(
                titleKey: "memory.stat.swap",
                value: ByteSizeFormatter.short(Int64(model.latest?.swapBytes ?? 0)),
                color: DesignTokens.Palette.purple,
                values: model.samples.map { Double($0.swapBytes) }
            )
            statCard(
                titleKey: "memory.stat.cpu",
                value: String(format: "%.0f%%", (model.latest?.cpuPercent ?? 0) * 100),
                color: DesignTokens.Palette.good,
                values: model.samples.map { $0.cpuPercent * 100 }
            )
        }
    }

    private func statCard(titleKey: LocalizedStringKey, value: String, color: Color, values: [Double]) -> some View {
        DesignCard(.elevated, padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(titleKey)
                        .font(DesignTokens.Typography.label)
                        .foregroundStyle(DesignTokens.Palette.text4)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Spacer()
                    Circle().fill(color).frame(width: 6, height: 6).shadow(color: color, radius: 3)
                }
                Text(verbatim: value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(DesignTokens.Palette.text1)
                    .tracking(-0.4)
                sparkline(values: values, color: color)
                    .frame(height: 24)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func sparkline(values: [Double], color: Color) -> some View {
        Chart {
            ForEach(Array(values.enumerated()), id: \.offset) { idx, v in
                LineMark(x: .value("t", idx), y: .value("v", v))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(color)
                AreaMark(x: .value("t", idx), y: .value("v", v))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.35), color.opacity(0)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartPlotStyle { plot in plot.background(Color.clear) }
    }

    // MARK: Live chart

    private var liveChartCard: some View {
        DesignCard(.elevated, padding: 18) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("memory.chart.title")
                        .font(DesignTokens.Typography.h2)
                        .foregroundStyle(DesignTokens.Palette.text1)
                    Spacer()
                    HStack(spacing: 10) {
                        legendDot(color: DesignTokens.Palette.blueHi, key: "memory.chart.legend.ram")
                        legendDot(color: DesignTokens.Palette.cyan,    key: "memory.chart.legend.cpu")
                    }
                }
                liveChart
                    .frame(height: 200)
            }
        }
    }

    private func legendDot(color: Color, key: LocalizedStringKey) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6).shadow(color: color, radius: 3)
            Text(key)
                .font(.system(size: 10.5))
                .foregroundStyle(DesignTokens.Palette.text3)
        }
    }

    private var liveChart: some View {
        let total = Double(model.latest?.totalBytes ?? 1)
        return Chart {
            ForEach(Array(model.samples.enumerated()), id: \.element.id) { idx, s in
                let ramPct = Double(s.usedBytes) / max(total, 1)
                LineMark(
                    x: .value("t", idx),
                    y: .value("ram", ramPct * 100)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(DesignTokens.Palette.blueHi)
                .lineStyle(StrokeStyle(lineWidth: 2))
                AreaMark(
                    x: .value("t", idx),
                    y: .value("ram", ramPct * 100)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [DesignTokens.Palette.blueHi.opacity(0.30),
                                 DesignTokens.Palette.blueHi.opacity(0)],
                        startPoint: .top, endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("t", idx),
                    y: .value("cpu", s.cpuPercent * 100)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(DesignTokens.Palette.cyan)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(DesignTokens.Palette.line1)
                AxisValueLabel {
                    if let n = value.as(Double.self) {
                        Text(verbatim: "\(Int(n))%")
                            .font(.system(size: 9))
                            .foregroundStyle(DesignTokens.Palette.text4)
                    }
                }
            }
        }
    }

    // MARK: Process placeholder

    private var processCard: some View {
        DesignCard(.default, padding: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle")
                    .foregroundStyle(DesignTokens.Palette.blueHi)
                VStack(alignment: .leading, spacing: 4) {
                    Text("memory.process.title")
                        .font(DesignTokens.Typography.h3)
                        .foregroundStyle(DesignTokens.Palette.text1)
                    Text("memory.process.body")
                        .font(.system(size: 11.5))
                        .foregroundStyle(DesignTokens.Palette.text3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
        }
    }
}

#Preview {
    MemoryView()
        .frame(width: 1180, height: 720)
        .background(MeshGradientBackground())
        .preferredColorScheme(.dark)
}
