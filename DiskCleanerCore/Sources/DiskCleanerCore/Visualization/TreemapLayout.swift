import Foundation
import CoreGraphics

/// One positioned rectangle in a treemap layout.
public struct TreemapTile: Identifiable, Sendable {
    public let id: UUID
    public let rect: CGRect

    public init(id: UUID, rect: CGRect) {
        self.id = id
        self.rect = rect
    }
}

/// A weighted item to be placed in a treemap.
public struct TreemapItem: Sendable {
    public let id: UUID
    public let weight: Double

    public init(id: UUID, weight: Double) {
        self.id = id
        self.weight = weight
    }
}

/// Computes a squarified treemap layout — a pure geometry routine, kept free
/// of any UI dependency so it can be unit tested.
public enum TreemapLayout {

    /// Lays `items` out within `rect`, sized proportionally to their weights.
    ///
    /// Items with a non-positive weight are ignored. The returned tiles always
    /// lie within `rect`.
    public static func layout(items: [TreemapItem], in rect: CGRect) -> [TreemapTile] {
        let valid = items.filter { $0.weight > 0 }
        guard !valid.isEmpty, rect.width > 0, rect.height > 0 else { return [] }

        let totalWeight = valid.reduce(0.0) { $0 + $1.weight }
        let totalArea = Double(rect.width) * Double(rect.height)
        let areas = valid
            .map { (id: $0.id, area: $0.weight / totalWeight * totalArea) }
            .sorted { $0.area > $1.area }

        var tiles: [TreemapTile] = []
        var free = rect
        var row: [(id: UUID, area: Double)] = []

        func shortestSide(_ r: CGRect) -> Double {
            Double(min(r.width, r.height))
        }

        func worstAspectRatio(_ row: [(id: UUID, area: Double)], side: Double) -> Double {
            guard !row.isEmpty, side > 0 else { return .infinity }
            let rowAreas = row.map { $0.area }
            let sum = rowAreas.reduce(0, +)
            guard sum > 0, let maxArea = rowAreas.max(), let minArea = rowAreas.min(), minArea > 0 else {
                return .infinity
            }
            let side2 = side * side
            let sum2 = sum * sum
            return max(side2 * maxArea / sum2, sum2 / (side2 * minArea))
        }

        func flush(_ row: [(id: UUID, area: Double)], into container: inout CGRect) {
            let sum = row.reduce(0.0) { $0 + $1.area }
            guard sum > 0 else { return }

            if container.width >= container.height {
                // Lay the row as a column down the left edge.
                let columnWidth = CGFloat(sum / Double(container.height))
                var y = container.minY
                for item in row {
                    let height = CGFloat(item.area / sum) * container.height
                    tiles.append(TreemapTile(
                        id: item.id,
                        rect: CGRect(x: container.minX, y: y, width: columnWidth, height: height)
                    ))
                    y += height
                }
                container = CGRect(
                    x: container.minX + columnWidth,
                    y: container.minY,
                    width: max(0, container.width - columnWidth),
                    height: container.height
                )
            } else {
                // Lay the row across the top edge.
                let rowHeight = CGFloat(sum / Double(container.width))
                var x = container.minX
                for item in row {
                    let width = CGFloat(item.area / sum) * container.width
                    tiles.append(TreemapTile(
                        id: item.id,
                        rect: CGRect(x: x, y: container.minY, width: width, height: rowHeight)
                    ))
                    x += width
                }
                container = CGRect(
                    x: container.minX,
                    y: container.minY + rowHeight,
                    width: container.width,
                    height: max(0, container.height - rowHeight)
                )
            }
        }

        var index = 0
        while index < areas.count {
            let item = areas[index]
            let side = shortestSide(free)
            let current = worstAspectRatio(row, side: side)
            let candidate = worstAspectRatio(row + [item], side: side)

            if row.isEmpty || candidate <= current {
                row.append(item)
                index += 1
            } else {
                flush(row, into: &free)
                row = []
            }
        }
        if !row.isEmpty {
            flush(row, into: &free)
        }
        return tiles
    }
}
