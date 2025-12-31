// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WindowCalculationKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "WindowCalculationKit",
            targets: ["WindowCalculationKit"]
        ),
    ],
    targets: [
        .target(
            name: "WindowCalculationKit"
        ),
        .testTarget(
            name: "WindowCalculationKitTests",
            dependencies: ["WindowCalculationKit"]
        ),
    ]
)
