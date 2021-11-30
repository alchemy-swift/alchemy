// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "alchemy",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .library(name: "Alchemy", targets: ["Alchemy"]),
        .library(name: "AlchemyTest", targets: ["AlchemyTest"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "0.15.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-core.git", from: "0.13.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/vapor/postgres-kit", from: "2.4.0"),
        .package(url: "https://github.com/vapor/mysql-kit", from: "4.3.0"),
        .package(url: "https://github.com/vapor/sqlite-kit", from: "4.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0"),
        .package(url: "https://github.com/alchemy-swift/papyrus", from: "0.2.1"),
        .package(url: "https://github.com/alchemy-swift/fusion", from: "0.2.2"),
        .package(url: "https://github.com/alchemy-swift/cron.git", from: "2.3.2"),
        .package(url: "https://github.com/alchemy-swift/pluralize", from: "1.0.1"),
        .package(url: "https://github.com/johnsundell/Plot.git", from: "0.8.0"),
        .package(url: "https://github.com/Mordil/RediStack.git", from: "1.0.0"),
        .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/vadymmarkov/Fakery", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "Alchemy",
            dependencies: [
                /// External dependencies
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "MySQLKit", package: "mysql-kit"),
                .product(name: "PostgresKit", package: "postgres-kit"),
                .product(name: "SQLiteKit", package: "sqlite-kit"),
                .product(name: "RediStack", package: "RediStack"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Plot", package: "Plot"),
                .product(name: "Papyrus", package: "papyrus"),
                .product(name: "Fusion", package: "fusion"),
                .product(name: "Cron", package: "cron"),
                .product(name: "Pluralize", package: "pluralize"),
                .product(name: "Rainbow", package: "Rainbow"),
                .product(name: "Fakery", package: "Fakery"),
                .product(name: "HummingbirdFoundation", package: "hummingbird"),
                .product(name: "HummingbirdHTTP2", package: "hummingbird-core"),
                .product(name: "HummingbirdTLS", package: "hummingbird-core"),
                
                /// Internal dependencies
                .byName(name: "AlchemyC"),
            ]
        ),
        .target(name: "AlchemyC", dependencies: []),
        .target(name: "AlchemyTest", dependencies: ["Alchemy"]),
        .testTarget(
            name: "AlchemyTests",
            dependencies: ["AlchemyTest"],
            path: "Tests/Alchemy"),
        .testTarget(
            name: "AlchemyTestUtilsTests",
            dependencies: ["AlchemyTest"],
            path: "Tests/AlchemyTest"),
    ]
)
