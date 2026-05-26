//
//  SettingsView.swift
//  DiskCleaner
//
//  The Settings scene (opened with Cmd+,) — five tabs of preferences backed
//  by `UserDefaults` via `@AppStorage` and by `CustomRulesStore` for the
//  custom-rules catalogue.
//

import SwiftUI
import AppKit
import DiskCleanerCore

struct SettingsView: View {

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("常规", systemImage: "gear") }
            DetectionSettingsView()
                .tabItem { Label("检测", systemImage: "magnifyingglass") }
            ExcludedPathsView()
                .tabItem { Label("扫描", systemImage: "rectangle.dashed") }
            CustomRulesView()
                .tabItem { Label("规则", systemImage: "list.bullet.rectangle") }
            ReminderSettingsView()
                .tabItem { Label("提醒", systemImage: "bell") }
        }
        .padding(20)
        .frame(width: 620, height: 400)
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

// MARK: - Excluded paths

private struct ExcludedPathsView: View {

    @State private var paths: [String] = []
    @State private var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("扫描时跳过这些目录")
                .font(.headline)
            Text("适合排除有大量缓存的开发目录、第三方备份目录等。")
                .font(.caption)
                .foregroundStyle(.secondary)

            List(selection: $selection) {
                ForEach(paths, id: \.self) { path in
                    Text(path)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .tag(path)
                }
            }
            .frame(minHeight: 180)

            HStack {
                Button { addPath() } label: {
                    Image(systemName: "plus")
                }
                Button {
                    if let path = selection { removePath(path) }
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(selection == nil)
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .onAppear { reload() }
    }

    private func reload() {
        paths = Array(AppSettings.excludedPaths()).sorted()
    }

    private func addPath() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "排除"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        AppSettings.addExcludedPath(url.path)
        reload()
    }

    private func removePath(_ path: String) {
        AppSettings.removeExcludedPath(path)
        selection = nil
        reload()
    }
}

// MARK: - Custom rules

private struct CustomRulesView: View {

    @State private var rules: [CustomJunkRule] = []
    @State private var selectedID: UUID?
    @State private var editingRule: CustomJunkRule?
    @State private var showingNewRule = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("额外的清理规则")
                .font(.headline)
            Text("在内置 10 条之外定义你自己的清理目标。规则会出现在「垃圾清理」结果里。")
                .font(.caption)
                .foregroundStyle(.secondary)

            List(selection: $selectedID) {
                ForEach(rules) { rule in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.name).lineLimit(1)
                            Text(rule.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        safetyBadge(rule.safety)
                    }
                    .tag(rule.id)
                }
            }
            .frame(minHeight: 180)

            HStack {
                Button { showingNewRule = true } label: {
                    Image(systemName: "plus")
                }
                Button {
                    if let id = selectedID, let rule = rules.first(where: { $0.id == id }) {
                        editingRule = rule
                    }
                } label: {
                    Image(systemName: "pencil")
                }
                .disabled(selectedID == nil)
                Button {
                    if let id = selectedID { deleteRule(id) }
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(selectedID == nil)
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .onAppear { reload() }
        .sheet(isPresented: $showingNewRule) {
            RuleEditSheet(
                rule: CustomJunkRule(
                    name: "",
                    path: "",
                    safety: .reviewNeeded,
                    explanation: ""
                ),
                onSave: persist
            )
        }
        .sheet(item: $editingRule) { rule in
            RuleEditSheet(rule: rule, onSave: persist)
        }
    }

    private func safetyBadge(_ safety: SafetyLevel) -> some View {
        Text(safety == .safe ? "安全" : "需确认")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                safety == .safe
                    ? Color.green.opacity(0.22)
                    : Color.orange.opacity(0.22),
                in: Capsule()
            )
    }

    private func reload() {
        Task {
            let loaded = await CustomRulesStore.shared.load()
            rules = loaded.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }

    private func persist(_ rule: CustomJunkRule) {
        Task {
            await CustomRulesStore.shared.upsert(rule)
            reload()
        }
    }

    private func deleteRule(_ id: UUID) {
        Task {
            await CustomRulesStore.shared.remove(id: id)
            selectedID = nil
            reload()
        }
    }
}

private struct RuleEditSheet: View {

    @State var rule: CustomJunkRule
    let onSave: (CustomJunkRule) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(rule.name.isEmpty ? "新建规则" : "编辑规则")
                .font(.title3)
                .fontWeight(.semibold)

            Form {
                TextField("名称", text: $rule.name)

                HStack(spacing: 6) {
                    TextField("路径（支持 ~ 与末尾 /*）", text: $rule.path)
                    Button("浏览…") { browseForPath() }
                }

                Picker("安全等级", selection: $rule.safety) {
                    Text("安全（默认勾选）").tag(SafetyLevel.safe)
                    Text("需确认（默认不勾选）").tag(SafetyLevel.reviewNeeded)
                }

                TextField("说明（可选）", text: $rule.explanation, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }
            .formStyle(.grouped)

            HStack {
                Button("取消", role: .cancel) { dismiss() }
                Spacer()
                Button("保存") {
                    onSave(rule)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(rule.name.isEmpty || rule.path.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 480, height: 340)
    }

    private func browseForPath() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.prompt = "选择"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        rule.path = url.path
    }
}

// MARK: - Reminder

private struct ReminderSettingsView: View {

    @AppStorage(AppSettings.reminderEnabledKey)
    private var reminderEnabled: Bool = false

    @AppStorage(AppSettings.reminderFrequencyKey)
    private var reminderFrequency: ReminderFrequency = AppSettings.reminderFrequencyDefault

    var body: some View {
        Form {
            Toggle("启用扫描提醒", isOn: $reminderEnabled)
                .onChange(of: reminderEnabled) { _, _ in
                    ScanReminder.shared.applyCurrentSettings()
                }

            Picker("提醒频率", selection: $reminderFrequency) {
                ForEach(ReminderFrequency.allCases) { frequency in
                    Text(frequency.label).tag(frequency)
                }
            }
            .pickerStyle(.menu)
            .disabled(!reminderEnabled)
            .onChange(of: reminderFrequency) { _, _ in
                if reminderEnabled {
                    ScanReminder.shared.applyCurrentSettings()
                }
            }

            Text("当上次扫描超过所选频率时，DiskCleaner 会发送系统通知提醒你。需要 app 在运行（即使在后台）才能触发。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SettingsView()
}
