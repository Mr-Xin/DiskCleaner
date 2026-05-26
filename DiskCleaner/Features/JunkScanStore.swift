//
//  JunkScanStore.swift
//  DiskCleaner
//
//  Shared @Observable store that runs `JunkRulesEngine` once and exposes
//  the result as ready-to-render `[SmartCleanupCategory]`. Owned by
//  `ContentView` and injected into both `DashboardView` and
//  `SmartCleanupView` so a single scan feeds both screens.
//
//  The scan itself is dispatched off the main actor via `Task.detached` —
//  `JunkRulesEngine.scan()` runs straight-line FileManager calls that don't
//  yield, so calling it from a main-actor context would block the UI.
//

import Foundation
import SwiftUI
import Observation
import DiskCleanerCore

@MainActor
@Observable
final class JunkScanStore {

    /// Last scan's resulting categories. Empty until the first scan finishes.
    var categories: [SmartCleanupCategory] = []
    var isScanning: Bool = false
    var lastError: (any Error)? = nil
    var lastScanAt: Date? = nil

    var hasScanned: Bool { lastScanAt != nil }

    /// Sum of bytes across every item in every category. Used by Dashboard
    /// to populate the Health Score card's "release X.X GB" summary.
    var totalReclaimableBytes: Int64 {
        categories.reduce(0) { acc, c in
            acc + c.items.reduce(0) { $0 + $1.bytes }
        }
    }

    /// Total item count across every category — surfaced to the Dashboard
    /// as "N quick wins".
    var totalItemCount: Int {
        categories.reduce(0) { $0 + $1.items.count }
    }

    @ObservationIgnored private var scanTask: Task<Void, Never>?

    /// Kick a scan if we haven't run one yet (or if one isn't already in
    /// flight). Safe to call from `.task { ... }` on every view appearance.
    func ensureScanned() async {
        guard !hasScanned, !isScanning else { return }
        await scan()
    }

    /// Force-rescan. Cancels any in-flight scan first.
    func scan() async {
        scanTask?.cancel()
        isScanning = true
        lastError = nil
        defer { isScanning = false }

        let customRules = await CustomRulesStore.shared.load()
        let allRules = JunkRuleCatalog.builtIn + customRules.map { $0.asJunkRule() }

        do {
            let items = try await Task.detached(priority: .userInitiated) {
                try await JunkRulesEngine(rules: allRules).scan()
            }.value
            categories = SmartCleanupCategory.fromJunkItems(items)
            lastScanAt = Date()
        } catch is CancellationError {
            // Quietly drop — caller will retry if it cares.
        } catch {
            lastError = error
        }
    }

    func cancel() {
        scanTask?.cancel()
        isScanning = false
    }
}
