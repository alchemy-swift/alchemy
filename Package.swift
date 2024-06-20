// swift-tools-version:5.10

import CompilerPluginSupport
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
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "1.8.1"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-core.git", from: "1.3.1"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "3.0.0"),
        .package(url: "https://github.com/apple/swift-syntax", from: "510.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.1.0"),
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

        // MARK: Experimental

        .package(url: "https://github.com/joshuawright11/AlchemyX.git", branch: "main"),
    ],
    targets: [

        // MARK: Demo

        .executableTarget(
            name: "AlchemyExample",
            dependencies: [
                .byName(name: "Alchemy"),
            ],
            path: "Example"
        ),

        // MARK: Libraries

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
                "AlchemyPlugin",
            ],
            path: "Alchemy"
        ),
        .target(
            name: "AlchemyC",
            path: "AlchemyC"
        ),
        .target(
            name: "AlchemyTest",
            dependencies: [
                "Alchemy"
            ],
            path: "AlchemyTest"
        ),

        // MARK: Tests

        .testTarget(
            name: "Tests",
            dependencies: [
                "AlchemyTest",
                "Alchemy"
            ],
            path: "Tests"
        ),

        // MARK: Plugin

        .macro(
            name: "AlchemyPlugin",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "AlchemyPlugin/Sources"
        ),
        .testTarget(
            name: "AlchemyPluginTests",
            dependencies: [
                "AlchemyPlugin",
                .product(name: "MacroTesting", package: "swift-macro-testing"),
            ],
            path: "AlchemyPlugin/Tests"
        ),
    ]
)
