//
//  AppSettings.swift
//  DiskCleaner
//
//  Keys, defaults and read helpers for user preferences stored in
//  `UserDefaults` (so that `@AppStorage` in views and plain reads from view
//  models share the same source of truth).
//

import Foundation

/// Where to start when the user opens the disk-visualization feature.
enum DefaultScanRoot: String, CaseIterable, Identifiable {
    case home
    case lastUsed
    case ask

    var id: String { rawValue }

    var label: String {
        switch self {
        case .home:     "主目录"
        case .lastUsed: "上次使用的位置"
        case .ask:      "每次询问"
        }
    }
}

enum AppSettings {

    // MARK: Keys

    static let defaultScanRootKey       = "defaultScanRoot"
    static let largeFileThresholdMBKey  = "largeFileThresholdMB"
    static let auditLogMaxEntriesKey    = "auditLogMaxEntries"
    static let lastScannedPathKey       = "lastScannedPath"

    // MARK: Defaults

    static let defaultScanRootDefault: DefaultScanRoot = .home
    static let largeFileThresholdMBDefault: Int        = 100
    static let auditLogMaxEntriesDefault: Int          = 500

    // MARK: Read helpers (for non-View code that can't use @AppStorage)

    static func defaultScanRoot() -> DefaultScanRoot {
        if
            let raw = UserDefaults.standard.string(forKey: defaultScanRootKey),
            let value = DefaultScanRoot(rawValue: raw)
        {
            return value
        }
        return defaultScanRootDefault
    }

    static func largeFileThresholdMB() -> Int {
        let stored = UserDefaults.standard.integer(forKey: largeFileThresholdMBKey)
        return stored > 0 ? stored : largeFileThresholdMBDefault
    }

    static func auditLogMaxEntries() -> Int {
        let stored = UserDefaults.standard.integer(forKey: auditLogMaxEntriesKey)
        return stored > 0 ? stored : auditLogMaxEntriesDefault
    }
}
