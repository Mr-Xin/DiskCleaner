//
//  StateViews.swift
//  DiskCleaner
//
//  The four "state" screens called out in §4.3 of the DiskFlow handoff:
//    EmptyStateView    — first launch / nothing scanned yet
//    LoadingStateView  — scan in progress
//    SuccessStateView  — cleanup finished
//    ErrorStateView    — permission missing (FDA)
//
//  Each one is a reusable component with sensible defaults; callers can
//  override the labels / numbers / actions when wiring into real flows.
//

import SwiftUI

// MARK: - Empty

struct EmptyStateView: View {

    var onChooseFolder: () -> Void = {}
    var onScanAll:      () -> Void = {}

    var body: some View {
        VStack(spacing: 20) {
            diskHero

            VStack(spacing: 8) {
                Text("state.empty.title")
                    .font(DesignTokens.Typography.h1)
                    .foregroundStyle(DesignTokens.Palette.text1)
                Text("state.empty.body")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.Palette.text3)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 380)
            }

            HStack(spacing: 10) {
                DesignButton(action: onChooseFolder) {
                    Text("state.empty.cta.choose")
                }
                DesignButton(.primary, action: onScanAll) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                        Text("state.empty.cta.scan_all")
                    }
                }
            }

            HStack(spacing: 14) {
                Label {
                    Text("state.empty.hint.readonly")
                } icon: {
                    Image(systemName: "shield")
                }
                Text(verbatim: "·")
                    .foregroundStyle(DesignTokens.Palette.text4)
                Label {
                    Text("state.empty.hint.no_delete")
                } icon: {
                    Image(systemName: "checkmark")
                }
            }
            .font(.system(size: 11.5))
            .foregroundStyle(DesignTokens.Palette.text3)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private var diskHero: some View {
        ZStack {
            // Soft blue radial glow behind the dashed circle.
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            DesignTokens.Palette.blue.opacity(0.20),
                            .clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 8)

            // Dashed circle with disk icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignTokens.Palette.glass2,
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Circle()
                    .strokeBorder(
                        DesignTokens.Palette.line2,
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 5])
                    )
                Image(systemName: "internaldrive")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(DesignTokens.Palette.blueHi)
            }
            .frame(width: 120, height: 120)
        }
    }
}

// MARK: - Loading

struct LoadingStateView: View {

    var percent: Int = 0
    var itemsIndexed: Int = 0
    var duplicateGroups: Int = 0
    var reclaimableBytes: Int64 = 0
    var currentPath: String = ""
    var onCancel: () -> Void = {}

