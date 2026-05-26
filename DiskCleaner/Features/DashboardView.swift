//
//  DashboardView.swift
//  DiskCleaner
//
//  Sprint 2: the Overview / Dashboard screen. Mirrors `hifi-dashboard.jsx`
//  in `design_handoff_diskflow`:
//    • Greeting row with volume chip + health chip
//    • 1.5fr / 1fr grid: Donut + breakdown legend  /  Health card + Memory mini
//    • 3-up Smart Cleanup suggestion cards
//
//  The view is intentionally driven by a lightweight `DashboardSnapshot`
//  value type so we can later wire in real data from `DiskCleanerCore`
//  without touching the view. For now it builds a placeholder snapshot
//  from the actual root volume capacity (the same one the sidebar uses).
//

import SwiftUI
import DiskCleanerCore

// MARK: - Snapshot

/// Per-category slice for the Dashboard donut + legend.
struct DashboardCategorySlice: Identifiable {
    let id = UUID()
    let titleKey: LocalizedStringKey
    let color: Color
    let bytes: Int64
    let percent: Double  // 0...100, of the total volume
}

/// Smart Cleanup suggestion card content.
struct DashboardSuggestion: Identifiable {
    let id = UUID()
    let tagKey: LocalizedStringKey
    let titleKey: LocalizedStringKey
    let descKey: LocalizedStringKey
    let bytes: Int64
    let glyph: DesignGlyphKind
    let code: String
}

/// Plain-data snapshot of everything the Dashboard needs to render.
/// All bytes are absolute; the view computes percents off `totalBytes`.
struct DashboardSnapshot {
    var userDisplayName: String
    var deviceLabel: String
    var lastScanAt: Date?
    var indexedFiles: Int?
    var volumeName: String

    var totalBytes: Int64
    var usedBytes: Int64
    var categories: [DashboardCategorySlice]

    var healthScore: Int        // 0–100
    var healthDeltaThisWeek: Int  // can be 0 / negative / positive
    var quickWinsCount: Int
    var reclaimableBytes: Int64

    var memoryEnabled: Bool
    var memoryTotalBytes: Int64
    var memoryUsedBytes: Int64

    var suggestions: [DashboardSuggestion]
}

// MARK: - Placeholder snapshot

extension DashboardSnapshot {

    /// Build a sensible placeholder snapshot from the live root volume
    /// + DiskCleaner sample suggestion content. Replace with engine-driven
    /// data as Sprints 3+ wire it up.
    static func placeholder() -> DashboardSnapshot {
        let (used, free, label) = mainVolumeUsage()
        let total = used + free

        // Same ratios used by `ContentView.placeholderBreakdown()`. When the
        // real category engine lands these will come from `ScanSnapshot`.
        let ratios: [(LocalizedStringKey, Color, Double)] = [
            ("dashboard.category.apps",   DesignTokens.Palette.catApps,   0.22),
            ("dashboard.category.docs",   DesignTokens.Palette.catDocs,   0.14),
            ("dashboard.category.video",  DesignTokens.Palette.catVideo,  0.10),
            ("dashboard.category.photo",  DesignTokens.Palette.catPhoto,  0.08),
            ("dashboard.category.system", DesignTokens.Palette.catSystem, 0.07),
            ("dashboard.category.cache",  DesignTokens.Palette.catCache,  0.04),
        ]
        let categories: [DashboardCategorySlice] = ratios.map { (key, color, ratio) in
            DashboardCategorySlice(
                titleKey: key,
                color: color,
                bytes: Int64(Double(total) * ratio),
                percent: ratio * 100
            )
        }

        // Suggestion content uses i18n keys; sizes are placeholder until
        // the engine surfaces real ones.
        let suggestions: [DashboardSuggestion] = [
            .init(
                tagKey:   "dashboard.smart.tag.cache",
                titleKey: "dashboard.smart.sample.xcode.title",
                descKey:  "dashboard.smart.sample.xcode.desc",
                bytes:    Int64(6.2 * 1_073_741_824),
                glyph:    .cache,
                code:     "XCD"
            ),
            .init(
                tagKey:   "dashboard.smart.tag.downloads",
                titleKey: "dashboard.smart.sample.downloads.title",
                descKey:  "dashboard.smart.sample.downloads.desc",
                bytes:    Int64(3.8 * 1_073_741_824),
                glyph:    .folder,
                code:     "DWN"
            ),
            .init(
                tagKey:   "dashboard.smart.tag.photos",
                titleKey: "dashboard.smart.sample.duppics.title",
                descKey:  "dashboard.smart.sample.duppics.desc",
                bytes:    Int64(2.4 * 1_073_741_824),
                glyph:    .photo,
                code:     "PIC"
            )
        ]
        let totalReclaim = suggestions.reduce(Int64(0)) { $0 + $1.bytes }

        return DashboardSnapshot(
            userDisplayName: macUserDisplayName(),
            deviceLabel: macDeviceLabel(),
            lastScanAt: nil,
            indexedFiles: nil,
            volumeName: label,
            totalBytes: total,
            usedBytes: used,
            categories: categories,
            healthScore: 82,
            healthDeltaThisWeek: 6,
            quickWinsCount: suggestions.count,
            reclaimableBytes: totalReclaim,
            memoryEnabled: false,
            memoryTotalBytes: 0,
            memoryUsedBytes: 0,
            suggestions: suggestions
        )
    }

