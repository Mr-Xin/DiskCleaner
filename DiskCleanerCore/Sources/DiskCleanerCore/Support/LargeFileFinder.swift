import Foundation

/// A single large file surfaced from a scan.
public struct LargeFile: Identifiable, Sendable {

    public let id = UUID()
    public let url: URL
    public let size: Int64
    public let modificationDate: Date?

    /// Display name of the file.
    public var name: String { url.lastPathComponent }

    public init(url: URL, size: Int64, modificationDate: Date?) {
        self.url = url
        self.size = size
        self.modificationDate = modificationDate
    }
}

/// Surfaces the largest files within an already-scanned `FileNode` tree.
public struct LargeFileFinder: Sendable {

    public init() {}

    /// Returns files whose allocated size is at least `minimumSize`, ordered
    /// largest first.
    ///
    /// - Parameters:
    ///   - tree: A tree produced by `DiskScanner`.
    ///   - minimumSize: Size threshold in bytes. Defaults to 100 MB.
    ///   - limit: Maximum number of results to return.
    public func find(
        in tree: FileNode,
        minimumSize: Int64 = 100 * 1024 * 1024,
        limit: Int = 200
    ) -> [LargeFile] {
        let matches = tree.allFiles()
            .filter { $0.allocatedSize >= minimumSize }
            .sorted { $0.allocatedSize > $1.allocatedSize }
            .prefix(limit)

        return matches.map {
            LargeFile(url: $0.url, size: $0.allocatedSize, modificationDate: $0.modificationDate)
        }
    }
}