    var body: some View {
        VStack(spacing: 22) {
            concentricRings

            VStack(spacing: 6) {
                Text("state.loading.title")
                    .font(DesignTokens.Typography.h1)
                    .foregroundStyle(DesignTokens.Palette.text1)
                Text("state.loading.subtitle")
                    .font(.system(size: 12.5))
                    .foregroundStyle(DesignTokens.Palette.text3)
            }

            VStack(spacing: 6) {
                progressBar
                if !currentPath.isEmpty {
                    HStack {
                        Text(currentPath)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Text(verbatim: "\(percent)%")
                    }
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(DesignTokens.Palette.text3)
                }
            }
            .frame(width: 440)

            statsCard

            DesignButton(.ghost, size: .small, action: onCancel) {
                Text("state.loading.cancel")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
    }

    private var concentricRings: some View {
        ZStack {
            // Outer ring track + active arc (blue gradient)
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 3)
                .frame(width: 104, height: 104)
            Circle()
                .trim(from: 0, to: CGFloat(percent) / 100)
                .stroke(
                    AngularGradient(
                        colors: [
                            DesignTokens.Palette.blue.opacity(0),
                            DesignTokens.Palette.blue
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 104, height: 104)
                .shadow(color: DesignTokens.Palette.blue.opacity(0.55), radius: 6)

            // Middle ring (cyan)
            Circle()
                .stroke(Color.white.opacity(0.04), lineWidth: 2)
                .frame(width: 80, height: 80)
            Circle()
                .trim(from: 0, to: 0.20)
                .stroke(
                    DesignTokens.Palette.cyan.opacity(0.7),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .rotationEffect(.degrees(60))
                .frame(width: 80, height: 80)

            // Inner ring (purple)
            Circle()
                .stroke(Color.white.opacity(0.04), lineWidth: 2)
                .frame(width: 56, height: 56)
            Circle()
                .trim(from: 0, to: 0.18)
                .stroke(
                    DesignTokens.Palette.purple.opacity(0.5),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .rotationEffect(.degrees(-30))
                .frame(width: 56, height: 56)

            // Center percent
            Text(verbatim: "\(percent)%")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(DesignTokens.Palette.blueHi)
        }
        .frame(width: 120, height: 120)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(DesignTokens.Palette.glass2)
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignTokens.Palette.blue,
                                DesignTokens.Palette.cyan
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geo.size.width * CGFloat(percent) / 100))
                    .shadow(color: DesignTokens.Palette.blue.opacity(0.4), radius: 6)
            }
        }
        .frame(height: 6)
    }

    private var statsCard: some View {
        HStack(spacing: 14) {
            statColumn(
                value: "\(itemsIndexed)",
                labelKey: "state.loading.stat.indexed"
            )
            statColumn(
                value: "\(duplicateGroups)",
                labelKey: "state.loading.stat.groups"
            )
            statColumn(
                value: ByteSizeFormatter.short(reclaimableBytes),
                labelKey: "state.loading.stat.reclaim"
            )
        }
        .padding(14)
        .frame(width: 440)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(DesignTokens.Palette.glass2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .strokeBorder(DesignTokens.Palette.line2, lineWidth: 1)
        )
    }

    private func statColumn(value: String, labelKey: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(DesignTokens.Palette.text1)
            Text(labelKey)
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.84)
                .foregroundStyle(DesignTokens.Palette.text4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Success

struct SuccessStateView: View {

    var freedBytes: Int64 = 0
    /// Display string for freed bytes; overrides the formatted `freedBytes`
    /// when non-nil. Useful for demo states.
    var freedDisplay: String? = nil

    var subtitleKey: LocalizedStringKey = "state.success.subtitle"

    /// Rows shown beneath the hero number — (label, bytes, accent color).
    var breakdown: [(label: String, bytes: Int64, color: Color)] = []

    var healthScoreBefore: Int = 82
    var healthScoreAfter: Int = 94

    var onDone:   () -> Void = {}
    var onDetail: () -> Void = {}

    var body: some View {
        VStack(spacing: 18) {
            greenCheckHero

            VStack(spacing: 6) {
                Text("state.success.label.freed")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.Palette.text3)
                Text(verbatim: freedDisplay ?? ByteSizeFormatter.short(freedBytes))
                    .font(.system(size: 56, weight: .bold))
                    .kerning(-2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, DesignTokens.Palette.good],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text(subtitleKey)
                    .font(.system(size: 12.5))
                    .foregroundStyle(DesignTokens.Palette.text3)
            }

            if !breakdown.isEmpty {
                VStack(spacing: 8) {
                    ForEach(0..<breakdown.count, id: \.self) { idx in
                        breakdownRow(breakdown[idx])
                    }
                }
                .frame(width: 460)
            }

            healthScoreCard
                .frame(width: 460)

            HStack(spacing: 10) {
                DesignButton(.ghost, size: .small, action: onDetail) {
                    Text("state.success.cta.detail")
                }
                DesignButton(.primary, size: .small, action: onDone) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                        Text("state.success.cta.done")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
    }

    private var greenCheckHero: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            DesignTokens.Palette.good.opacity(0.35),
                            .clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 12)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            DesignTokens.Palette.good,
                            Color(hex: 0x4abf80)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 96, height: 96)
                .shadow(color: DesignTokens.Palette.good.opacity(0.35), radius: 20, x: 0, y: 12)

            Image(systemName: "checkmark")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func breakdownRow(_ row: (label: String, bytes: Int64, color: Color)) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(DesignTokens.Palette.good.opacity(0.15))
                    .overlay(Circle().strokeBorder(DesignTokens.Palette.good, lineWidth: 1))
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DesignTokens.Palette.good)
            }
            .frame(width: 22, height: 22)

