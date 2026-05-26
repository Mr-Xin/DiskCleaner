import Foundation

/// Progress reported while a scan is running.
public struct ScanProgress: Sendable {

    /// Number of file-system items visited so far.
    public var scannedItemCount: Int

    /// Path most recently visited.
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

/// The outcome of a scan: the tree, plus auxiliary information about the run.
public struct ScanResult: Sendable {

    /// The scanned tree.
    public let root: FileNode

    /// Number of directories that could not be read because of permission or
    /// other errors. A large number when Full Disk Access is not granted is a
    /// hint to prompt the user.
    public let blockedDirectoryCount: Int

    public init(root: FileNode, blockedDirectoryCount: Int) {
        self.root = root
        self.blockedDirectoryCount = blockedDirectoryCount
    }
}

/// Walks a directory tree and builds a sized `FileNode` tree.
///
/// The top-level subtrees of the scanned root are walked in parallel via a
/// `TaskGroup`. Within each subtree the walk is sequential. A background task
/// samples the live progress at ~10 Hz and delivers it to `onProgress`, so
/// callers don't have to manage their own throttling.
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

    /// Scans the directory tree rooted at `url` and returns the result.
    public func scan(
        root url: URL,
        onProgress: (@Sendable (ScanProgress) -> Void)? = nil
    ) async throws -> ScanResult {
        let standardized = url.standardizedFileURL
        let accumulator = ScanAccumulator()

        // Background progress task. Sampling at a fixed cadence avoids
        // flooding the UI when scanning millions of files.
        let progressTask: Task<Void, Never>?
        if let onProgress {
            progressTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 100_000_000)  // ~10 Hz
                    if Task.isCancelled { return }
                    let snapshot = await accumulator.snapshot()
                    onProgress(snapshot)
                }
            }
        } else {
            progressTask = nil
        }

        do {
            let root = try await Self.scanRoot(at: standardized, accumulator: accumulator)
            progressTask?.cancel()
            if let onProgress {
                let final = await accumulator.snapshot()
                onProgress(final)
            }
            let blocked = await accumulator.blockedDirectoryCount
            return ScanResult(root: root, blockedDirectoryCount: blocked)
        } catch {
            progressTask?.cancel()
            throw error
        }
    }

    /// Scans the root and parallelises across its immediate subdirectories.
    private static func scanRoot(at url: URL, accumulator: ScanAccumulator) async throws -> FileNode {
        try Task.checkCancellation()

        let values = try url.resourceValues(forKeys: resourceKeys)
        let isDirectory = values.isDirectory ?? false
        let isSymlink = values.isSymbolicLink ?? false
        let name = values.name ?? url.lastPathComponent

        await accumulator.recordItem(at: url.path)

        guard isDirectory && !isSymlink else {
            let logical = Int64(values.fileSize ?? 0)
            let allocated = Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
            await accumulator.recordBytes(allocated)
            return FileNode(
                url: url,
                name: name,
                isDirectory: false,
                logicalSize: logical,
                allocatedSize: allocated,
                modificationDate: values.contentModificationDate
            )
        }

        let rootNode = FileNode(
            url: url,
            name: name,
            isDirectory: true,
            modificationDate: values.contentModificationDate
        )
        let children = await listChildren(of: url, accumulator: accumulator)

        try await withThrowingTaskGroup(of: FileNode.self) { group in
            for child in children {
                group.addTask {
                    try await scanSubtree(at: child, accumulator: accumulator)
                }
            }
            for try await childNode in group {
                childNode.parent = rootNode
                rootNode.children.append(childNode)
                rootNode.logicalSize += childNode.logicalSize
                rootNode.allocatedSize += childNode.allocatedSize
            }
        }

        return rootNode
    }

    /// Recursively scans a subtree. Sequential within itself; the parallelism
    /// comes from `scanRoot` running many of these concurrently.
    private static func scanSubtree(at url: URL, accumulator: ScanAccumulator) async throws -> FileNode {
        try Task.checkCancellation()

        let values = try url.resourceValues(forKeys: resourceKeys)
        let isDirectory = values.isDirectory ?? false
        let isSymlink = values.isSymbolicLink ?? false
        let name = values.name ?? url.lastPathComponent

        await accumulator.recordItem(at: url.path)

        guard isDirectory && !isSymlink else {
            let logical = Int64(values.fileSize ?? 0)
            let allocated = Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
            await accumulator.recordBytes(allocated)
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
        let children = await listChildren(of: url, accumulator: accumulator)

        for child in children {
            let childNode = try await scanSubtree(at: child, accumulator: accumulator)
            childNode.parent = node
            node.children.append(childNode)
            node.logicalSize += childNode.logicalSize
            node.allocatedSize += childNode.allocatedSize
        }
        return node
    }

    private static func listChildren(of url: URL, accumulator: ScanAccumulator) async -> [URL] {
        do {
            return try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: Array(resourceKeys),
                options: []
            )
        } catch {
            await accumulator.recordBlockedDirectory()
            return []
        }
    }
}
