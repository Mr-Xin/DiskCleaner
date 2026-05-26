import Foundation
import Testing
import DiskCleanerCoreBridge
@testable import DiskCleanerCore

struct CloneIDTests {

    /// Creates an APFS clone via `clonefile` and verifies both files report
    /// the same non-zero clone identifier. If the temporary volume happens
    /// not to support cloning, the test exits early rather than failing.
    @Test func clonedFilesShareCloneIdentifier() async throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("dcclone-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: directory) }

        let source = directory.appendingPathComponent("source.bin")
        let clone = directory.appendingPathComponent("clone.bin")
        try Data(repeating: 0x55, count: 4096).write(to: source)

        let cloneResult = source.path.withCString { sourcePtr in
            clone.path.withCString { clonePtr in
                dc_clone_file(sourcePtr, clonePtr)
            }
        }
        // Non-APFS volume → clonefile fails. Skip rather than fail.
        guard cloneResult == 0 else { return }

        let sourceID = source.path.withCString { dc_get_clone_id($0) }
        let cloneID = clone.path.withCString { dc_get_clone_id($0) }

        #expect(sourceID != 0)
        #expect(sourceID == cloneID)
    }

    @Test func nonexistentPathReturnsZero() async throws {
        let nowhere = "/var/folders/this/path/should/not/exist/\(UUID().uuidString)"
        let id = nowhere.withCString { dc_get_clone_id($0) }
        #expect(id == 0)
    }
}
