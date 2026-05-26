import Foundation

/// The safety guard that prevents DiskCleaner from ever deleting a path that
/// is critical to the system or to the user.
///
/// Every deletion performed by `DeletionService` is checked against
/// `isProtected(_:)` first. This is the single most important safety net in
/// the whole tool, so it is implemented and unit tested from day one.
public enum ProtectedPaths {

    /// Subtrees that must never be touched at all — neither the directory
    /// itself nor anything inside it.
    public static let forbiddenSubtrees: [String] = [
        "/System",
        "/usr",
        "/bin",
        "/sbin",
        "/dev",
        "/cores"
    ]

    /// Directories that must not be deleted *themselves*, even though specific
    /// files inside them (for example caches) may legitimately be cleaned.
    public static var criticalDirectories: Set<String> {
        var dirs: Set<String> = [
            "/",
            "/Library",
            "/Applications",
            "/Users",
            "/private",
            "/etc",
            "/var",
            "/tmp",
            "/opt"
        ]
        let home = normalized(FileManager.default.homeDirectoryForCurrentUser)
        dirs.insert(home)
        for sub in [
            "Library",
            "Library/Keychains",
            "Library/Preferences",
            "Documents",
            "Desktop",
            "Downloads",
            "Movies",
            "Music",
            "Pictures"
        ] {
            dirs.insert(home + "/" + sub)
        }
        return dirs
    }

    /// Returns `true` if `url` points to a path that DiskCleaner must refuse
    /// to delete.
    public static func isProtected(_ url: URL) -> Bool {
        let path = normalized(url)
        for subtree in forbiddenSubtrees where path == subtree || path.hasPrefix(subtree + "/") {
            return true
        }
        return criticalDirectories.contains(path)
    }

    /// Standardizes a file URL into an absolute path with no trailing slash.
    private static func normalized(_ url: URL) -> String {
        var path = url.standardizedFileURL.path
        while path.count > 1 && path.hasSuffix("/") {
            path.removeLast()
        }
        return path
    }
}
