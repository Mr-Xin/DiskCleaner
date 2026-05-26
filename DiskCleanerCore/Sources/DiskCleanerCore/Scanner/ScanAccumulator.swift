import Foundation

/// Internal accumulator used by `DiskScanner` to track scan progress across
/// concurrent subtree walks. Serialised by being an `actor`, so multiple
/// subtree tasks can record their progress without data races.
actor ScanAccumulator {

    private var scannedItemCount = 0
    private var bytesScanned: Int64 = 0
    private var currentPath = ""
    private(set) var blockedDirectoryCount = 0

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
