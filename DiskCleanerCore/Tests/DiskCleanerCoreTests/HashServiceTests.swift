import Foundation
import Testing
@testable import DiskCleanerCore

struct HashServiceTests {

    @Test func identicalFilesHaveEqualHashes() async throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("dchash-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: directory) }

        let content = Data("the quick brown fox".utf8)
        let fileA = directory.appendingPathComponent("a.txt")
        let fileB = directory.appendingPathComponent("b.txt")
        try content.write(to: fileA)
        try content.write(to: fileB)

        let service = HashService()
        let hashA = try await service.fullHash(of: fileA)
        let hashB = try await service.fullHash(of: fileB)

        #expect(hashA == hashB)
        #expect(!hashA.isEmpty)
    }

    @Test func differentFilesHaveDifferentHashes() async throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("dchash-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: directory) }

        let fileA = directory.appendingPathComponent("a.txt")
        let fileB = directory.appendingPathComponent("b.txt")
        try Data("aaaaaaaa".utf8).write(to: fileA)
        try Data("bbbbbbbb".utf8).write(to: fileB)

        let service = HashService()
        let hashA = try await service.fullHash(of: fileA)
        let hashB = try await service.fullHash(of: fileB)

        #expect(hashA != hashB)
    }
}
