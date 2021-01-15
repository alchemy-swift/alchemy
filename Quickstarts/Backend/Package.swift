// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Backend",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "Backend", targets: ["Backend"]),
    ],
    dependencies: [
        .package(url: "https://github.com/joshuawright11/alchemy", .upToNextMinor(from: "0.1.0")),
    ],
    targets: [
        .target(
            name: "Backend",
            dependencies: [
                .product(name: "Alchemy", package: "alchemy"),
            ]),
    ]
)
