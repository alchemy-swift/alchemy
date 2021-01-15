// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Shared",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "Shared", targets: ["Shared"]),
    ],
    dependencies: [
        .package(url: "https://github.com/joshuawright11/alchemy", .upToNextMinor(from: "0.1.0"))
    ],
    targets: [
        .target(
            name: "Shared",
            dependencies: [
                .product(name: "Fusion", package: "alchemy"),
                .product(name: "Papyrus", package: "alchemy")
            ]
        ),
    ]
)