            Text(verbatim: row.label)
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.Palette.text1)

            Spacer()

            Text(verbatim: ByteSizeFormatter.short(row.bytes))
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(row.color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(DesignTokens.Palette.glass2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .strokeBorder(DesignTokens.Palette.line2, lineWidth: 1)
        )
    }

    private var healthScoreCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("state.success.healthscore.label")
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(0.84)
                    .foregroundStyle(DesignTokens.Palette.text4)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(verbatim: "\(healthScoreBefore)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(DesignTokens.Palette.text1)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignTokens.Palette.text3)
                    Text(verbatim: "\(healthScoreAfter)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(DesignTokens.Palette.good)
                    Text(verbatim: "+\(healthScoreAfter - healthScoreBefore)")
                        .font(.system(size: 11.5))
                        .foregroundStyle(DesignTokens.Palette.good)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(DesignTokens.Palette.glass1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .strokeBorder(DesignTokens.Palette.line1, lineWidth: 1)
        )
    }
}

// MARK: - Error (FDA missing)

struct ErrorStateView: View {

    struct DriveRow: Identifiable {
        let id = UUID()
        let name: String
        let detail: String
        let locked: Bool
    }

    var drives: [DriveRow] = []

    var onLearnMore:    () -> Void = {}
    var onOpenSettings: () -> Void = {}
    var onRetry:        () -> Void = {}

    var body: some View {
        VStack(spacing: 18) {
            shieldHero

            VStack(spacing: 8) {
                Text("state.error.title")
                    .font(DesignTokens.Typography.h1)
                    .foregroundStyle(DesignTokens.Palette.text1)
                Text("state.error.body")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.Palette.text3)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 420)
            }

            HStack(spacing: 10) {
                DesignButton(.ghost, size: .small, action: onLearnMore) {
                    Text("state.error.cta.learn")
                }
                DesignButton(.primary, action: onOpenSettings) {
                    HStack(spacing: 6) {
                        Text("state.error.cta.open")
                        Image(systemName: "arrow.right")
                    }
                }
            }

            if !drives.isEmpty {
                drivesCard
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
    }

