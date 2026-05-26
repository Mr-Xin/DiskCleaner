import Foundation

/// A concrete junk item found on disk by matching a `JunkRule`.
public struct JunkItem: Identifiable, Sendable {

    public let id = UUID()
    public let rule: JunkRule
    public let url: URL
    public let size: Int64

    /// Display name of the item.
    public var name: String { url.lastPathComponent }

    public init(rule: JunkRule, url: URL, size: Int64) {
        self.rule = rule
        self.url = url
        self.size = size
    }
}

/// Matches the junk-rule catalog against the file system.
public struct JunkRulesEngine: Sendable {

    /// The rules this engine evaluates.
    public let rules: [JunkRule]

    public init(rules: [JunkRule] = JunkRuleCatalog.builtIn) {
        self.rules = rules
    }

    /// Scans the file system and returns every junk item the rules match.
    ///
    /// A rule path ending in `/*` contributes one `JunkItem` per direct child
    /// of that directory; any other path contributes a single item.
    public func scan() async throws -> [JunkItem] {
        let fileManager = FileManager.default
        var items: [JunkItem] = []

        for rule in rules {
            try Task.checkCancellation()
            for pattern in rule.paths {
                let expanded = FileSystemUtilities.expandingTilde(pattern)

                if expanded.hasSuffix("/*") {
                    let directory = String(expanded.dropLast(2))
                    guard let entries = try? fileManager.contentsOfDirectory(atPath: directory) else {
                        continue
                    }
                    for entry in entries {
                        try Task.checkCancellation()
                        let childURL = URL(fileURLWithPath: directory).appendingPathComponent(entry)
                        let size = FileSystemUtilities.totalAllocatedSize(of: childURL)
                        if size > 0 {
                            items.append(JunkItem(rule: rule, url: childURL, size: size))
                        }
                    }
                } else if fileManager.fileExists(atPath: expanded) {
                    let url = URL(fileURLWithPath: expanded)
                    let size = FileSystemUtilities.totalAllocatedSize(of: url)
                    if size > 0 {
                        items.append(JunkItem(rule: rule, url: url, size: size))
                    }
                }
            }
        }
        return items.sorted { $0.size > $1.size }
    }
}
