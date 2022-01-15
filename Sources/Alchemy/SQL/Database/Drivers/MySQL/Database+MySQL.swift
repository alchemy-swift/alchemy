import NIOSSL

extension Database {
    /// Creates a PostgreSQL database configuration.
    ///
    /// - Parameters:
    ///   - host: The host the database is running on.
    ///   - port: The port the database is running on.
    ///   - database: The name of the database to connect to.
    ///   - username: The username to authorize with.
    ///   - password: The password to authorize with.
    ///   - enableSSL: Should the connection use SSL.
    /// - Returns: The configuration for connecting to this database.
    public static func mysql(host: String, port: Int = 3306, database: String, username: String, password: String, enableSSL: Bool = false) -> Database {
        var tlsConfig = enableSSL ? TLSConfiguration.makeClientConfiguration() : nil
        tlsConfig?.certificateVerification = .none
        return mysql(socket: .ip(host: host, port: port), database: database, username: username, password: password, tlsConfiguration: tlsConfig)
    }
    
    /// Create a PostgreSQL database configuration.
    public static func mysql(socket: Socket, database: String, username: String, password: String, tlsConfiguration: TLSConfiguration? = nil) -> Database {
        Database(provider: MySQLDatabase(socket: socket, database: database, username: username, password: password, tlsConfiguration: tlsConfiguration))
    }
}
