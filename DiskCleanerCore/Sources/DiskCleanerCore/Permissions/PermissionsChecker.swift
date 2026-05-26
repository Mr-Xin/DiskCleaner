import Foundation

/// Checks whether DiskCleaner currently has the system permissions it needs.
public struct PermissionsChecker: Sendable {

    public init() {}

    /// Whether the app currently has Full Disk Access.
    ///
    /// Full Disk Access cannot be requested through an API — the user grants
    /// it in System Settings ▸ Privacy & Security ▸ Full Disk Access. The app
    /// can only *detect* it.
    ///
    /// Detection works by trying to open the TCC database for reading: that
    /// file is only readable when Full Disk Access has been granted. If the
    /// file cannot be opened (no access, or it is missing) the method returns
    /// `false`, which conservatively prompts the user to grant access.
    ///
    /// - Note: This heuristic should be verified on a real machine across a
    ///   few macOS versions, as TCC behaviour changes over time.
    public func hasFullDiskAccess() -> Bool {
        let tccDatabase = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db")

        guard let handle = try? FileHandle(forReadingFrom: tccDatabase) else {
            return false
        }
        try? handle.close()
        return true
    }
}
