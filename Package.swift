// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CTIA",
    defaultLocalization: "pt-BR",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CTIA",
            targets: ["CTIA"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CTIA",
            dependencies: [],
            path: "Sources/CTIA"
        ),
        .testTarget(
            name: "CTIATests",
            dependencies: ["CTIA"],
            path: "Tests/CTIATests"
        ),
    ]
)
