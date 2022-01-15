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
    public static func postgres(host: String, port: Int = 5432, database: String, username: String, password: String, enableSSL: Bool = false) -> Database {
        var tlsConfig = enableSSL ? TLSConfiguration.makeClientConfiguration() : nil
        tlsConfig?.certificateVerification = .none
        return postgres(socket: .ip(host: host, port: port), database: database, username: username, password: password, tlsConfiguration: tlsConfig)
    }
    
    /// Create a PostgreSQL database configuration.
    public static func postgres(socket: Socket, database: String, username: String, password: String, tlsConfiguration: TLSConfiguration? = nil) -> Database {
        Database(provider: PostgresDatabase(socket: socket, database: database, username: username, password: password, tlsConfiguration: tlsConfiguration))
    }
}
