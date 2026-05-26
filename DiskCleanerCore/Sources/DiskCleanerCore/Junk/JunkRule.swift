import Foundation

/// How safe it is to clean a given junk item.
public enum SafetyLevel: String, Codable, Sendable, CaseIterable {

    /// Safe to select by default in the UI.
    case safe

    /// Must be explicitly chosen by the user — never pre-selected.
    case reviewNeeded
}

/// Broad category a junk rule belongs to, used to group items in the UI.
public enum JunkCategory: String, Codable, Sendable, CaseIterable {
    case userCache
    case logs
    case trash
    case browserCache
    case developerJunk
    case packageManagerCache
    case oldDeviceBackup
    case mailDownloads
    case systemCache
    case largeOldDownloads
    case custom
}

/// A declarative description of one kind of cleanable junk.
///
/// Rules are data, not code, so the catalog can grow without touching the
/// matching engine.
public struct JunkRule: Identifiable, Sendable {

    public let id: String
    public let name: String
    public let category: JunkCategory
    public let safety: SafetyLevel

    /// Paths this rule targets. A leading `~` is expanded to the user's home
    /// directory; a trailing `/*` means "the contents of this directory".
    public let paths: [String]

    /// Human-readable explanation of what this is and why cleaning it is fine.
    public let explanation: String

    public init(
        id: String,
        name: String,
        category: JunkCategory,
        safety: SafetyLevel,
        paths: [String],
        explanation: String
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.safety = safety
        self.paths = paths
        self.explanation = explanation
    }
}
