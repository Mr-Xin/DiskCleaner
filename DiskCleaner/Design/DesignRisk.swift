//
//  DesignRisk.swift
//  DiskCleaner
//
//  Three-tier risk badge for the Smart Cleanup screen. Matches the
//  `<Risk level="…" />` component in `hifi-smart-cleanup.jsx`:
//    • `safe`    — green   — 安全
//    • `normal`  — blue    — 一般
//    • `caution` — amber   — 需复核
//
//  Renders as an 18pt-tall pill with a small glowing dot + localized label.
//  Both the label and the rest of the app use the `RiskLevel` enum to
//  classify items, so all "what risk is this" decisions live in one place.
//

import SwiftUI

enum RiskLevel: String, CaseIterable, Identifiable {
    case safe
    case normal
    case caution

    var id: String { rawValue }

    /// i18n key for the user-facing label.
    var labelKey: LocalizedStringKey {
        switch self {
        case .safe:    return "risk.safe.label"
        case .normal:  return "risk.normal.label"
        case .caution: return "risk.caution.label"
        }
    }

    var color: Color {
        switch self {
        case .safe:    return DesignTokens.Palette.good
        case .normal:  return DesignTokens.Palette.blueHi
        case .caution: return DesignTokens.Palette.warn
        }
    }
}

struct DesignRisk: View {

    let level: RiskLevel

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(level.color)
                .frame(width: 4, height: 4)
                .shadow(color: level.color, radius: 3)
            Text(level.labelKey)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(level.color)
        }
        .padding(.horizontal, 7)
        .frame(height: 18)
        .background(
            Capsule().fill(level.color.opacity(0.12))
        )
        .overlay(
            Capsule().strokeBorder(level.color.opacity(0.4), lineWidth: 1)
        )
    }
}
