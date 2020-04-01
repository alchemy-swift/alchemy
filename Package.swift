// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Alchemy",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "Alchemy",
            targets: ["Alchemy"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/codable-kit.git", .branch("master")),
    ],
    targets: [
        .target(
            name: "Alchemy",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "CodableKit", package: "codable-kit"),
            ]
        ),
        .target(
            name: "_Example",
            dependencies: ["Alchemy"]
        ),
        .testTarget(
            name: "AlchemyTests",
            dependencies: ["Alchemy"]
        ),
    ]
)
