import Foundation
import CryptoKit

/// Computes content hashes used to confirm that two files are truly identical.
public struct HashService: Sendable {

    public init() {}

    /// A fast hash of the head and tail of a file — stage 2 of duplicate
    /// detection. It cheaply rules out files that merely share a size.
    public func partialHash(of url: URL, chunkSize: Int = 4096) async throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var hasher = SHA256()
        if let head = try handle.read(upToCount: chunkSize), !head.isEmpty {
            hasher.update(data: head)
        }
        let size = try handle.seekToEnd()
        if size > UInt64(chunkSize) {
            try handle.seek(toOffset: size - UInt64(chunkSize))
            if let tail = try handle.read(upToCount: chunkSize), !tail.isEmpty {
                hasher.update(data: tail)
            }
        }
        return Self.hexString(hasher.finalize())
    }

    /// A full streaming content hash — stage 3 of duplicate detection.
    public func fullHash(of url: URL) async throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var hasher = SHA256()
        while let chunk = try handle.read(upToCount: 1 << 20), !chunk.isEmpty {
            try Task.checkCancellation()
            hasher.update(data: chunk)
        }
        return Self.hexString(hasher.finalize())
    }

    private static func hexString<D: Digest>(_ digest: D) -> String {
        digest.map { String(format: "%02x", $0) }.joined()
    }
}
