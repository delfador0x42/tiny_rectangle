// swift-tools-version: 5.9
// WindowManagerUI - SwiftUI views for the window manager

import PackageDescription

let package = Package(
    name: "WindowManagerUI",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "WindowManagerUI",
            targets: ["WindowManagerUI"]
        ),
    ],
    dependencies: [
        .package(path: "../WindowManagerCore")
    ],
    targets: [
        .target(
            name: "WindowManagerUI",
            dependencies: ["WindowManagerCore"]
        ),
    ]
)
