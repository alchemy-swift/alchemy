// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "alchemy",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .library(name: "Alchemy", targets: ["Alchemy"]),
        .library(name: "XCTAlchemy", targets: ["XCTAlchemy"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.33.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.6.0"),
        .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.9.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.1.0"),
        .package(url: "https://github.com/vapor/mysql-nio.git", from: "1.3.0"),
        .package(url: "https://github.com/vapor/postgres-kit", from: "2.0.0"),
        .package(url: "https://github.com/vapor/mysql-kit", from: "4.1.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "1.0.0-alpha"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0"),
        .package(path: "../papyrus"),
//        .package(url: "https://github.com/alchemy-swift/papyrus", from: "0.1.0"),
        .package(path: "../fusion"),
//        .package(url: "https://github.com/alchemy-swift/fusion", from: "0.2.0"),
        .package(url: "https://github.com/alchemy-swift/cron.git", from: "2.3.2"),
        .package(url: "https://github.com/alchemy-swift/pluralize", from: "1.0.1"),
        .package(url: "https://github.com/johnsundell/Plot.git", from: "0.8.0"),
        .package(url: "https://github.com/Mordil/RediStack.git", from: "1.0.0"),
        .package(url: "https://github.com/jakeheis/SwiftCLI", .upToNextMajor(from: "6.0.3")),
        .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/vapor/sqlite-kit", from: "4.0.0"),
        .package(url: "https://github.com/vadymmarkov/Fakery", from: "5.0.0"),
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
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Plot", package: "Plot"),
                .product(name: "LifecycleNIOCompat", package: "swift-service-lifecycle"),
                .product(name: "RediStack", package: "RediStack"),
                .product(name: "Papyrus", package: "papyrus"),
                .product(name: "Fusion", package: "fusion"),
                .product(name: "Cron", package: "cron"),
                .product(name: "Pluralize", package: "pluralize"),
                .product(name: "SwiftCLI", package: "SwiftCLI"),
                .product(name: "Rainbow", package: "Rainbow"),
                .product(name: "SQLiteKit", package: "sqlite-kit"),
                .product(name: "Fakery", package: "Fakery"),
                
                /// Internal dependencies
                "CAlchemy",
            ],
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-debug-time-function-bodies"])
            ]
        ),
        .target(name: "CAlchemy", dependencies: []),
        .target(name: "XCTAlchemy", dependencies: ["Alchemy"]),
        .testTarget(name: "AlchemyTests", dependencies: ["XCTAlchemy"]),
    ]
)
