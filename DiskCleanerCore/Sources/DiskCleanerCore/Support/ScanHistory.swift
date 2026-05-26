import Foundation

/// One scan completed at a point in time. Stored to disk so the
/// "扫描历史" feature can plot trends.
public struct ScanSnapshot: Identifiable, Codable, Sendable {

    public var id: UUID
    public let timestamp: Date
    public let rootPath: String
    public let totalAllocatedBytes: Int64
    public let itemCount: Int

    public init(
        id: UUID = UUID(),
        timestamp: Date,
        rootPath: String,
        totalAllocatedBytes: Int64,
        itemCount: Int
    ) {
        self.id = id
        self.timestamp = timestamp
        self.rootPath = rootPath
        self.totalAllocatedBytes = totalAllocatedBytes
        self.itemCount = itemCount
    }
}

/// Append-only history of scan snapshots. JSONL at
/// `~/Library/Application Support/DiskCleaner/scan-history.jsonl`.
public actor ScanHistoryStore {

    public static let shared = ScanHistoryStore()

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
            at: appDirectory, withIntermediateDirectories: true
        )
        self.fileURL = appDirectory.appendingPathComponent("scan-history.jsonl")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    /// Appends a snapshot to the history file.
    public func record(_ snapshot: ScanSnapshot) {
        guard let data = try? encoder.encode(snapshot) else { return }
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

    /// Returns snapshots newest first, up to `limit`.
    public func loadAll(limit: Int = 500) -> [ScanSnapshot] {
        guard
            let data = try? Data(contentsOf: fileURL),
            let text = String(data: data, encoding: .utf8)
        else { return [] }

        let lines = text.split(separator: "\n").reversed().prefix(limit)
        var snapshots: [ScanSnapshot] = []
        snapshots.reserveCapacity(lines.count)
        for line in lines {
            guard let lineData = String(line).data(using: .utf8) else { continue }
            if let snapshot = try? decoder.decode(ScanSnapshot.self, from: lineData) {
                snapshots.append(snapshot)
            }
        }
        return snapshots
    }

    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
