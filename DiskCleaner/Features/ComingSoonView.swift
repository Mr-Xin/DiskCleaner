//
//  ComingSoonView.swift
//  DiskCleaner
//
//  Generic placeholder for features the DiskFlow design defines but later
//  Sprints will implement (Overview / Memory / External). Sized to fit the
//  main content pane.
//

import SwiftUI

struct ComingSoonView: View {

    let title: String
    let systemImage: String
    let plannedSprint: String

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: systemImage)
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            DesignTokens.Palette.blue,
                            DesignTokens.Palette.purple,
                            DesignTokens.Palette.cyan
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: DesignTokens.Palette.blue.opacity(0.35), radius: 18)

            Text(verbatim: title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(DesignTokens.Palette.text1)

            Text("Coming in \(plannedSprint).")
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.Palette.text3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

#Preview {
    ComingSoonView(
        title: "Overview",
        systemImage: "square.grid.2x2",
        plannedSprint: "Sprint 2"
    )
    .frame(width: 800, height: 500)
    .background(MeshGradientBackground())
}