    private var shieldHero: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            DesignTokens.Palette.warn.opacity(0.25),
                            .clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 12)

            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignTokens.Palette.warn.opacity(0.15),
                            DesignTokens.Palette.warn.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 88, height: 88)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(DesignTokens.Palette.warn.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: DesignTokens.Palette.warn.opacity(0.20), radius: 20, x: 0, y: 12)

            Image(systemName: "shield")
                .font(.system(size: 42, weight: .regular))
                .foregroundStyle(DesignTokens.Palette.warn)
        }
    }

    private var drivesCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("state.error.drives.label")
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(0.84)
                    .foregroundStyle(DesignTokens.Palette.text4)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()
                .background(DesignTokens.Palette.line1)

            ForEach(Array(drives.enumerated()), id: \.element.id) { index, drive in
                driveRow(drive)
                if index < drives.count - 1 {
                    Divider().background(DesignTokens.Palette.line1)
                }
            }
        }
        .frame(width: 480)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(DesignTokens.Palette.glass2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .strokeBorder(DesignTokens.Palette.line2, lineWidth: 1)
        )
    }

    private func driveRow(_ drive: DriveRow) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "externaldrive")
                .font(.system(size: 14))
                .foregroundStyle(drive.locked ? DesignTokens.Palette.warn : DesignTokens.Palette.blueHi)
            Text(verbatim: drive.name)
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.Palette.text1)
            Spacer()
            Text(verbatim: drive.detail)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(drive.locked ? DesignTokens.Palette.warn : DesignTokens.Palette.text3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Cleaning (transition between "Run cleanup" and Success)

/// A single task displayed in the `CleaningStateView` list. Three states
/// drive the visual treatment: completed (green ✓), running (animated
/// spinner + shimmer), or queued (faint, dashed circle index).
enum CleaningTaskStatus {
    case done
    case running
    case queued
}

struct CleaningTask: Identifiable {
    let id = UUID()
    /// 1-based ordinal shown in the queued state circle.
    let index: Int
    /// User-visible task name (e.g. "清理 Xcode 缓存"). Verbatim — not localized.
    let title: String
    /// Tail string under the title (e.g. "6.2 GB"). Verbatim.
    let detail: String
    /// 0...1, how far through the task we are.
    let progress: Double
    let status: CleaningTaskStatus
}

/// The "doing something right now" transition screen — sits between
/// the Smart Cleanup CTA and the Success screen. Per README §4.3
/// the goal is to make the user feel something is happening, so the
/// visual is dense: pulsing radial glow, three concentric orbit rings,
/// floating particles, a hero number that animates upward, and a
/// task list with three statuses.
struct CleaningStateView: View {

    /// Bytes freed so far in this cleanup pass.
    var freedBytes: Int64
    /// Total bytes the user opted to clean.
    var totalBytes: Int64
    /// Task list. Order = display order.
    var tasks: [CleaningTask]

    @State private var pulse: Bool = false
    @State private var orbit: Double = 0

    var body: some View {
        VStack(spacing: 26) {
            heroOrbits

            VStack(spacing: 8) {
                heroNumber
                Text("state.cleaning.subtitle")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.Palette.text3)
            }

            taskList
                .frame(maxWidth: 520)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.linear(duration: 13).repeatForever(autoreverses: false)) {
                orbit = 360
            }
        }
    }

    // MARK: Hero orbits + central number

    private var heroOrbits: some View {
        ZStack {
            // Pulsing blue glow halo behind the orbits.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignTokens.Palette.blue.opacity(pulse ? 0.30 : 0.18),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .blur(radius: 14)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: pulse)

            // Three concentric orbit rings, each with a glowing satellite.
            orbitRing(radius: 110, color: DesignTokens.Palette.blue,   speed: 18,  reverse: false, phase: 0)
            orbitRing(radius:  85, color: DesignTokens.Palette.purple, speed: 13,  reverse: true,  phase: 120)
            orbitRing(radius:  60, color: DesignTokens.Palette.cyan,   speed:  8,  reverse: false, phase: 240)
        }
        .frame(width: 240, height: 240)
    }

    private func orbitRing(radius: CGFloat, color: Color, speed: Double, reverse: Bool, phase: Double) -> some View {
        ZStack {
            Circle()
                .strokeBorder(color.opacity(0.18), lineWidth: 1)
                .frame(width: radius * 2, height: radius * 2)
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color, radius: 8)
                .offset(x: radius)
                .rotationEffect(.degrees((reverse ? -orbit : orbit) + phase))
                .animation(.linear(duration: speed).repeatForever(autoreverses: false), value: orbit)
        }
    }

    private var heroNumber: some View {
        HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text(verbatim: ByteSizeFormatter.short(freedBytes))
                .font(.system(size: 48, weight: .bold))
                .tracking(-1.5)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            DesignTokens.Palette.blueHi,
                            DesignTokens.Palette.cyan
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text(verbatim: "/")
                .font(.system(size: 18))
                .foregroundStyle(DesignTokens.Palette.text3)
            Text(verbatim: ByteSizeFormatter.short(totalBytes))
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(DesignTokens.Palette.text2)
        }
    }

    // MARK: Task list

    private var taskList: some View {
        VStack(spacing: 8) {
            ForEach(tasks) { task in
                taskRow(task)
            }
        }
    }

    private func taskRow(_ task: CleaningTask) -> some View {
        HStack(spacing: 12) {
            taskStatusIcon(task)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(verbatim: task.title)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(taskTitleColor(task))
                    Spacer(minLength: 8)
                    Text(verbatim: task.detail)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(taskDetailColor(task))
                }
                progressBar(task)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(taskBackground(task))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .strokeBorder(taskBorder(task), lineWidth: 1)
        )
        .opacity(task.status == .queued ? 0.55 : 1)
        .shadow(
            color: task.status == .running
                ? DesignTokens.Palette.blue.opacity(0.30)
                : .clear,
            radius: 12
        )
    }

    @ViewBuilder
    private func taskStatusIcon(_ task: CleaningTask) -> some View {
        switch task.status {
        case .done:
            ZStack {
                Circle()
                    .fill(DesignTokens.Palette.good.opacity(0.18))
                    .frame(width: 22, height: 22)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DesignTokens.Palette.good)
            }
        case .running:
            ZStack {
                Circle()
                    .stroke(DesignTokens.Palette.blue.opacity(0.25), lineWidth: 2)
                    .frame(width: 22, height: 22)
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        DesignTokens.Palette.blueHi,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 22, height: 22)
                    .rotationEffect(.degrees(orbit))
                    .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: orbit)
            }
        case .queued:
            ZStack {
                Circle()
                    .strokeBorder(
                        DesignTokens.Palette.text4,
                        style: StrokeStyle(lineWidth: 1, dash: [2, 2])
                    )
                    .frame(width: 22, height: 22)
                Text(verbatim: "\(task.index)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DesignTokens.Palette.text3)
            }
        }
    }

    private func progressBar(_ task: CleaningTask) -> some View {
        let fillColor: Color = {
            switch task.status {
            case .done:    return DesignTokens.Palette.good
            case .running: return DesignTokens.Palette.blueHi
            case .queued:  return DesignTokens.Palette.text4
            }
        }()
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DesignTokens.Palette.glass2)
                Capsule()
                    .fill(fillColor)
                    .frame(width: max(0, geo.size.width * task.progress))
                    .shadow(color: fillColor.opacity(0.4), radius: 3)
            }
        }
        .frame(height: 4)
    }

    private func taskTitleColor(_ task: CleaningTask) -> Color {
        task.status == .queued ? DesignTokens.Palette.text3 : DesignTokens.Palette.text1
    }

    private func taskDetailColor(_ task: CleaningTask) -> Color {
        switch task.status {
        case .done:    return DesignTokens.Palette.good
        case .running: return DesignTokens.Palette.blueHi
        case .queued:  return DesignTokens.Palette.text4
        }
    }

    private func taskBackground(_ task: CleaningTask) -> Color {
        switch task.status {
        case .done:    return DesignTokens.Palette.glass1
        case .running: return DesignTokens.Palette.blue.opacity(0.08)
        case .queued:  return DesignTokens.Palette.glass1
        }
    }

    private func taskBorder(_ task: CleaningTask) -> Color {
        switch task.status {
        case .done:    return DesignTokens.Palette.line1
        case .running: return DesignTokens.Palette.blue.opacity(0.35)
        case .queued:  return DesignTokens.Palette.line1
        }
    }
}

