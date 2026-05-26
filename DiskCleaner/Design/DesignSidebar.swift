//
//  DesignSidebar.swift
//  DiskCleaner
//
//  The 224pt-wide left navigation column of the DiskFlow shell:
//    brand row  →  WORKSPACE section  →  SYSTEM section  →  storage stat card
//
//  Both nav sections drive the same `selection` binding — Settings is just a
//  regular nav item in the SYSTEM section now (no special tap handler).
//  Labels and section headings come from `Localizable.xcstrings` so the UI
//  stays in sync with the user-chosen language.
//

import SwiftUI
import DiskCleanerCore

// MARK: - Model

struct DesignNavItem: Identifiable, Hashable {
    let id: String
    /// i18n key resolved via xcstrings (e.g. `"feature.overview"`).
    let labelKey: String
    let systemImage: String
    var badge: String? = nil

    init(id: String, labelKey: String, systemImage: String, badge: String? = nil) {
        self.id = id
        self.labelKey = labelKey
        self.systemImage = systemImage
        self.badge = badge
    }
}

struct StorageBreakdownSegment: Identifiable {
    let id = UUID()
    let color: Color
    let percent: Double  // 0...1
}

// MARK: - Sidebar

struct DesignSidebar: View {

    let workspaceItems: [DesignNavItem]
    let systemItems: [DesignNavItem]
    @Binding var selection: String?

    let brandName: String

    // Storage stat card data
    let storageVolume: String
    let storageUsedBytes: Int64
    let storageFreeBytes: Int64
    let storageBreakdown: [StorageBreakdownSegment]

    var body: some View {
        VStack(spacing: 2) {
            brandRow
                .padding(.bottom, 8)

            sectionLabel("sidebar.section.workspace")
            ForEach(workspaceItems) { item in
                navRow(item)
            }

            sectionLabel("sidebar.section.system")
            ForEach(systemItems) { item in
                navRow(item)
            }

            Spacer(minLength: 0)

            storageCard
        }
        .padding(EdgeInsets(top: 14, leading: 12, bottom: 14, trailing: 12))
        .frame(width: DesignTokens.Spacing.sidebarWidth, alignment: .top)
        .frame(maxHeight: .infinity)
        .darkGlass(tintOpacity: 0.40)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(DesignTokens.Palette.line1)
                .frame(width: 1)
        }
    }

    // MARK: Brand

    private var brandRow: some View {
        HStack(spacing: 10) {
            brandMark
            Text(verbatim: brandName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DesignTokens.Palette.text1)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
    }

    private var brandMark: some View {
        ZStack {
            LinearGradient(
                colors: [
                    DesignTokens.Palette.blue,
                    DesignTokens.Palette.purple,
                    DesignTokens.Palette.cyan
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(verbatim: String(brandName.prefix(1)))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 28, height: 28)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: DesignTokens.Palette.blue.opacity(0.35), radius: 7, x: 0, y: 4)
    }

    // MARK: Section label

    private func sectionLabel(_ key: String) -> some View {
        HStack {
            Text(LocalizedStringKey(key))
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.84)
                .foregroundStyle(DesignTokens.Palette.text4)
            Spacer()
        }
        .padding(EdgeInsets(top: 12, leading: 10, bottom: 6, trailing: 10))
    }

    // MARK: Nav rows

    private func navRow(_ item: DesignNavItem) -> some View {
        let isActive = selection == item.id
        return Button {
            selection = item.id
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 14))
                    .foregroundStyle(isActive
                                     ? DesignTokens.Palette.blueHi
                                     : DesignTokens.Palette.text3)
                    .frame(width: 18, height: 18)
                Text(LocalizedStringKey(item.labelKey))
                    .font(.system(size: 13, weight: isActive ? .medium : .regular))
                    .foregroundStyle(isActive
                                     ? DesignTokens.Palette.text1
                                     : DesignTokens.Palette.text2)
                Spacer()
                if let badge = item.badge {
                    Text(verbatim: badge)
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .foregroundStyle(DesignTokens.Palette.text2)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(DesignTokens.Palette.glass3, in: Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(activeBackground(isActive: isActive))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func activeBackground(isActive: Bool) -> some View {
        if isActive {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignTokens.Palette.blue.opacity(0.18),
                            DesignTokens.Palette.purple.opacity(0.12)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .strokeBorder(
                            DesignTokens.Palette.blue.opacity(0.25),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.20), radius: 2, x: 0, y: 1)
        } else {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(Color.clear)
        }
    }

    // MARK: Storage card

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(verbatim: storageVolume)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.Palette.text3)
                Spacer()
                healthChip
            }
            stackedBar
            HStack {
                statLine(labelKey: "sidebar.storage.used", value: ByteSize.formatted(storageUsedBytes))
                Spacer()
                statLine(labelKey: "sidebar.storage.free", value: ByteSize.formatted(storageFreeBytes))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Palette.glass1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .strokeBorder(DesignTokens.Palette.line1, lineWidth: 1)
        )
    }

    private var healthChip: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(DesignTokens.Palette.good)
                .frame(width: 6, height: 6)
                .shadow(color: DesignTokens.Palette.good, radius: 4)
            Text(LocalizedStringKey("sidebar.storage.healthy"))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DesignTokens.Palette.good)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 1)
        .background(DesignTokens.Palette.glass2, in: Capsule())
        .overlay(Capsule().strokeBorder(DesignTokens.Palette.line1, lineWidth: 1))
    }

    private var stackedBar: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(storageBreakdown) { segment in
                    Rectangle()
                        .fill(segment.color)
                        .frame(width: max(0, geo.size.width * CGFloat(segment.percent)))
                }
            }
        }
        .frame(height: 10)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(DesignTokens.Palette.line1, lineWidth: 1)
        )
    }

    private func statLine(labelKey: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(LocalizedStringKey(labelKey))
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.Palette.text3)
            Text(verbatim: value)
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundStyle(DesignTokens.Palette.text1)
        }
    }
}
