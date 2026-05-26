//
//  ConfirmationSheets.swift
//  DiskCleaner
//
//  v1.0 补完 — confirmation modals from DiskFlow §13.04:
//
//    • ConfirmDeleteSheet   — warns before trashing > 1 GB worth of files
//    • ConfirmUninstallSheet — confirms full uninstall + which leftover buckets
//
//  Both sheets follow the same shell: centered 440-480pt card, warning
//  icon, scrollable preview of what's about to leave the system, an
//  optional "don't ask again" checkbox, and Cancel / destructive buttons.
//

import SwiftUI

// MARK: - Confirm delete

/// 440pt centered card shown before bulk trashing > 1 GB.
struct ConfirmDeleteSheet: View {

    /// Names + bytes of items the user is about to delete. We show up to
    /// 6 and a "+N more" footer if there are more.
    let items: [(name: String, bytes: Int64)]
    let totalBytes: Int64
    var onCancel: () -> Void
    var onConfirm: () -> Void

    /// Sticky "don't ask again" preference. The key lives in UserDefaults.
    @State private var dontAskAgain: Bool = false

    static let dontAskKey = "DiskCleaner.confirmDelete.dontAsk"

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 18) {
                heroIcon
                VStack(spacing: 6) {
                    Text("confirm.delete.title")
                        .font(DesignTokens.Typography.h1)
                        .foregroundStyle(DesignTokens.Palette.text1)
                    Text(verbatim: String(
                        format: NSLocalizedString("confirm.delete.body", comment: ""),
                        ByteSizeFormatter.short(totalBytes)
                    ))
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.Palette.text3)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                }
                itemList
                dontAskRow
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 18)

            Divider().background(DesignTokens.Palette.line1)

            HStack(spacing: 10) {
                DesignButton(.ghost, action: onCancel) {
                    Text("confirm.cancel")
                        .frame(maxWidth: .infinity)
                }
                DesignButton(.danger, action: {
                    if dontAskAgain {
                        UserDefaults.standard.set(true, forKey: Self.dontAskKey)
                    }
                    onConfirm()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("confirm.delete.confirm")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .frame(width: 440)
        .background(MeshGradientBackground())
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xxl))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xxl)
                .strokeBorder(DesignTokens.Palette.line2, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.55), radius: 40, y: 16)
    }

    private var heroIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [DesignTokens.Palette.warn.opacity(0.35), .clear],
                        center: .center, startRadius: 0, endRadius: 60
                    )
                )
                .frame(width: 110, height: 110)
                .blur(radius: 10)
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [DesignTokens.Palette.warn.opacity(0.20),
                                 DesignTokens.Palette.warn.opacity(0.06)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 64, height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(DesignTokens.Palette.warn.opacity(0.4), lineWidth: 1)
                )
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(DesignTokens.Palette.warn)
        }
    }

    private var itemList: some View {
        let visible = Array(items.prefix(6))
        let hidden = items.count - visible.count
        return VStack(spacing: 0) {
            ForEach(Array(visible.enumerated()), id: \.offset) { idx, item in
                HStack {
                    Image(systemName: "doc")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.Palette.text3)
                    Text(verbatim: item.name)
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.Palette.text2)
                        .lineLimit(1)
                    Spacer()
                    Text(verbatim: ByteSizeFormatter.short(item.bytes))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(DesignTokens.Palette.text2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                if idx < visible.count - 1 {
                    Rectangle()
                        .fill(DesignTokens.Palette.line1.opacity(0.4))
                        .frame(height: 1)
                }
            }
            if hidden > 0 {
                Text(verbatim: String(
                    format: NSLocalizedString("confirm.delete.more", comment: ""), hidden
                ))
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.Palette.text4)
                .padding(.vertical, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .background(DesignTokens.Palette.glass2)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .strokeBorder(DesignTokens.Palette.line1, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
    }

    private var dontAskRow: some View {
        HStack(spacing: 8) {
            DesignCheckbox(on: dontAskAgain) { dontAskAgain.toggle() }
            Text("confirm.delete.dont_ask")
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.Palette.text3)
            Spacer()
        }
    }
}

// MARK: - Confirm uninstall

/// 480pt centered card shown before a "completely uninstall" action.
struct ConfirmUninstallSheet: View {

    let appName: String
    let appBundleURL: URL
    /// Items grouped by bucket label, in display order.
    let buckets: [(label: LocalizedStringKey, files: Int, bytes: Int64, isRisky: Bool)]
    let totalLeftoverBytes: Int64
    var onCancel: () -> Void
    var onConfirm: (_ keepAppSupport: Bool) -> Void

    @State private var keepAppSupport: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 18) {
                HStack(spacing: 14) {
                    AppIconView(bundleURL: appBundleURL, size: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("confirm.uninstall.title")
                            .font(DesignTokens.Typography.h1)
                            .foregroundStyle(DesignTokens.Palette.text1)
                        Text(verbatim: String(
                            format: NSLocalizedString("confirm.uninstall.body", comment: ""),
                            appName, ByteSizeFormatter.short(totalLeftoverBytes)
                        ))
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.Palette.text3)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }

                bucketList

                warningBanner

                HStack(spacing: 8) {
                    DesignCheckbox(on: keepAppSupport) { keepAppSupport.toggle() }
                    Text("confirm.uninstall.keep_support")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.Palette.text2)
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 18)

            Divider().background(DesignTokens.Palette.line1)

            HStack(spacing: 10) {
                DesignButton(.ghost, action: onCancel) {
                    Text("confirm.cancel").frame(maxWidth: .infinity)
                }
                DesignButton(.danger, action: { onConfirm(keepAppSupport) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("confirm.uninstall.confirm")
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .frame(width: 480)
        .background(MeshGradientBackground())
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xxl))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xxl)
                .strokeBorder(DesignTokens.Palette.line2, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.55), radius: 40, y: 16)
    }

    private var bucketList: some View {
        VStack(spacing: 0) {
            ForEach(Array(buckets.enumerated()), id: \.offset) { idx, bucket in
                HStack {
                    Text(bucket.label)
                        .font(.system(size: 12, weight: bucket.isRisky ? .semibold : .regular))
                        .foregroundStyle(bucket.isRisky ? DesignTokens.Palette.warn : DesignTokens.Palette.text2)
                    if bucket.isRisky {
                        DesignChip(.warn) { Text("confirm.uninstall.risky") }
                    }
                    Spacer()
                    Text(verbatim: String(
                        format: NSLocalizedString("confirm.uninstall.bucket_count", comment: ""),
                        bucket.files
                    ))
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.Palette.text3)
                    Text(verbatim: ByteSizeFormatter.short(bucket.bytes))
                        .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(DesignTokens.Palette.text2)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(bucket.isRisky ? DesignTokens.Palette.warn.opacity(0.06) : Color.clear)
                if idx < buckets.count - 1 {
                    Rectangle()
                        .fill(DesignTokens.Palette.line1.opacity(0.4))
                        .frame(height: 1)
                }
            }
        }
        .background(DesignTokens.Palette.glass2)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .strokeBorder(DesignTokens.Palette.line1, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
    }

    private var warningBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(DesignTokens.Palette.warn)
            Text("confirm.uninstall.note")
                .font(.system(size: 11.5))
                .foregroundStyle(DesignTokens.Palette.text2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(DesignTokens.Palette.warn.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .strokeBorder(DesignTokens.Palette.warn.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }
}

#Preview("Confirm Delete") {
    ConfirmDeleteSheet(
        items: [
            (name: "Big Video.mov", bytes: 4_300_000_000),
            (name: "Old archive.zip", bytes: 1_200_000_000),
            (name: "Backup.tar.gz", bytes: 800_000_000)
        ],
        totalBytes: 6_300_000_000,
        onCancel: {},
        onConfirm: {}
    )
    .frame(width: 600, height: 500)
}