// MARK: - Byte formatter helper

/// Lightweight helper so state views can render byte counts without depending
/// directly on `DiskCleanerCore.ByteSize` (it's available via that module,
/// but keeping this layer agnostic makes the state views easy to preview).
enum ByteSizeFormatter {

    private static let formatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .binary
        f.allowedUnits = [.useMB, .useGB, .useTB]
        f.includesUnit = true
        return f
    }()

    static func short(_ bytes: Int64) -> String {
        formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Previews

#Preview("Empty") {
    EmptyStateView()
        .background(MeshGradientBackground())
        .preferredColorScheme(.dark)
        .frame(width: 900, height: 600)
}

#Preview("Loading") {
    LoadingStateView(
        percent: 68,
        itemsIndexed: 142_840,
        duplicateGroups: 42,
        reclaimableBytes: 12_400_000_000,
        currentPath: "~/Library/Caches/com.apple.bird"
    )
    .background(MeshGradientBackground())
    .preferredColorScheme(.dark)
    .frame(width: 900, height: 600)
}

#Preview("Success") {
    SuccessStateView(
        freedDisplay: "12.4 GB",
        breakdown: [
            ("Xcode 构建缓存", 6_200_000_000, DesignTokens.Palette.catCache),
            ("旧的下载",        3_800_000_000, DesignTokens.Palette.catOther),
            ("重复照片",        2_400_000_000, DesignTokens.Palette.catPhoto),
        ]
    )
    .background(MeshGradientBackground())
    .preferredColorScheme(.dark)
    .frame(width: 900, height: 600)
}

#Preview("Error") {
    ErrorStateView(
        drives: [
            .init(name: "Macintosh HD", detail: "312 / 512 GB",  locked: false),
            .init(name: "Backup-SSD",   detail: "Locked",        locked: true),
            .init(name: "Time Machine", detail: "1.8 / 4 TB",    locked: false),
        ]
    )
    .background(MeshGradientBackground())
    .preferredColorScheme(.dark)
    .frame(width: 900, height: 600)
}
