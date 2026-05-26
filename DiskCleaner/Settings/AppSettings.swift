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

/// The language the user chose for the app's UI. Backed by macOS's standard
/// `AppleLanguages` defaults key — the override takes effect on the next
/// launch of the app.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case chinese
    case english

    var id: String { rawValue }
}

extension AppLanguage {

    /// Applies this choice to UserDefaults. macOS picks up the new
    /// `AppleLanguages` value on the next launch of the app.
    func apply() {
        let defaults = UserDefaults.standard
        switch self {
        case .system:
            defaults.removeObject(forKey: "AppleLanguages")
        case .chinese:
            defaults.set(["zh-Hans"], forKey: "AppleLanguages")
        case .english:
            defaults.set(["en"], forKey: "AppleLanguages")
        }
    }
}

/// How often the scan reminder fires.
enum ReminderFrequency: String, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .daily:   1
        case .weekly:  7
        case .monthly: 30
        }
    }

    var label: String {
        switch self {
        case .daily:   "每天"
        case .weekly:  "每周"
        case .monthly: "每月"
        }
    }
}

enum AppSettings {

    // MARK: Keys

    static let defaultScanRootKey         = "defaultScanRoot"
    static let largeFileThresholdMBKey    = "largeFileThresholdMB"
    static let auditLogMaxEntriesKey      = "auditLogMaxEntries"
    static let lastScannedPathKey         = "lastScannedPath"
    static let appLanguageKey             = "appLanguage"
    static let excludedPathsKey           = "excludedPaths"
    static let reminderEnabledKey         = "scanReminderEnabled"
    static let reminderFrequencyKey       = "scanReminderFrequency"
    static let lastScanTimeKey            = "lastScanTime"

    // MARK: Defaults

    static let defaultScanRootDefault: DefaultScanRoot = .home
    static let largeFileThresholdMBDefault: Int        = 100
    static let auditLogMaxEntriesDefault: Int          = 500
    static let appLanguageDefault: AppLanguage         = .system
    static let reminderFrequencyDefault: ReminderFrequency = .weekly

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

    static func appLanguage() -> AppLanguage {
        if
            let raw = UserDefaults.standard.string(forKey: appLanguageKey),
            let value = AppLanguage(rawValue: raw)
        {
            return value
        }
        return appLanguageDefault
    }

    /// Paths the scanner should skip entirely. Standardised so comparisons
    /// against `URL.standardizedFileURL.path` succeed regardless of trailing
    /// slashes or relative segments.
    static func excludedPaths() -> Set<String> {
        let stored = UserDefaults.standard.stringArray(forKey: excludedPathsKey) ?? []
        return Set(stored.map { standardize($0) })
    }

    static func setExcludedPaths(_ paths: [String]) {
        let standardized = paths.map { standardize($0) }
        UserDefaults.standard.set(standardized, forKey: excludedPathsKey)
    }

    static func addExcludedPath(_ path: String) {
        var current = UserDefaults.standard.stringArray(forKey: excludedPathsKey) ?? []
        let normalized = standardize(path)
        if !current.contains(normalized) {
            current.append(normalized)
            UserDefaults.standard.set(current, forKey: excludedPathsKey)
        }
    }

    static func removeExcludedPath(_ path: String) {
        var current = UserDefaults.standard.stringArray(forKey: excludedPathsKey) ?? []
        let normalized = standardize(path)
        current.removeAll { $0 == normalized }
        UserDefaults.standard.set(current, forKey: excludedPathsKey)
    }

    static func reminderEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: reminderEnabledKey)
    }

    static func reminderFrequency() -> ReminderFrequency {
        if
            let raw = UserDefaults.standard.string(forKey: reminderFrequencyKey),
            let value = ReminderFrequency(rawValue: raw)
        {
            return value
        }
        return reminderFrequencyDefault
    }

    static func lastScanTime() -> Date? {
        let interval = UserDefaults.standard.double(forKey: lastScanTimeKey)
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    static func markScanCompleted() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastScanTimeKey)
    }

    // MARK: Helpers

    private static func standardize(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path
    }
}
