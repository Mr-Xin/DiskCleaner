//
//  SmartCleanupView.swift
//  DiskCleaner
//
//  Sprint 2.5 / 3: The Smart Cleanup center screen. Renders three phases
//  driven by `SmartCleanupModel.phase`:
//
//    .picking   → two-column picker (filter / group list + floating action bar)
//    .cleaning  → CleaningStateView animation while DeletionService runs
//    .success   → SuccessStateView with per-category breakdown + Done CTA
//
//  Scan data is pulled from the shared `JunkScanStore` injected by
//  ContentView, so the Dashboard and Smart Cleanup screens share one
//  scan instead of double-counting.
//

import SwiftUI
import DiskCleanerCore

struct SmartCleanupView: View {

    @State private var model = SmartCleanupModel()
    let store: JunkScanStore
    /// Invoked when the user dismisses the success screen via "完成".
    /// Host typically routes back to the Dashboard.
    var onDone: () -> Void = {}

    var body: some View {
        Group {
            switch model.phase {
            case .picking:
                pickerView
            case .cleaning(let progress):
                CleaningStateView(
                    freedBytes: progress.freedBytes,
                    totalBytes: progress.totalBytes,
                    tasks: progress.tasks
                )
            case .success(let summary):
                successView(summary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await store.ensureScanned()
            if !store.categories.isEmpty {
                model.applyCategories(store.categories)
            }
        }
        .onChange(of: store.lastScanAt) { _, _ in
            // Sync the newly-scanned categories whenever the store updates.
            if !store.categories.isEmpty {
                model.applyCategories(store.categories)
            }
        }
    }

    // MARK: - Picker phase

    private var pickerView: some View {
        ZStack {
            HStack(spacing: 0) {
                filterColumn
                    .frame(width: 240)
                    .background(filterColumnBackground)
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(DesignTokens.Palette.line1)
                            .frame(width: 1)
                    }
                mainColumn
                    .frame(maxWidth: .infinity)
            }

            if store.isScanning && !store.hasScanned {
                LoadingStateView(
                    percent: 0,
                    itemsIndexed: 0,
                    duplicateGroups: 0,
                    reclaimableBytes: 0,
                    currentPath: ""
                )
                .background(MeshGradientBackground())
            }
        }
    }

    private var filterColumnBackground: some View {
        Color.black.opacity(0.4)
            .background(.regularMaterial)
    }

    // MARK: - Filter column (left 240pt)

    private var filterColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Summary
            VStack(alignment: .leading, spacing: 4) {
                Text("smartcleanup.summary.label")
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(DesignTokens.Palette.text4)
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .padding(.leading, 4)
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(verbatim: ByteSizeFormatter.short(model.totalAvailableBytes))
                        .font(.system(size: 22, weight: .bold))
                        .tracking(-0.4)
                        .foregroundStyle(DesignTokens.Palette.blueHi)
                    Text(verbatim: String(
                        format: NSLocalizedString("smartcleanup.summary.detail", comment: ""),
                        model.categories.count,
                        model.totalAvailableItems
                    ))
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.Palette.text3)
                }
                .padding(.leading, 4)
            }
            .padding(.top, 4)

            Rectangle()
                .fill(DesignTokens.Palette.line1)
                .frame(height: 1)
                .padding(.vertical, 4)

            Text("smartcleanup.category.label")
                .font(DesignTokens.Typography.label)
                .foregroundStyle(DesignTokens.Palette.text4)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.leading, 4)

            ForEach(model.categories) { cat in
                categoryRow(cat)
            }

            Spacer(minLength: 8)

            safetyAssuranceCard
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 20)
    }

    private func categoryRow(_ cat: SmartCleanupCategory) -> some View {
        let isActive = model.activeCategoryID == cat.id
        let selectedCount = model.selectedCount(in: cat)
        return Button {
            model.focusCategory(cat)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(cat.color)
                        .frame(width: 8, height: 8)
                        .shadow(color: cat.color.opacity(0.5), radius: 4)
                    Text(cat.titleKey)
                        .font(.system(size: 12.5, weight: isActive ? .semibold : .medium))
                        .foregroundStyle(isActive ? DesignTokens.Palette.text1 : DesignTokens.Palette.text2)
                    Spacer(minLength: 4)
                    if selectedCount > 0 {
                        Text(verbatim: "\(selectedCount)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(DesignTokens.Palette.blue))
                    }
                }
                HStack {
                    Text(verbatim: String(
                        format: NSLocalizedString("smartcleanup.category.items_count", comment: ""),
                        cat.items.count
                    ))
                    Spacer(minLength: 4)
                    Text(verbatim: ByteSizeFormatter.short(model.categoryBytes(cat)))
                        .font(.system(size: 10.5, design: .monospaced))
                }
                .font(.system(size: 10.5))
                .foregroundStyle(DesignTokens.Palette.text3)
                .padding(.leading, 16)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(isActive ? DesignTokens.Palette.blue.opacity(0.10) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .strokeBorder(isActive ? DesignTokens.Palette.blue.opacity(0.25) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var safetyAssuranceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "shield")
                    .foregroundStyle(DesignTokens.Palette.blueHi)
                Text("smartcleanup.safety.title")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(DesignTokens.Palette.text2)
            }
            Text("smartcleanup.safety.body")
                .font(.system(size: 10.5))
                .foregroundStyle(DesignTokens.Palette.text3)
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Palette.glass1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .strokeBorder(DesignTokens.Palette.line1, lineWidth: 1)
        )
    }

    // MARK: - Main column

    private var mainColumn: some View {
        VStack(spacing: 0) {
            // Scrollable content (header + group list)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    titleAndFilterRow
                    groupList
                }
                .padding(22)
                .padding(.bottom, 80) // leave room for floating bar
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .bottom) {
            floatingActionBar
                .padding(.horizontal, 22)
                .padding(.bottom, 16)
        }
    }

    private var titleAndFilterRow: some View {
        HStack(alignment: .lastTextBaseline) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(DesignTokens.Palette.blueHi)
                Text("smartcleanup.title")
                    .font(DesignTokens.Typography.h1)
                    .foregroundStyle(DesignTokens.Palette.text1)
                Text("smartcleanup.subtitle")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.Palette.text3)
            }
            Spacer(minLength: 12)
            HStack(spacing: 6) {
                ForEach(Array(SmartCleanupRiskFilter.allCases.enumerated()), id: \.offset) { _, f in
                    filterChip(f)
                }
            }
        }
    }

    private func filterChip(_ f: SmartCleanupRiskFilter) -> some View {
        let active = model.filter == f
        return Button {
            model.filter = f
        } label: {
            DesignChip(active ? .active : .default) {
                Text(f.labelKey)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Group list

    private var groupList: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            ForEach(model.categories) { cat in
                groupCard(cat)
            }
        }
    }

    @ViewBuilder
    private func groupCard(_ cat: SmartCleanupCategory) -> some View {
        let isExpanded = (model.expandedCategoryID == cat.id)
        let totalBytes = model.categoryBytes(cat)

        if isExpanded {
            DesignCard(.elevated, padding: 0) {
                VStack(spacing: 0) {
                    groupHeader(cat, totalBytes: totalBytes, expanded: true)
                    Rectangle()
                        .fill(DesignTokens.Palette.line1)
                        .frame(height: 1)
                    expandedRows(cat)
                }
            }
        } else {
            DesignCard(.default, padding: 0) {
                groupHeader(cat, totalBytes: totalBytes, expanded: false)
            }
        }
    }

    private func groupHeader(
        _ cat: SmartCleanupCategory,
        totalBytes: Int64,
        expanded: Bool
    ) -> some View {
        Button {
            model.expand(cat)
        } label: {
            HStack(spacing: 12) {
                DesignCheckbox(model.groupCheckboxState(cat)) {
                    model.toggleAll(in: cat)
                }
                RoundedRectangle(cornerRadius: 3)
                    .fill(cat.color)
                    .frame(width: 10, height: 10)
                    .shadow(color: cat.color.opacity(0.6), radius: 5)
                VStack(alignment: .leading, spacing: 2) {
                    Text(cat.titleKey)
                        .font(DesignTokens.Typography.h2)
                        .foregroundStyle(DesignTokens.Palette.text1)
                    Text(cat.summaryKey)
                        .font(.system(size: 11.5))
                        .foregroundStyle(DesignTokens.Palette.text3)
                }
                Spacer(minLength: 8)
                Text(verbatim: ByteSizeFormatter.short(totalBytes))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(cat.color)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignTokens.Palette.text3)
                    .rotationEffect(.degrees(expanded ? 90 : 0))
                    .animation(.easeInOut(duration: 0.15), value: expanded)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background {
                if expanded {
                    LinearGradient(
                        colors: [
                            cat.color.opacity(0.07),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    Color.clear
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func expandedRows(_ cat: SmartCleanupCategory) -> some View {
        let visible = model.itemsAfterFilter(in: cat)
        return VStack(spacing: 0) {
            tableHeader
            ForEach(Array(visible.enumerated()), id: \.element.id) { idx, item in
                itemRow(item)
                if idx < visible.count - 1 {
                    Rectangle()
                        .fill(DesignTokens.Palette.line1.opacity(0.5))
                        .frame(height: 1)
                        .padding(.horizontal, 12)
                }
            }
        }
    }

    /// Eight-column header — matches the design's grid-template-columns:
    /// `32 80 32 1fr 110 110 70 24`.
    private var tableHeader: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 32)
            Text("smartcleanup.col.risk")
                .frame(width: 80, alignment: .leading)
            Color.clear.frame(width: 32)
            Text("smartcleanup.col.item_path")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("smartcleanup.col.reason")
                .frame(width: 110, alignment: .leading)
            Text("smartcleanup.col.last_access")
                .frame(width: 110, alignment: .leading)
            Text("smartcleanup.col.size")
                .frame(width: 70, alignment: .trailing)
            Color.clear.frame(width: 24)
        }
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(DesignTokens.Palette.text4)
        .textCase(.uppercase)
        .tracking(0.8)
        .frame(height: 28)
        .padding(.horizontal, 12)
        .background(DesignTokens.Palette.glass1)
    }

    private func itemRow(_ item: SmartCleanupItem) -> some View {
        let selected = model.selectedItemIDs.contains(item.id)
        return HStack(spacing: 0) {
            // 32pt checkbox
            DesignCheckbox(on: selected) { model.toggle(item) }
                .frame(width: 32, alignment: .leading)
            // 80pt risk badge
            DesignRisk(level: item.risk)
                .frame(width: 80, alignment: .leading)
            // 32pt glyph
            DesignGlyph(
                kind: .cache,
                code: String(item.name.prefix(2)).uppercased(),
                size: 22
            )
            .frame(width: 32, alignment: .leading)
            // 1fr name + path
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: item.name)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(DesignTokens.Palette.text1)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(verbatim: item.path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(DesignTokens.Palette.text3)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // 110pt reason
            Text(verbatim: item.reasonDisplay)
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.Palette.text3)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: 110, alignment: .leading)
            // 110pt last access
            Text(verbatim: item.lastAccessDisplay)
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.Palette.text3)
                .frame(width: 110, alignment: .leading)
            // 70pt size
            Text(verbatim: ByteSizeFormatter.short(item.bytes))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Palette.text1)
                .frame(width: 70, alignment: .trailing)
            // 24pt more
            Image(systemName: "ellipsis")
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.Palette.text3)
                .frame(width: 24, alignment: .center)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(selected ? DesignTokens.Palette.blue.opacity(0.06) : Color.clear)
    }

    // MARK: - Floating action bar

    private var floatingActionBar: some View {
        HStack(spacing: 12) {
            DesignCheckbox(model.selectedItemCount > 0 ? .on : .off) {
                if model.selectedItemCount > 0 {
                    model.selectedItemIDs.removeAll()
                }
            }
            Text(verbatim: String(
                format: NSLocalizedString("smartcleanup.fab.selected_count", comment: ""),
                model.selectedItemCount
            ))
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(DesignTokens.Palette.text1)

            Text(verbatim: "· \(ByteSizeFormatter.short(model.selectedBytes))")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Palette.blueHi)

            Spacer(minLength: 12)

            riskBreakdown
                .font(.system(size: 11))

            DesignButton(.ghost, size: .small, action: { model.selectOnlySafeItems() }) {
                Text("smartcleanup.fab.only_safe")
            }
            DesignButton(.primary, size: .standard, action: runCleanup) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                    Text(verbatim: String(
                        format: NSLocalizedString("smartcleanup.fab.cleanup_cta", comment: ""),
                        ByteSizeFormatter.short(model.selectedBytes)
                    ))
                }
            }
            .disabled(canCleanup == false)
        }
        .padding(.horizontal, 18)
        .frame(height: DesignTokens.Spacing.floatingBarHeight)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(Color(hex: 0x161c27, opacity: 0.85))
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .strokeBorder(DesignTokens.Palette.line2, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.45), radius: 24, y: 8)
    }

    /// Whether the "立即清理" CTA should fire. We require at least one
    /// selected item with a real URL — placeholder rows can't be deleted.
    private var canCleanup: Bool {
        for cat in model.categories {
            for it in cat.items
            where model.selectedItemIDs.contains(it.id) && it.url != nil {
                return true
            }
        }
        return false
    }

    /// Three optional dotted counts in the floating action bar. Hides
    /// counts of zero and trims the leading separator so layout reads
    /// cleanly with one, two, or three categories selected.
    private var riskBreakdown: some View {
        let stats: [(count: Int, color: Color, labelKey: String)] = [
            (model.selectedCount(risk: .safe),
             DesignTokens.Palette.good,
             "smartcleanup.fab.safe_count"),
            (model.selectedCount(risk: .normal),
             DesignTokens.Palette.blueHi,
             "smartcleanup.fab.normal_count"),
            (model.selectedCount(risk: .caution),
             DesignTokens.Palette.warn,
             "smartcleanup.fab.caution_count")
        ]
        let visible = stats.filter { $0.count > 0 }
        return HStack(spacing: 6) {
            ForEach(Array(visible.enumerated()), id: \.offset) { idx, s in
                if idx > 0 {
                    Text(verbatim: "·").foregroundStyle(DesignTokens.Palette.text4)
                }
                HStack(spacing: 3) {
                    Circle()
                        .fill(s.color)
                        .frame(width: 5, height: 5)
                        .shadow(color: s.color, radius: 2)
                    Text(verbatim: String(
                        format: NSLocalizedString(s.labelKey, comment: ""),
                        s.count
                    ))
                    .foregroundStyle(s.color)
                }
            }
        }
    }

    // MARK: - Success phase

    private func successView(_ summary: CleanupSummary) -> some View {
        // Color each row by its source category for a richer visual.
        let rows: [(label: String, bytes: Int64, color: Color)] = summary.breakdown.map { row in
            let color = model.categories
                .first(where: { $0.titleDisplay == row.label })?
                .color ?? DesignTokens.Palette.good
            return (label: row.label, bytes: row.bytes, color: color)
        }
        return SuccessStateView(
            freedBytes: summary.freedBytes,
            breakdown: rows,
            healthScoreBefore: summary.healthBefore,
            healthScoreAfter: summary.healthAfter,
            onDone: {
                model.resetToPicking()
                onDone()
            },
            onDetail: { model.resetToPicking() }
        )
        .background(MeshGradientBackground())
    }

    // MARK: - Actions

    private func runCleanup() {
        guard canCleanup else { return }
        Task { await model.runCleanup() }
    }
}

#Preview {
    let store: JunkScanStore = {
        let s = JunkScanStore()
        // Seed the preview with placeholder samples so the picker has
        // something to render without running a real scan.
        s.categories = SmartCleanupCategory.samples()
        s.lastScanAt = Date()
        return s
    }()
    return SmartCleanupView(store: store)
        .frame(width: 1200, height: 760)
        .background(MeshGradientBackground())
        .preferredColorScheme(.dark)
}
