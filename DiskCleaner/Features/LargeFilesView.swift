//
//  LargeFilesView.swift
//  DiskCleaner
//
//  Sprint 4 — Large Files screen per DiskFlow §4.1. Two-column layout:
//
//    ┌─────────────────────────────────────┬─────────────────────┐
//    │ Action bar + type chips             │                     │
//    │ ─────────────────────────────────── │                     │
//    │ Table (checkbox · type glyph ·      │ Preview panel       │
//    │ name+path · size · modified ·       │ (280pt)             │
//    │ type · ⋯)                           │                     │
//    │ ──── floating bar (when selected) ──│                     │
//    └─────────────────────────────────────┴─────────────────────┘
//

import SwiftUI
import AppKit
import Observation
import DiskCleanerCore

// MARK: - File type bucket

enum LargeFileType: String, CaseIterable, Identifiable {
    case all
    case video
    case archive
    case image
    case folder
    case audio
    case other

    var id: String { rawValue }

    var labelKey: LocalizedStringKey {
        switch self {
        case .all:     return "largefiles.type.all"
        case .video:   return "largefiles.type.video"
        case .archive: return "largefiles.type.archive"
        case .image:   return "largefiles.type.image"
        case .folder:  return "largefiles.type.folder"
        case .audio:   return "largefiles.type.audio"
        case .other:   return "largefiles.type.other"
        }
    }

    var glyph: DesignGlyphKind {
        switch self {
        case .video:   return .video
        case .image:   return .photo
        case .archive: return .archive
        case .folder:  return .folder
        case .audio:   return .docs
        case .other:   return .other
        case .all:     return .other
        }
    }

    /// Classify a URL by extension. Cheap heuristic — good enough for the
    /// type filter pill row without inspecting file headers.
    static func classify(_ url: URL) -> LargeFileType {
        let ext = url.pathExtension.lowercased()
        let video:   Set<String> = ["mp4","mov","avi","mkv","m4v","webm","wmv","flv","mpg","mpeg"]
        let image:   Set<String> = ["jpg","jpeg","png","gif","heic","webp","bmp","tiff","raw","cr2","nef"]
        let archive: Set<String> = ["zip","rar","7z","tar","gz","bz2","xz","dmg","iso","ipa","apk"]
        let audio:   Set<String> = ["mp3","wav","flac","aac","m4a","ogg","aif","aiff"]
        if video.contains(ext)   { return .video }
        if image.contains(ext)   { return .image }
        if archive.contains(ext) { return .archive }
        if audio.contains(ext)   { return .audio }
        return .other
    }
}

// MARK: - View Model

@MainActor
@Observable
final class LargeFilesViewModel {

    var files: [LargeFile] = []
    var selection: Set<UUID> = []
    var isScanning = false
    var hasScanned = false
    var lastError: (any Error)?
    var scanProgress: ScanProgress?
    var permissionWarning: String?
    var typeFilter: LargeFileType = .all
    /// User-tunable size floor — defaults to whatever Settings says.
    var minimumSizeMB: Int = AppSettings.largeFileThresholdMB()

    @ObservationIgnored private var rootURL: URL?
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private let permissionsChecker = PermissionsChecker()

    var filteredFiles: [LargeFile] {
        files.filter { typeFilter == .all || LargeFileType.classify($0.url) == typeFilter }
    }

    var selectedFiles: [LargeFile] {
        filteredFiles.filter { selection.contains($0.id) }
    }

    var selectedBytes: Int64 {
        selectedFiles.reduce(Int64(0)) { $0 + $1.size }
    }

    var totalBytes: Int64 {
        filteredFiles.reduce(Int64(0)) { $0 + $1.size }
    }

    var firstSelected: LargeFile? {
        if let first = selectedFiles.first { return first }
        return filteredFiles.first
    }

