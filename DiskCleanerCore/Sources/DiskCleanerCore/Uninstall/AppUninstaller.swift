import Foundation

/// An application installed on the system.
public struct InstalledApp: Identifiable, Sendable {

    public var id: String { bundleIdentifier }

    public let bundleIdentifier: String
    public let name: String
    public let bundleURL: URL

    public init(bundleIdentifier: String, name: String, bundleURL: URL) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.bundleURL = bundleURL
    }
}

/// How confident we are that a leftover file really belongs to an app.
public enum MatchConfidence: String, Sendable {

    /// Exact bundle-identifier match — safe to select by default.
    case high

    /// Fuzzy match on the app's name — should be confirmed by the user.
    case low
}

/// A file left behind by an application — a candidate for removal on uninstall.
public struct LeftoverFile: Identifiable, Sendable {

    public let id = UUID()
    public let url: URL
    public let size: Int64
    public let confidence: MatchConfidence

    /// Display name of the file.
    public var name: String { url.lastPathComponent }

    public init(url: URL, size: Int64, confidence: MatchConfidence) {
        self.url = url
        self.size = size
        self.confidence = confidence
    }
}

/// Lists installed applications and locates the files they leave behind.
public struct AppUninstaller: Sendable {

    public init() {}

    /// Standard locations searched for an app's leftover files, relative to
    /// the user's home directory.
    private static let leftoverSearchPaths: [String] = [
        "Library/Application Support",
        "Library/Caches",
        "Library/Logs",
        "Library/Preferences",
        "Library/Containers",
        "Library/Group Containers",
        "Library/Saved Application State",
        "Library/WebKit",
        "Library/HTTPStorages",
        "Library/Cookies",
        "Library/LaunchAgents"
    ]

    /// Enumerates applications in `/Applications` and `~/Applications`.
    public func installedApps() async throws -> [InstalledApp] {
        let fileManager = FileManager.default
        let directories = [
            URL(fileURLWithPath: "/Applications"),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        var apps: [InstalledApp] = []
        var seen: Set<String> = []

        for directory in directories {
            try Task.checkCancellation()
            guard let entries = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            ) else { continue }

            for entry in entries where entry.pathExtension == "app" {
                guard
                    let bundle = Bundle(url: entry),
                    let identifier = bundle.bundleIdentifier,
                    !seen.contains(identifier)
                else { continue }
                seen.insert(identifier)

                let name = (bundle.infoDictionary?["CFBundleName"] as? String)
                    ?? entry.deletingPathExtension().lastPathComponent
                apps.append(InstalledApp(
                    bundleIdentifier: identifier,
                    name: name,
                    bundleURL: entry
                ))
            }
        }
        return apps.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    /// Finds files associated with `app` across the standard Library locations.
    ///
    /// Matches are classified `.high` (the file name contains the bundle id)
    /// or `.low` (the file name contains the app's display name).
    public func leftovers(for app: InstalledApp) async throws -> [LeftoverFile] {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        let bundleID = app.bundleIdentifier.lowercased()
        let appName = app.name.lowercased()

        var results: [LeftoverFile] = []

        for relativePath in Self.leftoverSearchPaths {
            try Task.checkCancellation()
            let directory = home.appendingPathComponent(relativePath)
            guard let entries = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            ) else { continue }

            for entry in entries {
                let entryName = entry.lastPathComponent.lowercased()
                let confidence: MatchConfidence

                if entryName.contains(bundleID) {
                    confidence = .high
                } else if !appName.isEmpty && entryName.contains(appName) {
                    confidence = .low
                } else {
                    continue
                }

                let size = FileSystemUtilities.totalAllocatedSize(of: entry)
                results.append(LeftoverFile(url: entry, size: size, confidence: confidence))
            }
        }
        return results.sorted { $0.size > $1.size }
    }
}
