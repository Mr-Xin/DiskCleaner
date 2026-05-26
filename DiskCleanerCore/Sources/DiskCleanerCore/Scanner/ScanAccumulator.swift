import Foundation

/// Internal accumulator used by `DiskScanner` to track scan progress across
/// concurrent subtree walks. Serialised by being an `actor`, so multiple
/// subtree tasks can record their progress without data races.
actor ScanAccumulator {

    /// Standardised paths the scanner should skip. Exposed `nonisolated` so
    /// list-children code can filter without an extra `await`.
    nonisolated let excludedPaths: Set<String>

    private var scannedItemCount = 0
    private var bytesScanned: Int64 = 0
    private var currentPath = ""
    private(set) var blockedDirectoryCount = 0

    init(excludedPaths: Set<String> = []) {
        self.excludedPaths = excludedPaths
    }

    func recordItem(at path: String) {
        scannedItemCount += 1
        currentPath = path
    }

    func recordBytes(_ bytes: Int64) {
        bytesScanned += bytes
    }

    func recordBlockedDirectory() {
        blockedDirectoryCount += 1
    }

    func snapshot() -> ScanProgress {
        ScanProgress(
            scannedItemCount: scannedItemCount,
            currentPath: currentPath,
            bytesScanned: bytesScanned
        )
    }
}
