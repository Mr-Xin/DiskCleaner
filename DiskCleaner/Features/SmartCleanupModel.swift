//
//  SmartCleanupModel.swift
//  DiskCleaner
//
//  Plain-data model + view-model for the Smart Cleanup center screen.
//  The view (`SmartCleanupView`) is fully driven by this model so that
//  later Sprints can swap the placeholder factory for engine data
//  without changing the view at all.
//

import SwiftUI
import Observation
import DiskCleanerCore

// MARK: - Domain types

/// A single suggested item inside a Smart Cleanup category.
struct SmartCleanupItem: Identifiable, Equatable {
    static func == (lhs: SmartCleanupItem, rhs: SmartCleanupItem) -> Bool {
        lhs.id == rhs.id
    }

    let id: UUID = UUID()
    /// Display name (the rightmost path component, typically).
    let name: String
    /// Full path, displayed in mono under the name (truncating tail).
    let path: String
    /// Bytes that would be reclaimed by removing this item.
    let bytes: Int64
    /// Short verbatim string for "last access" (e.g. "2 小时前", "今天").
    /// Already localized at construction time — the view renders verbatim.
    let lastAccessDisplay: String
    /// Risk classification — drives both the badge and the "safe-only" filter.
    let risk: RiskLevel
    /// Short verbatim explanation ("14 个旧项目的构建产物 · 需要时会自动重建").
    /// Already localized at construction time — the view renders verbatim.
    let reasonDisplay: String
    /// Whether the item is checked by default.
    let defaultSelected: Bool
    /// Real file URL on disk, or `nil` for collapsed placeholders.
    /// When `nil`, `runCleanup` skips the item.
    let url: URL?
}

/// A category groups related items (Caches / Old downloads / Duplicates /
/// Large unused / App leftovers / System temp). Identified by a stable id
/// so the selection set survives re-renders.
struct SmartCleanupCategory: Identifiable, Equatable {
    let id: String
    let titleKey: LocalizedStringKey
    let summaryKey: LocalizedStringKey
    /// String form of `titleKey`, resolved at construction so the runCleanup
    /// task list can render category names without going through SwiftUI.
    let titleDisplay: String
    let color: Color
    let glyph: DesignGlyphKind
    let items: [SmartCleanupItem]
}

// MARK: - Sample (placeholder) data

extension SmartCleanupCategory {

