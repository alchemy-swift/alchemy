import NIOSSL
import PostgresNIO

extension Database {
    /// Creates a PostgreSQL database.
    public static func postgres(host: String, port: Int = 5432, database: String, username: String, password: String, enableSSL: Bool = false) -> Database {
        var tls = enableSSL ? TLSConfiguration.makeClientConfiguration() : nil
        tls?.certificateVerification = .none
        let configuration = PostgresConfiguration(
            hostname: host,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: tls.map { .prefer($0.sslContext) } ?? .disable
        )
        return postgres(configuration: configuration)
    }

    public static func postgres(url: String) -> Database {
        postgres(configuration: .init(url: url))
    }

    public static func postgres(unixPath: String, username: String, password: String, database: String) -> Database {
        postgres(configuration: .init(unixDomainSocketPath: unixPath, username: username, password: password, database: database))
    }

    public static func postgres(configuration: PostgresConfiguration) -> Database {
        Database(provider: PostgresDatabaseProvider(configuration: configuration), grammar: PostgresGrammar())
    }
}

extension TLSConfiguration {
    var sslContext: NIOSSLContext {
        do {
            return try NIOSSLContext(configuration: self)
        } catch {
            preconditionFailure("Error initializing Postgres TLS: \(error).")
        }
    }
}
