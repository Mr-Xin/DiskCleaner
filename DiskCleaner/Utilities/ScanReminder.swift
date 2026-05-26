//
//  ScanReminder.swift
//  DiskCleaner
//
//  Background reminder that nudges the user to re-scan if the last scan was
//  too long ago. Uses `NSBackgroundActivityScheduler` to fire periodically
//  while the app is running, and `UNUserNotificationCenter` to deliver the
//  reminder. (The app must be open for the scheduler to fire — there is no
//  launchd LaunchAgent in this build.)
//

import Foundation
import AppKit
import UserNotifications

@MainActor
final class ScanReminder {

    static let shared = ScanReminder()

    private var scheduler: NSBackgroundActivityScheduler?

    private init() {}

    /// Reads current preferences and registers or unregisters the scheduler.
    /// Call this from the App's `init` and again whenever the user changes
    /// the reminder setting in Settings.
    func applyCurrentSettings() {
        scheduler?.invalidate()
        scheduler = nil

        guard AppSettings.reminderEnabled() else { return }

        Task {
            await Self.requestNotificationAuthorizationIfNeeded()
        }

        let frequency = AppSettings.reminderFrequency()
        let interval = TimeInterval(frequency.days * 24 * 60 * 60)

        let activity = NSBackgroundActivityScheduler(
            identifier: "ai.vomo.diskcleaner.scan-reminder"
        )
        activity.interval = interval
        activity.repeats = true
        activity.tolerance = TimeInterval(60 * 60) // 1 hour
        activity.qualityOfService = .background
        activity.schedule { completion in
            Task { @MainActor in
                Self.maybeNotifyStale(frequency: frequency)
                completion(.finished)
            }
        }
        scheduler = activity
    }

    // MARK: - Internals

    private static func maybeNotifyStale(frequency: ReminderFrequency) {
        let last = AppSettings.lastScanTime()
        let threshold = TimeInterval(frequency.days * 24 * 60 * 60)
        let isStale: Bool
        if let last {
            isStale = Date().timeIntervalSince(last) >= threshold
        } else {
            isStale = true
        }
        guard isStale else { return }

        let content = UNMutableNotificationContent()
        content.title = "DiskCleaner"
        content.body = reminderBody(last: last)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { _ in }
    }

    private static func reminderBody(last: Date?) -> String {
        if let last {
            let days = Int(Date().timeIntervalSince(last) / (24 * 3600))
            return String(format: NSLocalizedString(
                "上次扫描已经过去 %d 天了，要不要再跑一次？",
                comment: "Reminder body when last scan was N days ago"
            ), days)
        }
        return NSLocalizedString(
            "好像还没扫描过磁盘，要不要跑一次？",
            comment: "Reminder body when no previous scan exists"
        )
    }

    private static func requestNotificationAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
    }
}
