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
        .library(
            name: "Papyrus-iOS",
            targets: ["Papyrus-iOS"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.1.0"),
        .package(url: "https://github.com/vapor/mysql-nio.git", from: "1.0.0-rc.2.2"),
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.11.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/postgres-kit", from: "2.0.0"),
        .package(url: "https://github.com/vapor/mysql-kit", from: "4.0.0-rc.1.6"),
        .package(url: "https://github.com/Azoy/Echo", .branch("master")),
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "Alchemy",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Echo", package: "Echo"),
                .product(name: "PostgresKit", package: "postgres-kit"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "MySQLKit", package: "mysql-kit"),
                .product(name: "MySQLNIO", package: "mysql-nio"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOHTTP2", package: "swift-nio-http2"),
            ]
        ),
        .target(
            name: "_Example",
            dependencies: ["Alchemy"]
        ),
        .target(
            name: "Papyrus-iOS",
            dependencies: ["Alchemy", "Alamofire"]
        ),
        .testTarget(
            name: "AlchemyTests",
            dependencies: ["Alchemy"]
        ),
    ]
)
