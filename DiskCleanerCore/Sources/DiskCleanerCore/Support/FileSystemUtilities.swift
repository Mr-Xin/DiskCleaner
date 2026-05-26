import Foundation

/// Small file-system helpers shared across the engine.
public enum FileSystemUtilities {

    /// The current user's home directory path.
    public static var homeDirectory: String {
        FileManager.default.homeDirectoryForCurrentUser.path
    }

    /// Expands a leading `~` in `path` to the user's home directory.
    public static func expandingTilde(_ path: String) -> String {
        if path == "~" { return homeDirectory }
        if path.hasPrefix("~/") { return homeDirectory + String(path.dropFirst(1)) }
        return path
    }

    /// Total allocated size on disk, in bytes, of a file or directory.
    ///
    /// Directories are summed recursively. Symbolic links are not followed.
    public static func totalAllocatedSize(of url: URL) -> Int64 {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .totalFileAllocatedSizeKey,
            .fileAllocatedSizeKey,
            .fileSizeKey
        ]
        guard let values = try? url.resourceValues(forKeys: keys) else { return 0 }
        if values.isSymbolicLink == true { return 0 }

        if values.isDirectory == true {
            guard let children = try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: Array(keys)
            ) else { return 0 }
            var total: Int64 = 0
            for child in children {
                total += totalAllocatedSize(of: child)
            }
            return total
        }

        let bytes = values.totalFileAllocatedSize
            ?? values.fileAllocatedSize
            ?? values.fileSize
            ?? 0
        return Int64(bytes)
    }
}
