//
//  FullDiskAccessView.swift
//  DiskCleaner
//
//  Onboarding screen that guides the user to grant Full Disk Access.
//

import SwiftUI
import AppKit

struct FullDiskAccessView: View {

    let hasAccess: Bool
    let onRecheck: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasAccess ? "checkmark.shield.fill" : "lock.shield")
                .font(.system(size: 60))
                .foregroundStyle(hasAccess ? Color.green : Color.orange)

            Text(hasAccess ? "已获得完全磁盘访问" : "需要完全磁盘访问")
                .font(.title)
                .fontWeight(.semibold)

            Text(explanation)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 440)

            if !hasAccess {
                VStack(alignment: .leading, spacing: 10) {
                    stepRow(1, "点击下方「打开系统设置」")
                    stepRow(2, "在列表中找到 DiskCleaner，打开它的开关")
                    stepRow(3, "回到本窗口，点击「重新检查」")
                }
                .padding(16)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))

                Button("打开系统设置") { openFullDiskAccessSettings() }
                    .controlSize(.large)
            }

            HStack(spacing: 12) {
                Button("重新检查", action: onRecheck)
                Button(hasAccess ? "开始使用" : "暂时跳过（部分功能受限）", action: onContinue)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 4)
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var explanation: String {
        hasAccess
        ? "DiskCleaner 现在可以扫描磁盘上的文件了。"
        : "DiskCleaner 需要完全磁盘访问，才能扫描系统各处的缓存、日志和大文件。这项权限只能由你在系统设置中手动授予。"
    }

    private func stepRow(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Color.accentColor, in: Circle())
            Text(text)
        }
    }

    private func openFullDiskAccessSettings() {
        // The pane identifier changed when System Preferences became System
        // Settings on macOS 13. Try the new id first, fall back to the old
        // one, and finally to launching System Settings on its own.
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        ]
        for urlString in candidates {
            if let url = URL(string: urlString), NSWorkspace.shared.open(url) {
                return
            }
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
    }
}

#Preview {
    FullDiskAccessView(hasAccess: false, onRecheck: {}, onContinue: {})
}
