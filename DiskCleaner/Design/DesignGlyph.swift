//
//  DesignGlyph.swift
//  DiskCleaner
//
//  The colored gradient square with a tiny uppercase code that shows up
//  on Smart Cleanup cards (Dashboard) and Large Files rows. Each "kind"
//  picks a color from the design's category palette and a default code.
//
//  Matches `.df-glyph` in `hifi.css`.
//

import SwiftUI

enum DesignGlyphKind {
    case apps
    case docs
    case video
    case photo
    case system
    case cache
    case folder
    case archive
    case other

    var color: Color {
        switch self {
        case .apps:    return DesignTokens.Palette.catApps
        case .docs:    return DesignTokens.Palette.catDocs
        case .video:   return DesignTokens.Palette.catVideo
        case .photo:   return DesignTokens.Palette.catPhoto
        case .system:  return DesignTokens.Palette.catSystem
        case .cache:   return DesignTokens.Palette.catCache
        case .folder:  return DesignTokens.Palette.catOther
        case .archive: return DesignTokens.Palette.catDocs
        case .other:   return DesignTokens.Palette.catOther
        }
    }
}

struct DesignGlyph: View {

    let kind: DesignGlyphKind
    /// 2–3 character uppercase code shown over the gradient square.
    let code: String
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            kind.color,
                            kind.color.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: kind.color.opacity(0.45), radius: 8, y: 2)

            Text(verbatim: code)
                .font(.system(size: size * 0.28, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.92))
                .tracking(0.5)
        }
        .frame(width: size, height: size)
    }
}