    private static func mainVolumeUsage() -> (used: Int64, free: Int64, label: String) {
        let url = URL(fileURLWithPath: "/")
        let keys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeNameKey
        ]
        guard let values = try? url.resourceValues(forKeys: keys) else {
            return (used: 0, free: 0, label: "Macintosh HD")
        }
        let total = Int64(values.volumeTotalCapacity ?? 0)
        let free = Int64(values.volumeAvailableCapacity ?? 0)
        let used = max(0, total - free)
        return (used: used, free: free, label: values.volumeName ?? "Macintosh HD")
    }

    private static func macUserDisplayName() -> String {
        // `NSFullUserName()` returns the macOS "long name" (e.g. "Alex Chen").
        // Trim whitespace; fall back to short user name if empty.
        let full = NSFullUserName().trimmingCharacters(in: .whitespaces)
        return full.isEmpty ? NSUserName() : full
    }

    private static func macDeviceLabel() -> String {
        // Use the host name's first component as a friendly label. The
        // real device model ("MacBook Pro 14\"") will come from IOKit
        // when we wire engine data in a later Sprint.
        let host = ProcessInfo.processInfo.hostName
        if let first = host.components(separatedBy: ".").first, !first.isEmpty {
            return first
        }
        return "Mac"
    }
}

// MARK: - View

struct DashboardView: View {

    @State private var snapshot: DashboardSnapshot = .placeholder()
    /// Shared scan store. When non-nil and scanned, its data replaces the
    /// snapshot's placeholder reclaim numbers + suggestion cards.
    let store: JunkScanStore?
    /// Tapped from the Health Score card's "Run smart cleanup" primary CTA.
    var onRunSmartCleanup: () -> Void = {}
    /// Tapped from the Smart Cleanup section's "查看全部 →" ghost button.
    var onViewAllSuggestions: () -> Void = {}

    init(
        store: JunkScanStore? = nil,
        onRunSmartCleanup: @escaping () -> Void = {},
        onViewAllSuggestions: @escaping () -> Void = {}
    ) {
        self.store = store
        self.onRunSmartCleanup = onRunSmartCleanup
        self.onViewAllSuggestions = onViewAllSuggestions
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                greetingRow
                mainGrid
                smartCleanupSection
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .task {
            // Background scan on first appearance — Dashboard quietly
            // upgrades from placeholders to real numbers when ready.
            await store?.ensureScanned()
        }
        .task {
            // Sample memory once on appear so the mini card shows live data
            // without spinning up the polling timer that Memory Monitor uses.
            if let sample = readMemorySampleOnce() {
                snapshot.memoryEnabled = true
                snapshot.memoryTotalBytes = Int64(sample.totalBytes)
                snapshot.memoryUsedBytes = Int64(sample.usedBytes)
            }
        }
    }

    /// Reclaimable bytes from real scan when available, otherwise the
    /// snapshot's placeholder value.
    private var effectiveReclaimableBytes: Int64 {
        if let s = store, s.hasScanned {
            return s.totalReclaimableBytes
        }
        return snapshot.reclaimableBytes
    }

    private var effectiveQuickWinsCount: Int {
        if let s = store, s.hasScanned {
            return s.totalItemCount
        }
        return snapshot.quickWinsCount
    }

