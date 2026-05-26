import Foundation

/// The built-in catalog of junk-cleaning rules.
///
/// The catalog is intentionally conservative: anything whose removal could
/// surprise the user is marked `.reviewNeeded`, so the UI leaves it unchecked
/// by default.
public enum JunkRuleCatalog {

    public static let builtIn: [JunkRule] = [
        JunkRule(
            id: "user-caches",
            name: "用户缓存",
            category: .userCache,
            safety: .safe,
            paths: ["~/Library/Caches/*"],
            explanation: "应用运行时生成的可重建缓存，删除后会按需自动重新生成。"
        ),
        JunkRule(
            id: "app-logs",
            name: "应用日志",
            category: .logs,
            safety: .safe,
            paths: ["~/Library/Logs/*"],
            explanation: "应用写入的诊断日志，对日常使用没有影响。"
        ),
        JunkRule(
            id: "trash",
            name: "废纸篓",
            category: .trash,
            safety: .safe,
            paths: ["~/.Trash/*"],
            explanation: "已被移入废纸篓、等待清空的文件。"
        ),
        JunkRule(
            id: "browser-caches",
            name: "浏览器缓存",
            category: .browserCache,
            safety: .safe,
            paths: [
                "~/Library/Caches/com.apple.Safari/*",
                "~/Library/Caches/Google/Chrome/*",
                "~/Library/Caches/Firefox/*"
            ],
            explanation: "浏览器为加速访问而缓存的网页资源，可安全清理。"
        ),
        JunkRule(
            id: "xcode-derived-data",
            name: "Xcode DerivedData",
            category: .developerJunk,
            safety: .safe,
            paths: ["~/Library/Developer/Xcode/DerivedData/*"],
            explanation: "Xcode 的中间编译产物，下次构建会自动重建。"
        ),
        JunkRule(
            id: "xcode-device-support",
            name: "iOS 设备支持文件",
            category: .developerJunk,
            safety: .reviewNeeded,
            paths: ["~/Library/Developer/Xcode/iOS DeviceSupport/*"],
            explanation: "为不同 iOS 版本调试缓存的符号文件，连接旧设备时会再次生成。"
        ),
        JunkRule(
            id: "package-manager-caches",
            name: "包管理器缓存",
            category: .packageManagerCache,
            safety: .safe,
            paths: [
                "~/.npm/_cacache/*",
                "~/Library/Caches/Yarn/*",
                "~/Library/Caches/pip/*",
                "~/Library/Caches/CocoaPods/*",
                "~/Library/Caches/org.swift.swiftpm/*"
            ],
            explanation: "npm / yarn / pip / CocoaPods / SwiftPM 下载的包缓存。"
        ),
        JunkRule(
            id: "ios-device-backups",
            name: "旧 iOS 设备备份",
            category: .oldDeviceBackup,
            safety: .reviewNeeded,
            paths: ["~/Library/Application Support/MobileSync/Backup/*"],
            explanation: "iPhone / iPad 的本地备份，可能很大。删除前请确认你不再需要它。"
        ),
        JunkRule(
            id: "mail-downloads",
            name: "邮件附件下载",
            category: .mailDownloads,
            safety: .reviewNeeded,
            paths: ["~/Library/Containers/com.apple.mail/Data/Library/Mail Downloads/*"],
            explanation: "从邮件中打开过的附件副本，原始附件仍保留在邮件里。"
        ),
        JunkRule(
            id: "system-caches",
            name: "系统缓存",
            category: .systemCache,
            safety: .reviewNeeded,
            paths: ["/Library/Caches/*"],
            explanation: "系统级缓存，清理需要管理员权限；初版可暂不处理。"
        )
    ]
}
