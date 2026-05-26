import Foundation

/// Helpers for working with byte counts.
public enum ByteSize {

    private static let units = ["B", "KB", "MB", "GB", "TB", "PB"]

    /// Formats a byte count into a short, human-readable string.
    ///
    /// Examples: `0` → `"0 B"`, `1536` → `"1.5 KB"`, `1048576` → `"1.0 MB"`.
    public static func formatted(_ bytes: Int64) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        }
        var value = Double(bytes)
        var unitIndex = 0
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        return String(format: "%.1f", value) + " " + units[unitIndex]
    }
}
