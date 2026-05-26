import Foundation
import Testing
@testable import DiskCleanerCore

struct CustomRulesStoreTests {

    private func makeStore() throws -> (CustomRulesStore, URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("dccustom-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return (CustomRulesStore(directory: directory), directory)
    }

    @Test func savesAndLoadsRules() async throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let rule = CustomJunkRule(
            name: "Test Rule",
            path: "~/Library/Caches/test",
            safety: .safe,
            explanation: "test"
        )

        await store.save([rule])
        let loaded = await store.load()

        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Test Rule")
        #expect(loaded.first?.safety == .safe)
    }

    @Test func upsertReplacesExistingRuleById() async throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let rule = CustomJunkRule(
            name: "Original",
            path: "/tmp/x",
            safety: .reviewNeeded,
            explanation: ""
        )
        await store.upsert(rule)

        var updated = rule
        updated.name = "Updated"
        await store.upsert(updated)

        let loaded = await store.load()
        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Updated")
    }

    @Test func removeDeletesByID() async throws {
        let (store, directory) = try makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let rule = CustomJunkRule(
            name: "X",
            path: "/tmp/x",
            safety: .safe,
            explanation: ""
        )
        await store.upsert(rule)
        await store.remove(id: rule.id)

        let loaded = await store.load()
        #expect(loaded.isEmpty)
    }

    @Test func asJunkRuleProducesUniqueCustomCategoryRule() {
        let rule = CustomJunkRule(
            name: "Demo",
            path: "/tmp/demo",
            safety: .reviewNeeded,
            explanation: "hello"
        )
        let junkRule = rule.asJunkRule()
        #expect(junkRule.category == .custom)
        #expect(junkRule.safety == .reviewNeeded)
        #expect(junkRule.paths == ["/tmp/demo"])
        #expect(junkRule.id.hasPrefix("custom-"))
    }
}