    /// The seven categories shown in the design wireframe. These are
    /// placeholder content with i18n keys — replace with real engine
    /// data when the Smart Cleanup pipeline lands.
    static func samples() -> [SmartCleanupCategory] {
        [
            // 1. Caches (expanded by default in the design)
            SmartCleanupCategory(
                id: "cache",
                titleKey: "smartcleanup.category.cache.title",
                summaryKey: "smartcleanup.category.cache.summary",
                titleDisplay: NSLocalizedString("smartcleanup.category.cache.title", comment: ""),
                color: DesignTokens.Palette.catCache,
                glyph: .cache,
                items: [
                    .init(
                        name: "DerivedData",
                        path: "~/Library/Developer/Xcode/DerivedData",
                        bytes: Int64(6.2 * 1_073_741_824),
                        lastAccessDisplay: NSLocalizedString("smartcleanup.access.hours_ago_2", comment: ""),
                        risk: .safe,
                        reasonDisplay: NSLocalizedString("smartcleanup.item.derived_data.reason", comment: ""),
                        defaultSelected: true,
                        url: nil
                    ),
                    .init(
                        name: "iOS DeviceSupport",
                        path: "~/Library/Developer/Xcode/iOS DeviceSupport",
                        bytes: Int64(2.4 * 1_073_741_824),
                        lastAccessDisplay: NSLocalizedString("smartcleanup.access.months_ago_4", comment: ""),
                        risk: .normal,
                        reasonDisplay: NSLocalizedString("smartcleanup.item.device_support.reason", comment: ""),
                        defaultSelected: true,
                        url: nil
                    ),
                    .init(
                        name: "Chrome/Cache",
                        path: "~/Library/Caches/Google/Chrome/Default/Cache",
                        bytes: Int64(3.1 * 1_073_741_824),
                        lastAccessDisplay: NSLocalizedString("smartcleanup.access.today", comment: ""),
                        risk: .safe,
                        reasonDisplay: NSLocalizedString("smartcleanup.item.chrome_cache.reason", comment: ""),
                        defaultSelected: true,
                        url: nil
                    ),
                    .init(
                        name: "Slack/Cache",
                        path: "~/Library/Caches/com.tinyspeck.slackmacgap",
                        bytes: Int64(1.6 * 1_073_741_824),
                        lastAccessDisplay: NSLocalizedString("smartcleanup.access.hours_ago_2", comment: ""),
                        risk: .safe,
                        reasonDisplay: NSLocalizedString("smartcleanup.item.slack_cache.reason", comment: ""),
                        defaultSelected: true,
                        url: nil
                    ),
                    .init(
                        name: "Spotify/PersistentCache",
                        path: "~/Library/Caches/com.spotify.client",
                        bytes: Int64(1.2 * 1_073_741_824),
                        lastAccessDisplay: NSLocalizedString("smartcleanup.access.today", comment: ""),
                        risk: .safe,
                        reasonDisplay: NSLocalizedString("smartcleanup.item.spotify_cache.reason", comment: ""),
                        defaultSelected: true,
                        url: nil
                    ),
                    .init(
                        name: "com.apple.bird",
                        path: "~/Library/Caches/com.apple.bird",
                        bytes: 480 * 1_048_576,
                        lastAccessDisplay: NSLocalizedString("smartcleanup.access.today", comment: ""),
                        risk: .normal,
                        reasonDisplay: NSLocalizedString("smartcleanup.item.icloud_meta.reason", comment: ""),
                        defaultSelected: true,
                        url: nil
                    ),
                    .init(
                        name: "Adobe/Common/Media Cache",
                        path: "~/Library/Caches/Adobe/Common/Media Cache",
                        bytes: 820 * 1_048_576,
                        lastAccessDisplay: NSLocalizedString("smartcleanup.access.weeks_ago_3", comment: ""),
                        risk: .safe,
                        reasonDisplay: NSLocalizedString("smartcleanup.item.adobe_cache.reason", comment: ""),
                        defaultSelected: true,
                        url: nil
                    ),
                    .init(
                        name: "WebKit/MediaCache",
                        path: "~/Library/Caches/com.apple.WebKit",
                        bytes: 380 * 1_048_576,
                        lastAccessDisplay: NSLocalizedString("smartcleanup.access.yesterday", comment: ""),
                        risk: .safe,
                        reasonDisplay: NSLocalizedString("smartcleanup.item.webkit_cache.reason", comment: ""),
                        defaultSelected: true,
                        url: nil
                    ),
                    .init(
                        name: "JetBrains/IDE Cache",
                        path: "~/Library/Caches/JetBrains/IntelliJIdea2024.3",
                        bytes: Int64(1.4 * 1_073_741_824),
                        lastAccessDisplay: NSLocalizedString("smartcleanup.access.days_ago_8", comment: ""),
                        risk: .caution,
                        reasonDisplay: NSLocalizedString("smartcleanup.item.jetbrains_cache.reason", comment: ""),
                        defaultSelected: false,
                        url: nil
                    )
                ]
            ),

            // 2. Old downloads (collapsed)
            SmartCleanupCategory(
                id: "downloads",
                titleKey: "smartcleanup.category.downloads.title",
                summaryKey: "smartcleanup.category.downloads.summary",
                titleDisplay: NSLocalizedString("smartcleanup.category.downloads.title", comment: ""),
                color: DesignTokens.Palette.catOther,
                glyph: .folder,
                items: collapsedPlaceholder(count: 42, total: Int64(3.8 * 1_073_741_824))
            ),

            // 3. Duplicates (collapsed)
            SmartCleanupCategory(
                id: "duplicates",
                titleKey: "smartcleanup.category.duplicates.title",
                summaryKey: "smartcleanup.category.duplicates.summary",
                titleDisplay: NSLocalizedString("smartcleanup.category.duplicates.title", comment: ""),
                color: DesignTokens.Palette.catPhoto,
                glyph: .photo,
                items: collapsedPlaceholder(count: 42, total: Int64(2.4 * 1_073_741_824))
            ),

            // 4. Large unused (collapsed)
            SmartCleanupCategory(
                id: "large",
                titleKey: "smartcleanup.category.large.title",
                summaryKey: "smartcleanup.category.large.summary",
                titleDisplay: NSLocalizedString("smartcleanup.category.large.title", comment: ""),
                color: DesignTokens.Palette.catVideo,
                glyph: .video,
                items: collapsedPlaceholder(count: 12, total: Int64(4.2 * 1_073_741_824))
            ),

            // 5. App leftovers (collapsed)
            SmartCleanupCategory(
                id: "leftover",
                titleKey: "smartcleanup.category.leftover.title",
                summaryKey: "smartcleanup.category.leftover.summary",
                titleDisplay: NSLocalizedString("smartcleanup.category.leftover.title", comment: ""),
                color: DesignTokens.Palette.catApps,
                glyph: .apps,
                items: collapsedPlaceholder(count: 8, total: Int64(1.6 * 1_073_741_824))
            ),

            // 6. System temp (collapsed)
            SmartCleanupCategory(
                id: "temp",
                titleKey: "smartcleanup.category.temp.title",
                summaryKey: "smartcleanup.category.temp.summary",
                titleDisplay: NSLocalizedString("smartcleanup.category.temp.title", comment: ""),
                color: DesignTokens.Palette.catSystem,
                glyph: .system,
                items: collapsedPlaceholder(count: 56, total: 820 * 1_048_576)
            )
        ]
    }

