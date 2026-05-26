//
//  ContentView.swift
//  DiskCleaner
//
//  The application shell. The top-level Feature selection is owned by
//  `DiskCleanerApp` so the menu bar's CommandMenu can drive it; ContentView
//  accepts it as a `Binding`.
//
//  The sidebar pins a footer button at its bottom edge that opens a popup
//  menu (Claude-style) with Settings, a Language submenu, and About — the
//  most common per-app actions one click away from anywhere in the app.
//

import SwiftUI
import AppKit
import DiskCleanerCore

/// Top-level features of DiskCleaner.
enum Feature: String, CaseIterable, Identifiable {
    case visualization
    case junk
    case duplicates
    case uninstall
    case history
    case audit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .visualization: "磁盘空间可视化"
        case .junk:          "垃圾清理"
        case .duplicates:    "大文件 / 重复文件"
        case .uninstall:     "应用卸载"
        case .history:       "扫描历史"
        case .audit:         "最近操作"
        }
    }

    var systemImage: String {
        switch self {
        case .visualization: "chart.pie"
        case .junk:          "trash"
        case .duplicates:    "doc.on.doc"
        case .uninstall:     "xmark.bin"
        case .history:       "chart.line.uptrend.xyaxis"
        case .audit:         "clock.arrow.circlepath"
        }
    }
}

struct ContentView: View {

    @Binding var selection: Feature?
    @State private var hasFullDiskAccess: Bool
    @State private var showOnboarding: Bool

    @AppStorage(AppSettings.appLanguageKey)
    private var appLanguage: AppLanguage = AppSettings.appLanguageDefault
    @State private var showLanguageRestartAlert = false

    init(selection: Binding<Feature?>) {
        self._selection = selection
        let granted = PermissionsChecker().hasFullDiskAccess()
        _hasFullDiskAccess = State(initialValue: granted)
        _showOnboarding = State(initialValue: !granted)
    }

    var body: some View {
        if showOnboarding {
            FullDiskAccessView(
                hasAccess: hasFullDiskAccess,
                onRecheck: { hasFullDiskAccess = PermissionsChecker().hasFullDiskAccess() },
                onContinue: { showOnboarding = false }
            )
        } else {
            mainView
                .alert("语言已更改", isPresented: $showLanguageRestartAlert) {
                    Button("立即重启") { relaunchApp() }
                    Button("稍后", role: .cancel) {}
                } message: {
                    Text("退出后再次打开 DiskCleaner，新语言才会生效。")
                }
        }
    }

    private var mainView: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(Feature.allCases, selection: $selection) { feature in
                    Label(feature.title, systemImage: feature.systemImage)
                        .tag(feature)
                }
                .navigationTitle("DiskCleaner")

                Divider()
                sidebarFooter
            }
            .navigationSplitViewColumnWidth(min: 210, ideal: 240)
        } detail: {
            detailView
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection ?? .visualization {
        case .visualization: DiskMapView()
        case .junk:          JunkCleaningView()
        case .duplicates:    DuplicatesView()
        case .uninstall:     UninstallView()
        case .history:       HistoryView()
        case .audit:         AuditLogView()
        }
    }

    // MARK: - Sidebar Footer Menu

    private var sidebarFooter: some View {
        Menu {
            SettingsLink {
                Label("设置", systemImage: "gearshape")
            }
            .keyboardShortcut(",", modifiers: .command)

            Menu {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        selectLanguage(language)
                    } label: {
                        languageMenuLabel(for: language)
                    }
                }
            } label: {
                Label("语言", systemImage: "globe")
            }

            Divider()

            Button {
                showAboutPanel()
            } label: {
                Label("关于 DiskCleaner", systemImage: "info.circle")
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.tint)
                    .frame(width: 32, height: 32)
                    .background(.tint.opacity(0.15), in: Circle())

                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: "DiskCleaner")
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text(verbatim: "v\(appVersion)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
    }

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0"
    }

    /// Each language is shown in its own name, with a checkmark on the
    /// currently selected one. "简体中文" and "English" stay untranslated;
    /// "跟随系统" follows the UI language.
    @ViewBuilder
    private func languageMenuLabel(for language: AppLanguage) -> some View {
        let isSelected = appLanguage == language
        Label {
            switch language {
            case .system:  Text("跟随系统")
            case .chinese: Text(verbatim: "简体中文")
            case .english: Text(verbatim: "English")
            }
        } icon: {
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
    }

    private func selectLanguage(_ language: AppLanguage) {
        guard language != appLanguage else { return }
        appLanguage = language
        language.apply()
        showLanguageRestartAlert = true
    }

    private func showAboutPanel() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel(nil)
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

#Preview {
    ContentView(selection: .constant(.visualization))
}
