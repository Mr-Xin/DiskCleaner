//
//  DesignCard.swift
//  DiskCleaner
//
//  Reusable card surface used across the DiskFlow screens. Matches the
//  `.df-card`, `.df-card.elevated`, and `.df-card.glow-blue` variants in
//  `hifi.css`.
//
//  - `.default`   — flat glass surface with a subtle border
//  - `.elevated`  — adds a soft drop shadow + brighter background
//  - `.glowBlue`  — primary CTA card with a blue glow (Health Score card)
//
//  The card itself only owns the chrome (background / border / shadow /
//  corner radius / padding); content layout is the caller's responsibility.
//

import SwiftUI

enum DesignCardVariant {
    case `default`
    case elevated
    case glowBlue
}

struct DesignCard<Content: View>: View {

    let variant: DesignCardVariant
    let padding: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        _ variant: DesignCardVariant = .default,
        padding: CGFloat = DesignTokens.Spacing.cardPadding,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.variant = variant
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
    }

    private var backgroundColor: Color {
        switch variant {
        case .default:  return DesignTokens.Palette.glass2
        case .elevated: return DesignTokens.Palette.glass3
        case .glowBlue: return DesignTokens.Palette.glass3
        }
    }

    private var borderColor: Color {
        switch variant {
        case .default:  return DesignTokens.Palette.line1
        case .elevated: return DesignTokens.Palette.line2
        case .glowBlue: return DesignTokens.Palette.blue.opacity(0.35)
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .default:  return .clear
        case .elevated: return Color.black.opacity(0.32)
        case .glowBlue: return DesignTokens.Palette.blue.opacity(0.28)
        }
    }

    private var shadowRadius: CGFloat {
        switch variant {
        case .default:  return 0
        case .elevated: return 16
        case .glowBlue: return 28
        }
    }

    private var shadowY: CGFloat {
        switch variant {
        case .default:  return 0
        case .elevated: return 4
        case .glowBlue: return 0
        }
    }
}
