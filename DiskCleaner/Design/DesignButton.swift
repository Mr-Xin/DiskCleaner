//
//  DesignButton.swift
//  DiskCleaner
//
//  The four button variants from the DiskFlow design tokens (default / primary
//  / ghost / danger) at two sizes (standard 32pt and small 26pt). Pulls colors
//  and radii from `DesignTokens`.
//

import SwiftUI

enum DesignButtonVariant {
    case `default`
    case primary
    case ghost
    case danger
}

enum DesignButtonSize {
    case standard
    case small
}

struct DesignButton<Label: View>: View {

    let variant: DesignButtonVariant
    let size: DesignButtonSize
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    init(
        _ variant: DesignButtonVariant = .default,
        size: DesignButtonSize = .standard,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.variant = variant
        self.size = size
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            label()
                .font(.system(
                    size: size == .small ? 11.5 : 12.5,
                    weight: variant == .primary ? .semibold : .medium
                ))
                .foregroundStyle(textColor)
                .padding(.horizontal, size == .small ? 10 : 14)
                .frame(height: size == .small ? 26 : 32)
                .background(backgroundView)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(
                    color: variant == .primary
                        ? DesignTokens.Palette.blue.opacity(0.35)
                        : .clear,
                    radius: 7,
                    x: 0,
                    y: 4
                )
        }
        .buttonStyle(.plain)
    }

    private var cornerRadius: CGFloat {
        size == .small ? 7 : DesignTokens.Radius.md
    }

    private var textColor: Color {
        switch variant {
        case .default, .ghost: return DesignTokens.Palette.text1
        case .primary:         return .white
        case .danger:          return DesignTokens.Palette.danger
        }
    }

    private var borderColor: Color {
        switch variant {
        case .default: return DesignTokens.Palette.line2
        case .primary: return DesignTokens.Palette.blue.opacity(0.6)
        case .ghost:   return DesignTokens.Palette.line1
        case .danger:  return DesignTokens.Palette.danger.opacity(0.25)
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .default:
            DesignTokens.Palette.glass2
        case .primary:
            LinearGradient(
                colors: [
                    DesignTokens.Palette.blue,
                    Color(hex: 0x3a87f0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .ghost:
            Color.clear
        case .danger:
            DesignTokens.Palette.danger.opacity(0.08)
        }
    }
}