    func chooseFolderAndScan() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "选择要分析的文件夹"
        panel.prompt = "分析"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        startScan(url)
    }

    func scanHome() {
        startScan(FileManager.default.homeDirectoryForCurrentUser)
    }

    func rescan() {
        if let rootURL {
            startScan(rootURL)
        } else {
            scanHome()
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        isScanning = false
    }

    func toggle(_ file: LargeFile) {
        if selection.contains(file.id) { selection.remove(file.id) }
        else { selection.insert(file.id) }
    }

    func clearSelection() {
        selection.removeAll()
    }

    func reveal(_ file: LargeFile) {
        NSWorkspace.shared.activateFileViewerSelecting([file.url])
    }

    func trashSelected() {
        let toDelete = selectedFiles
        guard !toDelete.isEmpty else { return }
        Task { [weak self] in
            do {
                let result = try await DeletionService().moveToTrash(
                    toDelete.map { $0.url }, source: "large-files"
                )
                let trashed = Set(result.trashed.map { $0.standardizedFileURL })
                self?.files.removeAll { trashed.contains($0.url.standardizedFileURL) }
                self?.selection.removeAll()
            } catch {
                self?.lastError = error
            }
        }
    }

    func trashOne(_ file: LargeFile) {
        Task { [weak self] in
            do {
                _ = try await DeletionService().moveToTrash([file.url], source: "large-files")
                self?.files.removeAll { $0.id == file.id }
                self?.selection.remove(file.id)
            } catch {
                self?.lastError = error
            }
        }
    }

    func openSystemSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        ]
        for urlString in candidates {
            if let url = URL(string: urlString), NSWorkspace.shared.open(url) { return }
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
    }

    func dismissPermissionWarning() {
        permissionWarning = nil
    }

    private func startScan(_ url: URL) {
        scanTask?.cancel()
        rootURL = url
        isScanning = true
        hasScanned = false
        lastError = nil
        scanProgress = nil
        permissionWarning = nil
        files = []
        selection = []

        let threshold = Int64(minimumSizeMB) * 1024 * 1024
        scanTask = Task { [weak self] in
            let progressHandler: (@Sendable (ScanProgress) -> Void) = { [weak self] progress in
                Task { @MainActor [weak self] in self?.scanProgress = progress }
            }
            let excludedPaths = AppSettings.excludedPaths()
            do {
                let result = try await DiskScanner().scan(
                    root: url,
                    excludedPaths: excludedPaths,
                    onProgress: progressHandler
                )
                if Task.isCancelled { return }
                let found = LargeFileFinder().find(
                    in: result.root,
                    minimumSize: threshold,
                    limit: 500
                )
                guard let self else { return }
                self.files = found
                self.hasScanned = true
                if result.blockedDirectoryCount > 0 && !self.permissionsChecker.hasFullDiskAccess() {
                    self.permissionWarning = "扫描中有 \(result.blockedDirectoryCount) 个目录因权限受阻。授予完全磁盘访问后重新扫描，结果会更完整。"
                }
            } catch is CancellationError {
                // ignored
            } catch {
                self?.lastError = error
            }
            self?.isScanning = false
        }
    }
}

// MARK: - View

struct LargeFilesView: View {

    @State private var model = LargeFilesViewModel()
    @State private var pendingConfirm: Bool = false

    /// Threshold above which we surface the confirm sheet — anything below
    /// this stays a silent Trash-move (the file is fully reversible there).
    private let confirmThresholdBytes: Int64 = 1_073_741_824 // 1 GB

    var body: some View {
        VStack(spacing: 0) {
            actionBar
            Divider().background(DesignTokens.Palette.line1)
            content
        }
        .sheet(isPresented: $pendingConfirm) {
            ConfirmDeleteSheet(
                items: model.selectedFiles.map { (name: $0.name, bytes: $0.size) },
                totalBytes: model.selectedBytes,
                onCancel: { pendingConfirm = false },
                onConfirm: {
                    pendingConfirm = false
                    model.trashSelected()
                }
            )
        }
    }

