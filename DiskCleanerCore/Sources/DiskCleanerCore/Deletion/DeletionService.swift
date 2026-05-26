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
/// which is fully reversible. Each deletion writes an entry to the shared
/// `AuditLog` so the user can review what happened.
public struct DeletionService: Sendable {

    private let auditLog: AuditLog?

    public init(auditLog: AuditLog? = AuditLog.shared) {
        self.auditLog = auditLog
    }

    /// Moves the given files to the Trash and records each attempt in the
    /// audit log.
    ///
    /// - Parameters:
    ///   - urls: Files to delete.
    ///   - source: Short tag identifying which feature initiated the deletion;
    ///             recorded in the audit log entry.
    public func moveToTrash(
        _ urls: [URL],
        source: String = "unknown"
    ) async throws -> DeletionResult {
        for url in urls where ProtectedPaths.isProtected(url) {
            throw DeletionError.pathIsProtected(url)
        }

        let fileManager = FileManager.default
        var trashed: [URL] = []
        var failures: [FailedDeletion] = []

        for url in urls {
            try Task.checkCancellation()
            let sizeBefore = FileSystemUtilities.totalAllocatedSize(of: url)
            do {
                try fileManager.trashItem(at: url, resultingItemURL: nil)
                trashed.append(url)
                await auditLog?.record(AuditEntry(
                    timestamp: Date(),
                    url: url,
                    sizeBytes: sizeBefore,
                    source: source,
                    success: true
                ))
            } catch {
                failures.append(FailedDeletion(url: url, reason: error.localizedDescription))
                await auditLog?.record(AuditEntry(
                    timestamp: Date(),
                    url: url,
                    sizeBytes: sizeBefore,
                    source: source,
                    success: false
                ))
            }
        }

        return DeletionResult(trashed: trashed, failures: failures)
    }
}
