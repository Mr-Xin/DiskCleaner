import Foundation
import Testing
@testable import DiskCleanerCore

struct AuditLogTests {

    private func makeLog() throws -> (AuditLog, URL) {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("dcaudit-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        return (AuditLog(directory: temp), temp)
    }

    @Test func recordsAndReadsBackEntries() async throws {
        let (log, temp) = try makeLog()
        defer { try? FileManager.default.removeItem(at: temp) }

        let entry = AuditEntry(
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            url: URL(fileURLWithPath: "/tmp/example.txt"),
            sizeBytes: 1024,
            source: "test",
            success: true
        )
        await log.record(entry)

        let read = await log.readRecent()
        #expect(read.count == 1)
        #expect(read.first?.sizeBytes == 1024)
        #expect(read.first?.source == "test")
        #expect(read.first?.success == true)
    }

    @Test func returnsEntriesNewestFirst() async throws {
        let (log, temp) = try makeLog()
        defer { try? FileManager.default.removeItem(at: temp) }

        let earlier = AuditEntry(
            timestamp: Date(timeIntervalSince1970: 1_000),
            url: URL(fileURLWithPath: "/a"),
            sizeBytes: 100,
            source: "test",
            success: true
        )
        let later = AuditEntry(
            timestamp: Date(timeIntervalSince1970: 2_000),
            url: URL(fileURLWithPath: "/b"),
            sizeBytes: 200,
            source: "test",
            success: true
        )
        await log.record(earlier)
        await log.record(later)

        let read = await log.readRecent()
        #expect(read.count == 2)
        #expect(read.first?.url == URL(fileURLWithPath: "/b"))
        #expect(read.last?.url == URL(fileURLWithPath: "/a"))
    }

    @Test func clearRemovesAllEntries() async throws {
        let (log, temp) = try makeLog()
        defer { try? FileManager.default.removeItem(at: temp) }

        await log.record(AuditEntry(
            timestamp: Date(),
            url: URL(fileURLWithPath: "/x"),
            sizeBytes: 1,
            source: "test",
            success: true
        ))
        await log.clear()

        let read = await log.readRecent()
        #expect(read.isEmpty)
    }
}