    /// Trigger trash with size-based confirm interception. Files ≥ 1 GB
    /// (in aggregate) prompt the sheet unless the user has previously
    /// ticked "don't ask again".
    private func attemptTrashSelected() {
        let dontAsk = UserDefaults.standard.bool(forKey: ConfirmDeleteSheet.dontAskKey)
        if !dontAsk && model.selectedBytes >= confirmThresholdBytes {
            pendingConfirm = true
        } else {
            model.trashSelected()
        }
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            DesignButton(.default, size: .small, action: { model.chooseFolderAndScan() }) {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                    Text("largefiles.action.choose")
                }
            }
            DesignButton(.ghost, size: .small, action: { model.scanHome() }) {
                HStack(spacing: 6) {
                    Image(systemName: "house")
                    Text("largefiles.action.home")
                }
            }
            if model.hasScanned && !model.isScanning {
                DesignButton(.ghost, size: .small, action: { model.rescan() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("largefiles.action.rescan")
                    }
                }
            }
            Spacer()
            HStack(spacing: 6) {
                ForEach(LargeFileType.allCases) { f in
                    Button {
                        model.typeFilter = f
                    } label: {
                        DesignChip(model.typeFilter == f ? .active : .default) {
                            Text(f.labelKey)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .disabled(model.isScanning)
    }

    @ViewBuilder
    private var content: some View {
        if model.isScanning {
            LoadingStateView(
                percent: 0,
                itemsIndexed: model.scanProgress?.scannedItemCount ?? 0,
                duplicateGroups: 0,
                reclaimableBytes: model.scanProgress?.bytesScanned ?? 0,
                currentPath: model.scanProgress?.currentPath ?? "",
                onCancel: { model.cancelScan() }
            )
        } else if let err = model.lastError {
            ErrorStateView(
                onOpenSettings: { model.openSystemSettings() },
                onRetry: { model.rescan() }
            )
            .overlay(
                Text(verbatim: err.localizedDescription)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.Palette.text3)
                    .padding(.top, 200),
                alignment: .top
            )
        } else if model.hasScanned, !model.files.isEmpty {
            mainSplit
        } else if model.hasScanned {
            ContentUnavailableView(
                "largefiles.empty.title",
                systemImage: "checkmark.circle",
                description: Text("largefiles.empty.body")
            )
            .padding()
        } else {
            EmptyStateView(
                onChooseFolder: { model.chooseFolderAndScan() },
                onScanAll: { model.scanHome() }
            )
        }
    }

    private var mainSplit: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                if let warn = model.permissionWarning {
                    PermissionBanner(
                        message: warn,
                        onOpenSettings: { model.openSystemSettings() },
                        onDismiss: { model.dismissPermissionWarning() }
                    )
                }
                tableHeader
                Divider().background(DesignTokens.Palette.line1)
                fileTable
            }
            .overlay(alignment: .bottom) {
                if !model.selection.isEmpty {
                    floatingBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            }
            Divider().background(DesignTokens.Palette.line1)
            previewPanel
                .frame(width: 280)
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 12) {
            Color.clear.frame(width: 16)
            Color.clear.frame(width: 32)
            Text("largefiles.col.name").frame(maxWidth: .infinity, alignment: .leading)
            Text("largefiles.col.size").frame(width: 90, alignment: .trailing)
            Text("largefiles.col.modified").frame(width: 110, alignment: .leading)
            Text("largefiles.col.type").frame(width: 80, alignment: .leading)
            Color.clear.frame(width: 24)
        }
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(DesignTokens.Palette.text4)
        .textCase(.uppercase)
        .tracking(0.8)
        .frame(height: 30)
        .padding(.horizontal, 16)
        .background(DesignTokens.Palette.glass1)
    }