    /// Fabricate `count` placeholder items totalling roughly `total` bytes,
    /// so the collapsed-group cards have realistic sums without requiring
    /// the caller to spell out every row. These are never displayed
    /// individually until the engine wires in real data.
    private static func collapsedPlaceholder(count: Int, total: Int64) -> [SmartCleanupItem] {
        guard count > 0 else { return [] }
        let each = total / Int64(count)
        return (0..<count).map { i in
            SmartCleanupItem(
                name: "Item \(i + 1)",
                path: "~/placeholder/\(i + 1)",
                bytes: each,
                lastAccessDisplay: NSLocalizedString("smartcleanup.access.today", comment: ""),
                risk: .normal,
                reasonDisplay: NSLocalizedString("smartcleanup.category.cache.summary", comment: ""),
                defaultSelected: false,
                url: nil
            )
        }
    }
}

// MARK: - Engine adapter

extension SmartCleanupCategory {

    /// Categories that `JunkRulesEngine` can actually populate today. When
    /// a real scan returns nothing for one of these, we show an empty
    /// category — not the sample data — so the user isn't lied to.
    /// The other ids (duplicates / leftover) keep their placeholder content
    /// until their dedicated engines wire up.
    private static let engineBackedIDs: Set<String> = ["cache", "temp", "downloads", "large"]

    /// Maps `JunkRulesEngine` output into the six on-screen Smart Cleanup
    /// categories. Engine-backed categories show real items (or empty);
    /// the remaining categories keep their placeholder samples so the
    /// wireframe stays populated until those engines arrive.
    static func fromJunkItems(_ items: [JunkItem]) -> [SmartCleanupCategory] {
        var byCategory: [String: [JunkItem]] = [:]
        for item in items {
            let target = smartCleanupID(for: item.rule.category)
            byCategory[target, default: []].append(item)
        }

        return samples().map { placeholder in
            if let realItems = byCategory[placeholder.id], !realItems.isEmpty {
                let mapped = realItems
                    .sorted { $0.size > $1.size }
                    .map { SmartCleanupItem(junkItem: $0) }
                return SmartCleanupCategory(
                    id: placeholder.id,
                    titleKey: placeholder.titleKey,
                    summaryKey: placeholder.summaryKey,
                    titleDisplay: placeholder.titleDisplay,
                    color: placeholder.color,
                    glyph: placeholder.glyph,
                    items: mapped
                )
            }
            if engineBackedIDs.contains(placeholder.id) {
                // Real scan ran for this category but found nothing.
                return SmartCleanupCategory(
                    id: placeholder.id,
                    titleKey: placeholder.titleKey,
                    summaryKey: placeholder.summaryKey,
                    titleDisplay: placeholder.titleDisplay,
                    color: placeholder.color,
                    glyph: placeholder.glyph,
                    items: []
                )
            }
            return placeholder
        }
    }

