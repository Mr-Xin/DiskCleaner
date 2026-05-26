import Foundation

/// A user-defined junk rule. Stored as JSON in Application Support and merged
/// with the built-in catalog at runtime.
public struct CustomJunkRule: Identifiable, Codable, Sendable, Hashable {

    public var id: UUID
    public var name: String

    /// Path or glob to match. A leading `~` is expanded to the user's home
    /// directory; a trailing `/*` means "the direct contents of this dir".
    public var path: String

    public var safety: SafetyLevel
    public var explanation: String

    public init(
        id: UUID = UUID(),
        name: String,
        path: String,
        safety: SafetyLevel,
        explanation: String
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.safety = safety
        self.explanation = explanation
    }
}

extension CustomJunkRule {

    /// Converts this user-defined rule into the engine's internal `JunkRule`
    /// type so it can be evaluated alongside the built-in catalog.
    public func asJunkRule() -> JunkRule {
        JunkRule(
            id: "custom-\(id.uuidString)",
            name: name,
            category: .custom,
            safety: safety,
            paths: [path],
            explanation: explanation
        )
    }
}

/// Persists custom junk rules as JSON at
/// `~/Library/Application Support/DiskCleaner/custom-rules.json`.
public actor CustomRulesStore {

    public static let shared = CustomRulesStore()

    /// Path to the JSON file. Safe to read without `await` because it is set
    /// once during init and never changes.
    public nonisolated let fileURL: URL

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directory: URL? = nil) {
        let base = directory
            ?? (FileManager.default.urls(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask
                ).first
                ?? FileManager.default.temporaryDirectory)
        let appDirectory = base.appendingPathComponent("DiskCleaner", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: appDirectory, withIntermediateDirectories: true
        )
        self.fileURL = appDirectory.appendingPathComponent("custom-rules.json")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        self.decoder = JSONDecoder()
    }

    public func load() -> [CustomJunkRule] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? decoder.decode([CustomJunkRule].self, from: data)) ?? []
    }

    public func save(_ rules: [CustomJunkRule]) {
        guard let data = try? encoder.encode(rules) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Adds or replaces a rule (by id), then persists the catalogue.
    public func upsert(_ rule: CustomJunkRule) {
        var rules = load()
        rules.removeAll { $0.id == rule.id }
        rules.append(rule)
        save(rules)
    }

    public func remove(id: UUID) {
        var rules = load()
        rules.removeAll { $0.id == id }
        save(rules)
    }
}
