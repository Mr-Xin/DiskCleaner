//
//  DesignDonut.swift
//  DiskCleaner
//
//  Multi-segment donut chart used on the Dashboard (Overview) screen.
//  Renders each segment as a stroked arc on a circle with a small gap.
//  Caller supplies an array of `DonutSegment(percent, color)` where the
//  sum of percents is allowed to be ≤ 100 (any remainder is shown as a
//  muted background ring).
//
//  Optionally renders a centered label (big number) and sub-label.
//

import SwiftUI

struct DonutSegment: Identifiable {
    let id = UUID()
    let percent: Double  // 0...100
    let color: Color
}

struct DesignDonut: View {

    var segments: [DonutSegment]
    var size: CGFloat = 220
    var stroke: CGFloat = 26
    /// Localized big label centered in the ring (e.g. "312 GB"). Optional.
    var label: String?
    /// Localized sub-label rendered under the big label. Optional.
    var subLabel: String?

    /// Tiny gap between adjacent segments, in degrees.
    private let gapDegrees: Double = 1.4

    var body: some View {
        ZStack {
            // Background ring — also acts as the remainder when segments
            // sum to less than 100%.
            Circle()
                .stroke(
                    DesignTokens.Palette.glass2,
                    style: StrokeStyle(lineWidth: stroke, lineCap: .round)
                )

            // Segments.
            ForEach(Array(segments.enumerated()), id: \.element.id) { _, seg in
                let (start, end) = arcBounds(for: seg)
                Circle()
                    .trim(from: start, to: end)
                    .stroke(
                        seg.color,
                        style: StrokeStyle(lineWidth: stroke, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: seg.color.opacity(0.45), radius: 6)
            }

            // Center text.
            VStack(spacing: 2) {
                if let label {
                    Text(verbatim: label)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    DesignTokens.Palette.blueHi,
                                    DesignTokens.Palette.cyan
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                if let subLabel {
                    Text(verbatim: subLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.Palette.text3)
                }
            }
        }
        .frame(width: size, height: size)
    }

    /// Returns `(start, end)` trim positions in `[0,1]` for the given
    /// segment, taking the cumulative percent of preceding segments + the
    /// per-segment gap into account.
    private func arcBounds(for seg: DonutSegment) -> (Double, Double) {
        let totalGap = gapDegrees * Double(max(segments.count, 1))
        let usableDeg = 360.0 - totalGap

        var startDeg: Double = 0
        for s in segments {
            if s.id == seg.id { break }
            startDeg += usableDeg * (s.percent / 100.0) + gapDegrees
        }
        let segDeg = usableDeg * (seg.percent / 100.0)
        let endDeg = startDeg + segDeg

        return (startDeg / 360.0, endDeg / 360.0)
    }
}
