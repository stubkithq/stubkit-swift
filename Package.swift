// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Stubkit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "Stubkit", targets: ["Stubkit"]),
    ],
    targets: [
        .target(name: "Stubkit", path: "Sources/Stubkit"),
        .testTarget(name: "StubkitTests", dependencies: ["Stubkit"], path: "Tests/StubkitTests"),
    ]
)
