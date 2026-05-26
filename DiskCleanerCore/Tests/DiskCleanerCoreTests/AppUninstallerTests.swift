import Foundation
import Testing
@testable import DiskCleanerCore

struct AppUninstallerTests {

    @Test func detectsLaunchAgentPlist() {
        #expect(AppUninstaller.isLaunchService(
            URL(fileURLWithPath: "/Users/test/Library/LaunchAgents/com.example.foo.plist")
        ))
    }

    @Test func detectsLaunchDaemonPlist() {
        #expect(AppUninstaller.isLaunchService(
            URL(fileURLWithPath: "/Library/LaunchDaemons/com.example.bar.plist")
        ))
    }

    @Test func nonPlistFilesAreNotServices() {
        #expect(!AppUninstaller.isLaunchService(
            URL(fileURLWithPath: "/Users/test/Library/LaunchAgents/notes.txt")
        ))
    }

    @Test func plistsOutsideLaunchDirectoriesAreNotServices() {
        #expect(!AppUninstaller.isLaunchService(
            URL(fileURLWithPath: "/Users/test/Library/Caches/com.example.bar.plist")
        ))
        #expect(!AppUninstaller.isLaunchService(
            URL(fileURLWithPath: "/Users/test/Library/Preferences/com.example.bar.plist")
        ))
    }
}
