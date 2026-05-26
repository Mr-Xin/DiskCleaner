//
//  SettingsView.swift
//  DiskCleaner
//
//  The Settings scene (opened with Cmd+,) — preferences backed by
//  `UserDefaults` via `@AppStorage`.
//

import SwiftUI
import AppKit

struct SettingsView: View {

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("常规", systemImage: "gear") }
            DetectionSettingsView()
                .tabItem { Label("检测", systemImage: "magnifyingglass") }
        }
        .padding(20)
        .frame(width: 520, height: 280)
    }
}

// MARK: - General

private struct GeneralSettingsView: View {

    @AppStorage(AppSettings.appLanguageKey)
    private var appLanguage: AppLanguage = AppSettings.appLanguageDefault

    @AppStorage(AppSettings.defaultScanRootKey)
    private var defaultScanRoot: DefaultScanRoot = AppSettings.defaultScanRootDefault

    @State private var showRestartAlert = false

    var body: some View {
        Form {
            Picker("语言", selection: $appLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    label(for: language).tag(language)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: appLanguage) { _, newValue in
                newValue.apply()
                showRestartAlert = true
            }

            Picker("默认扫描位置", selection: $defaultScanRoot) {
                ForEach(DefaultScanRoot.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.menu)
        }
        .formStyle(.grouped)
        .alert("语言已更改", isPresented: $showRestartAlert) {
            Button("立即重启") { relaunchApp() }
            Button("稍后", role: .cancel) {}
        } message: {
            Text("退出后再次打开 DiskCleaner，新语言才会生效。")
        }
    }

    /// Each language is shown in its own name — "简体中文" and "English" stay
    /// the same regardless of UI language, while "跟随系统" is localized.
    @ViewBuilder
    private func label(for language: AppLanguage) -> some View {
        switch language {
        case .system:  Text("跟随系统")
        case .chinese: Text(verbatim: "简体中文")
        case .english: Text(verbatim: "English")
        }
    }

    private func relaunchApp() {
        let bundleURL = Bundle.main.bundleURL
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-n", bundleURL.path]
        try? process.run()
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Detection

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
