extension Database {
    /// Creates a MySQL database configuration.
    ///
    /// - Parameters:
    ///   - host: The host the database is running on.
    ///   - port: The port the database is running on.
    ///   - database: The name of the database to connect to.
    ///   - username: The username to authorize with.
    ///   - password: The password to authorize with.
    /// - Returns: The configuration for connecting to this database.
    public static func mysql(host: String, port: Int = 3306, database: String, username: String, password: String) -> Database {
        return mysql(config: DatabaseConfig(
            socket: .ip(host: host, port: port),
            database: database,
            username: username,
            password: password
        ))
    }
    
    /// Create a MySQL database configuration.
    ///
    /// - Parameter config: The raw configuration to connect with.
    /// - Returns: The configured database.
    public static func mysql(config: DatabaseConfig) -> Database {
        Database(driver: MySQLDatabase(config: config))
    }
}
