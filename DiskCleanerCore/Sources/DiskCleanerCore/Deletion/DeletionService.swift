import Foundation

/// Errors that can occur while deleting files.
public enum DeletionError: Error, Sendable {

    /// The path is protected and the deletion was refused (see `ProtectedPaths`).
    case pathIsProtected(URL)
}

/// A single failed deletion.
public struct FailedDeletion: Sendable {

    public let url: URL
    public let reason: String

    public init(url: URL, reason: String) {
        self.url = url
        self.reason = reason
    }
}

/// The outcome of a deletion request.
public struct DeletionResult: Sendable {

    /// Files successfully moved to the Trash.
    public let trashed: [URL]

    /// Files that could not be moved, each with a reason.
    public let failures: [FailedDeletion]

    /// Total bytes nominally reclaimed (sum of trashed file sizes is computed
    /// by the caller; this convenience is left to the UI layer for now).
    public var trashedCount: Int { trashed.count }

    public init(trashed: [URL], failures: [FailedDeletion]) {
        self.trashed = trashed
        self.failures = failures
    }
}

/// Performs deletions.
///
/// By design the default — and, for now, only — operation is "move to Trash",
/// which is fully reversible. Permanent deletion will be added later behind an
/// extra layer of confirmation.
public struct DeletionService: Sendable {

    public init() {}

    /// Moves the given files to the Trash.
    ///
    /// Every URL is first checked against `ProtectedPaths`. If *any* of them is
    /// protected, the whole batch is rejected before a single file is touched.
    /// Individual files that fail for other reasons (missing, no permission)
    /// are collected in `DeletionResult.failures` rather than aborting.
    public func moveToTrash(_ urls: [URL]) async throws -> DeletionResult {
        for url in urls where ProtectedPaths.isProtected(url) {
            throw DeletionError.pathIsProtected(url)
        }

        let fileManager = FileManager.default
        var trashed: [URL] = []
        var failures: [FailedDeletion] = []

        for url in urls {
            try Task.checkCancellation()
            do {
                try fileManager.trashItem(at: url, resultingItemURL: nil)
                trashed.append(url)
            } catch {
                failures.append(FailedDeletion(url: url, reason: error.localizedDescription))
            }
        }

        return DeletionResult(trashed: trashed, failures: failures)
    }
}
