import Testing
@testable import DiskCleanerCore

struct JunkRuleCatalogTests {

    @Test func catalogIsNotEmpty() {
        #expect(!JunkRuleCatalog.builtIn.isEmpty)
    }

    @Test func everyRuleHasAtLeastOnePath() {
        #expect(JunkRuleCatalog.builtIn.allSatisfy { !$0.paths.isEmpty })
    }

    @Test func ruleIDsAreUnique() {
        let rules = JunkRuleCatalog.builtIn
        let ids = Set(rules.map(\.id))
        #expect(ids.count == rules.count)
    }
}