    /// Top-3 categories by bytes once we have a real scan; otherwise the
    /// snapshot's three placeholder cards.
    private var effectiveSuggestions: [DashboardSuggestion] {
        guard let s = store, s.hasScanned else { return snapshot.suggestions }
        let categories = s.categories
            .filter { !$0.items.isEmpty && $0.items.contains(where: { $0.url != nil }) }
            .sorted { lhs, rhs in
                let l = lhs.items.reduce(Int64(0)) { $0 + $1.bytes }
                let r = rhs.items.reduce(Int64(0)) { $0 + $1.bytes }
                return l > r
            }
            .prefix(3)
        guard !categories.isEmpty else { return snapshot.suggestions }
        return categories.map { cat in
            let bytes = cat.items.reduce(Int64(0)) { $0 + $1.bytes }
            let topItem = cat.items
                .filter { $0.url != nil }
                .max(by: { $0.bytes < $1.bytes })
            return DashboardSuggestion(
                tagKey: cat.titleKey,
                titleKey: LocalizedStringKey(topItem?.name ?? cat.titleDisplay),
                descKey: cat.summaryKey,
                bytes: bytes,
                glyph: cat.glyph,
                code: String((topItem?.name ?? cat.titleDisplay).prefix(3)).uppercased()
            )
        }
    }

    // MARK: Greeting

