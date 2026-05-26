//
//  SettingsScreen.swift
//  DiskCleaner
//
//  The DiskFlow-style Settings page, rendered inline as the `.settings`
//  Feature (not in a separate Settings scene). Single scrollable column
//  ≤ 760pt wide, four section cards (Scanning / Cleanup / Notifications /
//  Advanced), custom DesignToggle + Menu-based value cells, version footer.
//

import SwiftUI
import AppKit
import DiskCleanerCore

struct SettingsScreen: View {

    // MARK: AppStorage

    @AppStorage(AppSettings.defaultScanRootKey)
    private var defaultScanRoot: DefaultScanRoot = AppSettings.defaultScanRootDefault

    @AppStorage(AppSettings.largeFileThresholdMBKey)
    private var largeFileThresholdMB: Int = AppSettings.largeFileThresholdMBDefault

    @AppStorage(AppSettings.auditLogMaxEntriesKey)
    private var auditLogMaxEntries: Int = AppSettings.auditLogMaxEntriesDefault

    @AppStorage(AppSettings.reminderEnabledKey)
    private var reminderEnabled: Bool = false

    @AppStorage(AppSettings.reminderFrequencyKey)
    private var reminderFrequency: ReminderFrequency = AppSettings.reminderFrequencyDefault

    @AppStorage(AppSettings.appLanguageKey)
    private var appLanguage: AppLanguage = AppSettings.appLanguageDefault

    @State private var fdaGranted: Bool = PermissionsChecker().hasFullDiskAccess()
    @State private var showExcludedPathsSheet = false
    @State private var showCustomRulesSheet = false
    @State private var showLanguageRestartAlert = false

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("settings.title")
                    .font(DesignTokens.Typography.h1)
                    .foregroundStyle(DesignTokens.Palette.text1)

