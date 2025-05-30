// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CBOR",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "CBOR",
            targets: ["CBOR"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "CBOR",
            dependencies: []),
        .testTarget(
            name: "CBORTests",
            dependencies: ["CBOR"],
            resources: [.copy("TestPlan.md")])
    ]
)