    private var greetingRow: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                (Text(greetingKey) + Text(verbatim: "，\(snapshot.userDisplayName)"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(DesignTokens.Palette.text1)
                subtitleView
                    .font(.system(size: 12.5))
                    .foregroundStyle(DesignTokens.Palette.text3)
            }
            Spacer(minLength: 12)
            HStack(spacing: 8) {
                DesignChip { Text(verbatim: snapshot.volumeName) }
                DesignChip(healthChipVariant, showsDot: true) {
                    Text(verbatim: String(
                        format: NSLocalizedString("dashboard.chip.healthy", comment: ""),
                        snapshot.healthScore
                    ))
                }
            }
        }
    }

    private var greetingKey: LocalizedStringKey {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12:  return "dashboard.greeting.morning"
        case 12..<18: return "dashboard.greeting.afternoon"
        default:      return "dashboard.greeting.evening"
        }
    }

    @ViewBuilder
    private var subtitleView: some View {
        if let last = snapshot.lastScanAt, let n = snapshot.indexedFiles {
            Text(verbatim: String(
                format: NSLocalizedString("dashboard.greeting.subtitle.indexed", comment: ""),
                snapshot.deviceLabel,
                relativeShort(last),
                Int64(n)
            ))
        } else {
            Text(verbatim: String(
                format: NSLocalizedString("dashboard.greeting.subtitle.unscanned", comment: ""),
                snapshot.deviceLabel
            ))
        }
    }

    private func relativeShort(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return String(localized: "dashboard.greeting.relative.just_now")
        }
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return String(format: NSLocalizedString("dashboard.greeting.relative.minutes", comment: ""), minutes)
        }
        let hours = minutes / 60
        if hours < 24 {
            return String(format: NSLocalizedString("dashboard.greeting.relative.hours", comment: ""), hours)
        }
        let days = hours / 24
        return String(format: NSLocalizedString("dashboard.greeting.relative.days", comment: ""), days)
    }

    private var healthChipVariant: DesignChipVariant {
        switch snapshot.healthScore {
        case ..<60: return .danger
        case 60..<80: return .warn
        default: return .good
        }
    }

    // MARK: Main grid

    private var mainGrid: some View {
        HStack(alignment: .top, spacing: 16) {
            storageCard
                .frame(maxWidth: .infinity)
                .layoutPriority(1.5)
            rightColumn
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
        }
    }

    private var storageCard: some View {
        DesignCard(.elevated, padding: 22) {
            ZStack(alignment: .topLeading) {
                // Soft blue glow behind the donut.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DesignTokens.Palette.blue.opacity(0.25),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 160
                        )
                    )
                    .frame(width: 280, height: 280)
                    .blur(radius: 20)
                    .offset(x: -60, y: -60)
                    .allowsHitTesting(false)

                HStack(alignment: .center, spacing: 24) {
                    donutColumn
                    legendColumn
                }
            }
        }
    }

    private var donutColumn: some View {
        let donutLabel: String = {
            let used = ByteSizeFormatter.short(snapshot.usedBytes)
            // Just the "312 GB" part — total goes into sub label.
            return used.replacingOccurrences(of: " ", with: "\u{00A0}")
        }()
        let subLabel: String = {
            let total = ByteSizeFormatter.short(snapshot.totalBytes)
            return String(
                format: NSLocalizedString("dashboard.donut.center.used_label", comment: ""),
                total
            )
        }()
        return DesignDonut(
            segments: snapshot.categories.map { DonutSegment(percent: $0.percent, color: $0.color) },
            size: 220,
            stroke: 26,
            label: donutLabel,
            subLabel: subLabel
        )
    }

    private var legendColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("dashboard.storage.title")
                    .font(DesignTokens.Typography.h2)
                    .foregroundStyle(DesignTokens.Palette.text1)
                Spacer(minLength: 8)
                Text(verbatim: String(
                    format: NSLocalizedString("dashboard.storage.category_count", comment: ""),
                    snapshot.categories.count
                ))
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(DesignTokens.Palette.text4)
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
            VStack(alignment: .leading, spacing: 10) {
                ForEach(snapshot.categories) { cat in
                    legendRow(cat)
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legendRow(_ cat: DashboardCategorySlice) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(cat.color)
                .frame(width: 10, height: 10)
                .shadow(color: cat.color.opacity(0.5), radius: 4)
            Text(cat.titleKey)
                .font(.system(size: 12.5))
                .foregroundStyle(DesignTokens.Palette.text1)
            Spacer(minLength: 8)
            Text(verbatim: ByteSizeFormatter.short(cat.bytes))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(DesignTokens.Palette.text2)
                .frame(width: 70, alignment: .trailing)
            Text(verbatim: "\(Int(cat.percent.rounded()))%")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(DesignTokens.Palette.text3)
                .frame(width: 36, alignment: .trailing)
        }
    }

    // MARK: Right column

    private var rightColumn: some View {
        VStack(spacing: 16) {
            healthCard
            memoryMiniCard
        }
    }

    private var healthCard: some View {
        DesignCard(.glowBlue, padding: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("dashboard.health.label")
                        .font(DesignTokens.Typography.label)
                        .foregroundStyle(DesignTokens.Palette.text4)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Spacer(minLength: 8)
                    DesignChip(healthChipVariant, showsDot: true) {
                        Text(healthStatusKey)
                    }
                }

                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(verbatim: "\(snapshot.healthScore)")
                        .font(.system(size: 64, weight: .bold))
                        .tracking(-1.5)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    .white,
                                    DesignTokens.Palette.blueHi,
                                    DesignTokens.Palette.cyan
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text("dashboard.health.over")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(DesignTokens.Palette.text3)
                    Spacer(minLength: 0)
                    if snapshot.healthDeltaThisWeek > 0 {
                        Label {
                            Text(verbatim: String(
                                format: NSLocalizedString("dashboard.health.delta.up", comment: ""),
                                snapshot.healthDeltaThisWeek
                            ))
                        } icon: {
                            Image(systemName: "arrow.up")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DesignTokens.Palette.good)
                    } else {
                        Text("dashboard.health.delta.flat")
                            .font(.system(size: 11))
                            .foregroundStyle(DesignTokens.Palette.text3)
                    }
                }

                DesignBar(fill: Double(snapshot.healthScore) / 100.0, variant: .good)

                Text(verbatim: String(
                    format: NSLocalizedString("dashboard.health.summary", comment: ""),
                    effectiveQuickWinsCount,
                    ByteSizeFormatter.short(effectiveReclaimableBytes)
                ))
                    .font(.system(size: 12.5))
                    .foregroundStyle(DesignTokens.Palette.text2)
                    .fixedSize(horizontal: false, vertical: true)

                DesignButton(.primary, action: runSmartCleanup) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                        Text("dashboard.health.cta.run")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var healthStatusKey: LocalizedStringKey {
        switch snapshot.healthScore {
        case ..<60: return "dashboard.health.status.danger"
        case 60..<80: return "dashboard.health.status.warn"
        default: return "dashboard.health.status.good"
        }
    }

    private var memoryMiniCard: some View {
        DesignCard(.default, padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("dashboard.memory.label")
                        .font(DesignTokens.Typography.label)
                        .foregroundStyle(DesignTokens.Palette.text4)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Spacer(minLength: 8)
                    if snapshot.memoryEnabled {
                        DesignChip(memoryChipVariant, showsDot: true) {
                            Text(memoryStatusKey)
                        }
                    } else {
                        DesignChip(showsDot: false) {
                            Text("dashboard.memory.unavailable")
                        }
                    }
                }

                if snapshot.memoryEnabled {
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(verbatim: ByteSizeFormatter.short(snapshot.memoryUsedBytes))
                            .font(.system(size: 26, weight: .bold))
                            .tracking(-0.4)
                            .foregroundStyle(DesignTokens.Palette.text1)
                        Text(verbatim: String(
                            format: NSLocalizedString("dashboard.memory.over", comment: ""),
                            ByteSizeFormatter.short(snapshot.memoryTotalBytes)
                        ))
                            .font(.system(size: 13))
                            .foregroundStyle(DesignTokens.Palette.text3)
                        Spacer(minLength: 0)
                        Text(verbatim: String(
                            format: NSLocalizedString("dashboard.memory.used_pct", comment: ""),
                            memoryUsedPercent
                        ))
                            .font(.system(size: 11))
                            .foregroundStyle(DesignTokens.Palette.text3)
                    }
                    DesignBar(fill: Double(memoryUsedPercent) / 100.0, variant: memoryBarVariant)
                } else {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundStyle(DesignTokens.Palette.text3)
                        Text("feature.memory")
                            .font(.system(size: 12.5))
                            .foregroundStyle(DesignTokens.Palette.text3)
                    }
                    DesignBar(fill: 0, variant: .default)
                        .opacity(0.5)
                }
            }
        }
    }

    private var memoryUsedPercent: Int {
        guard snapshot.memoryTotalBytes > 0 else { return 0 }
        let ratio = Double(snapshot.memoryUsedBytes) / Double(snapshot.memoryTotalBytes)
        return Int((ratio * 100).rounded())
    }

    private var memoryChipVariant: DesignChipVariant {
        switch memoryUsedPercent {
        case ..<60: return .good
        case 60..<85: return .warn
        default: return .danger
        }
    }

    private var memoryBarVariant: DesignBarVariant {
        switch memoryUsedPercent {
        case ..<60: return .good
        case 60..<85: return .warn
        default: return .danger
        }
    }

    private var memoryStatusKey: LocalizedStringKey {
        switch memoryUsedPercent {
        case ..<60: return "dashboard.memory.status.good"
        case 60..<85: return "dashboard.memory.status.warn"
        default: return "dashboard.memory.status.danger"
        }
    }

    // MARK: Smart Cleanup

    private var smartCleanupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(DesignTokens.Palette.blueHi)
                    Text("dashboard.smart.title")
                        .font(DesignTokens.Typography.h2)
                        .foregroundStyle(DesignTokens.Palette.text1)
                    Text(verbatim: String(
                        format: NSLocalizedString("dashboard.smart.summary", comment: ""),
                        effectiveQuickWinsCount,
                        ByteSizeFormatter.short(effectiveReclaimableBytes)
                    ))
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.Palette.text3)
                }
                Spacer(minLength: 8)
                DesignButton(.ghost, size: .small, action: viewAllSuggestions) {
                    HStack(spacing: 4) {
                        Text("dashboard.smart.view_all")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                }
            }

            HStack(alignment: .top, spacing: 12) {
                ForEach(effectiveSuggestions) { s in
                    suggestionCard(s)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func suggestionCard(_ s: DashboardSuggestion) -> some View {
        DesignCard(.elevated, padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 10) {
                    DesignGlyph(kind: s.glyph, code: s.code, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.tagKey)
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundStyle(DesignTokens.Palette.text4)
                            .textCase(.uppercase)
                            .tracking(0.8)
                        Text(s.titleKey)
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(DesignTokens.Palette.text1)
                    }
                    Spacer(minLength: 4)
                    Text(verbatim: ByteSizeFormatter.short(s.bytes))
                        .font(.system(size: 16, weight: .bold))
                        .tracking(-0.2)
                        .foregroundStyle(s.glyph.color)
                }

                Text(s.descKey)
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.Palette.text3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    DesignButton(.default, size: .small, action: { reviewSuggestion(s) }) {
                        Text("dashboard.smart.action.review")
                            .frame(maxWidth: .infinity)
                    }
                    DesignButton(.ghost, size: .small, action: { skipSuggestion(s) }) {
                        Text("dashboard.smart.action.skip")
                    }
                }
            }
        }
    }

    // MARK: Actions

    private func runSmartCleanup()    { onRunSmartCleanup() }
    private func viewAllSuggestions() { onViewAllSuggestions() }
    private func reviewSuggestion(_ s: DashboardSuggestion) { onViewAllSuggestions() }
    private func skipSuggestion(_ s: DashboardSuggestion)   { /* TBD */ }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .frame(width: 980, height: 720)
        .background(MeshGradientBackground())
        .preferredColorScheme(.dark)
}
