import Foundation
import Testing
@testable import DiskCleanerCore

struct FileSystemUtilitiesTests {

    @Test func expandsLeadingTilde() {
        let home = FileSystemUtilities.homeDirectory
        #expect(FileSystemUtilities.expandingTilde("~/Library/Caches") == home + "/Library/Caches")
        #expect(FileSystemUtilities.expandingTilde("~") == home)
        #expect(FileSystemUtilities.expandingTilde("/tmp/example") == "/tmp/example")
    }

    @Test func measuresFileSize() throws {
        let fileManager = FileManager.default
        let file = fileManager.temporaryDirectory
            .appendingPathComponent("dcsize-\(UUID().uuidString).bin")
        try Data(repeating: 0, count: 8192).write(to: file)
        defer { try? fileManager.removeItem(at: file) }

        // Allocated size is block-aligned, so it is at least the logical size.
        #expect(FileSystemUtilities.totalAllocatedSize(of: file) >= 8192)
    }
}
