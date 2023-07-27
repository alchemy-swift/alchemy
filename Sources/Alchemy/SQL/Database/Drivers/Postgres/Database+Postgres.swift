import NIOSSL
import PostgresKit

extension Database {
    /// Creates a PostgreSQL database.
    public static func postgres(host: String, port: Int = 5432, database: String, username: String, password: String, enableSSL: Bool = false) -> Database {
        var tls = enableSSL ? TLSConfiguration.makeClientConfiguration() : nil
        tls?.certificateVerification = .none
        let config = SQLPostgresConfiguration(
            hostname: host,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: tls?.postgres ?? .disable
        )
        return postgres(config: config)
    }

    public static func postgres(url: String) -> Database {
        postgres(config: try! SQLPostgresConfiguration(url: url))
    }

    public static func postgres(unixPath: String, username: String, password: String, database: String) -> Database {
        let config = SQLPostgresConfiguration(unixDomainSocketPath: unixPath, username: username, password: password, database: database)
        return postgres(config: config)
    }

    public static func postgres(config: SQLPostgresConfiguration) -> Database {
        Database(provider: PostgresDatabaseProvider(config: config), dialect: PostgresDialect())
    }
}

extension TLSConfiguration {
    fileprivate var postgres: PostgresConnection.Configuration.TLS {
        do {
            return .prefer(try NIOSSLContext(configuration: self))
        } catch {
            preconditionFailure("Error initializing Postgres TLS: \(error).")
        }
    }
}
