import Foundation

/// Progress reported while a scan is running.
public struct ScanProgress: Sendable {

    /// Number of file-system items visited so far.
    public var scannedItemCount: Int

    /// Path currently being visited.
    public var currentPath: String

    /// Total bytes accounted for so far.
    public var bytesScanned: Int64

    public init(
        scannedItemCount: Int = 0,
        currentPath: String = "",
        bytesScanned: Int64 = 0
    ) {
        self.scannedItemCount = scannedItemCount
        self.currentPath = currentPath
        self.bytesScanned = bytesScanned
    }
}

/// Walks a directory tree and builds a sized `FileNode` tree.
///
/// This first implementation uses `FileManager`, which is correct and simple.
/// A later phase can swap in a `getattrlistbulk`-based fast path and parallel
/// subtree traversal without changing this public API.
public struct DiskScanner: Sendable {

    public init() {}

    /// Resource keys pre-fetched for every item, to avoid extra `stat` calls.
    private static let resourceKeys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isSymbolicLinkKey,
        .nameKey,
        .fileSizeKey,
        .totalFileAllocatedSizeKey,
        .contentModificationDateKey
    ]

    /// Scans the directory tree rooted at `url` and returns the root node,
    /// with aggregate sizes filled in.
    ///
    /// - Parameters:
    ///   - url: Root directory (or file) to scan.
    ///   - onProgress: Optional callback invoked as items are visited.
    /// - Throws: `CancellationError` if the surrounding `Task` is cancelled,
    ///   or a file-system error if the root itself cannot be read.
    public func scan(
        root url: URL,
        onProgress: (@Sendable (ScanProgress) -> Void)? = nil
    ) async throws -> FileNode {
        var progress = ScanProgress()
        return try Self.scanItem(
            at: url.standardizedFileURL,
            progress: &progress,
            onProgress: onProgress
        )
    }

    /// Recursively scans a single item, returning its `FileNode`.
    private static func scanItem(
        at url: URL,
        progress: inout ScanProgress,
        onProgress: (@Sendable (ScanProgress) -> Void)?
    ) throws -> FileNode {
        try Task.checkCancellation()

        let values = try url.resourceValues(forKeys: resourceKeys)
        let isDirectory = values.isDirectory ?? false
        let isSymlink = values.isSymbolicLink ?? false
        let name = values.name ?? url.lastPathComponent

        progress.scannedItemCount += 1
        progress.currentPath = url.path
        onProgress?(progress)

        // Symbolic links are not followed — this avoids cycles and the
        // double-counting of files reachable through more than one path.
        guard isDirectory && !isSymlink else {
            let logical = Int64(values.fileSize ?? 0)
            let allocated = Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
            progress.bytesScanned += allocated
            return FileNode(
                url: url,
                name: name,
                isDirectory: false,
                logicalSize: logical,
                allocatedSize: allocated,
                modificationDate: values.contentModificationDate
            )
        }

        let node = FileNode(
            url: url,
            name: name,
            isDirectory: true,
            modificationDate: values.contentModificationDate
        )

        // A directory we are not allowed to read is treated as empty rather
        // than aborting the whole scan.
        let children = (try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: []
        )) ?? []

        for child in children {
            let childNode = try scanItem(at: child, progress: &progress, onProgress: onProgress)
            childNode.parent = node
            node.children.append(childNode)
            node.logicalSize += childNode.logicalSize
            node.allocatedSize += childNode.allocatedSize
        }

        return node
    }
}
