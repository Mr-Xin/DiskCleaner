//
//  DesignCheckbox.swift
//  DiskCleaner
//
//  Custom checkbox used in tables and list rows across DiskFlow. Matches
//  `Check` in `hifi-shared.jsx`: 14×14 rounded square, glass background
//  when off; blue gradient + white ✓ when on. Also supports an
//  intermediate "indeterminate" state for group-header toggles.
//

import SwiftUI

enum DesignCheckboxState {
    case off
    case on
    case indeterminate  // some-children-selected — minus bar
}

struct DesignCheckbox: View {

    let state: DesignCheckboxState
    let action: () -> Void
    var size: CGFloat = 14

    init(
        _ state: DesignCheckboxState,
        action: @escaping () -> Void = {}
    ) {
        self.state = state
        self.action = action
    }

    /// Convenience initialiser taking a boolean.
    init(on: Bool, action: @escaping () -> Void = {}) {
        self.state = on ? .on : .off
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(borderColor, lineWidth: 1)
                    )
                    .shadow(
                        color: state == .on
                            ? DesignTokens.Palette.blue.opacity(0.35)
                            : .clear,
                        radius: 4
                    )
                checkmark
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.12), value: state)
    }

    @ViewBuilder
    private var checkmark: some View {
        switch state {
        case .off:
            EmptyView()
        case .on:
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.65, weight: .bold))
                .foregroundStyle(Color.white)
        case .indeterminate:
            Rectangle()
                .fill(Color.white)
                .frame(width: size * 0.55, height: 1.4)
        }
    }

    private var backgroundFill: AnyShapeStyle {
        switch state {
        case .off:
            return AnyShapeStyle(DesignTokens.Palette.glass2)
        case .on, .indeterminate:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        DesignTokens.Palette.blue,
                        Color(hex: 0x3a87f0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var borderColor: Color {
        switch state {
        case .off:                   return DesignTokens.Palette.line2
        case .on, .indeterminate:    return DesignTokens.Palette.blue.opacity(0.7)
        }
    }
}
