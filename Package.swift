// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CBOR",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "CBOR",
            targets: ["CBOR"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "CBOR",
            dependencies: []),
        .testTarget(
            name: "CBORTests",
            dependencies: ["CBOR"]),
    ]
)