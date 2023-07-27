import NIOSSL
import MySQLKit

extension Database {
    /// Creates a MySQL database.
    public static func mysql(host: String, port: Int = 3306, database: String, username: String, password: String, enableSSL: Bool = false) -> Database {
        var tls = enableSSL ? TLSConfiguration.makeClientConfiguration() : nil
        tls?.certificateVerification = .none
        let config = MySQLConfiguration(
            hostname: host,
            port: port,
            username: username,
            password: password,
            database: database,
            tlsConfiguration: tls
        )
        return mysql(config: config)
    }

    public static func mysql(url: String) -> Database {
        mysql(config: MySQLConfiguration(url: url)!)
    }

    public static func mysql(unixPath: String, username: String, password: String, database: String) -> Database {
        let config = MySQLConfiguration(unixDomainSocketPath: unixPath, username: username, password: password, database: database)
        return mysql(config: config)
    }

    public static func mysql(config: MySQLConfiguration) -> Database {
        Database(provider: MySQLDatabaseProvider(config: config), dialect: MySQLDialect())
    }
}
