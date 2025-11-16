// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TaskPaper",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "TaskPaper",
            targets: ["TaskPaper"])
    ],
    targets: [
        .target(
            name: "TaskPaper",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]),
        .testTarget(
            name: "TaskPaperTests",
            dependencies: ["TaskPaper"])
    ]
)