    private var fileTable: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 0) {
                ForEach(model.filteredFiles) { file in
                    fileRow(file)
                    Rectangle()
                        .fill(DesignTokens.Palette.line1.opacity(0.4))
                        .frame(height: 1)
                }
            }
        }
    }

    private func fileRow(_ file: LargeFile) -> some View {
        let isSelected = model.selection.contains(file.id)
        let type = LargeFileType.classify(file.url)
        return HStack(spacing: 12) {
            DesignCheckbox(on: isSelected) { model.toggle(file) }
                .frame(width: 16)
            DesignGlyph(kind: type.glyph, code: file.url.pathExtension.uppercased().prefix(3).description, size: 28)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: file.name)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(DesignTokens.Palette.text1)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(verbatim: file.url.deletingLastPathComponent().path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(DesignTokens.Palette.text3)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: ByteSize.formatted(file.size))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Palette.text1)
                .frame(width: 90, alignment: .trailing)
            Text(verbatim: relativeDate(file.modificationDate))
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.Palette.text3)
                .frame(width: 110, alignment: .leading)
            Text(type.labelKey)
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.Palette.text3)
                .frame(width: 80, alignment: .leading)
            Menu {
                Button("largefiles.context.reveal")  { model.reveal(file) }
                Button("largefiles.context.trash", role: .destructive) { model.trashOne(file) }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.Palette.text3)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? DesignTokens.Palette.blue.opacity(0.08) : Color.clear)
        .onTapGesture { model.selection = [file.id] }
    }

    private var previewPanel: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if let file = model.firstSelected {
                VStack(alignment: .leading, spacing: 14) {
                    Text("largefiles.preview.label")
                        .font(DesignTokens.Typography.label)
                        .foregroundStyle(DesignTokens.Palette.text4)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    thumbnail(for: file)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: file.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DesignTokens.Palette.text1)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(verbatim: file.url.deletingLastPathComponent().path)
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundStyle(DesignTokens.Palette.text3)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                    metaList(file)
                    HStack(spacing: 6) {
                        DesignButton(.ghost, size: .small, action: { model.reveal(file) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "folder")
                                Text("largefiles.preview.reveal")
                            }
                        }
                        DesignButton(.danger, size: .small, action: { model.trashOne(file) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("largefiles.preview.trash")
                            }
                        }
                    }
                }
                .padding(16)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundStyle(DesignTokens.Palette.text4)
                    Text("largefiles.preview.empty")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.Palette.text3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            }
        }
        .background(DesignTokens.Palette.glass1)
    }

    private func thumbnail(for file: LargeFile) -> some View {
        let type = LargeFileType.classify(file.url)
        return ZStack {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(
                    LinearGradient(
                        colors: [type.glyph.color.opacity(0.6), type.glyph.color.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            VStack(spacing: 6) {
                Image(systemName: thumbIcon(type))
                    .font(.system(size: 38, weight: .regular))
                    .foregroundStyle(.white.opacity(0.95))
                Text(verbatim: file.url.pathExtension.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .aspectRatio(16/10, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    private func thumbIcon(_ t: LargeFileType) -> String {
        switch t {
        case .video:   return "play.rectangle.fill"
        case .image:   return "photo"
        case .archive: return "archivebox"
        case .audio:   return "waveform"
        case .folder:  return "folder.fill"
        case .other, .all: return "doc.fill"
        }
    }

    private func metaList(_ file: LargeFile) -> some View {
        VStack(spacing: 6) {
            metaRow("largefiles.meta.size", value: ByteSize.formatted(file.size))
            metaRow("largefiles.meta.type", value: NSLocalizedString(localizedTypeKey(for: file), comment: ""))
            metaRow("largefiles.meta.modified", value: relativeDate(file.modificationDate))
        }
    }

    private func localizedTypeKey(for file: LargeFile) -> String {
        switch LargeFileType.classify(file.url) {
        case .video:   return "largefiles.type.video"
        case .archive: return "largefiles.type.archive"
        case .image:   return "largefiles.type.image"
        case .audio:   return "largefiles.type.audio"
        case .folder:  return "largefiles.type.folder"
        case .other:   return "largefiles.type.other"
        case .all:     return "largefiles.type.other"
        }
    }

    private func metaRow(_ key: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.Palette.text3)
            Spacer()
            Text(verbatim: value)
                .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                .foregroundStyle(DesignTokens.Palette.text1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(DesignTokens.Palette.glass2)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .strokeBorder(DesignTokens.Palette.line1, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    private var floatingBar: some View {
        HStack(spacing: 12) {
            DesignCheckbox(.on) { model.clearSelection() }
            Text(verbatim: String(
                format: NSLocalizedString("largefiles.fab.selected", comment: ""),
                model.selection.count
            ))
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(DesignTokens.Palette.text1)
            Text(verbatim: "· \(ByteSize.formatted(model.selectedBytes))")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(DesignTokens.Palette.blueHi)
            Spacer()
            DesignButton(.danger, size: .standard, action: { attemptTrashSelected() }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("largefiles.fab.trash")
                }
            }
        }
        .padding(.horizontal, 18)
        .frame(height: DesignTokens.Spacing.floatingBarHeight)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(Color(hex: 0x161c27, opacity: 0.85))
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .strokeBorder(DesignTokens.Palette.line2, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.45), radius: 24, y: 8)
    }

    private func relativeDate(_ date: Date?) -> String {
        guard let date else { return NSLocalizedString("smartcleanup.access.unknown", comment: "") }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    LargeFilesView()
        .frame(width: 1180, height: 720)
        .background(MeshGradientBackground())
        .preferredColorScheme(.dark)
}
