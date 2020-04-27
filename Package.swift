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
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.0.0-rc"),
        .package(url: "https://github.com/MihaelIsaev/SwifQL.git", from:"2.0.0-beta"),
//        .package(url: "https://github.com/MihaelIsaev/SwifQLNIO.git", from:"2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.11.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0")

    ],
    targets: [
        .target(
            name: "Alchemy",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "SwifQL", package: "SwifQL"),
//                .product(name: "SwifQLNIO", package: "SwifQLNIO"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOHTTP2", package: "swift-nio-http2"),
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
