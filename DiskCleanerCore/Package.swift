// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DiskCleanerCore",
    platforms: [
        .macOS("14.0")
    ],
    products: [
        .library(
            name: "DiskCleanerCore",
            targets: ["DiskCleanerCore"]
        )
    ],
    targets: [
        // Thin C bridge for macOS-specific APIs that have no clean Swift
        // equivalent — currently just APFS clone-id lookup via getattrlist.
        .target(
            name: "DiskCleanerCoreBridge",
            publicHeadersPath: "include"
        ),
        .target(
            name: "DiskCleanerCore",
            dependencies: ["DiskCleanerCoreBridge"]
        ),
        .testTarget(
            name: "DiskCleanerCoreTests",
            dependencies: ["DiskCleanerCore", "DiskCleanerCoreBridge"]
        )
    ]
)