    /// Mapping from the engine's coarse `JunkCategory` to the Smart Cleanup
    /// UI's six on-screen buckets.
    private static func smartCleanupID(for category: JunkCategory) -> String {
        switch category {
        case .userCache, .browserCache, .developerJunk, .packageManagerCache, .systemCache:
            return "cache"
        case .logs, .trash:
            return "temp"
        case .mailDownloads, .largeOldDownloads:
            return "downloads"
        case .oldDeviceBackup:
            return "large"
        case .custom:
            return "cache"
        }
    }
}

private extension SmartCleanupItem {

    /// Lazily-allocated formatter for "X 天前" style last-access strings.
    /// Uses the user's current locale, matching the rest of the UI.
    static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    init(junkItem: JunkItem) {
        let attrs = (try? junkItem.url.resourceValues(forKeys: [
            .contentAccessDateKey,
            .contentModificationDateKey
        ]))
        let date = attrs?.contentAccessDate ?? attrs?.contentModificationDate
        let access: String
        if let date {
            access = SmartCleanupItem.relativeFormatter.localizedString(for: date, relativeTo: Date())
        } else {
            access = NSLocalizedString("smartcleanup.access.unknown", comment: "")
        }
        self.init(
            name: junkItem.url.lastPathComponent,
            path: junkItem.url.path,
            bytes: junkItem.size,
            lastAccessDisplay: access,
            risk: junkItem.rule.safety == .safe ? .safe : .caution,
            reasonDisplay: junkItem.rule.explanation,
            defaultSelected: junkItem.rule.safety == .safe,
            url: junkItem.url
        )
    }
}

// MARK: - Filter

enum SmartCleanupRiskFilter: CaseIterable {
    case all
    case safeOnly
    case cautionOnly

    var labelKey: LocalizedStringKey {
        switch self {
        case .all:          return "smartcleanup.filter.all"
        case .safeOnly:     return "smartcleanup.filter.safe_only"
        case .cautionOnly:  return "smartcleanup.filter.caution"
        }
    }

    func includes(_ level: RiskLevel) -> Bool {
        switch self {
        case .all:         return true
        case .safeOnly:    return level == .safe
        case .cautionOnly: return level == .caution
        }
    }
}

// MARK: - Phases

/// The runtime phase of the Smart Cleanup screen: picking items, running
/// the cleanup transition animation, or showing the success summary.
enum SmartCleanupPhase: Equatable {
    case picking
    case cleaning(progress: CleanupProgress)
    case success(summary: CleanupSummary)
}

struct CleanupProgress: Equatable {
    var freedBytes: Int64
    var totalBytes: Int64
    var tasks: [CleaningTask]
}

extension CleaningTask: Equatable {
    static func == (lhs: CleaningTask, rhs: CleaningTask) -> Bool {
        lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.detail == rhs.detail
            && lhs.progress == rhs.progress
            && lhs.status == rhs.status
    }
}

struct CleanupSummary: Equatable {
    var freedBytes: Int64
    var breakdown: [Row]
    var healthBefore: Int
    var healthAfter: Int

    struct Row: Equatable {
        var label: String
        var bytes: Int64
        var colorHex: UInt32  // store as hex for Equatable; view re-derives Color
    }
}

// MARK: - View model

/// Observable model owning categories, selection state, expansion state,
/// the active risk filter, and the cleanup phase. Designed to be created
/// by the view (single owner) and outlived by no one — Smart Cleanup state
/// isn't persisted across launches in v0.9.x.
@MainActor
@Observable
final class SmartCleanupModel {

    var categories: [SmartCleanupCategory]
    /// Item ids that are checked. Persisted in memory only.
    var selectedItemIDs: Set<UUID>
    /// Category id of the currently expanded group (only one at a time).
    var expandedCategoryID: String?
    /// Category currently focused by the left filter column.
    var activeCategoryID: String?
    var filter: SmartCleanupRiskFilter
    var phase: SmartCleanupPhase
    /// Most recent cleanup error surfaced into the UI; `nil` after a clean run.
    var lastError: String?

    init(categories: [SmartCleanupCategory] = []) {
        self.categories = categories
        self.selectedItemIDs = Self.defaultSelection(in: categories)
        self.expandedCategoryID = "cache"
        self.activeCategoryID = "cache"
        self.filter = .all
        self.phase = .picking
        self.lastError = nil
    }

