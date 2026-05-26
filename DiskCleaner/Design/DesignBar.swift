//
//  DesignBar.swift
//  DiskCleaner
//
//  Gradient-filled progress bar with a soft glow on the filled portion.
//  Matches `df-bar` / `df-bar-fill` in `hifi.css`. Four variants pull from
//  the design tokens — default (blue), good, warn, danger.
//

import SwiftUI

enum DesignBarVariant {
    case `default`
    case good
    case warn
    case danger
}

struct DesignBar: View {

    /// Fill ratio in `[0, 1]`. Values outside the range are clamped.
    var fill: Double
    var variant: DesignBarVariant = .default
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DesignTokens.Palette.glass2)
                    .overlay(
                        Capsule().strokeBorder(DesignTokens.Palette.line1, lineWidth: 1)
                    )

                Capsule()
                    .fill(gradient)
                    .frame(width: max(0, geo.size.width * clampedFill))
                    .shadow(color: glowColor.opacity(0.6), radius: 4, y: 0)
                    .animation(.easeOut(duration: 0.2), value: clampedFill)
            }
        }
        .frame(height: height)
    }

    private var clampedFill: Double { min(1, max(0, fill)) }

    private var gradient: LinearGradient {
        let colors: [Color]
        switch variant {
        case .default:
            colors = [DesignTokens.Palette.blue, DesignTokens.Palette.cyan]
        case .good:
            colors = [DesignTokens.Palette.good, Color(hex: 0x3ab787)]
        case .warn:
            colors = [DesignTokens.Palette.warn, Color(hex: 0xff8e3a)]
        case .danger:
            colors = [DesignTokens.Palette.danger, Color(hex: 0xff3d52)]
        }
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }

    private var glowColor: Color {
        switch variant {
        case .default: return DesignTokens.Palette.blue
        case .good:    return DesignTokens.Palette.good
        case .warn:    return DesignTokens.Palette.warn
        case .danger:  return DesignTokens.Palette.danger
        }
    }
}
