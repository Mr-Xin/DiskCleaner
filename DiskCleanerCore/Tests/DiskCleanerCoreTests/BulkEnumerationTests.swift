import Foundation
import Testing
import DiskCleanerCoreBridge
@testable import DiskCleanerCore

struct BulkEnumerationTests {

    /// Exercises the C bridge's bulk-enumeration path against a directory
    /// containing two files of known sizes and one subdirectory. Verifies
    /// the parser reads names, object types and file sizes correctly.
    @Test func enumeratesDirectoryWithKnownFiles() throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("dcbulk-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: directory) }

        let fileA = directory.appendingPathComponent("alpha.txt")
        let fileB = directory.appendingPathComponent("beta.bin")
        let subdir = directory.appendingPathComponent("sub", isDirectory: true)
        try Data(repeating: 0x41, count: 100).write(to: fileA)
        try Data(repeating: 0x42, count: 250).write(to: fileB)
        try fileManager.createDirectory(at: subdir, withIntermediateDirectories: true)

        let ctxOpt = directory.path.withCString { dc_bulk_open($0) }
        #expect(ctxOpt != nil, "dc_bulk_open should succeed on a temp directory")
        guard let ctx = ctxOpt else { return }
        defer { dc_bulk_close(ctx) }

        let capacity = 64
        var buffer = [DCBulkEntry](repeating: DCBulkEntry(), count: capacity)
        var names: Set<String> = []
        var logicalSize: [String: Int64] = [:]
        var isDirectory: [String: Bool] = [:]

        while true {
            let count = buffer.withUnsafeMutableBufferPointer { buf -> Int32 in
                dc_bulk_next(ctx, buf.baseAddress!, capacity)
            }
            #expect(count >= 0, "dc_bulk_next should not error")
            if count <= 0 { break }
            for i in 0..<Int(count) {
                let raw = buffer[i]
                let name = withUnsafePointer(to: raw.name) { ptr -> String in
                    ptr.withMemoryRebound(to: CChar.self, capacity: 256) {
                        String(cString: $0)
                    }
                }
                if name.isEmpty || name == "." || name == ".." { continue }
                names.insert(name)
                logicalSize[name] = raw.logical_size
                isDirectory[name] = raw.is_directory != 0
            }
        }

        #expect(names.contains("alpha.txt"))
        #expect(names.contains("beta.bin"))
        #expect(names.contains("sub"))
        #expect(logicalSize["alpha.txt"] == 100)
        #expect(logicalSize["beta.bin"] == 250)
        #expect(isDirectory["sub"] == true)
        #expect(isDirectory["alpha.txt"] == false)
        #expect(isDirectory["beta.bin"] == false)
    }

    /// Opening a non-existent path returns nil rather than crashing.
    @Test func openingNonexistentPathReturnsNil() {
        let nowhere = "/var/folders/this/path/should/not/exist/\(UUID().uuidString)"
        let ctx = nowhere.withCString { dc_bulk_open($0) }
        #expect(ctx == nil)
    }
}
