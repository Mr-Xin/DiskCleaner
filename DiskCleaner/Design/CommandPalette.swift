//
//  CommandPalette.swift
//  DiskCleaner
//
//  Sprint 9 — ⌘K command palette per DiskFlow §05.
//
//  620pt centered overlay panel: search input (Lucide-style sparkle icon
//  + caret) and four grouped result sections (Recommended / Navigate /
//  Actions / Recent). The highlighted row gets a blue left stripe and a
//  subtle blue tint, matching the design.
//

import SwiftUI

// MARK: - Command model

enum CommandKind {
    case recommended
    case navigate
    case action
    case recent

    var labelKey: LocalizedStringKey {
        switch self {
        case .recommended: return "palette.section.recommended"
        case .navigate:    return "palette.section.navigate"
        case .action:      return "palette.section.action"
        case .recent:      return "palette.section.recent"
        }
    }
}

struct PaletteCommand: Identifiable {
    let id = UUID()
    let kind: CommandKind
    let titleKey: LocalizedStringKey
    /// English fallback text. Used for substring filtering since
    /// LocalizedStringKey doesn't expose its raw string.
    let searchHaystack: String
    let icon: String
    /// Optional keyboard shortcut display (e.g. "⌘K"). Verbatim.
    let shortcut: String?
    let run: () -> Void
}

// MARK: - Palette view

struct CommandPalette: View {

    @Binding var isPresented: Bool
    let commands: [PaletteCommand]

    @State private var query: String = ""
    @State private var highlight: Int = 0
    @FocusState private var inputFocused: Bool

    private var filtered: [PaletteCommand] {
        guard !query.isEmpty else { return commands }
        let lower = query.lowercased()
        return commands.filter { $0.searchHaystack.lowercased().contains(lower) }
    }

    private var grouped: [(CommandKind, [PaletteCommand])] {
        let kinds: [CommandKind] = [.recommended, .navigate, .action, .recent]
        return kinds.compactMap { kind in
            let items = filtered.filter { $0.kind == kind }
            return items.isEmpty ? nil : (kind, items)
        }
    }

    /// Flat list of currently-visible commands in render order — drives
    /// ↑↓ navigation indexing.
    private var visible: [PaletteCommand] {
        grouped.flatMap { $0.1 }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 0) {
                searchBar
                Divider().background(DesignTokens.Palette.line1)
                resultList
                Divider().background(DesignTokens.Palette.line1)
                footerHints
            }
            .frame(width: 620)
            .background(MeshGradientBackground())
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xxl))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xxl)
                    .strokeBorder(DesignTokens.Palette.line2, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.55), radius: 40, y: 16)
        }
        .onAppear {
            inputFocused = true
            highlight = 0
        }
        .onChange(of: query) { _, _ in
            highlight = 0
        }
        .onKeyPress(.escape) { isPresented = false; return .handled }
        .onKeyPress(.downArrow) {
            if !visible.isEmpty { highlight = (highlight + 1) % visible.count }
            return .handled
        }
        .onKeyPress(.upArrow) {
            if !visible.isEmpty {
                highlight = (highlight - 1 + visible.count) % visible.count
            }
            return .handled
        }
        .onKeyPress(.return) {
            execute()
            return .handled
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(DesignTokens.Palette.blueHi)
                .font(.system(size: 14))
            TextField("palette.search.placeholder", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DesignTokens.Palette.text1)
                .focused($inputFocused)
                .onSubmit { execute() }
            blinkingCaret
            Spacer()
            Text(verbatim: "⌘K")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Palette.text4)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(DesignTokens.Palette.line2, lineWidth: 1)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    /// Tiny vertical bar that blinks ~1.2 Hz — gives the empty-state input
    /// a sign of life even when SwiftUI's native caret is hidden by the
    /// surrounding glass.
    @State private var caretOn = true
    private var blinkingCaret: some View {
        Rectangle()
            .fill(DesignTokens.Palette.blueHi)
            .frame(width: 1.5, height: 16)
            .opacity(caretOn ? 1 : 0)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
                    caretOn.toggle()
                }
            }
    }

    private var resultList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(grouped.enumerated()), id: \.offset) { _, group in
                    sectionLabel(group.0)
                    ForEach(group.1) { cmd in
                        row(cmd)
                    }
                }
                if visible.isEmpty {
                    Text("palette.empty")
                        .font(.system(size: 12.5))
                        .foregroundStyle(DesignTokens.Palette.text3)
                        .padding(20)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 380)
    }

    private func sectionLabel(_ kind: CommandKind) -> some View {
        Text(kind.labelKey)
            .font(DesignTokens.Typography.label)
            .foregroundStyle(DesignTokens.Palette.text4)
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    private func row(_ cmd: PaletteCommand) -> some View {
        let idx = visible.firstIndex(where: { $0.id == cmd.id }) ?? 0
        let isActive = idx == highlight
        return Button {
            cmd.run()
            isPresented = false
        } label: {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(isActive ? DesignTokens.Palette.blueHi : Color.clear)
                    .frame(width: 3)
                Image(systemName: cmd.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(isActive ? DesignTokens.Palette.blueHi : DesignTokens.Palette.text3)
                    .frame(width: 18)
                Text(cmd.titleKey)
                    .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(DesignTokens.Palette.text1)
                Spacer()
                if let s = cmd.shortcut {
                    Text(verbatim: s)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(DesignTokens.Palette.text4)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(DesignTokens.Palette.line2, lineWidth: 1)
                        )
                }
            }
            .padding(.trailing, 16)
            .padding(.vertical, 8)
            .background(isActive ? DesignTokens.Palette.blue.opacity(0.10) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering, let i = visible.firstIndex(where: { $0.id == cmd.id }) {
                highlight = i
            }
        }
    }

    private var footerHints: some View {
        HStack(spacing: 14) {
            hint(symbol: "arrow.up.arrow.down", labelKey: "palette.hint.navigate")
            hint(symbol: "return", labelKey: "palette.hint.run")
            hint(symbol: "escape", labelKey: "palette.hint.close")
            Spacer()
        }
        .font(.system(size: 10))
        .foregroundStyle(DesignTokens.Palette.text4)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func hint(symbol: String, labelKey: LocalizedStringKey) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(labelKey)
        }
    }

    private func execute() {
        guard visible.indices.contains(highlight) else { return }
        let cmd = visible[highlight]
        cmd.run()
        isPresented = false
    }
}
