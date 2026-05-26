//
//  DesignToolbar.swift
//  DiskCleaner
//
//  The 52pt-tall toolbar that sits at the top of the main content area
//  (below the OS title bar): search field on the left, action icons on
//  the right. Dark glass background per the DiskFlow design tokens.
//

import SwiftUI

struct DesignToolbar<Trailing: View>: View {

    @Binding var searchText: String
    /// Placeholder text — i18n key resolved via `LocalizedStringKey`.
    let placeholderKey: String
    let onRefresh: () -> Void
    let onNotifications: () -> Void

    @ViewBuilder let trailingActions: () -> Trailing

    init(
        searchText: Binding<String>,
        placeholderKey: String = "toolbar.search.placeholder",
        onRefresh: @escaping () -> Void = {},
        onNotifications: @escaping () -> Void = {},
        @ViewBuilder trailingActions: @escaping () -> Trailing = { EmptyView() }
    ) {
        self._searchText = searchText
        self.placeholderKey = placeholderKey
        self.onRefresh = onRefresh
        self.onNotifications = onNotifications
        self.trailingActions = trailingActions
    }

    var body: some View {
        HStack(spacing: 10) {
            searchField
            Spacer(minLength: 0)
            iconButton(systemImage: "arrow.clockwise", action: onRefresh)
            iconButton(systemImage: "bell", action: onNotifications)
            trailingActions()
        }
        .padding(.horizontal, 18)
        .frame(height: DesignTokens.Spacing.toolbarHeight)
        .darkGlass(tintOpacity: 0.25)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DesignTokens.Palette.line1)
                .frame(height: 1)
        }
    }

    // MARK: Search field

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.Palette.text3)
            TextField(
                LocalizedStringKey(placeholderKey),
                text: $searchText,
                prompt: Text(LocalizedStringKey(placeholderKey))
                    .foregroundStyle(DesignTokens.Palette.text3)
            )
            .textFieldStyle(.plain)
            .font(.system(size: 12.5))
            .foregroundStyle(DesignTokens.Palette.text1)
            Spacer(minLength: 0)
            Text(verbatim: "⌘K")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(DesignTokens.Palette.text3)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.Palette.glass2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(DesignTokens.Palette.line1, lineWidth: 1)
                )
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .frame(maxWidth: 480)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Palette.glass2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .strokeBorder(DesignTokens.Palette.line1, lineWidth: 1)
        )
    }

    // MARK: Icon button (32×32)

    private func iconButton(
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.Palette.text2)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Palette.glass2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .strokeBorder(DesignTokens.Palette.line1, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
