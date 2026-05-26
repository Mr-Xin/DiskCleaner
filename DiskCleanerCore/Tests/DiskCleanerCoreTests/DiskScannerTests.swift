import Foundation
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

        let node = try await DiskScanner().scan(root: root)

        #expect(node.isDirectory)
        #expect(node.children.count == 2)          // a.txt and sub/
        #expect(node.logicalSize == 350)           // 100 + 250
    }

    /// A single file scans to a single, non-directory node.
    @Test func scansASingleFile() async throws {
        let fileManager = FileManager.default
        let file = fileManager.temporaryDirectory
            .appendingPathComponent("dcfile-\(UUID().uuidString).bin")
        try Data(repeating: 0x00, count: 4096).write(to: file)
        defer { try? fileManager.removeItem(at: file) }

        let node = try await DiskScanner().scan(root: file)

        #expect(!node.isDirectory)
        #expect(node.children.isEmpty)
        #expect(node.logicalSize == 4096)
    }
}