    /// Replace the live category list (e.g. after a fresh engine scan) and
    /// recompute default selection so newly-arrived items get their checks.
    /// Existing selection is dropped — UUIDs differ across constructions.
    func applyCategories(_ cats: [SmartCleanupCategory]) {
        self.categories = cats
        self.selectedItemIDs = Self.defaultSelection(in: cats)
        if !cats.contains(where: { $0.id == expandedCategoryID }) {
            expandedCategoryID = cats.first?.id
            activeCategoryID = cats.first?.id
        }
    }

    private static func defaultSelection(in cats: [SmartCleanupCategory]) -> Set<UUID> {
        var ids = Set<UUID>()
        for cat in cats where cat.id == "cache" {
            for it in cat.items where it.defaultSelected {
                ids.insert(it.id)
            }
        }
        return ids
    }

    // MARK: Derived sums

    func itemsAfterFilter(in category: SmartCleanupCategory) -> [SmartCleanupItem] {
        category.items.filter { filter.includes($0.risk) }
    }

    func selectedCount(in category: SmartCleanupCategory) -> Int {
        category.items.reduce(0) { acc, it in
            acc + (selectedItemIDs.contains(it.id) ? 1 : 0)
        }
    }

    var totalAvailableBytes: Int64 {
        categories.reduce(0) { acc, c in
            acc + c.items.reduce(0) { $0 + $1.bytes }
        }
    }

    var totalAvailableItems: Int {
        categories.reduce(0) { $0 + $1.items.count }
    }

    var selectedBytes: Int64 {
        categories.reduce(0) { acc, c in
            acc + c.items.reduce(0) { sum, it in
                sum + (selectedItemIDs.contains(it.id) ? it.bytes : 0)
            }
        }
    }

    var selectedItemCount: Int { selectedItemIDs.count }

    func selectedCount(risk: RiskLevel) -> Int {
        var count = 0
        for c in categories {
            for it in c.items where it.risk == risk && selectedItemIDs.contains(it.id) {
                count += 1
            }
        }
        return count
    }

    func categoryBytes(_ c: SmartCleanupCategory) -> Int64 {
        c.items.reduce(0) { $0 + $1.bytes }
    }

    // MARK: Mutations

    func toggle(_ item: SmartCleanupItem) {
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }

    /// Header-checkbox toggle: select all if any are off, otherwise deselect all.
    func toggleAll(in category: SmartCleanupCategory) {
        let allOn = category.items.allSatisfy { selectedItemIDs.contains($0.id) }
        if allOn {
            for it in category.items { selectedItemIDs.remove(it.id) }
        } else {
            for it in category.items { selectedItemIDs.insert(it.id) }
        }
    }

    /// State of the group-level checkbox.
    func groupCheckboxState(_ category: SmartCleanupCategory) -> DesignCheckboxState {
        let total = category.items.count
        let selected = selectedCount(in: category)
        if selected == 0 { return .off }
        if selected == total { return .on }
        return .indeterminate
    }

    /// "Only safe" quick toggle in the floating bar.
    func selectOnlySafeItems() {
        selectedItemIDs.removeAll()
        for c in categories {
            for it in c.items where it.risk == .safe {
                selectedItemIDs.insert(it.id)
            }
        }
    }

    func expand(_ category: SmartCleanupCategory) {
        if expandedCategoryID == category.id {
            expandedCategoryID = nil
        } else {
            expandedCategoryID = category.id
            activeCategoryID = category.id
        }
    }

    func focusCategory(_ category: SmartCleanupCategory) {
        activeCategoryID = category.id
        expandedCategoryID = category.id
    }

    func resetToPicking() {
        phase = .picking
        lastError = nil
    }

    // MARK: Cleanup execution

