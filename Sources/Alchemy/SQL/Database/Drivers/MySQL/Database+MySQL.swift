import NIOSSL

extension Database {
    /// Creates a MySQL database.
    public static func mysql(host: String, port: Int = 3306, database: String, username: String, password: String, enableSSL: Bool = false) -> Database {
        var tls = enableSSL ? TLSConfiguration.makeClientConfiguration() : nil
        tls?.certificateVerification = .none
        let configuration = MySQLConfiguration(
            hostname: host,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: tls
        )
        return mysql(configuration: configuration)
    }

    public static func mysql(url: String) -> Database {
        mysql(configuration: MySQLConfiguration(url: url))
    }

    public static func mysql(unixPath: String, username: String, password: String, database: String) -> Database {
        let configuration = MySQLConfiguration(unixDomainSocketPath: unixPath, username: username, password: password, database: database)
        return mysql(configuration: configuration)
    }

    public static func mysql(configuration: MySQLConfiguration) -> Database {
        Database(provider: MySQLDatabaseProvider(configuration: configuration), dialect: MySQLGrammar())
    }
}
