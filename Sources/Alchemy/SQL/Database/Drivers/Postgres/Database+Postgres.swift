extension Database {
    /// Creates a PostgreSQL database configuration.
    ///
    /// - Parameters:
    ///   - host: The host the database is running on.
    ///   - port: The port the database is running on.
    ///   - database: The name of the database to connect to.
    ///   - username: The username to authorize with.
    ///   - password: The password to authorize with.
    /// - Returns: The configuration for connecting to this database.
    public static func postgres(host: String, port: Int = 5432, database: String, username: String, password: String) -> Database {
        return postgres(config: DatabaseConfig(
            socket: .ip(host: host, port: port),
            database: database,
            username: username,
            password: password
        ))
    }
    
    /// Create a PostgreSQL database configuration.
    ///
    /// - Parameter config: The raw configuration to connect with.
    /// - Returns: The configured database.
    public static func postgres(config: DatabaseConfig) -> Database {
        Database(driver: PostgresDatabase(config: config))
    }
}