                scanningSection
                cleanupSection
                notificationsSection
                advancedSection
                footer
            }
            .padding(.vertical, 22)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 30)
        }
        .sheet(isPresented: $showExcludedPathsSheet) {
            ExcludedPathsSheet()
        }
        .sheet(isPresented: $showCustomRulesSheet) {
            CustomRulesSheet()
        }
        .alert("language.changed.title", isPresented: $showLanguageRestartAlert) {
            Button("language.changed.restart") { relaunchApp() }
            Button("language.changed.later", role: .cancel) {}
        } message: {
            Text("language.changed.body")
        }
        .onAppear {
            fdaGranted = PermissionsChecker().hasFullDiskAccess()
        }
    }

    // MARK: Sections

    private var scanningSection: some View {
        SettingsSection(titleKey: "settings.section.scanning") {
            settingsRow(
                labelKey: "settings.row.default_scan.label",
                subKey:   "settings.row.default_scan.sub"
            ) {
                Menu {
                    ForEach(DefaultScanRoot.allCases) { option in
                        Button { defaultScanRoot = option } label: {
                            Text(scanRootKey(option))
                        }
                    }
                } label: {
                    valueLabel(text: Text(scanRootKey(defaultScanRoot)))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            divider

            settingsRow(
                labelKey: "settings.row.excluded.label",
                subKey:   "settings.row.excluded.sub"
            ) {
                DesignButton(.ghost, size: .small, action: { showExcludedPathsSheet = true }) {
                    HStack(spacing: 4) {
                        Text("settings.row.excluded.action")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                }
            }

            divider

            settingsRow(
                labelKey: "settings.row.large_threshold.label",
                subKey:   "settings.row.large_threshold.sub"
            ) {
                Menu {
                    ForEach([10, 50, 100, 250, 500, 1024], id: \.self) { mb in
                        Button { largeFileThresholdMB = mb } label: {
                            Text(verbatim: "\(mb) MB")
                        }
                    }
                } label: {
                    valueLabel(text: Text(verbatim: "\(largeFileThresholdMB) MB"))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
    }

    private var cleanupSection: some View {
        SettingsSection(titleKey: "settings.section.cleanup") {
            settingsRow(
                labelKey: "settings.row.custom_rules.label",
                subKey:   "settings.row.custom_rules.sub"
            ) {
                DesignButton(.ghost, size: .small, action: { showCustomRulesSheet = true }) {
                    HStack(spacing: 4) {
                        Text("settings.row.custom_rules.action")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                }
            }

            divider

            settingsRow(
                labelKey: "settings.row.audit_max.label",
                subKey:   "settings.row.audit_max.sub"
            ) {
                Menu {
                    ForEach([100, 200, 500, 1000, 2000, 5000], id: \.self) { n in
                        Button { auditLogMaxEntries = n } label: {
                            Text(verbatim: "\(n)")
                        }
                    }
                } label: {
                    valueLabel(text: Text(verbatim: "\(auditLogMaxEntries)"))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
    }

    private var notificationsSection: some View {
        SettingsSection(titleKey: "settings.section.notifications") {
            settingsRow(
                labelKey: "settings.row.reminder.label",
                subKey:   "settings.row.reminder.sub"
            ) {
                DesignToggle(isOn: $reminderEnabled)
                    .onChange(of: reminderEnabled) { _, _ in
                        ScanReminder.shared.applyCurrentSettings()
                    }
            }

            divider

            settingsRow(
                labelKey: "settings.row.reminder_freq.label",
                subKey:   "settings.row.reminder_freq.sub"
            ) {
                Menu {
                    ForEach(ReminderFrequency.allCases) { f in
                        Button { reminderFrequency = f } label: {
                            Text(frequencyKey(f))
                        }
                    }
                } label: {
                    valueLabel(text: Text(frequencyKey(reminderFrequency)))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .disabled(!reminderEnabled)
                .opacity(reminderEnabled ? 1 : 0.5)
                .onChange(of: reminderFrequency) { _, _ in
                    if reminderEnabled {
                        ScanReminder.shared.applyCurrentSettings()
                    }
                }
            }
        }
    }

    private var advancedSection: some View {
        SettingsSection(titleKey: "settings.section.advanced") {
            settingsRow(
                labelKey: "settings.row.fda.label",
                subKey:   "settings.row.fda.sub"
            ) {
                if fdaGranted {
                    statusBadge(key: "settings.row.fda.granted", style: .good)
                } else {
                    DesignButton(.ghost, size: .small, action: openFDASettings) {
                        Text("settings.action.open_settings")
                    }
                }
            }

            divider

            settingsRow(
                labelKey: "settings.row.language.label",
                subKey:   "settings.row.language.sub"
            ) {
                Menu {
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            guard lang != appLanguage else { return }
                            appLanguage = lang
                            lang.apply()
                            showLanguageRestartAlert = true
                        } label: {
                            languageLabel(lang)
                        }
                    }
                } label: {
                    valueLabel(content: { languageLabel(appLanguage) })
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
    }

    private var footer: some View {
        HStack {
            Text(verbatim: footerText)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(DesignTokens.Palette.text3)
            Spacer()
            DesignButton(.ghost, size: .small, action: {}) {
                Text("settings.footer.update")
            }
            DesignButton(size: .small, action: showAbout) {
                Text("settings.footer.about")
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 30)
    }

    // MARK: Helpers

    private var divider: some View {
        Divider()
            .background(DesignTokens.Palette.line1)
            .padding(.horizontal, 18)
    }

    private func settingsRow<Trailing: View>(
        labelKey: LocalizedStringKey,
        subKey: LocalizedStringKey,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(labelKey)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DesignTokens.Palette.text1)
                Text(subKey)
                    .font(.system(size: 11.5))
                    .foregroundStyle(DesignTokens.Palette.text3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private func valueLabel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 4) {
            content()
                .font(.system(size: 12.5))
                .foregroundStyle(DesignTokens.Palette.text2)
            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundStyle(DesignTokens.Palette.text3)
        }
    }

    private func valueLabel(text: Text) -> some View {
        valueLabel { text }
    }

    private enum BadgeStyle {
        case good, warn, danger
    }

    private func statusBadge(key: LocalizedStringKey, style: BadgeStyle) -> some View {
        let color: Color = {
            switch style {
            case .good:   return DesignTokens.Palette.good
            case .warn:   return DesignTokens.Palette.warn
            case .danger: return DesignTokens.Palette.danger
            }
        }()
        return HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color, radius: 4)
            Text(key)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(DesignTokens.Palette.glass2, in: Capsule())
        .overlay(Capsule().strokeBorder(DesignTokens.Palette.line1, lineWidth: 1))
    }

    private func scanRootKey(_ option: DefaultScanRoot) -> LocalizedStringKey {
        switch option {
        case .home:     return "scan_root.home"
        case .lastUsed: return "scan_root.last_used"
        case .ask:      return "scan_root.ask"
        }
    }

    private func frequencyKey(_ f: ReminderFrequency) -> LocalizedStringKey {
        switch f {
        case .daily:   return "frequency.daily"
        case .weekly:  return "frequency.weekly"
        case .monthly: return "frequency.monthly"
        }
    }

    @ViewBuilder
    private func languageLabel(_ lang: AppLanguage) -> some View {
        switch lang {
        case .system:  Text("language.system")
        case .chinese: Text(verbatim: "简体中文")
        case .english: Text(verbatim: "English")
        }
    }

    private var footerText: String {
        let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0"
        let processInfo = ProcessInfo.processInfo
        let osVersion = processInfo.operatingSystemVersion
        let osString = "macOS \(osVersion.majorVersion).\(osVersion.minorVersion)"
        #if arch(arm64)
        let arch = "Apple Silicon"
        #else
        let arch = "Intel"
        #endif
        return "DiskFlow \(version) · \(osString) · \(arch)"
    }

    private func openFDASettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        ]
        for s in candidates {
            if let url = URL(string: s), NSWorkspace.shared.open(url) { return }
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
    }

    private func showAbout() {
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

// MARK: - Section card

private struct SettingsSection<Content: View>: View {

    let titleKey: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titleKey)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Palette.text1)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .fill(DesignTokens.Palette.glass2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .strokeBorder(DesignTokens.Palette.line2, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.32), radius: 16, y: 4)
        }
    }
}

// MARK: - Excluded paths sheet (ported from former SettingsView)

private struct ExcludedPathsSheet: View {

    @Environment(\.dismiss) private var dismiss
    @State private var paths: [String] = []
    @State private var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("settings.row.excluded.label")
                    .font(DesignTokens.Typography.h2)
                Spacer()
                DesignButton(.ghost, size: .small, action: { dismiss() }) {
                    Image(systemName: "xmark")
                }
            }
            Text("settings.row.excluded.sub")
                .font(.system(size: 11.5))
                .foregroundStyle(DesignTokens.Palette.text3)

            List(selection: $selection) {
                ForEach(paths, id: \.self) { path in
                    Text(verbatim: path)
                        .font(.system(size: 12, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .tag(path)
                }
            }
            .frame(minHeight: 220)

            HStack {
                DesignButton(action: addPath) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text(verbatim: "添加")
                    }
                }
                DesignButton(action: removePath) {
                    HStack(spacing: 4) {
                        Image(systemName: "minus")
                        Text(verbatim: "移除")
                    }
                }
                .disabled(selection == nil)
                Spacer()
            }
        }
        .padding(20)
        .frame(width: 540, height: 380)
        .onAppear(perform: reload)
    }

    private func reload() {
        paths = Array(AppSettings.excludedPaths()).sorted()
    }

    private func addPath() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        AppSettings.addExcludedPath(url.path)
        reload()
    }

    private func removePath() {
        guard let path = selection else { return }
        AppSettings.removeExcludedPath(path)
        selection = nil
        reload()
    }
}

// MARK: - Custom rules sheet (ported from former SettingsView)

private struct CustomRulesSheet: View {

    @Environment(\.dismiss) private var dismiss
    @State private var rules: [CustomJunkRule] = []
    @State private var selectedID: UUID?
    @State private var editingRule: CustomJunkRule?
    @State private var showingNewRule = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("settings.row.custom_rules.label")
                    .font(DesignTokens.Typography.h2)
                Spacer()
                DesignButton(.ghost, size: .small, action: { dismiss() }) {
                    Image(systemName: "xmark")
                }
            }
            Text("settings.row.custom_rules.sub")
                .font(.system(size: 11.5))
                .foregroundStyle(DesignTokens.Palette.text3)

            List(selection: $selectedID) {
                ForEach(rules) { rule in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: rule.name).lineLimit(1)
                            Text(verbatim: rule.path)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(DesignTokens.Palette.text3)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Text(verbatim: rule.safety == .safe ? "安全" : "需确认")
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(
                                (rule.safety == .safe
                                    ? DesignTokens.Palette.good
                                    : DesignTokens.Palette.warn).opacity(0.22),
                                in: Capsule()
                            )
                    }
                    .tag(rule.id)
                }
            }
            .frame(minHeight: 220)

            HStack {
                DesignButton(action: { showingNewRule = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text(verbatim: "新建")
                    }
                }
                DesignButton(action: editSelected) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text(verbatim: "编辑")
                    }
                }
                .disabled(selectedID == nil)
                DesignButton(action: deleteSelected) {
                    HStack(spacing: 4) {
                        Image(systemName: "minus")
                        Text(verbatim: "删除")
                    }
                }
                .disabled(selectedID == nil)
                Spacer()
            }
        }
        .padding(20)
        .frame(width: 600, height: 420)
        .onAppear(perform: reload)
        .sheet(isPresented: $showingNewRule) {
            RuleEditSheet(
                rule: CustomJunkRule(name: "", path: "", safety: .reviewNeeded, explanation: ""),
                onSave: persist
            )
        }
        .sheet(item: $editingRule) { rule in
            RuleEditSheet(rule: rule, onSave: persist)
        }
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

    private func editSelected() {
        guard let id = selectedID, let rule = rules.first(where: { $0.id == id }) else { return }
        editingRule = rule
    }

    private func deleteSelected() {
        guard let id = selectedID else { return }
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
        VStack(alignment: .leading, spacing: 14) {
            Text(verbatim: rule.name.isEmpty ? "新建规则" : "编辑规则")
                .font(DesignTokens.Typography.h2)

            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: "名称")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Palette.text3)
                TextField("", text: $rule.name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: "路径（支持 ~ 与末尾 /*）")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Palette.text3)
                HStack {
                    TextField("", text: $rule.path)
                        .textFieldStyle(.roundedBorder)
                    DesignButton(size: .small, action: browseForPath) {
                        Text(verbatim: "浏览…")
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: "安全等级")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Palette.text3)
                Picker("", selection: $rule.safety) {
                    Text(verbatim: "安全（默认勾选）").tag(SafetyLevel.safe)
                    Text(verbatim: "需确认（默认不勾选）").tag(SafetyLevel.reviewNeeded)
                }
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: "说明（可选）")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Palette.text3)
                TextField("", text: $rule.explanation, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3, reservesSpace: true)
            }

            HStack {
                DesignButton(.ghost, size: .small, action: { dismiss() }) {
                    Text(verbatim: "取消")
                }
                Spacer()
                DesignButton(.primary, size: .small, action: {
                    onSave(rule)
                    dismiss()
                }) {
                    Text(verbatim: "保存")
                }
                .disabled(rule.name.isEmpty || rule.path.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 460, height: 360)
    }

    private func browseForPath() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        rule.path = url.path
    }
}

#Preview {
    SettingsScreen()
        .frame(width: 900, height: 800)
        .background(MeshGradientBackground())
}
