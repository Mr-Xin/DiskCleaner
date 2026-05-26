//
//  Tokens.swift
//  DiskCleaner
//
//  Design tokens for the DiskFlow visual system. Mirrors the values in
//  `design_handoff_diskflow/hifi.css :root`. Anything visual elsewhere in the
//  app should pull from this namespace rather than hard-coding values.
//

import SwiftUI

enum DesignTokens {

    // MARK: - Colors

    enum Palette {

        // Backgrounds
        static let bg0 = Color(hex: 0x07090d)
        static let bg1 = Color(hex: 0x0d1117)
        static let bg2 = Color(hex: 0x11161f)
        static let bg3 = Color(hex: 0x161c27)

        // Glass surfaces (white over dark)
        static let glass1  = Color.white.opacity(0.03)
        static let glass2  = Color.white.opacity(0.05)
        static let glass3  = Color.white.opacity(0.08)
        static let glassHi = Color.white.opacity(0.12)

        // Borders / dividers
        static let line1 = Color.white.opacity(0.06)
        static let line2 = Color.white.opacity(0.10)
        static let line3 = Color.white.opacity(0.16)

        // Text
        static let text1 = Color(hex: 0xf0f3f8)  // primary
        static let text2 = Color(hex: 0xb6bfcf)  // secondary
        static let text3 = Color(hex: 0x7a8497)  // tertiary
        static let text4 = Color(hex: 0x4d566a)  // faint / labels

        // Soft neon accents
        static let blue   = Color(hex: 0x4d9eff)
        static let blueHi = Color(hex: 0x6fb3ff)
        static let cyan   = Color(hex: 0x5dd5e8)
        static let purple = Color(hex: 0x9b8bff)
        static let pink   = Color(hex: 0xd287ff)

        // Category colors
        static let catApps   = Color(hex: 0x4d9eff)
        static let catDocs   = Color(hex: 0x9b8bff)
        static let catVideo  = Color(hex: 0xd287ff)
        static let catPhoto  = Color(hex: 0xff8eb1)
        static let catSystem = Color(hex: 0x5dd5e8)
        static let catCache  = Color(hex: 0xffb55c)
        static let catOther  = Color(hex: 0x6e7991)

        // Semantic
        static let good   = Color(hex: 0x5fd49a)
        static let warn   = Color(hex: 0xffb45c)
        static let danger = Color(hex: 0xff6b7d)
    }

    // MARK: - Radii

    enum Radius {
        static let xs:   CGFloat = 4
        static let sm:   CGFloat = 6
        static let md:   CGFloat = 10
        static let lg:   CGFloat = 14
        static let xl:   CGFloat = 18
        static let xxl:  CGFloat = 22
        static let pill: CGFloat = 999
    }

    // MARK: - Typography

    enum Typography {
        static let h1         = Font.system(size: 24,   weight: .bold)
        static let h2         = Font.system(size: 15,   weight: .semibold)
        static let h3         = Font.system(size: 13,   weight: .semibold)
        static let body       = Font.system(size: 13,   weight: .regular)
        static let bodyMedium = Font.system(size: 12.5, weight: .medium)
        static let caption    = Font.system(size: 11.5, weight: .regular)
        static let label      = Font.system(size: 10.5, weight: .semibold)
        static let display    = Font.system(size: 56,   weight: .bold)
        static let mono       = Font.system(size: 12,   weight: .regular, design: .monospaced)
    }

    // MARK: - Spacing

    enum Spacing {
        static let cardPadding:      CGFloat = 18
        static let gridGap:          CGFloat = 14
        static let toolbarHeight:    CGFloat = 52
        static let titlebarHeight:   CGFloat = 38
        static let sidebarWidth:     CGFloat = 224
        static let previewPaneWidth: CGFloat = 280
        static let floatingBarHeight: CGFloat = 56
    }

    // MARK: - Shadows

    /// `shadow(color:radius:x:y:)` parameter triples for the documented shadow
    /// tokens. SwiftUI's single `.shadow` modifier can't compose multiple
    /// shadows; stack `.shadow` modifiers when a token specifies more than
    /// one layer (e.g. `shadow.md` is two layers).
    enum Shadow {
        static let smColor = Color.black.opacity(0.40)
        static let smRadius: CGFloat = 1
        static let smY: CGFloat = 1

        static let mdOuter = (color: Color.black.opacity(0.32), radius: CGFloat(16), y: CGFloat(4))
        static let mdInner = (color: Color.black.opacity(0.40), radius: CGFloat(2),  y: CGFloat(1))

        static let lgOuter = (color: Color.black.opacity(0.50), radius: CGFloat(40), y: CGFloat(12))
        static let lgInner = (color: Color.black.opacity(0.30), radius: CGFloat(6),  y: CGFloat(2))

        static let glowBlue = (color: Color(hex: 0x4d9eff).opacity(0.35), radius: CGFloat(24), y: CGFloat(0))
        static let glowCyan = (color: Color(hex: 0x5dd5e8).opacity(0.30), radius: CGFloat(24), y: CGFloat(0))
    }
}

// MARK: - Color hex init

extension Color {

    /// Hex initializer in the form `Color(hex: 0xRRGGBB)` (optionally with
    /// an opacity in `[0,1]`).
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
