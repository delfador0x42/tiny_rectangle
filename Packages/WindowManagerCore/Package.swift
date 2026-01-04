// swift-tools-version: 5.9
// WindowManagerCore - Core window calculation and geometry logic

import PackageDescription

let package = Package(
    name: "WindowManagerCore",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "WindowManagerCore",
            targets: ["WindowManagerCore"]
        ),
    ],
    targets: [
        .target(
            name: "WindowManagerCore",
            dependencies: []
        ),
        .testTarget(
            name: "WindowManagerCoreTests",
            dependencies: ["WindowManagerCore"]
        ),
    ]
)
