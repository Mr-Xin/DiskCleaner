//
//  SettingsView.swift
//  DiskCleaner
//
//  The Settings scene (opened with Cmd+,) — two tabs of preferences backed
//  by `UserDefaults` via `@AppStorage`.
//

import SwiftUI

struct SettingsView: View {

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("常规", systemImage: "gear") }
            DetectionSettingsView()
                .tabItem { Label("检测", systemImage: "magnifyingglass") }
        }
        .padding(20)
        .frame(width: 520, height: 240)
    }
}

private struct GeneralSettingsView: View {

    @AppStorage(AppSettings.defaultScanRootKey)
    private var defaultScanRoot: DefaultScanRoot = AppSettings.defaultScanRootDefault

    var body: some View {
        Form {
            Picker("默认扫描位置", selection: $defaultScanRoot) {
                ForEach(DefaultScanRoot.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.menu)
        }
        .formStyle(.grouped)
    }
}

private struct DetectionSettingsView: View {

    @AppStorage(AppSettings.largeFileThresholdMBKey)
    private var largeFileThresholdMB: Int = AppSettings.largeFileThresholdMBDefault

    @AppStorage(AppSettings.auditLogMaxEntriesKey)
    private var auditLogMaxEntries: Int = AppSettings.auditLogMaxEntriesDefault

    var body: some View {
        Form {
            Stepper(
                "大文件阈值：\(largeFileThresholdMB) MB",
                value: $largeFileThresholdMB,
                in: 10...2048,
                step: 10
            )
            Stepper(
                "审计日志保留上限：\(auditLogMaxEntries) 条",
                value: $auditLogMaxEntries,
                in: 50...5000,
                step: 50
            )
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SettingsView()
}
