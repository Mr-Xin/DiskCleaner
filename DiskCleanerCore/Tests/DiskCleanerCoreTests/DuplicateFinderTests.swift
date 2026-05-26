import Foundation
import Testing
@testable import DiskCleanerCore

struct DuplicateFinderTests {

    @Test func findsIdenticalFilesEvenWhenSizesCollide() async throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("dcdup-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: directory) }

        // Two identical files plus one of the same *size* but different content.
        let duplicateContent = Data(repeating: 0x7A, count: 2048)
        let dup1 = directory.appendingPathComponent("dup1.bin")
        let dup2 = directory.appendingPathComponent("dup2.bin")
        let unique = directory.appendingPathComponent("unique.bin")
        try duplicateContent.write(to: dup1)
        try duplicateContent.write(to: dup2)
        try Data(repeating: 0x42, count: 2048).write(to: unique)

        let groups = try await DuplicateFinder().findDuplicates(among: [dup1, dup2, unique])

        #expect(groups.count == 1)
        #expect(groups.first?.urls.count == 2)
        #expect(groups.first?.fileSize == 2048)
    }

    @Test func reportsNoDuplicatesWhenAllFilesDiffer() async throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("dcdup-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: directory) }

        let fileA = directory.appendingPathComponent("a.bin")
        let fileB = directory.appendingPathComponent("b.bin")
        try Data(repeating: 0x01, count: 1024).write(to: fileA)
        try Data(repeating: 0x02, count: 512).write(to: fileB)

        let groups = try await DuplicateFinder().findDuplicates(among: [fileA, fileB])

        #expect(groups.isEmpty)
    }
}
