// swift-tools-version:6.0

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "alchemy",
    platforms: [
        .macOS(.v14),
        .iOS(.v16),
    ],
    products: [
        .executable(name: "AlchemyExample", targets: ["AlchemyExample"]),
        .library(name: "Alchemy", targets: ["Alchemy"]),
        .library(name: "AlchemyTesting", targets: ["AlchemyTesting"]),
    ],
    dependencies: [
        "alchemy-swift/cron":                     "2.3.2",
        "alchemy-swift/pluralize":                "1.0.1",
        "apple/swift-log":                        "1.0.0",
        "apple/swift-argument-parser":            "1.0.0",
        "apple/swift-async-algorithms":           "1.0.0",
        "apple/swift-crypto":                     "3.0.0",
        "apple/swift-http-types":                 "1.0.0",
        "swiftlang/swift-syntax":               "602.0.0",
        "hummingbird-project/hummingbird":        "2.5.0",
        "hummingbird-project/hummingbird-auth":   "2.0.2",
        "onevcat/Rainbow":                        "4.0.0",
        "pointfreeco/swift-concurrency-extras":   "1.1.0",
        "swift-server/async-http-client":         "1.0.0",
        "swift-server/RediStack":                 "1.6.2",
        "vapor/async-kit":                        "1.0.0",
        "vapor/multipart-kit":                    "4.7.0",
        "vapor/mysql-nio":                        "1.0.0",
        "vapor/postgres-nio":                    "1.17.0",
        "vapor/sqlite-nio":                       "1.0.0",
        "joshuawright11/AlchemyX":                 "main", // experimental
    ],
    targets: [

        // MARK: Demo

        .executableTarget(
            name: "AlchemyExample",
            dependencies: ["Alchemy"],
            path: "AlchemyExample"
        ),

        // MARK: Alchemy

        .target(
            name: "Alchemy",
            dependencies: [
                
                /// Experimental

                .product(name: "AlchemyX", package: "AlchemyX"),

                /// Core

                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
                .product(name: "Cron", package: "cron"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdHTTP2", package: "hummingbird"),
                .product(name: "HummingbirdTLS", package: "hummingbird"),
                .product(name: "HummingbirdBcrypt", package: "hummingbird-auth"),
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

                "AlchemyPlugin",
            ],
            path: "Alchemy/Sources"
        ),
        .testTarget(
            name: "AlchemyTests",
            dependencies: ["Alchemy", "AlchemyTesting"],
            path: "Alchemy/Tests"
        ),

        // MARK: AlchemyPlugin

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
            dependencies: ["AlchemyPlugin"],
            path: "AlchemyPlugin/Tests"
        ),

        // MARK: AlchemyTesting

        .target(
            name: "AlchemyTesting",
            dependencies: ["Alchemy"],
            path: "AlchemyTesting/Sources"
        ),
        .testTarget(
            name: "AlchemyTestingTests",
            dependencies: ["AlchemyTesting"],
            path: "AlchemyTesting/Tests"
        ),
    ],
    swiftLanguageModes: [.v5]
)

extension [Package.Dependency]: @retroactive ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        self = elements.map { key, value in
            if let version = PackageDescription.Version(value) {
                return .package(url: "https://github.com/\(key)", from: version)
            } else {
                return .package(url: "https://github.com/\(key)", branch: value)
            }
        }
    }
}
