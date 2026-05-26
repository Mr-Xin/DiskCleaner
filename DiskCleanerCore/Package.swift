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
        .target(
            name: "DiskCleanerCore"
        ),
        .testTarget(
            name: "DiskCleanerCoreTests",
            dependencies: ["DiskCleanerCore"]
        )
    ]
)