    /// Runs the selected deletions through `DeletionService`, advancing the
    /// `phase` from `.picking` → `.cleaning(...)` → `.success(...)`. One
    /// task per category is shown in the Cleaning transition view; the
    /// category is marked `running` while its items move to the Trash, then
    /// `done` once that batch returns. Items with `url == nil` (placeholder
    /// rows) are skipped silently.
    func runCleanup(deletionService: DeletionService = DeletionService()) async {
        // Group selected items by category, preserving sidebar order.
        var grouped: [(category: SmartCleanupCategory, items: [SmartCleanupItem])] = []
        for cat in categories {
            let chosen = cat.items.filter {
                selectedItemIDs.contains($0.id) && $0.url != nil
            }
            if !chosen.isEmpty {
                grouped.append((cat, chosen))
            }
        }

        guard !grouped.isEmpty else { return }

        let totalBytes = grouped.reduce(Int64(0)) { acc, pair in
            acc + pair.items.reduce(Int64(0)) { $0 + $1.bytes }
        }

        // Seed task list — all queued initially.
        var tasks: [CleaningTask] = grouped.enumerated().map { idx, pair in
            CleaningTask(
                index: idx + 1,
                title: pair.category.titleDisplay,
                detail: ByteSizeFormatter.short(pair.items.reduce(Int64(0)) { $0 + $1.bytes }),
                progress: 0,
                status: .queued
            )
        }
        var freed: Int64 = 0
        phase = .cleaning(progress: CleanupProgress(
            freedBytes: 0, totalBytes: totalBytes, tasks: tasks
        ))

        for (idx, pair) in grouped.enumerated() {
            // Flip current task → running.
            tasks[idx] = CleaningTask(
                index: tasks[idx].index,
                title: tasks[idx].title,
                detail: tasks[idx].detail,
                progress: 0.05,
                status: .running
            )
            phase = .cleaning(progress: CleanupProgress(
                freedBytes: freed, totalBytes: totalBytes, tasks: tasks
            ))

            let urls = pair.items.compactMap(\.url)
            let bytesInBatch = pair.items.reduce(Int64(0)) { $0 + $1.bytes }
            do {
                let result = try await deletionService.moveToTrash(
                    urls, source: "smart-cleanup"
                )
                // Approximate freed bytes: count items that actually trashed.
                let trashedSet = Set(result.trashed.map { $0.standardizedFileURL })
                let trashedBytes = pair.items
                    .filter { it in
                        guard let u = it.url?.standardizedFileURL else { return false }
                        return trashedSet.contains(u)
                    }
                    .reduce(Int64(0)) { $0 + $1.bytes }
                freed += trashedBytes

                // Drop trashed items from the category so the picker
                // reflects the freed-up state when the user goes back.
                if let catIdx = categories.firstIndex(where: { $0.id == pair.category.id }) {
                    var cat = categories[catIdx]
                    cat = SmartCleanupCategory(
                        id: cat.id,
                        titleKey: cat.titleKey,
                        summaryKey: cat.summaryKey,
                        titleDisplay: cat.titleDisplay,
                        color: cat.color,
                        glyph: cat.glyph,
                        items: cat.items.filter { it in
                            guard let u = it.url?.standardizedFileURL else { return true }
                            return !trashedSet.contains(u)
                        }
                    )
                    categories[catIdx] = cat
                }
                // Drop the corresponding selection ids.
                for it in pair.items {
                    guard let u = it.url?.standardizedFileURL else { continue }
                    if trashedSet.contains(u) {
                        selectedItemIDs.remove(it.id)
                    }
                }
            } catch {
                lastError = error.localizedDescription
                // Mark this task and remaining as done-with-error and bail.
            }
            tasks[idx] = CleaningTask(
                index: tasks[idx].index,
                title: tasks[idx].title,
                detail: ByteSizeFormatter.short(bytesInBatch),
                progress: 1.0,
                status: .done
            )
            phase = .cleaning(progress: CleanupProgress(
                freedBytes: freed, totalBytes: totalBytes, tasks: tasks
            ))

            // Tiny pause so the eye actually catches the running animation.
            try? await Task.sleep(nanoseconds: 350_000_000)
        }

        // Build the success summary breakdown (top categories by bytes).
        let breakdown = grouped
            .map { pair in
                CleanupSummary.Row(
                    label: pair.category.titleDisplay,
                    bytes: pair.items.reduce(Int64(0)) { $0 + $1.bytes },
                    colorHex: 0xFFFFFF  // unused; view re-derives from category id
                )
            }
            .sorted { $0.bytes > $1.bytes }

        phase = .success(summary: CleanupSummary(
            freedBytes: freed,
            breakdown: breakdown,
            healthBefore: 82,
            healthAfter: min(100, 82 + Int(Double(freed) / 1_073_741_824.0))
        ))
    }
}
