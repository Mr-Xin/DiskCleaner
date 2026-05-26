import Foundation
import os.lock
import Testing
@testable import DiskCleanerCore

struct DiskScannerTests {

    /// Builds a known directory tree in a temporary location, scans it, and
    /// checks that sizes aggregate correctly.
    @Test func scansTreeAndAggregatesSizes() async throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("dcscan-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: root) }

        let subdirectory = root.appendingPathComponent("sub", isDirectory: true)
        try fileManager.createDirectory(at: subdirectory, withIntermediateDirectories: true)

        try Data(repeating: 0x41, count: 100).write(to: root.appendingPathComponent("a.txt"))
        try Data(repeating: 0x42, count: 250).write(to: subdirectory.appendingPathComponent("b.txt"))

        let result = try await DiskScanner().scan(root: root)

        #expect(result.root.isDirectory)
        #expect(result.root.children.count == 2)          // a.txt and sub/
        #expect(result.root.logicalSize == 350)           // 100 + 250
        #expect(result.blockedDirectoryCount == 0)
    }

    /// A single file scans to a single, non-directory node.
    @Test func scansASingleFile() async throws {
        let fileManager = FileManager.default
        let file = fileManager.temporaryDirectory
            .appendingPathComponent("dcfile-\(UUID().uuidString).bin")
        try Data(repeating: 0x00, count: 4096).write(to: file)
        defer { try? fileManager.removeItem(at: file) }

        let result = try await DiskScanner().scan(root: file)

        #expect(!result.root.isDirectory)
        #expect(result.root.children.isEmpty)
        #expect(result.root.logicalSize == 4096)
    }

    /// `onProgress` is called at least once — the scanner's final emit
    /// always fires when a handler is provided.
    @Test func emitsAtLeastOneProgressUpdate() async throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("dcprog-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: directory) }
        try Data(repeating: 0, count: 128)
            .write(to: directory.appendingPathComponent("file.bin"))

        let counter = OSAllocatedUnfairLock(initialState: 0)
        _ = try await DiskScanner().scan(root: directory) { _ in
            counter.withLock { $0 += 1 }
        }
        let total = counter.withLock { $0 }
        #expect(total >= 1)
    }
}
