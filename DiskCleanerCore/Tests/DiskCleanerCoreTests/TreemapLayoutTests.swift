import Foundation
import CoreGraphics
import Testing
@testable import DiskCleanerCore

struct TreemapLayoutTests {

    @Test func placesEveryItemWithinBounds() {
        let rect = CGRect(x: 0, y: 0, width: 400, height: 300)
        let items = [
            TreemapItem(id: UUID(), weight: 50),
            TreemapItem(id: UUID(), weight: 30),
            TreemapItem(id: UUID(), weight: 15),
            TreemapItem(id: UUID(), weight: 5)
        ]

        let tiles = TreemapLayout.layout(items: items, in: rect)

        #expect(tiles.count == items.count)
        for tile in tiles {
            #expect(tile.rect.minX >= rect.minX - 0.5)
            #expect(tile.rect.minY >= rect.minY - 0.5)
            #expect(tile.rect.maxX <= rect.maxX + 0.5)
            #expect(tile.rect.maxY <= rect.maxY + 0.5)
        }
    }

    @Test func largerWeightYieldsLargerArea() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 200)
        let bigID = UUID()
        let smallID = UUID()
        let items = [
            TreemapItem(id: bigID, weight: 75),
            TreemapItem(id: smallID, weight: 25)
        ]

        let tiles = TreemapLayout.layout(items: items, in: rect)
        let bigArea = tiles.first { $0.id == bigID }.map { $0.rect.width * $0.rect.height } ?? 0
        let smallArea = tiles.first { $0.id == smallID }.map { $0.rect.width * $0.rect.height } ?? 0

        #expect(bigArea > smallArea)
    }

    @Test func ignoresNonPositiveWeights() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let items = [
            TreemapItem(id: UUID(), weight: 10),
            TreemapItem(id: UUID(), weight: 0)
        ]

        let tiles = TreemapLayout.layout(items: items, in: rect)

        #expect(tiles.count == 1)
    }
}
