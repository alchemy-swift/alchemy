// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "alchemy",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .executable(name: "Demo", targets: ["AlchemyExample"]),
        .library(name: "Alchemy", targets: ["Alchemy"]),
        .library(name: "AlchemyTest", targets: ["AlchemyTest"]),
    ],
    dependencies: [
        .package(path: "../AlchemyX"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "1.8.1"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-core.git", from: "1.3.1"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "3.0.0"),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.17.0"),
        .package(url: "https://github.com/vapor/mysql-nio.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/sqlite-nio.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/multipart-kit", from: "4.5.1"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0"),
        .package(url: "https://github.com/alchemy-swift/cron.git", from: "2.3.2"),
        .package(url: "https://github.com/alchemy-swift/pluralize", from: "1.0.1"),
        .package(url: "https://github.com/swift-server/RediStack", branch: "1.5.1"),
        .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/vadymmarkov/Fakery", from: "5.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "AlchemyExample",
            dependencies: [
                .byName(name: "Alchemy"),
            ],
            path: "Example"
        ),
        .target(
            name: "Alchemy",
            dependencies: [
                /// Experimental

                .product(name: "AlchemyX", package: "AlchemyX"),

                /// Core

                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Cron", package: "cron"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Fakery", package: "Fakery"),
                .product(name: "HummingbirdFoundation", package: "hummingbird"),
                .product(name: "HummingbirdHTTP2", package: "hummingbird-core"),
                .product(name: "HummingbirdTLS", package: "hummingbird-core"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "MultipartKit", package: "multipart-kit"),
                .product(name: "Pluralize", package: "pluralize"),
                .product(name: "Rainbow", package: "Rainbow"),

                /// Databases

                .product(name: "AsyncKit", package: "async-kit"),
                .product(name: "MySQLNIO", package: "mysql-nio"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "SQLiteNIO", package: "sqlite-nio"),
                .product(name: "RediStack", package: "RediStack"),

                /// Internal dependencies

                "AlchemyC",
            ],
            path: "Alchemy"
        ),
        .target(name: "AlchemyC", path: "AlchemyC"),
        .target(
            name: "AlchemyTest",
            dependencies: [
                "Alchemy"
            ],
            path: "AlchemyTest"
        ),
        .testTarget(
            name: "Tests",
            dependencies: [
                "AlchemyTest",
                "Alchemy"
            ],
            path: "Tests"
        ),
    ]
)
