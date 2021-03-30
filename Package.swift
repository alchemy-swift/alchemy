// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "alchemy",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
    ],
    products: [
        .library(name: "Alchemy", targets: ["Alchemy"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.1.0"),
        .package(url: "https://github.com/vapor/mysql-nio.git", from: "1.0.0-rc.2.2"),
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.11.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/postgres-kit", from: "2.0.0"),
        .package(url: "https://github.com/vapor/mysql-kit", from: "4.0.0-rc.1.6"),
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.0")),
        .package(name: "Plot", url: "https://github.com/johnsundell/plot.git", from: "0.8.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "1.0.0-alpha"),
        .package(url: "https://github.com/Mordil/RediStack.git", from: "1.0.0"),
        .package(url: "https://github.com/alchemy-swift/papyrus", .branch("main")),
        .package(url: "https://github.com/alchemy-swift/fusion", .branch("main")),
        .package(name: "Cron", url: "https://github.com/Ponyboy47/Cron-Swift.git", from: "2.3.0"),
    ],
    targets: [
        .target(
            name: "Alchemy",
            dependencies: [
                /// External dependencies
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "PostgresKit", package: "postgres-kit"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "MySQLKit", package: "mysql-kit"),
                .product(name: "MySQLNIO", package: "mysql-nio"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOHTTP2", package: "swift-nio-http2"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Plot", package: "Plot"),
                .product(name: "LifecycleNIOCompat", package: "swift-service-lifecycle"),
                .product(name: "RediStack", package: "RediStack"),
                .product(name: "Papyrus", package: "papyrus"),
                .product(name: "Fusion", package: "fusion"),
                .product(name: "Cron", package: "Cron"),
                
                /// Internal dependencies
                "CAlchemy",
            ]
        ),
        .target(name: "CAlchemy", dependencies: []),
        .testTarget(name: "AlchemyTests", dependencies: ["Alchemy"]),
    ]
)
