//
//  DesignToggle.swift
//  DiskCleaner
//
//  The 34×20 custom toggle from the DiskFlow design — blue gradient + glow
//  when on, glass surface when off. Matches `HiFiSettings.Toggle` in
//  `hifi-screens-2.jsx`.
//

import SwiftUI

struct DesignToggle: View {

    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(trackFill)
                    .frame(width: 34, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(borderColor, lineWidth: 1)
                    )
                    .shadow(
                        color: isOn ? DesignTokens.Palette.blue.opacity(0.4) : .clear,
                        radius: 4
                    )
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .padding(2)
                    .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isOn)
    }

    private var trackFill: AnyShapeStyle {
        if isOn {
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
        return AnyShapeStyle(DesignTokens.Palette.glass3)
    }

    private var borderColor: Color {
        isOn ? DesignTokens.Palette.blue.opacity(0.6) : DesignTokens.Palette.line2
    }
}
