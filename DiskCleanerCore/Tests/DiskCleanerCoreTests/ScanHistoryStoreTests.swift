import Foundation
import Testing
@testable import DiskCleanerCore

struct ScanHistoryStoreTests {

    private func makeStore() throws -> (ScanHistoryStore, URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("dchistory-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return (ScanHistoryStore(directory: directory), directory)
    }

    @Test func recordsAndLoadsSnapshots() async throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let snapshot = ScanSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_000_000),
            rootPath: "/Users/test/Documents",
            totalAllocatedBytes: 12_345,
            itemCount: 42
        )
        await store.record(snapshot)

        let loaded = await store.loadAll()
        #expect(loaded.count == 1)
        #expect(loaded.first?.rootPath == "/Users/test/Documents")
        #expect(loaded.first?.totalAllocatedBytes == 12_345)
        #expect(loaded.first?.itemCount == 42)
    }

    @Test func returnsSnapshotsNewestFirst() async throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let earlier = ScanSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_000),
            rootPath: "/a",
            totalAllocatedBytes: 100,
            itemCount: 1
        )
        let later = ScanSnapshot(
            timestamp: Date(timeIntervalSince1970: 2_000),
            rootPath: "/b",
            totalAllocatedBytes: 200,
            itemCount: 2
        )
        await store.record(earlier)
        await store.record(later)

        let loaded = await store.loadAll()
        #expect(loaded.count == 2)
        #expect(loaded.first?.rootPath == "/b")
        #expect(loaded.last?.rootPath == "/a")
    }

    @Test func clearRemovesAllSnapshots() async throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        await store.record(ScanSnapshot(
            timestamp: Date(),
            rootPath: "/x",
            totalAllocatedBytes: 1,
            itemCount: 1
        ))
        await store.clear()

        let loaded = await store.loadAll()
        #expect(loaded.isEmpty)
    }
}
