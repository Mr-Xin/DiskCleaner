//
//  DarkGlass.swift
//  DiskCleaner
//
//  The DiskFlow design uses several dark glass surfaces with slightly
//  different darkness levels (`rgba(11,14,20,α)` in the CSS). We approximate
//  them by stacking a dark tint over a SwiftUI `Material`.
//

import SwiftUI

extension View {

    /// Stacks a dark tint over a SwiftUI material to approximate the
    /// `rgba(11,14,20,α)` dark glass surfaces in the DiskFlow design.
    ///
    /// - Parameters:
    ///   - tintOpacity: Opacity of the dark tint layered on top of the
    ///                  material. Tune this to hit the design's α.
    ///   - material:    Underlying SwiftUI material. `.regularMaterial`
    ///                  matches the design most closely on dark backgrounds.
    func darkGlass(
        tintOpacity: Double = 0.30,
        material: Material = .regularMaterial
    ) -> some View {
        self
            .background(Color.black.opacity(tintOpacity))
            .background(material)
    }
}
