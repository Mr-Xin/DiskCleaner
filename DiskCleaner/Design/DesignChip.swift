//
//  DesignChip.swift
//  DiskCleaner
//
//  Pill-shaped status chip from the DiskFlow design tokens. Five variants —
//  default / active / good / warn / danger — with an optional colored dot
//  preceding the label. Matches `df-chip` in `hifi.css`.
//

import SwiftUI

enum DesignChipVariant {
    case `default`
    case active
    case good
    case warn
    case danger
}

struct DesignChip<Content: View>: View {

    let variant: DesignChipVariant
    let showsDot: Bool
    @ViewBuilder let content: () -> Content

    init(
        _ variant: DesignChipVariant = .default,
        showsDot: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.variant = variant
        self.showsDot = showsDot
        self.content = content
    }

    var body: some View {
        HStack(spacing: 6) {
            if showsDot {
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
                    .shadow(color: dotColor.opacity(0.7), radius: 3)
            }
            content()
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(backgroundColor)
        )
        .overlay(
            Capsule().strokeBorder(borderColor, lineWidth: 1)
        )
    }

    private var textColor: Color {
        switch variant {
        case .default, .active: return DesignTokens.Palette.text1
        case .good:             return DesignTokens.Palette.good
        case .warn:             return DesignTokens.Palette.warn
        case .danger:           return DesignTokens.Palette.danger
        }
    }

    private var dotColor: Color {
        switch variant {
        case .default: return DesignTokens.Palette.text3
        case .active:  return DesignTokens.Palette.blue
        case .good:    return DesignTokens.Palette.good
        case .warn:    return DesignTokens.Palette.warn
        case .danger:  return DesignTokens.Palette.danger
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .default: return DesignTokens.Palette.glass2
        case .active:  return DesignTokens.Palette.blue.opacity(0.14)
        case .good:    return DesignTokens.Palette.good.opacity(0.12)
        case .warn:    return DesignTokens.Palette.warn.opacity(0.12)
        case .danger:  return DesignTokens.Palette.danger.opacity(0.12)
        }
    }

    private var borderColor: Color {
        switch variant {
        case .default: return DesignTokens.Palette.line1
        case .active:  return DesignTokens.Palette.blue.opacity(0.35)
        case .good:    return DesignTokens.Palette.good.opacity(0.30)
        case .warn:    return DesignTokens.Palette.warn.opacity(0.30)
        case .danger:  return DesignTokens.Palette.danger.opacity(0.30)
        }
    }
}
