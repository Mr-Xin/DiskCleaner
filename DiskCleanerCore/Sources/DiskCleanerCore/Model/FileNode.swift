import Foundation

/// A single node in a scanned file tree — either a file or a directory.
///
/// `FileNode` is a reference type so that a directory's aggregate size can be
/// updated in place as its children are discovered during a scan.
///
/// It is marked `@unchecked Sendable`: a scanned tree is treated as immutable
/// once `DiskScanner.scan` returns, and DiskCleaner only ever hands a finished
/// tree from a background scan to the main actor. Mutating a tree concurrently
/// is not supported.
public final class FileNode: Identifiable, @unchecked Sendable {

    /// Stable identity for use in SwiftUI lists and outlines.
    public let id = UUID()

    /// Location of the item on disk.
    public let url: URL

    /// Display name (the last path component).
    public let name: String

    /// Whether this node is a directory.
    public let isDirectory: Bool

    /// Logical size in bytes — the sum of file content sizes.
    public var logicalSize: Int64

    /// Actual size on disk in bytes — block-aligned allocation. This is the
    /// figure that matters for "how much space will I actually get back".
    public var allocatedSize: Int64

    /// Last modification date, when available.
    public var modificationDate: Date?

    /// Parent node. Declared `weak` to avoid a retain cycle.
    public weak var parent: FileNode?

    /// Child nodes. Empty for files.
    public var children: [FileNode]

    public init(
        url: URL,
        name: String,
        isDirectory: Bool,
        logicalSize: Int64 = 0,
        allocatedSize: Int64 = 0,
        modificationDate: Date? = nil,
        children: [FileNode] = []
    ) {
        self.url = url
        self.name = name
        self.isDirectory = isDirectory
        self.logicalSize = logicalSize
        self.allocatedSize = allocatedSize
        self.modificationDate = modificationDate
        self.children = children
    }
}

extension FileNode {

    /// Children sorted by allocated size, largest first.
    public var childrenBySize: [FileNode] {
        children.sorted { $0.allocatedSize > $1.allocatedSize }
    }

    /// Depth of this node from the root (root is 0).
    public var depth: Int {
        var depth = 0
        var current = parent
        while let node = current {
            depth += 1
            current = node.parent
        }
        return depth
    }

    /// Every file (non-directory) descendant. If this node is itself a file,
    /// the result is `[self]`.
    public func allFiles() -> [FileNode] {
        if !isDirectory { return [self] }
        return children.flatMap { $0.allFiles() }
    }

    /// Total number of items in the subtree (this node plus every descendant).
    public var totalItemCount: Int {
        1 + children.reduce(0) { $0 + $1.totalItemCount }
    }

    /// The chain of nodes from the root down to (and including) this node.
    public var pathFromRoot: [FileNode] {
        var chain: [FileNode] = []
        var current: FileNode? = self
        while let node = current {
            chain.append(node)
            current = node.parent
        }
        return chain.reversed()
    }
}
