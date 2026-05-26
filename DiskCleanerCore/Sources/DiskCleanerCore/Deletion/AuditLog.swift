import Foundation

/// One entry in the deletion audit log.
public struct AuditEntry: Codable, Sendable, Identifiable {

    /// Stable identity for SwiftUI lists.
    public var id: String { "\(timestamp.timeIntervalSince1970)-\(url.path)" }

    public let timestamp: Date
    public let url: URL

    /// Size on disk at the time the file was moved to the Trash, in bytes.
    public let sizeBytes: Int64

    /// Short tag describing which feature performed the deletion
    /// (`"disk-map"`, `"junk-clean"`, `"duplicates"`, `"uninstall"`).
    public let source: String

    /// `true` if the file was successfully moved to the Trash.
    public let success: Bool

    public init(
        timestamp: Date,
        url: URL,
        sizeBytes: Int64,
        source: String,
        success: Bool
    ) {
        self.timestamp = timestamp
        self.url = url
        self.sizeBytes = sizeBytes
        self.source = source
        self.success = success
    }

    enum CodingKeys: String, CodingKey {
        case timestamp, url, sizeBytes, source, success
    }
}

/// Append-only audit log of every deletion DiskCleaner performs.
///
/// Entries are written as JSONL (one JSON object per line) to
/// `~/Library/Application Support/DiskCleaner/audit.log`. An `actor` so that
/// concurrent writes from different features serialise cleanly.
public actor AuditLog {

    /// Default shared instance, backed by the app's Application Support
    /// directory.
    public static let shared = AuditLog()

    /// Path to the JSONL audit log file. Safe to read without `await`
    /// because it is set once during init and never changes.
    public nonisolated let fileURL: URL

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directory: URL? = nil) {
        let base = directory
            ?? (FileManager.default.urls(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask
                ).first
                ?? FileManager.default.temporaryDirectory)
        let appDirectory = base.appendingPathComponent("DiskCleaner", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: appDirectory,
            withIntermediateDirectories: true
        )
        self.fileURL = appDirectory.appendingPathComponent("audit.log")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    /// Appends a single entry to the log.
    public func record(_ entry: AuditEntry) {
        guard let data = try? encoder.encode(entry) else { return }
        var line = data
        line.append(0x0A) // '\n'

        let manager = FileManager.default
        if !manager.fileExists(atPath: fileURL.path) {
            manager.createFile(atPath: fileURL.path, contents: nil)
        }
        guard let handle = try? FileHandle(forWritingTo: fileURL) else { return }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: line)
    }

    /// Returns the most recent entries, newest first.
    public func readRecent(limit: Int = 200) -> [AuditEntry] {
        guard
            let data = try? Data(contentsOf: fileURL),
            let text = String(data: data, encoding: .utf8)
        else { return [] }

        let lines = text.split(separator: "\n").reversed().prefix(limit)
        var entries: [AuditEntry] = []
        entries.reserveCapacity(lines.count)
        for line in lines {
            guard let lineData = String(line).data(using: .utf8) else { continue }
            if let entry = try? decoder.decode(AuditEntry.self, from: lineData) {
                entries.append(entry)
            }
        }
        return entries
    }

    /// Removes the entire log file.
    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
