//
//  MeshGradientBackground.swift
//  DiskCleaner
//
//  The ambient "mesh gradient" backdrop used behind the whole DiskFlow shell:
//  a dark linear gradient with three soft neon radial highlights layered on
//  top (blue top-left, purple top-right, cyan bottom-centre).
//
//  Mirrors the CSS in `design_handoff_diskflow/hifi.css .df` background-image.
//

import SwiftUI

struct MeshGradientBackground: View {

    var body: some View {
        ZStack {
            // Base dark linear gradient.
            LinearGradient(
                colors: [
                    Color(hex: 0x0e131c),
                    Color(hex: 0x0a0d14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Soft blue highlight, top-left.
            GeometryReader { proxy in
                let size = proxy.size
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: DesignTokens.Palette.blue.opacity(0.16), location: 0.0),
                        .init(color: .clear,                                  location: 1.0)
                    ]),
                    center: UnitPoint(x: 0.12, y: -0.10),
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.75
                )
            }

            // Soft purple highlight, top-right.
            GeometryReader { proxy in
                let size = proxy.size
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: DesignTokens.Palette.purple.opacity(0.14), location: 0.0),
                        .init(color: .clear,                                    location: 1.0)
                    ]),
                    center: UnitPoint(x: 1.10, y: 0.10),
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.65
                )
            }

            // Cool cyan highlight, bottom-centre.
            GeometryReader { proxy in
                let size = proxy.size
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: DesignTokens.Palette.cyan.opacity(0.08), location: 0.0),
                        .init(color: .clear,                                  location: 1.0)
                    ]),
                    center: UnitPoint(x: 0.50, y: 1.20),
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.70
                )
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    MeshGradientBackground()
        .frame(width: 800, height: 500)
        .preferredColorScheme(.dark)
}
