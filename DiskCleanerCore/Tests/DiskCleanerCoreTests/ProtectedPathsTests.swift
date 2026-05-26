import Foundation
import Testing
@testable import DiskCleanerCore

struct ProtectedPathsTests {

    @Test func protectsSystemSubtrees() {
        #expect(ProtectedPaths.isProtected(URL(fileURLWithPath: "/System")))
        #expect(ProtectedPaths.isProtected(URL(fileURLWithPath: "/System/Library/CoreServices")))
        #expect(ProtectedPaths.isProtected(URL(fileURLWithPath: "/usr/bin")))
    }

    @Test func protectsCriticalDirectories() {
        #expect(ProtectedPaths.isProtected(URL(fileURLWithPath: "/")))
        #expect(ProtectedPaths.isProtected(URL(fileURLWithPath: "/Library")))
        #expect(ProtectedPaths.isProtected(URL(fileURLWithPath: "/Applications")))
    }

    @Test func protectsTheUserLibraryItself() {
        let library = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
        #expect(ProtectedPaths.isProtected(library))
    }

    @Test func allowsCacheFilesInsideUserLibrary() {
        let cacheItem = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches/com.example.app")
        #expect(!ProtectedPaths.isProtected(cacheItem))
    }
}
