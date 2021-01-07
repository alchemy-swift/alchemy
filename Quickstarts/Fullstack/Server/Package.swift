// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Server",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "Server", targets: ["Server"]),
    ],
    dependencies: [
        .package(url: "https://github.com/joshuawright11/alchemy", .branch("master")),
        .package(path: "../Shared"),
    ],
    targets: [
        .target(
            name: "Server",
            dependencies: [
                .product(name: "Alchemy", package: "alchemy"),
                "Shared",
            ]),
        .testTarget(
            name: "ServerTests",
            dependencies: [
                "Server"
            ]),
    ]
)
