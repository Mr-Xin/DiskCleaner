import Foundation
import DiskCleanerCoreBridge

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

/// Compact view of one directory child, populated either by the
/// `getattrlistbulk` fast path or the FileManager fallback.
struct ChildEntry: Sendable {
    let url: URL
    let name: String
    let isDirectory: Bool
    let isSymlink: Bool
    let logicalSize: Int64
    let allocatedSize: Int64

    static func fromURL(_ url: URL) -> ChildEntry? {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey, .isSymbolicLinkKey, .nameKey,
            .fileSizeKey, .totalFileAllocatedSizeKey
        ]
        guard let values = try? url.resourceValues(forKeys: keys) else { return nil }
        let name = values.name ?? url.lastPathComponent
        let isDir = values.isDirectory ?? false
        let isSym = values.isSymbolicLink ?? false
        let logical = Int64(values.fileSize ?? 0)
        let allocated = Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
        return ChildEntry(
            url: url, name: name,
            isDirectory: isDir, isSymlink: isSym,
            logicalSize: logical, allocatedSize: allocated
        )
    }
}

/// Walks a directory tree and builds a sized `FileNode` tree.
///
/// Strategy:
/// - Top-level subtrees of the scanned root are walked in parallel via a
///   `TaskGroup`. Within each subtree the walk is sequential.
/// - For each directory, child enumeration prefers the C bridge's
///   `getattrlistbulk` fast path (single syscall, all metadata inline) and
///   falls back to `FileManager.contentsOfDirectory` if the bulk call cannot
///   be used. The fallback also handles directories the bulk path opened
///   successfully but mid-enumeration errored.
/// - A background task samples accumulated progress at ~10 Hz and delivers
///   it to `onProgress`, so callers don't manage their own throttling.
public struct DiskScanner: Sendable {

    public init() {}

    /// Resource keys for the root entry (needed only for the root URL — child
    /// entries get their metadata from the bulk API or the FileManager
    /// fallback inside `listChildEntries`).
    private static let rootResourceKeys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isSymbolicLinkKey,
        .nameKey,
        .fileSizeKey,
        .totalFileAllocatedSizeKey,
        .contentModificationDateKey
    ]

    /// Scans the directory tree rooted at `url` and returns the result.
    ///
    /// - Parameters:
    ///   - url: Root directory (or file) to scan.
    ///   - excludedPaths: Standardised absolute paths to skip entirely.
    ///                    A matching directory is not entered; a matching
    ///                    file is not counted.
    ///   - onProgress: Optional callback invoked at ~10 Hz with progress.
    public func scan(
        root url: URL,
        excludedPaths: Set<String> = [],
        onProgress: (@Sendable (ScanProgress) -> Void)? = nil
    ) async throws -> ScanResult {
        let standardized = url.standardizedFileURL
        let accumulator = ScanAccumulator(excludedPaths: excludedPaths)

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
    private static func scanRoot(
        at url: URL,
        accumulator: ScanAccumulator
    ) async throws -> FileNode {
        try Task.checkCancellation()

        let values = try url.resourceValues(forKeys: rootResourceKeys)
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
        let children = await listChildEntries(of: url, accumulator: accumulator)

        try await withThrowingTaskGroup(of: FileNode.self) { group in
            for child in children {
                group.addTask {
                    try await scanSubtree(child, accumulator: accumulator)
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
    private static func scanSubtree(
        _ entry: ChildEntry,
        accumulator: ScanAccumulator
    ) async throws -> FileNode {
        try Task.checkCancellation()
        await accumulator.recordItem(at: entry.url.path)

        guard entry.isDirectory && !entry.isSymlink else {
            await accumulator.recordBytes(entry.allocatedSize)
            return FileNode(
                url: entry.url,
                name: entry.name,
                isDirectory: false,
                logicalSize: entry.logicalSize,
                allocatedSize: entry.allocatedSize,
                modificationDate: nil
            )
        }

        let node = FileNode(
            url: entry.url,
            name: entry.name,
            isDirectory: true,
            modificationDate: nil
        )
        let children = await listChildEntries(of: entry.url, accumulator: accumulator)
        for child in children {
            let childNode = try await scanSubtree(child, accumulator: accumulator)
            childNode.parent = node
            node.children.append(childNode)
            node.logicalSize += childNode.logicalSize
            node.allocatedSize += childNode.allocatedSize
        }
        return node
    }

    /// Lists the immediate children of `url`, preferring the bulk-enumeration
    /// fast path and falling back to FileManager on any failure. Entries
    /// whose path is in the accumulator's excluded set are dropped.
    private static func listChildEntries(
        of url: URL,
        accumulator: ScanAccumulator
    ) async -> [ChildEntry] {
        let entries: [ChildEntry]
        if let bulk = bulkListChildren(of: url) {
            entries = bulk
        } else {
            entries = await fallbackListChildren(of: url, accumulator: accumulator)
        }
        let excluded = accumulator.excludedPaths
        guard !excluded.isEmpty else { return entries }
        return entries.filter { !excluded.contains($0.url.standardizedFileURL.path) }
    }

    /// Fast path: enumerate via `getattrlistbulk`. Returns nil if the bridge
    /// could not open the directory or errored mid-enumeration; callers
    /// should fall back to FileManager.
    private static func bulkListChildren(of url: URL) -> [ChildEntry]? {
        guard let ctx = url.path.withCString({ path in dc_bulk_open(path) }) else {
            return nil
        }
        defer { dc_bulk_close(ctx) }

        let capacity = 64
        var buffer = [DCBulkEntry](repeating: DCBulkEntry(), count: capacity)
        var result: [ChildEntry] = []

        while true {
            let count = buffer.withUnsafeMutableBufferPointer { buf -> Int32 in
                dc_bulk_next(ctx, buf.baseAddress!, capacity)
            }
            if count < 0 { return nil }
            if count == 0 { break }
            for i in 0..<Int(count) {
                let raw = buffer[i]
                let name = withUnsafePointer(to: raw.name) { ptr -> String in
                    ptr.withMemoryRebound(to: CChar.self, capacity: 256) {
                        String(cString: $0)
                    }
                }
                if name.isEmpty || name == "." || name == ".." { continue }
                let childURL = url.appendingPathComponent(name)
                result.append(ChildEntry(
                    url: childURL,
                    name: name,
                    isDirectory: raw.is_directory != 0,
                    isSymlink: raw.is_symlink != 0,
                    logicalSize: raw.logical_size,
                    allocatedSize: raw.allocated_size
                ))
            }
        }
        return result
    }

    /// Fallback path: use FileManager + URLResourceValues. Slower (one stat
    /// per entry) but works everywhere.
    private static func fallbackListChildren(
        of url: URL,
        accumulator: ScanAccumulator
    ) async -> [ChildEntry] {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey, .isSymbolicLinkKey, .nameKey,
            .fileSizeKey, .totalFileAllocatedSizeKey
        ]
        do {
            let urls = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: Array(keys),
                options: []
            )
            return urls.compactMap { ChildEntry.fromURL($0) }
        } catch {
            await accumulator.recordBlockedDirectory()
            return []
        }
    }
}
