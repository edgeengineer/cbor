// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CBOR",
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
