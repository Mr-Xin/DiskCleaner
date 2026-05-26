import Foundation

/// A set of files whose contents are identical.
public struct DuplicateGroup: Identifiable, Sendable {

    public let id = UUID()

    /// The identical files. Always contains at least two entries.
    public let urls: [URL]

    /// Size of a single copy, in bytes.
    public let fileSize: Int64

    /// Bytes that could be reclaimed by keeping one copy and removing the rest.
    public var reclaimableBytes: Int64 {
        fileSize * Int64(max(0, urls.count - 1))
    }

    public init(urls: [URL], fileSize: Int64) {
        self.urls = urls
        self.fileSize = fileSize
    }
}

/// Finds duplicate files via a three-stage pipeline:
/// 1. group by size, 2. partial hash, 3. full hash.
///
/// Hard links are excluded by inode identity — deleting a hard link frees no
/// space. APFS clones are *not* detected (they have distinct inodes); that is
/// a known limitation to be addressed in a later phase.
public struct DuplicateFinder: Sendable {

    private let hashService = HashService()

    public init() {}

    /// Returns groups of identical files found among `files`, ordered by the
    /// amount of space each group could reclaim (largest first).
    public func findDuplicates(among files: [URL]) async throws -> [DuplicateGroup] {
        // Stage 1 — group by size; unique sizes cannot have duplicates.
        var bySize: [Int64: [URL]] = [:]
        for url in files {
            try Task.checkCancellation()
            guard let size = fileSize(of: url), size > 0 else { continue }
            bySize[size, default: []].append(url)
        }

        var groups: [DuplicateGroup] = []
        for (size, sameSize) in bySize where sameSize.count > 1 {
            // Stage 2 — partial (head + tail) hash.
            let byPartial = try await bucketed(sameSize) {
                try await hashService.partialHash(of: $0)
            }
            for partialBucket in byPartial where partialBucket.count > 1 {
                // Stage 3 — full content hash.
                let byFull = try await bucketed(partialBucket) {
                    try await hashService.fullHash(of: $0)
                }
                for fullBucket in byFull where fullBucket.count > 1 {
                    let unique = withoutHardLinkDuplicates(fullBucket)
                    if unique.count > 1 {
                        groups.append(DuplicateGroup(urls: unique, fileSize: size))
                    }
                }
            }
        }
        return groups.sorted { $0.reclaimableBytes > $1.reclaimableBytes }
    }

    /// Groups `urls` into buckets keyed by the value of `hash`.
    private func bucketed(
        _ urls: [URL],
        using hash: (URL) async throws -> String
    ) async throws -> [[URL]] {
        var buckets: [String: [URL]] = [:]
        for url in urls {
            try Task.checkCancellation()
            guard let key = try? await hash(url) else { continue }
            buckets[key, default: []].append(url)
        }
        return Array(buckets.values)
    }

    private func fileSize(of url: URL) -> Int64? {
        guard
            let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
            let size = values.fileSize
        else { return nil }
        return Int64(size)
    }

    /// Removes URLs that point at the same physical file (hard links).
    private func withoutHardLinkDuplicates(_ urls: [URL]) -> [URL] {
        var seenInodes: Set<Int> = []
        var result: [URL] = []
        for url in urls {
            if
                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                let inode = attributes[.systemFileNumber] as? Int
            {
                if seenInodes.contains(inode) { continue }
                seenInodes.insert(inode)
            }
            result.append(url)
        }
        return result
    }
}
